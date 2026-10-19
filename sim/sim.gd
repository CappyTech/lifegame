class_name Sim
extends RefCounted
## The simulation entry points. Each takes a WorldState and a choice, mutates
## the state, and returns the events it recorded. Nothing here may touch
## nodes, scenes, the clock or global RNG.

## Choice types the sim understands. Choices are Dictionaries so the UI and
## the conformance files can express them the same way.
const CHOICE_TALK: StringName = &"talk"
const CHOICE_REST: StringName = &"rest"

const EVENT_TALKED: StringName = &"talked"
const EVENT_RESTED: StringName = &"rested"
const EVENT_SLOT_SLIPPED: StringName = &"slot_slipped"
const EVENT_WARNING: StringName = &"person_warning"
const EVENT_ACTED: StringName = &"person_acted"
const EVENT_SLEPT: StringName = &"slept"

## Talking to someone: raises belonging and trust, eases pressure, and leaves
## a memory. Player actions change inputs, never outcomes.
const TALK_BELONGING: float = 8.0
const TALK_TRUST: float = 2.0
const TALK_PRESSURE_RELIEF: float = 0.6

const REST_ENERGY: int = 30


## Applies one player choice in the current slot and advances the slot.
## Returns the events recorded. Unknown choice types record nothing but still
## use the slot, so doing nothing leaves a trace.
static func apply(state: WorldState, choice: Dictionary) -> Array[SimEvent]:
	var before: int = state.events.size()
	var type: StringName = StringName(choice.get("type", ""))
	match type:
		CHOICE_TALK:
			_talk(state, StringName(choice.get("person", "")))
		CHOICE_REST:
			state.player_energy = mini(100, state.player_energy + REST_ENERGY)
			state.add_event(EVENT_RESTED, [Person.PLAYER_ID])
		_:
			state.add_event(EVENT_SLOT_SLIPPED, [Person.PLAYER_ID])
	state.slot += 1
	return state.events.slice(before)


## Ends the day: unused slots slip, needs drift, memories fade, every person
## weighs their options, and the day counter advances. Returns the events,
## which are what the overnight report is built from.
static func sleep(state: WorldState) -> Array[SimEvent]:
	var before: int = state.events.size()
	while state.slot < WorldState.SLOTS_PER_DAY:
		state.add_event(EVENT_SLOT_SLIPPED, [Person.PLAYER_ID])
		state.slot += 1

	for p: Person in state.people:
		People.drift_needs(p)
		People.fade_memories(p)
		_weigh_options(state, p)

	state.add_event(EVENT_SLEPT, [Person.PLAYER_ID])
	state.day += 1
	state.slot = WorldState.SLOT_MORNING
	return state.events.slice(before)


static func _talk(state: WorldState, who: StringName) -> void:
	var p: Person = state.person(who)
	if p == null:
		state.add_event(EVENT_SLOT_SLIPPED, [Person.PLAYER_ID], {"reason": "no_such_person"})
		return
	p.adjust_need(&"belonging", TALK_BELONGING)
	p.adjust_trust(Person.PLAYER_ID, TALK_TRUST)
	for option_id: StringName in p.pressure:
		p.pressure[option_id] = float(p.pressure[option_id]) * TALK_PRESSURE_RELIEF
	var e: SimEvent = state.add_event(EVENT_TALKED, [Person.PLAYER_ID, who])
	p.memories.append({
		"about": Person.PLAYER_ID,
		"event_id": e.id,
		"tag": &"talked",
		"weight": 1.0,
		"emotional": false,
	})


static func _weigh_options(state: WorldState, p: Person) -> void:
	var spent: Array[Dictionary] = []
	for option: Dictionary in p.options:
		var option_id: StringName = option["id"]
		var size: StringName = option["size"]
		var noise: float = state.rng.randf_range(-People.NOISE, People.NOISE)
		var score: float = People.score_option(p, option, noise)
		var pressure: float = People.next_pressure(p.pressure_on(option_id), score)
		var threshold: float = People.threshold_for(size)

		if pressure >= threshold:
			state.add_event(EVENT_ACTED, [p.id], {"option": String(option_id), "size": String(size)})
			p.pressure.erase(option_id)
			p.warned.erase(option_id)
			# A big act (quitting, leaving town) changes the person's situation,
			# so the option is spent. Small and medium acts can recur.
			if size == &"big":
				spent.append(option)
			continue

		if size == &"big" and pressure >= threshold * 0.5 and not bool(p.warned.get(option_id, false)):
			state.add_event(EVENT_WARNING, [p.id], {"option": String(option_id)})
			p.warned[option_id] = true

		p.pressure[option_id] = pressure

	for option: Dictionary in spent:
		p.options.erase(option)
