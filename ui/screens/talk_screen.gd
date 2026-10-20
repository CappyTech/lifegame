extends Control
## Catching up with someone: speaker card and context on the left, the
## conversation on the right. After the reply, the outcome takes the
## conversation's place.

var game: Node
var state: WorldState
var person_id: StringName = &""

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
			"pressure_keys": [],
		})
	if state.activity.is_empty():
		return  # waiting on the reply / outcome flow
	var conv: Conversation = Activity.conversation(state, StringName(str(state.activity["conversation"])))
	var opener_key: String = conv.opener_key if conv != null else "conv.catch_up.opener"
	conversation.visible = true
	outcome.visible = false
	conversation.show_conversation({
		"opener": UiText.keyed(opener_key),
		"choices": UiText.choices(Talk.choices(state)),
		"timer_seconds": conv.timer_seconds if conv != null else 0.0,
		"silence_text": UiText.keyed(conv.silence_key) if conv != null and conv.silence_key != "" else "",
	})


func _on_chosen(choice_id: String) -> void:
	game.call("apply", {"type": "step", "choice": choice_id})
	var reply_key: String = str(state.last_outcome.get("reply_key", ""))
	conversation.show_reply(UiText.keyed(reply_key) if reply_key != "" else "")


func _on_reply_done() -> void:
	conversation.visible = false
	outcome.visible = true
	outcome.show_outcome(UiText.outcome(state.last_outcome))
