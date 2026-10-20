extends TestCase
## Data-driven conformance cases. Each JSON file under tests/conformance/ is:
##
##   {
##     "name": "...",
##     "seed": 42,
##     "dealing": false,            true to start before the hand is dealt
##     "people": [ Person.from_dict input, ... ],
##     "days": [ [choice, choice, ...], ... ],   one list of choices per day
##     "expect": {
##       "events": [ {"day": 12, "type": "person_warning", "actor": "dean", "option": "quit"}, ... ],
##       "people": { "dean": { "pressure": {"quit": 12.34}, "trust_player": 10 } }
##     }
##   }
##
## Events listed in "expect.events" must all occur (day, type, first actor,
## and option if given). "expect.people" values are checked to 0.01.

const CASES_DIR: String = "res://tests/conformance"


func test_conformance_cases() -> void:
	var dir: DirAccess = DirAccess.open(CASES_DIR)
	assert_true(dir != null, "conformance dir opens")
	if dir == null:
		return
	var files: PackedStringArray = dir.get_files()
	files.sort()
	var ran: int = 0
	for f: String in files:
		if not f.ends_with(".json"):
			continue
		_run_case(CASES_DIR.path_join(f))
		ran += 1
	assert_true(ran > 0, "at least one conformance case")


func _run_case(path: String) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		fail("%s: not valid JSON" % path)
		return
	var c: Dictionary = parsed
	var label: String = str(c.get("name", path.get_file()))

	var s: WorldState = WorldState.create(int(c["seed"]))
	if not bool(c.get("dealing", false)):
		s.phase = WorldState.PHASE_LIVING
	for pd: Dictionary in c.get("people", []):
		s.add_person(Person.from_dict(pd))
	for day_choices: Array in c.get("days", []):
		for choice: Dictionary in day_choices:
			Sim.apply(s, choice)
		Sim.sleep(s)

	var expect: Dictionary = c.get("expect", {})
	for want: Dictionary in expect.get("events", []):
		if not _has_event(s, want):
			fail("%s: expected event %s" % [label, JSON.stringify(want)])

	var people: Dictionary = expect.get("people", {})
	for pid: String in people:
		var p: Person = s.person(StringName(pid))
		if p == null:
			fail("%s: no person %s" % [label, pid])
			continue
		var want: Dictionary = people[pid]
		for opt: String in want.get("pressure", {}):
			assert_near(p.pressure_on(StringName(opt)), float(want["pressure"][opt]), 0.01,
				"%s: %s pressure on %s" % [label, pid, opt])
		if want.has("trust_player"):
			assert_near(p.trust_toward(Person.PLAYER_ID), float(want["trust_player"]), 0.01,
				"%s: %s trust toward player" % [label, pid])
		for need: String in want.get("needs", {}):
			assert_near(float(p.needs[StringName(need)]), float(want["needs"][need]), 0.01,
				"%s: %s need %s" % [label, pid, need])
	if expect.has("event_count"):
		assert_eq(s.events.size(), int(expect["event_count"]), "%s: total events" % label)


static func _has_event(s: WorldState, want: Dictionary) -> bool:
	for e: SimEvent in s.events:
		if e.day != int(want["day"]) or String(e.type) != str(want["type"]):
			continue
		if want.has("actor") and (e.actors.is_empty() or String(e.actors[0]) != str(want["actor"])):
			continue
		if want.has("option") and str(e.data.get("option", "")) != str(want["option"]):
			continue
		return true
	return false
