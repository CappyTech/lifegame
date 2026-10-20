class_name Talk
extends RefCounted
## Catching up with someone who matters. One or more beats: their opener,
## your reply, their response, and sometimes a second conversation if you
## asked properly. Raises belonging and trust, eases pressure, and leaves
## memories. Player actions change inputs, never outcomes.

const PRESSURE_RELIEF: float = 0.6

## Used when there is no catalogue (tests) or the person's conversation is
## missing from content. Same numbers as the content "catch_up".
const FALLBACK: Dictionary = {
	"chat": {"id": "chat", "trust": 2.0, "belonging": 8.0, "memory_tag": "talked"},
	"ask": {"id": "ask", "trust": 3.0, "belonging": 6.0, "memory_tag": "asked_after_them", "emotional": true},
	"quiet": {"id": "quiet", "belonging": 3.0, "memory_tag": "talked"},
}
const FALLBACK_PREFIX: String = "conv.catch_up"


static func start(state: WorldState, who: StringName) -> bool:
	var p: Person = state.person(who)
	if p == null:
		return false
	var conv_id: StringName = p.conversation
	if Activity.conversation(state, conv_id) == null and state.catalogue != null:
		conv_id = &"catch_up"
	state.activity = {
		"kind": String(Sim.ACTIVITY_TALK),
		"phase": "talk",
		"person": String(who),
		"conversation": String(conv_id),
		"beats": 0,
		"last_reply_key": "",
		"relationships": [],
		"learned": [],
		"energy": 0,
	}
	return true


static func context(state: WorldState) -> Dictionary:
	var p: Person = state.person(StringName(str(state.activity.get("person", ""))))
	return Activity.context_for_person(state, p) if p != null else {}


## The opener for the current beat.
static func opener_key(state: WorldState) -> String:
	var conv: Conversation = Activity.conversation(state, StringName(str(state.activity.get("conversation", ""))))
	if conv == null:
		return FALLBACK_PREFIX + ".opener"
	return Activity.opener_key(conv, context(state))


## The choices to show for the current beat.
static func choices(state: WorldState) -> Array[Dictionary]:
	var conv: Conversation = Activity.conversation(state, StringName(str(state.activity.get("conversation", ""))))
	return Activity.visible_choices(conv, FALLBACK, FALLBACK_PREFIX, context(state))


static func step(state: WorldState, choice: Dictionary) -> void:
	var a: Dictionary = state.activity
	var who: StringName = StringName(str(a.get("person", "")))
	var p: Person = state.person(who)
	var choice_id: String = str(choice.get("choice", "quiet"))
	var conv_id: StringName = StringName(str(a.get("conversation", "")))
	var ctx: Dictionary = Activity.context_for_person(state, p) if p != null else {}
	var effects: Dictionary = Activity.choice_effects(state, conv_id, choice_id, FALLBACK)
	var reply: String = Activity.reply_key(effects, ctx)

	var e: SimEvent = state.add_event(Activity.EVENT_TALKED, [Person.PLAYER_ID, who], {"choice": choice_id, "conversation": String(conv_id)})
	if p != null:
		for option_id: StringName in p.pressure:
			p.pressure[option_id] = float(p.pressure[option_id]) * PRESSURE_RELIEF
		Activity.push(a, "relationships", Activity.apply_choice_effects(state, p, effects, e.id))
	a["energy"] = int(a["energy"]) + int(effects.get("energy", 0))
	var learn_key: String = str(effects.get("learn_key", ""))
	if learn_key != "" and Activity.learn(state, learn_key, who):
		Activity.push(a, "learned", learn_key)
	a["beats"] = int(a["beats"]) + 1

	var next: StringName = StringName(str(effects.get("next", "")))
	if next != &"" and Activity.conversation(state, next) != null:
		a["conversation"] = String(next)
		a["last_reply_key"] = reply
		return

	var outcome: Dictionary = Activity.new_outcome()
	outcome["energy"] = int(a["energy"])
	outcome["relationships"] = _dedupe(a["relationships"])
	outcome["learned"] = a["learned"]
	if p != null:
		Activity.push(outcome, "lines", {"key": "report.talked", "params": {"name": p.name}})
	outcome["reply_key"] = reply
	Activity.finish(state, outcome)


## One line per person: the last word on how it went.
static func _dedupe(rels: Array) -> Array:
	var by_name: Dictionary = {}
	for r: Dictionary in rels:
		by_name[r["name"]] = r
	var out: Array = []
	for name: Variant in by_name:
		out.append(by_name[name])
	return out
