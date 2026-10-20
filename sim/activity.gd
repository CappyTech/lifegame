class_name Activity
extends RefCounted
## Shared plumbing for activities (talk, cab shift, burger shift). An
## activity lives in state.activity while in progress and ends by calling
## finish() with an outcome, which the Outcome screen shows and the report
## draws on.
##
## Outcome shape:
##   money: int                      change to cash in hand
##   energy: int                     change to energy
##   lines: Array[Dictionary]        report-style entries {key, params}
##   relationships: Array[Dictionary] {name, key}  how someone's view of you moved
##   learned: Array[String]          string keys for things found out

const EVENT_ACTIVITY_DONE: StringName = &"activity_done"
const EVENT_ACTIVITY_ABANDONED: StringName = &"activity_abandoned"
const EVENT_AUTOMATION_UNLOCKED: StringName = &"automation_unlocked"
const EVENT_TALKED: StringName = &"talked"

const DEFAULT_UNLOCK_SKILL: float = 0.7


## Appends to an Array held in a Dictionary without an unsafe cast.
static func push(into: Dictionary, key: String, value: Variant) -> void:
	var arr: Array = into[key]
	arr.append(value)


static func push_all(into: Dictionary, key: String, values: Array) -> void:
	var arr: Array = into[key]
	arr.append_array(values)


static func new_outcome() -> Dictionary:
	return {"money": 0, "energy": 0, "lines": [], "relationships": [], "learned": []}


static func step(state: WorldState, choice: Dictionary) -> void:
	match StringName(str(state.activity.get("kind", ""))):
		Sim.ACTIVITY_TALK:
			Talk.step(state, choice)
		Sim.ACTIVITY_CAB:
			Cab.step(state, choice)
		Sim.ACTIVITY_BURGER:
			Burger.step(state, choice)


static func finish(state: WorldState, outcome: Dictionary) -> void:
	var kind: String = str(state.activity.get("kind", ""))
	state.player_money += int(outcome.get("money", 0))
	state.player_energy = clampi(state.player_energy + int(outcome.get("energy", 0)), 0, 100)
	state.last_outcome = outcome
	state.activity = {}
	state.add_event(EVENT_ACTIVITY_DONE, [Person.PLAYER_ID], {"kind": kind})
	state.slot += 1


## Sleeping mid-activity. Walking away costs the slot; a job walked away
## from is remembered by whoever you left (v0: the event alone).
static func abandon(state: WorldState) -> void:
	var kind: String = str(state.activity.get("kind", ""))
	state.activity = {}
	state.add_event(EVENT_ACTIVITY_ABANDONED, [Person.PLAYER_ID], {"kind": kind})
	state.slot += 1


## Applies a conversation choice's effects to a person and writes the
## memory. Returns the relationship line for the outcome, or empty.
static func apply_choice_effects(_state: WorldState, p: Person, effects: Dictionary, event_id: int) -> Dictionary:
	var trust: float = float(effects.get("trust", 0.0))
	var belonging: float = float(effects.get("belonging", 0.0))
	var resentment: float = float(effects.get("resentment", 0.0))
	p.adjust_trust(Person.PLAYER_ID, trust)
	p.adjust_need(&"belonging", belonging)
	p.adjust_resentment(Person.PLAYER_ID, resentment)
	var tag: String = str(effects.get("memory_tag", ""))
	if tag != "":
		p.memories.append({
			"about": Person.PLAYER_ID,
			"event_id": event_id,
			"tag": StringName(tag),
			"weight": 1.0,
			"emotional": bool(effects.get("emotional", false)),
		})
	if trust > 0.0:
		return {"name": p.name, "key": "outcome.rel.up"}
	if trust < 0.0 or resentment > 0.0:
		return {"name": p.name, "key": "outcome.rel.down"}
	return {"name": p.name, "key": "outcome.rel.same"}


## Looks up a conversation from content, or null when there is none (tests
## run without a catalogue; callers fall back to built-in choices).
static func conversation(state: WorldState, id: StringName) -> Conversation:
	if state.catalogue == null:
		return null
	return state.catalogue.conversation(id)


## Choice effects for a conversation id and choice id, from content when
## present, else from the fallback table.
static func choice_effects(state: WorldState, conv_id: StringName, choice_id: String, fallback: Dictionary) -> Dictionary:
	var conv: Conversation = conversation(state, conv_id)
	if conv != null:
		var c: Dictionary = conv.choice(choice_id)
		if not c.is_empty():
			return c
		if choice_id == "silence":
			return {"id": "silence", "memory_tag": conv.silence_memory_tag}
	return fallback.get(choice_id, {})


## Marks a job as masterable once skill passes its threshold. Fires once.
static func check_unlock(state: WorldState, job_id: StringName, outcome: Dictionary) -> void:
	if state.is_auto_unlocked(job_id):
		return
	var threshold: float = DEFAULT_UNLOCK_SKILL
	if state.catalogue != null and state.catalogue.job(job_id) != null:
		threshold = state.catalogue.job(job_id).auto_unlock_skill
	if state.skill(job_id) >= threshold:
		state.auto_unlocked.append(job_id)
		state.add_event(EVENT_AUTOMATION_UNLOCKED, [Person.PLAYER_ID], {"job": String(job_id)})
		Activity.push(outcome, "learned", "outcome.automation." + String(job_id))
