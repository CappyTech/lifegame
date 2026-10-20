class_name Activity
extends RefCounted
## Shared plumbing for activities (talk, cab shift, burger shift). An
## activity lives in state.activity while in progress and ends by calling
## finish() with an outcome, which the Outcome screen shows and the report
## draws on. Also the conversation machinery: building a context from a
## speaker, checking "when" conditions, picking openers and replies.
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
const EVENT_LEARNED: StringName = &"learned"

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
## memory. Returns the relationship line for the outcome.
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


## Records something the player now knows. Returns true if it was new.
static func learn(state: WorldState, key: String, from: StringName = &"") -> bool:
	if key == "" or state.learned.has(key):
		return false
	state.learned.append(key)
	var actors: Array[StringName] = [Person.PLAYER_ID]
	if from != &"":
		actors.append(from)
	state.add_event(EVENT_LEARNED, actors, {"what": key})
	return true


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


## The context a conversation is checked against, for a person.
static func context_for_person(state: WorldState, p: Person) -> Dictionary:
	var tags: Dictionary = {}
	for m: Dictionary in p.memories:
		if m["about"] == Person.PLAYER_ID:
			tags[String(m["tag"])] = true
	var trust: float = p.trust_toward(Person.PLAYER_ID)
	return {
		"trust": trust,
		"band": String(People.trust_band(trust)),
		"mood": String(People.mood(p)),
		"tags": tags,
		"learned": state.learned,
		"warned": p.warned,
		"rides": 0,
		"day": state.day,
		"needs": p.needs,
		"met": not tags.is_empty(),
	}


## The context for a passer-by record.
static func context_for_passenger(state: WorldState, pax: Dictionary) -> Dictionary:
	var rides: int = int(pax.get("rides", 0))
	var trust: float = float(pax.get("trust", 0.0))
	return {
		"trust": trust,
		"band": String(People.trust_band(trust)),
		"mood": "fine",
		"tags": {"chatted": true} if rides > 0 else {},
		"learned": state.learned,
		"warned": {},
		"rides": rides,
		"day": state.day,
		"needs": {},
		"met": rides > 0,
	}


## Does a "when" condition hold in this context? Empty when always holds.
static func when_ok(ctx: Dictionary, when: Variant) -> bool:
	if not when is Dictionary:
		return true
	var w: Dictionary = when
	if w.is_empty():
		return true
	var tags: Dictionary = ctx.get("tags", {})
	var learned: Array = ctx.get("learned", [])
	if w.has("trust_min") and float(ctx.get("trust", 0.0)) < float(w["trust_min"]):
		return false
	if w.has("trust_max") and float(ctx.get("trust", 0.0)) > float(w["trust_max"]):
		return false
	if w.has("band"):
		var bands: Array = w["band"]
		if not bands.has(str(ctx.get("band", ""))):
			return false
	if w.has("mood"):
		var moods: Array = w["mood"]
		if not moods.has(str(ctx.get("mood", ""))):
			return false
	if w.has("has_memory") and not tags.has(str(w["has_memory"])):
		return false
	if w.has("lacks_memory") and tags.has(str(w["lacks_memory"])):
		return false
	if w.has("learned") and not learned.has(str(w["learned"])):
		return false
	if w.has("not_learned") and learned.has(str(w["not_learned"])):
		return false
	if w.has("warned"):
		var warned: Dictionary = ctx.get("warned", {})
		if not bool(warned.get(StringName(str(w["warned"])), false)):
			return false
	if w.has("rides_min") and int(ctx.get("rides", 0)) < int(w["rides_min"]):
		return false
	if w.has("rides_max") and int(ctx.get("rides", 0)) > int(w["rides_max"]):
		return false
	if w.has("min_day") and int(ctx.get("day", 1)) < int(w["min_day"]):
		return false
	if w.has("first_meeting") and bool(w["first_meeting"]) == bool(ctx.get("met", false)):
		return false
	var needs: Dictionary = ctx.get("needs", {})
	if w.has("need_below"):
		for need: Variant in w["need_below"]:
			if float(needs.get(StringName(str(need)), 100.0)) >= float(w["need_below"][need]):
				return false
	if w.has("need_above"):
		for need: Variant in w["need_above"]:
			if float(needs.get(StringName(str(need)), 0.0)) <= float(w["need_above"][need]):
				return false
	return true


## The opener for this context: first matching conditional opener, else
## the fallback opener_key.
static func opener_key(conv: Conversation, ctx: Dictionary) -> String:
	for o: Dictionary in conv.openers:
		if when_ok(ctx, o.get("when", {})):
			return str(o["text_key"])
	return conv.opener_key


## The choices to show: content choices whose condition holds, or the
## fallback table turned into choices (text keys <prefix>.<id>).
static func visible_choices(conv: Conversation, fallback: Dictionary, fallback_prefix: String, ctx: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if conv != null:
		for c: Dictionary in conv.choices:
			if when_ok(ctx, c.get("when", {})):
				out.append(c)
		return out
	for id: String in fallback:
		out.append({"id": id, "text_key": "%s.%s" % [fallback_prefix, id], "reply_key": "%s.%s.reply" % [fallback_prefix, id]})
	return out


## Their response to a choice in this context.
static func reply_key(choice: Dictionary, ctx: Dictionary) -> String:
	for r: Variant in choice.get("replies", []):
		if not r is Dictionary:
			continue
		var rd: Dictionary = r
		if when_ok(ctx, rd.get("when", {})):
			return str(rd["text_key"])
	return str(choice.get("reply_key", ""))


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
		push(outcome, "learned", "outcome.automation." + String(job_id))
