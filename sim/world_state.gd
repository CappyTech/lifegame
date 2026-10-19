class_name WorldState
extends RefCounted
## Everything the sim knows about one life. Plain data; Sim mutates it.
## Carries its own RandomNumberGenerator so results depend only on the seed
## and the choices made.

const SAVE_VERSION: int = 1

const SLOT_MORNING: int = 0
const SLOT_AFTERNOON: int = 1
const SLOT_EVENING: int = 2
const SLOTS_PER_DAY: int = 3

var seed: int = 0
var day: int = 1
var slot: int = SLOT_MORNING
var rerolls_left: int = 3
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var player_money: int = 0
var player_energy: int = 100

var people: Array[Person] = []
var events: Array[SimEvent] = []
var next_event_id: int = 1


static func create(world_seed: int) -> WorldState:
	var s := WorldState.new()
	s.seed = world_seed
	s.rng.seed = world_seed
	return s


func person(id: StringName) -> Person:
	for p: Person in people:
		if p.id == id:
			return p
	return null


func add_person(p: Person) -> void:
	assert(person(p.id) == null, "duplicate person id %s" % p.id)
	people.append(p)


func add_event(type: StringName, actors: Array[StringName], data: Dictionary = {}, place: StringName = &"") -> SimEvent:
	var e := SimEvent.new()
	e.id = next_event_id
	next_event_id += 1
	e.day = day
	e.slot = slot
	e.type = type
	e.actors = actors
	e.place = place
	e.data = data
	events.append(e)
	return e


## Events recorded on a given day, in order.
func events_on(which_day: int) -> Array[SimEvent]:
	var out: Array[SimEvent] = []
	for e: SimEvent in events:
		if e.day == which_day:
			out.append(e)
	return out


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"seed": seed,
		"day": day,
		"slot": slot,
		"rerolls_left": rerolls_left,
		"rng_state": rng.state,
		"player": {"money": player_money, "energy": player_energy},
		"people": people.map(func(p: Person) -> Dictionary: return p.to_dict()),
		"events": events.map(func(e: SimEvent) -> Dictionary: return e.to_dict()),
		"next_event_id": next_event_id,
	}
