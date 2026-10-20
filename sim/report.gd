class_name Report
extends RefCounted
## Builds the overnight report from a day's events. Returns entries, not
## text: each is {"key": String, "params": Dictionary, "event_id": int,
## "slot": int}. The UI translates the key with tr() and formats the
## params. Keeping text out of the sim keeps it pure and keeps every line
## traceable to an event.

const SLOT_KEYS: Array[String] = ["morning", "afternoon", "evening"]


static func build(state: WorldState, which_day: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: SimEvent in state.events_on(which_day):
		var entry: Dictionary = _entry_for(state, e)
		if not entry.is_empty():
			out.append(entry)
	if out.is_empty():
		out.append({"key": "report.quiet", "params": {}, "event_id": 0, "slot": 0})
	return out


## What the player did in each slot today, as one entry per slot, for the
## plan view. Slots with nothing recorded are absent.
static func today_by_slot(state: WorldState) -> Dictionary:
	var out: Dictionary = {}
	for entry: Dictionary in build(state, state.day):
		var slot: int = int(entry["slot"])
		if not out.has(slot) and _is_player_action(entry["key"]):
			out[slot] = entry
	return out


static func _is_player_action(key: String) -> bool:
	for prefix: String in ["report.slot_slipped.", "report.talked", "report.rested", "report.shift.", "report.walked_out."]:
		if key.begins_with(prefix):
			return true
	return false


static func _entry_for(state: WorldState, e: SimEvent) -> Dictionary:
	var entry: Dictionary = {"key": "", "params": {}, "event_id": e.id, "slot": e.slot}
	match e.type:
		Sim.EVENT_SLOT_SLIPPED:
			entry["key"] = "report.slot_slipped." + SLOT_KEYS[clampi(e.slot, 0, SLOT_KEYS.size() - 1)]
		Activity.EVENT_TALKED:
			entry["key"] = "report.talked"
			entry["params"] = {"name": _name(state, e.actors[1])}
		Sim.EVENT_RESTED:
			entry["key"] = "report.rested"
		Sim.EVENT_WARNING:
			entry["key"] = "report.person_warning"
			entry["params"] = {"name": _name(state, e.actors[0])}
		Sim.EVENT_ACTED:
			entry["key"] = "report.person_acted." + str(e.data.get("option", ""))
			entry["params"] = {"name": _name(state, e.actors[0]), "option": str(e.data.get("option", ""))}
		Cab.EVENT_SHIFT_WORKED:
			var job: String = str(e.data.get("job", ""))
			entry["key"] = "report.shift." + job + ("_auto" if bool(e.data.get("auto", false)) else "")
			entry["params"] = {"pay": int(e.data.get("pay", 0))}
		Cab.EVENT_FARE_DODGED:
			entry["key"] = "report.fare_dodged"
			entry["params"] = {"name": _passenger(state, str(e.data.get("passenger", "")))}
		Cab.EVENT_RUMOUR:
			entry["key"] = "report.rumour." + str(e.data.get("about", ""))
			entry["params"] = {"name": _passenger(state, str(e.data.get("from", "")))}
		Cab.EVENT_NOTICED:
			entry["key"] = "report.noticed." + str(e.data.get("place", ""))
		Activity.EVENT_AUTOMATION_UNLOCKED:
			entry["key"] = "report.automation_unlocked." + str(e.data.get("job", ""))
		Activity.EVENT_ACTIVITY_ABANDONED:
			entry["key"] = "report.walked_out." + str(e.data.get("kind", ""))
		Hand.EVENT_LIFE_STARTED:
			entry["key"] = "report.life_started"
		_:
			return {}
	return entry


static func _name(state: WorldState, id: StringName) -> String:
	var p: Person = state.person(id)
	return p.name if p != null and p.name != "" else String(id)


static func _passenger(state: WorldState, id: String) -> String:
	if state.passers_by.has(id):
		return str(state.passers_by[id]["name"])
	return id
