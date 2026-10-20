extends Control
## The burger shop shift. Shop floor map and context on the left; on the
## right the live beat: choose a shift, engage, the tickets, the outcome.

var game: Node
var state: WorldState
var _reply_read: bool = false

@onready var map: TownMap = %Map
@onready var context: ContextPanel = %Context
@onready var choose: PanelContainer = %Choose
@onready var choose_title: Label = %ChooseTitle
@onready var shift_buttons: VBoxContainer = %ShiftButtons
@onready var engage: VBoxContainer = %Engage
@onready var speaker: SpeakerCard = %Speaker
@onready var conversation: ConversationView = %Conversation
@onready var ticket_work: TicketWork = %TicketWork
@onready var outcome: OutcomeView = %Outcome


func _ready() -> void:
	choose_title.text = tr("ui.choose_shift")
	for shift: String in ["lunch", "evening"]:
		var b := Button.new()
		b.text = "%s\n%s" % [tr("ui.shift." + shift), tr("ui.shift.%s.hint" % shift)]
		b.theme_type_variation = &"Choice"
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func() -> void: game.call("apply", {"type": "step", "shift": shift}))
		shift_buttons.add_child(b)
	conversation.chosen.connect(_on_engage_chosen)
	conversation.continued.connect(_on_reply_read)
	ticket_work.item_pressed.connect(func(item: String) -> void: game.call("apply", {"type": "step", "item": item}))
	outcome.continued.connect(func() -> void: game.call("outcome_done"))


func refresh(with_state: WorldState) -> void:
	state = with_state
	if state.activity.is_empty():
		_show_only(outcome)
		_show_map("")
		outcome.show_outcome(UiText.outcome(state.last_outcome))
		return
	var a: Dictionary = state.activity
	match str(a["phase"]):
		"choose_shift":
			_show_only(choose)
			_show_map("")
			(shift_buttons.get_child(0) as Button).grab_focus()
		"engage":
			_show_only(engage)
			_show_map("pass")
			_show_engage()
		"work":
			var reply_key: String = str(a.get("reply_key", ""))
			if reply_key != "" and not _reply_read:
				_show_only(engage)
				_show_map("pass")
				conversation.show_reply(UiText.keyed(reply_key))
				return
			_show_only(ticket_work)
			var tickets: Array = a["tickets"]
			var ti: int = int(a["ticket"])
			var items: Array = tickets[ti] if ti < tickets.size() else []
			var ii: int = int(a["item"])
			_show_map(TownMap.station_for_item(str(items[ii])) if ii < items.size() else "pass")
			ticket_work.show_ticket({
				"ticket_n": ti + 1,
				"total": tickets.size(),
				"items": items,
				"done": ii,
				"mistakes": int(a["mistakes"]),
				"menu": Burger.MENU,
			})


func _show_engage() -> void:
	var dean: Person = state.person(Burger.OWNER)
	var ctx: Dictionary = Activity.context_for_person(state, dean) if dean != null else {}
	if dean != null:
		speaker.show_speaker(SpeakerCard.data_for_person(dean))
	var conv_id: StringName = StringName(str(state.activity.get("conversation", "burger_engage")))
	var conv: Conversation = Activity.conversation(state, conv_id)
	conversation.show_conversation({
		"opener": UiText.keyed(Activity.opener_key(conv, ctx) if conv != null else "conv.burger_engage.opener"),
		"choices": UiText.choices(Activity.visible_choices(conv, Burger.ENGAGE_FALLBACK, "conv.burger_engage", ctx)),
		"timer_seconds": conv.timer_seconds if conv != null else 0.0,
		"silence_text": UiText.keyed(conv.silence_key) if conv != null and conv.silence_key != "" else "",
	})


func _on_engage_chosen(id: String) -> void:
	game.call("apply", {"type": "step", "choice": id})


func _on_reply_read() -> void:
	_reply_read = true
	refresh(state)


func _show_map(active_station: String) -> void:
	map.show_map({
		"mode": "shop",
		"stations": TownMap.shop_stations(),
		"position": "pass",
		"active_station": active_station,
		"marked": [],
	})
	var mood: String = ""
	var dean: Person = state.person(Burger.OWNER)
	if dean != null:
		mood = ContextPanel.mood_key_for(dean)
	context.show_context({
		"activity_key": "ui.context.burger_shift",
		"place_key": "place.burger_shop.name",
		"mood_key": mood,
		"pressure_keys": [],
	})


func _show_only(panel: Control) -> void:
	for p: Control in [choose, engage, ticket_work, outcome]:
		p.visible = p == panel
