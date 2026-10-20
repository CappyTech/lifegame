class_name Cab
extends RefCounted
## The cab shift: you learn the town. Three fares. For each: choose from
## three dispatch cards, the ride (talk or radio), the drive (route), and
## the drop-off. Regulars open up over rides; a detour shows you something.

const JOB: StringName = &"cab"
const FARES_PER_SHIFT: int = 3
const CARDS_PER_FARE: int = 3
const ENERGY_PER_FARE: int = 8
const DETOUR_ENERGY: int = 2
const AUTO_ENERGY: int = 24
const AUTO_PAY_FACTOR: float = 0.85
const SKILL_PER_FARE: float = 0.03
const SKILL_AUTO: float = 0.01
const ROADWORKS_CHANCE: float = 0.15
const RUNNER_CHANCE: float = 0.3

const EVENT_FARE_TAKEN: StringName = &"fare_taken"
const EVENT_FARE_COMPLETED: StringName = &"fare_completed"
const EVENT_FARE_DODGED: StringName = &"fare_dodged"
const EVENT_ROADWORKS: StringName = &"roadworks"
const EVENT_NOTICED: StringName = &"noticed"
const EVENT_RUMOUR: StringName = &"rumour"
const EVENT_SHIFT_WORKED: StringName = &"shift_worked"

## Zone per place when there is no catalogue (tests).
const FALLBACK_ZONES: Dictionary = {
	"high_street": 1, "council": 1, "crown": 1, "burger_shop": 1,
	"estate": 2, "chippy": 2, "hospital": 2, "station": 2, "retail_park": 3,
}

## Places worth noticing on a detour, in a fixed order.
const SIGHTS: Array[String] = ["chippy", "retail_park", "crown", "high_street"]

const RIDE_FALLBACK: Dictionary = {
	"chat": {"id": "chat", "trust": 3.0, "belonging": 4.0, "memory_tag": "chatted"},
	"ask": {"id": "ask", "trust": 4.0, "belonging": 3.0, "memory_tag": "asked"},
	"radio": {"id": "radio"},
}


static func start(state: WorldState, auto: bool) -> bool:
	if state.passers_by.is_empty():
		return false
	if auto and state.is_auto_unlocked(JOB):
		_auto(state)
		return true
	state.activity = {
		"kind": String(Sim.ACTIVITY_CAB),
		"phase": "choose_fare",
		"fares": deal_fares(state),
		"fare": {},
		"done": 0,
		"earned": 0,
		"tips": 0,
		"energy": 0,
		"lines": [],
		"relationships": [],
		"learned": [],
		"fare_outcome": {},
	}
	return true


## Three dispatch cards: passenger, destination, fare, what they're like.
static func deal_fares(state: WorldState) -> Array[Dictionary]:
	var ids: Array[String] = []
	for k: String in state.passers_by:
		ids.append(k)
	ids.sort()
	var zones: Dictionary = _zones(state)
	var cards: Array[Dictionary] = []
	while cards.size() < CARDS_PER_FARE and not ids.is_empty():
		var pid: String = ids.pop_at(state.rng.randi_range(0, ids.size() - 1))
		var pax: Dictionary = state.passers_by[pid]
		var dests: Array[String] = []
		for place: String in zones:
			if place != str(pax["home"]):
				dests.append(place)
		var dest: String = dests[state.rng.randi_range(0, dests.size() - 1)]
		var zone: int = int(zones[dest])
		var fare: int = 4 + zone * 3 + state.rng.randi_range(0, 2)
		cards.append({
			"passenger": pid,
			"name": str(pax["name"]),
			"destination": dest,
			"zone": zone,
			"fare": fare,
			"trait": str(pax["trait"]),
			"regular": int(pax["rides"]) >= 2,
			"said": "",
		})
	return cards


static func step(state: WorldState, choice: Dictionary) -> void:
	var a: Dictionary = state.activity
	match str(a["phase"]):
		"choose_fare":
			var idx: int = int(choice.get("fare", -1))
			var fares: Array = a["fares"]
			if idx < 0 or idx >= fares.size():
				return
			a["fare"] = fares[idx]
			state.add_event(EVENT_FARE_TAKEN, [Person.PLAYER_ID], {"passenger": a["fare"]["passenger"], "destination": a["fare"]["destination"]})
			a["phase"] = "drive" if str(a["fare"]["trait"]) == "quiet" else "ride"
		"ride":
			_ride(state, a, str(choice.get("choice", "radio")))
		"drive":
			_drive(state, a, str(choice.get("route", "main")))
		"fare_done":
			a["done"] = int(a["done"]) + 1
			a["fare_outcome"] = {}
			if int(a["done"]) >= FARES_PER_SHIFT:
				_finish(state, a)
			else:
				a["fares"] = deal_fares(state)
				a["fare"] = {}
				a["phase"] = "choose_fare"


static func _ride(state: WorldState, a: Dictionary, said: String) -> void:
	var fare: Dictionary = a["fare"]
	var pid: String = str(fare["passenger"])
	var pax: Dictionary = state.passers_by[pid]
	var effects: Dictionary = Activity.choice_effects(state, &"ride", said, RIDE_FALLBACK)
	pax["trust"] = float(pax["trust"]) + float(effects.get("trust", 0.0))
	fare["said"] = said
	fare["reply_key"] = str(effects.get("reply_key", ""))
	if said == "ask" and int(pax["rides"]) >= 1 and str(pax["knows"]) != "":
		var key: String = "rumour." + str(pax["knows"])
		if not state.learned.has(key):
			state.learned.append(key)
			state.add_event(EVENT_RUMOUR, [Person.PLAYER_ID], {"from": pid, "about": str(pax["knows"])})
			Activity.push(a, "learned", key)
			fare["rumour"] = key
	a["phase"] = "drive"


static func _drive(state: WorldState, a: Dictionary, route: String) -> void:
	var fare: Dictionary = a["fare"]
	var pid: String = str(fare["passenger"])
	var pax: Dictionary = state.passers_by[pid]
	var price: int = int(fare["fare"])
	var tip: int = 0
	var energy: int = -ENERGY_PER_FARE
	var out: Dictionary = Activity.new_outcome()
	var said: String = str(fare.get("said", ""))

	if said == "chat" or said == "ask":
		tip += 1 + state.rng.randi_range(0, 1)
	if route == "main":
		tip += int(round(price * 0.1))
	else:
		energy -= DETOUR_ENERGY
		var sight: String = SIGHTS[state.rng.randi_range(0, SIGHTS.size() - 1)]
		var key: String = "seen." + sight
		state.add_event(EVENT_NOTICED, [Person.PLAYER_ID], {"place": sight})
		if not state.learned.has(key):
			state.learned.append(key)
			Activity.push(a, "learned", key)
		Activity.push(out, "learned", key)
	if state.rng.randf() < ROADWORKS_CHANCE:
		tip = maxi(0, tip - 1)
		state.add_event(EVENT_ROADWORKS, [Person.PLAYER_ID])
		Activity.push(out, "lines", {"key": "outcome.roadworks", "params": {}})

	var dodged: bool = str(fare["trait"]) == "late_lads" and state.rng.randf() < RUNNER_CHANCE
	if dodged:
		price = 0
		tip = 0
		state.add_event(EVENT_FARE_DODGED, [Person.PLAYER_ID], {"passenger": pid})
		Activity.push(out, "lines", {"key": "outcome.fare_dodged", "params": {"name": fare["name"]}})
	else:
		Activity.push(out, "lines", {"key": "outcome.fare", "params": {"name": fare["name"], "fare": price, "tip": tip}})

	if int(pax["rides"]) == 0:
		state.player_known += 1
	pax["rides"] = int(pax["rides"]) + 1
	state.add_skill(JOB, SKILL_PER_FARE)
	state.add_event(EVENT_FARE_COMPLETED, [Person.PLAYER_ID], {
		"passenger": pid, "destination": fare["destination"], "fare": price, "tip": tip, "route": route, "said": said,
	}, StringName(str(fare["destination"])))

	if said != "" and said != "radio" and not dodged:
		Activity.push(out, "relationships", {"name": fare["name"], "key": "outcome.rel.up"})
	if fare.has("rumour"):
		Activity.push(out, "learned", str(fare["rumour"]))

	out["money"] = price + tip
	out["energy"] = energy
	a["earned"] = int(a["earned"]) + price
	a["tips"] = int(a["tips"]) + tip
	a["energy"] = int(a["energy"]) + energy
	Activity.push_all(a, "lines", out["lines"])
	Activity.push_all(a, "relationships", out["relationships"])
	a["fare_outcome"] = out
	a["phase"] = "fare_done"


static func _finish(state: WorldState, a: Dictionary) -> void:
	var out: Dictionary = Activity.new_outcome()
	out["money"] = int(a["earned"]) + int(a["tips"])
	out["energy"] = int(a["energy"])
	out["lines"] = [{"key": "outcome.cab_shift", "params": {"fares": FARES_PER_SHIFT, "earned": a["earned"], "tips": a["tips"]}}]
	out["relationships"] = a["relationships"]
	out["learned"] = a["learned"]
	state.add_event(EVENT_SHIFT_WORKED, [Person.PLAYER_ID], {"job": String(JOB), "pay": out["money"], "auto": false})
	Activity.check_unlock(state, JOB, out)
	Activity.finish(state, out)


## Automated shift: the fares happen, the people and rumours don't.
static func _auto(state: WorldState) -> void:
	var earned: int = 0
	for _i: int in FARES_PER_SHIFT:
		var cards: Array[Dictionary] = deal_fares(state)
		var fare: Dictionary = cards[0]
		var pid: String = str(fare["passenger"])
		var pax: Dictionary = state.passers_by[pid]
		pax["rides"] = int(pax["rides"]) + 1
		earned += int(fare["fare"])
		state.add_event(EVENT_FARE_COMPLETED, [Person.PLAYER_ID], {
			"passenger": pid, "destination": fare["destination"], "fare": fare["fare"], "tip": 0, "route": "main", "said": "auto",
		}, StringName(str(fare["destination"])))
		state.add_skill(JOB, SKILL_AUTO)
	var out: Dictionary = Activity.new_outcome()
	out["money"] = int(round(earned * AUTO_PAY_FACTOR))
	out["energy"] = -AUTO_ENERGY
	out["lines"] = [{"key": "outcome.cab_shift_auto", "params": {"fares": FARES_PER_SHIFT, "earned": out["money"]}}]
	state.add_event(EVENT_SHIFT_WORKED, [Person.PLAYER_ID], {"job": String(JOB), "pay": out["money"], "auto": true})
	state.activity = {"kind": String(Sim.ACTIVITY_CAB)}
	Activity.finish(state, out)


static func _zones(state: WorldState) -> Dictionary:
	if state.catalogue == null or state.catalogue.places.is_empty():
		return FALLBACK_ZONES
	var zones: Dictionary = {}
	for id: StringName in state.catalogue.place_ids():
		var place: PlaceDef = state.catalogue.place(id)
		if place.fare_zone > 0:
			zones[String(id)] = place.fare_zone
	return zones
