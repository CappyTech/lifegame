class_name Sim
extends RefCounted
## The simulation entry points. Each takes a WorldState and a choice,
## mutates the state, and returns the events it recorded. Nothing here may
## touch nodes, scenes, the clock or global RNG.
##
## Choices are Dictionaries so the UI and the conformance files express
## them the same way:
##   {"type": "deal"} / {"type": "reroll"} / {"type": "pick", "card": id}
##   {"type": "start", "activity": "talk", "person": id}
##   {"type": "start", "activity": "cab_shift", "auto": false}
##   {"type": "start", "activity": "burger_shift", "auto": false}
##   {"type": "rest"}
##   {"type": "step", ...}      handed to the activity in progress
##   {}                         let the slot slip

const CHOICE_DEAL: StringName = &"deal"
const CHOICE_REROLL: StringName = &"reroll"
const CHOICE_PICK: StringName = &"pick"
const CHOICE_START: StringName = &"start"
const CHOICE_STEP: StringName = &"step"
const CHOICE_REST: StringName = &"rest"

const ACTIVITY_TALK: StringName = &"talk"
const ACTIVITY_CAB: StringName = &"cab_shift"
const ACTIVITY_BURGER: StringName = &"burger_shift"

const EVENT_RESTED: StringName = &"rested"
const EVENT_SLOT_SLIPPED: StringName = &"slot_slipped"
const EVENT_WARNING: StringName = &"person_warning"
const EVENT_ACTED: StringName = &"person_acted"
const EVENT_SLEPT: StringName = &"slept"

const REST_ENERGY: int = 30
const SLEEP_ENERGY: int = 40


## Applies one player choice. Instant choices use the current slot;
## starting an activity does not until it finishes. Returns the events
## recorded. An unknown choice still uses the slot, so doing nothing
## leaves a trace.
static func apply(state: WorldState, choice: Dictionary) -> Array[SimEvent]:
	var before: int = state.events.size()
	var type: StringName = StringName(str(choice.get("type", "")))

	if state.phase == WorldState.PHASE_DEALING:
		_apply_dealing(state, type, choice)
		return state.events.slice(before)

	if not state.activity.is_empty():
		if type == CHOICE_STEP:
			Activity.step(state, choice)
		return state.events.slice(before)

	if state.slot >= WorldState.SLOTS_PER_DAY:
		return state.events.slice(before)

	match type:
		CHOICE_START:
			_start(state, choice)
		CHOICE_REST:
			state.player_energy = mini(100, state.player_energy + REST_ENERGY)
			state.add_event(EVENT_RESTED, [Person.PLAYER_ID])
			state.slot += 1
		_:
			state.add_event(EVENT_SLOT_SLIPPED, [Person.PLAYER_ID])
			state.slot += 1
	return state.events.slice(before)


## Ends the day: unused slots slip, needs drift, memories fade, every person
## weighs their options, and the day counter advances. Returns the events,
## which are what the overnight report is built from.
static func sleep(state: WorldState) -> Array[SimEvent]:
	var before: int = state.events.size()
	if not state.activity.is_empty():
		Activity.abandon(state)
	while state.slot < WorldState.SLOTS_PER_DAY:
		state.add_event(EVENT_SLOT_SLIPPED, [Person.PLAYER_ID])
		state.slot += 1

	for p: Person in state.people:
		People.drift_needs(p)
		People.fade_memories(p)
		_weigh_options(state, p)

	state.player_energy = mini(100, state.player_energy + SLEEP_ENERGY)
	state.add_event(EVENT_SLEPT, [Person.PLAYER_ID])
	state.day += 1
	state.slot = WorldState.SLOT_MORNING
	return state.events.slice(before)


static func _apply_dealing(state: WorldState, type: StringName, choice: Dictionary) -> void:
	match type:
		CHOICE_DEAL:
			Hand.deal(state)
		CHOICE_REROLL:
			Hand.reroll(state)
		CHOICE_PICK:
			Hand.pick(state, StringName(str(choice.get("card", ""))))


static func _start(state: WorldState, choice: Dictionary) -> void:
	var kind: StringName = StringName(str(choice.get("activity", "")))
	var auto: bool = bool(choice.get("auto", false))
	var started: bool = false
	match kind:
		ACTIVITY_TALK:
			started = Talk.start(state, StringName(str(choice.get("person", ""))))
		ACTIVITY_CAB:
			started = Cab.start(state, auto)
		ACTIVITY_BURGER:
			started = Burger.start(state, auto)
	if not started:
		state.add_event(EVENT_SLOT_SLIPPED, [Person.PLAYER_ID], {"reason": "could_not_start", "activity": String(kind)})
		state.slot += 1


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
