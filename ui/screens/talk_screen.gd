extends Control
## Catching up with someone: speaker card and context on the left, the
## conversation on the right. Each beat: their opener, your reply, their
## response, Carry on. A conversation may run to a second beat; when it
## ends, the outcome takes the conversation's place.

var game: Node
var state: WorldState
var person_id: StringName = &""
## True between choosing a reply and pressing Carry on, so a refresh from
## the game does not redraw over the response.
var _reading_reply: bool = false

@onready var speaker: SpeakerCard = %Speaker
@onready var context: ContextPanel = %Context
@onready var conversation: ConversationView = %Conversation
@onready var outcome: OutcomeView = %Outcome


func _ready() -> void:
	conversation.chosen.connect(_on_chosen)
	conversation.continued.connect(_on_reply_done)
	outcome.continued.connect(func() -> void: game.call("outcome_done"))


func refresh(with_state: WorldState) -> void:
	state = with_state
	if not state.activity.is_empty():
		person_id = StringName(str(state.activity["person"]))
	var p: Person = state.person(person_id)
	if p != null:
		speaker.show_speaker(SpeakerCard.data_for_person(p))
		context.show_context({
			"activity_key": "ui.context.talk",
			"place_key": "",
			"mood_key": ContextPanel.mood_key_for(p),
			"pressure_keys": _pressures(p),
		})
	if state.activity.is_empty() or _reading_reply:
		return
	var conv: Conversation = Activity.conversation(state, StringName(str(state.activity["conversation"])))
	conversation.visible = true
	outcome.visible = false
	conversation.show_conversation({
		"opener": UiText.keyed(Talk.opener_key(state)),
		"choices": UiText.choices(Talk.choices(state)),
		"timer_seconds": conv.timer_seconds if conv != null else 0.0,
		"silence_text": UiText.keyed(conv.silence_key) if conv != null and conv.silence_key != "" else "",
	})


func _pressures(p: Person) -> Array[String]:
	var out: Array[String] = []
	for option_id: StringName in p.warned:
		if bool(p.warned[option_id]):
			out.append("ui.context.pressure.warned")
			break
	return out


func _on_chosen(choice_id: String) -> void:
	_reading_reply = true
	game.call("apply", {"type": "step", "choice": choice_id})
	var reply_key: String = ""
	if state.activity.is_empty():
		reply_key = str(state.last_outcome.get("reply_key", ""))
	else:
		reply_key = str(state.activity.get("last_reply_key", ""))
	conversation.show_reply(UiText.keyed(reply_key) if reply_key != "" else "")


func _on_reply_done() -> void:
	_reading_reply = false
	if state.activity.is_empty():
		conversation.visible = false
		outcome.visible = true
		outcome.show_outcome(UiText.outcome(state.last_outcome))
	else:
		refresh(state)
