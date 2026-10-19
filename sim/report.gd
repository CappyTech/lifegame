class_name Report
extends RefCounted
## Builds the overnight report from a day's events. Returns entries, not
## text: each is {"key": String, "params": Dictionary}. The UI translates the
## key with tr() and formats the params. Keeping text out of the sim keeps
## it pure and keeps every line traceable to an event.

const SLOT_KEYS: Array[String] = ["morning", "afternoon", "evening"]


static func build(state: WorldState, which_day: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: SimEvent in state.events_on(which_day):
		var entry: Dictionary = _entry_for(state, e)
		if not entry.is_empty():
			out.append(entry)
	if out.is_empty():
		out.append({"key": "report.quiet", "params": {}, "event_id": 0})
	return out


static func _entry_for(state: WorldState, e: SimEvent) -> Dictionary:
	var entry: Dictionary = {"key": "", "params": {}, "event_id": e.id}
	match e.type:
		Sim.EVENT_SLOT_SLIPPED:
			entry["key"] = "report.slot_slipped." + SLOT_KEYS[clampi(e.slot, 0, SLOT_KEYS.size() - 1)]
		Sim.EVENT_TALKED:
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
		_:
			return {}
	return entry


static func _name(state: WorldState, id: StringName) -> String:
	var p: Person = state.person(id)
	return p.name if p != null and p.name != "" else String(id)
