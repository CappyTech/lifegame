class_name WorldState
extends RefCounted
## Everything the sim knows about one life. Plain data; Sim mutates it.
## Carries its own RandomNumberGenerator so results depend only on the seed
## and the choices made.

const SAVE_VERSION: int = 2

const SLOT_MORNING: int = 0
const SLOT_AFTERNOON: int = 1
const SLOT_EVENING: int = 2
const SLOTS_PER_DAY: int = 3

const PHASE_DEALING: StringName = &"dealing"
const PHASE_LIVING: StringName = &"living"

## Content. Not part of the save; set at creation.
var catalogue: Catalogue = null

var world_seed: int = 0
var day: int = 1
var slot: int = SLOT_MORNING
var rerolls_left: int = 3
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var phase: StringName = PHASE_DEALING
var hand: Array[StringName] = []
var life_card: StringName = &""

var player_money: int = 0
var player_energy: int = 100
var player_known: int = 0
## Job id -> skill 0..1.
var job_skills: Dictionary = {}
var auto_unlocked: Array[StringName] = []
## Things the player has learned (rumour keys, places noticed).
var learned: Array[String] = []

var people: Array[Person] = []
## Light records for passers-by: id -> {name, trait, home, rides, trust, knows}.
var passers_by: Dictionary = {}

## The activity in progress, or empty. Shape depends on "kind".
var activity: Dictionary = {}
## The last finished activity's outcome, for the Outcome screen.
var last_outcome: Dictionary = {}

var events: Array[SimEvent] = []
var next_event_id: int = 1


static func create(with_seed: int, with_catalogue: Catalogue = null) -> WorldState:
	var s := WorldState.new()
	s.world_seed = with_seed
	s.rng.seed = with_seed
	s.catalogue = with_catalogue
	return s


func person(id: StringName) -> Person:
	for p: Person in people:
		if p.id == id:
			return p
	return null


func add_person(p: Person) -> void:
	assert(person(p.id) == null, "duplicate person id %s" % p.id)
	people.append(p)


func skill(job_id: StringName) -> float:
	return float(job_skills.get(job_id, 0.0))


func add_skill(job_id: StringName, delta: float) -> void:
	job_skills[job_id] = clampf(skill(job_id) + delta, 0.0, 1.0)


func is_auto_unlocked(job_id: StringName) -> bool:
	return auto_unlocked.has(job_id)


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
		"seed": world_seed,
		"day": day,
		"slot": slot,
		"rerolls_left": rerolls_left,
		"rng_state": rng.state,
		"phase": String(phase),
		"hand": hand.map(func(c: StringName) -> String: return String(c)),
		"life_card": String(life_card),
		"player": {
			"money": player_money,
			"energy": player_energy,
			"known": player_known,
			"job_skills": job_skills.duplicate(),
			"auto_unlocked": auto_unlocked.map(func(j: StringName) -> String: return String(j)),
			"learned": learned.duplicate(),
		},
		"people": people.map(func(p: Person) -> Dictionary: return p.to_dict()),
		"passers_by": passers_by.duplicate(true),
		"activity": activity.duplicate(true),
		"last_outcome": last_outcome.duplicate(true),
		"events": events.map(func(e: SimEvent) -> Dictionary: return e.to_dict()),
		"next_event_id": next_event_id,
	}
