class_name Talk
extends RefCounted
## Catching up with someone who matters. One exchange: their opener, your
## reply, their response. Raises belonging and trust, eases pressure, and
## leaves a memory. Player actions change inputs, never outcomes.

const PRESSURE_RELIEF: float = 0.6

## Used when there is no catalogue (tests) or the person's conversation is
## missing from content. Same numbers as the content "catch_up".
const FALLBACK: Dictionary = {
	"chat": {"id": "chat", "trust": 2.0, "belonging": 8.0, "memory_tag": "talked"},
	"ask": {"id": "ask", "trust": 3.0, "belonging": 6.0, "memory_tag": "asked_after_them", "emotional": true},
	"quiet": {"id": "quiet", "belonging": 3.0, "memory_tag": "talked"},
}


static func start(state: WorldState, who: StringName) -> bool:
	var p: Person = state.person(who)
	if p == null:
		return false
	state.activity = {
		"kind": String(Sim.ACTIVITY_TALK),
		"phase": "talk",
		"person": String(who),
		"conversation": String(p.conversation),
	}
	return true


## The choices to show: from content when present, else the fallback.
static func choices(state: WorldState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var conv: Conversation = Activity.conversation(state, StringName(str(state.activity.get("conversation", ""))))
	if conv != null:
		for c: Dictionary in conv.choices:
			out.append(c)
		return out
	for id: String in FALLBACK:
		out.append({"id": id, "text_key": "conv.catch_up." + id, "reply_key": "conv.catch_up.%s.reply" % id})
	return out


static func step(state: WorldState, choice: Dictionary) -> void:
	var who: StringName = StringName(str(state.activity.get("person", "")))
	var p: Person = state.person(who)
	var choice_id: String = str(choice.get("choice", "quiet"))
	var conv_id: StringName = StringName(str(state.activity.get("conversation", "")))
	var effects: Dictionary = Activity.choice_effects(state, conv_id, choice_id, FALLBACK)

	var outcome: Dictionary = Activity.new_outcome()
	var e: SimEvent = state.add_event(Activity.EVENT_TALKED, [Person.PLAYER_ID, who], {"choice": choice_id})
	if p != null:
		for option_id: StringName in p.pressure:
			p.pressure[option_id] = float(p.pressure[option_id]) * PRESSURE_RELIEF
		Activity.push(outcome, "relationships", Activity.apply_choice_effects(state, p, effects, e.id))
		Activity.push(outcome, "lines", {"key": "report.talked", "params": {"name": p.name}})
	outcome["energy"] = int(effects.get("energy", 0))
	outcome["reply_key"] = str(effects.get("reply_key", ""))
	Activity.finish(state, outcome)
