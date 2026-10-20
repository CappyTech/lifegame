extends Control
## The cab shift. Map and context on the left; on the right whichever beat
## is live: dispatch cards, the ride, the drive, or a drop-off / end of
## shift outcome.

var game: Node
var state: WorldState
## Passenger whose ride reply has been read, so the drive can show.
var _reply_read_for: String = ""

@onready var map: TownMap = %Map
@onready var context: ContextPanel = %Context
@onready var dispatch: PanelContainer = %Dispatch
@onready var dispatch_title: Label = %DispatchTitle
@onready var dispatch_hint: Label = %DispatchHint
@onready var fare_cards: VBoxContainer = %FareCards
@onready var ride: VBoxContainer = %Ride
@onready var speaker: SpeakerCard = %Speaker
@onready var conversation: ConversationView = %Conversation
@onready var route_work: RouteWork = %RouteWork
@onready var outcome: OutcomeView = %Outcome


func _ready() -> void:
	dispatch_title.text = tr("ui.choose_fare")
	dispatch_hint.text = tr("ui.choose_fare_hint")
	conversation.chosen.connect(func(id: String) -> void: game.call("apply", {"type": "step", "choice": id}))
	conversation.continued.connect(_show_drive)
	route_work.chosen.connect(func(id: String) -> void: game.call("apply", {"type": "step", "route": id}))
	outcome.continued.connect(_on_outcome_done)


func refresh(with_state: WorldState) -> void:
	state = with_state
	if state.activity.is_empty():
		_show_only(outcome)
		_show_map("cab_office", "", [])
		_show_context("place.cab_office.name", [])
		outcome.show_outcome(UiText.outcome(state.last_outcome))
		return
	var a: Dictionary = state.activity
	var fare: Dictionary = a.get("fare", {})
	match str(a["phase"]):
		"choose_fare":
			_show_only(dispatch)
			var marked: Array[String] = []
			for c: Dictionary in a["fares"]:
				marked.append(str(c["destination"]))
			_show_map("cab_office", "", marked)
			_show_context("place.cab_office.name", [])
			_show_fares(a["fares"])
		"ride":
			_show_only(ride)
			_show_map("cab_office", str(fare["destination"]), [])
			_show_context("place.cab_office.name", _pressures(fare))
			_show_ride(fare)
		"drive":
			_show_map("cab_office", str(fare["destination"]), [])
			_show_context("place.cab_office.name", _pressures(fare))
			var reply_key: String = str(fare.get("reply_key", ""))
			if reply_key != "" and _reply_read_for != str(fare["passenger"]):
				_show_only(ride)
				conversation.show_reply(UiText.keyed(reply_key))
				return
			_show_only(route_work)
			route_work.show_routes({
				"title_key": "ui.the_drive",
				"hint_key": "ui.the_drive_hint",
				"routes": [
					{"id": "main", "label_key": "ui.route.main", "hint_key": "ui.route.main.hint"},
					{"id": "detour", "label_key": "ui.route.detour", "hint_key": "ui.route.detour.hint"},
				],
			})
		"fare_done":
			_show_only(outcome)
			_show_map(str(fare["destination"]), "", [])
			_show_context("place.%s.name" % str(fare["destination"]), [])
			var more: bool = int(a["done"]) + 1 < Cab.FARES_PER_SHIFT
			outcome.show_outcome(UiText.outcome(a["fare_outcome"], "ui.next_fare" if more else "ui.continue"))


func _show_fares(cards: Array) -> void:
	for child: Node in fare_cards.get_children():
		fare_cards.remove_child(child)
		child.queue_free()
	var first: Button = null
	for i: int in cards.size():
		var c: Dictionary = cards[i]
		var b := Button.new()
		var who: String = tr("ui.fare_card").format({"name": c["name"], "destination": tr("place.%s.name" % str(c["destination"]))})
		var trait_key: String = "ui.fare_trait." + ("long_trip" if int(c["zone"]) >= 3 else str(c["trait"]))
		b.text = "%s   %s\n%s" % [who, tr("ui.fare_price").format({"fare": c["fare"]}), tr(trait_key)]
		b.theme_type_variation = &"Choice"
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func() -> void: game.call("apply", {"type": "step", "fare": i}))
		fare_cards.add_child(b)
		if first == null:
			first = b
	if first != null:
		first.grab_focus()


func _show_ride(fare: Dictionary) -> void:
	var pax: Dictionary = state.passers_by[str(fare["passenger"])]
	speaker.show_speaker(SpeakerCard.data_for_passenger(pax, str(fare["trait"])))
	var conv: Conversation = Activity.conversation(state, &"ride")
	var choices: Array[Dictionary] = []
	if conv != null:
		for c: Dictionary in conv.choices:
			choices.append(c)
	else:
		for id: String in Cab.RIDE_FALLBACK:
			choices.append({"id": id, "text_key": "conv.ride." + id})
	conversation.visible = true
	conversation.show_conversation({
		"opener": UiText.keyed(conv.opener_key if conv != null else "conv.ride.opener"),
		"choices": UiText.choices(choices),
		"timer_seconds": 0.0,
	})


## The reply has been read; on to the drive.
func _show_drive() -> void:
	var fare: Dictionary = state.activity.get("fare", {})
	_reply_read_for = str(fare.get("passenger", ""))
	refresh(state)


func _pressures(fare: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var pax: Dictionary = state.passers_by[str(fare["passenger"])]
	if int(pax["rides"]) > 0:
		out.append("ui.context.pressure.known")
	if str(pax["knows"]) != "" and int(pax["rides"]) >= 1:
		out.append("ui.context.pressure.rumour")
	if str(fare["trait"]) == "late_lads":
		out.append("ui.context.pressure.risk")
	return out


func _show_map(at: String, destination: String, marked: Array[String]) -> void:
	map.show_map({
		"mode": "town",
		"places": TownMap.town_places(state.catalogue),
		"position": at,
		"destination": destination,
		"marked": marked,
	})


func _show_context(place_key: String, pressure_keys: Array[String]) -> void:
	context.show_context({
		"activity_key": "ui.context.cab_shift",
		"place_key": place_key,
		"mood_key": "",
		"pressure_keys": pressure_keys,
	})


func _show_only(panel: Control) -> void:
	for p: Control in [dispatch, ride, route_work, outcome]:
		p.visible = p == panel


func _on_outcome_done() -> void:
	if state.activity.is_empty():
		game.call("outcome_done")
	else:
		game.call("apply", {"type": "step"})
