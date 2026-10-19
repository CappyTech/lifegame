extends TestCase


func _manager() -> Person:
	return Person.from_dict({
		"id": "dean",
		"role": "manager",
		"needs": {"money": 40, "belonging": 45, "ambition": 50, "rest": 70},
		"traits": {"loyal": 0.3},
		"relationships": {"player": {"trust": 10, "resentment": 0}},
		"options": [{
			"id": "quit", "size": "big", "base": 20,
			"needs": {"money": 0.35, "belonging": 0.4},
			"traits": {"loyal": -25},
			"trust": {"player": -0.15},
			"memories": {"talked": -2},
		}],
	})


func test_same_seed_same_result() -> void:
	var a: WorldState = _run(7, 20, false)
	var b: WorldState = _run(7, 20, false)
	assert_eq(a.to_dict(), b.to_dict(), "two runs with the same seed and choices")


func test_different_seed_different_noise() -> void:
	var a: WorldState = _run(7, 5, false)
	var b: WorldState = _run(8, 5, false)
	assert_true(
		a.person(&"dean").pressure_on(&"quit") != b.person(&"dean").pressure_on(&"quit"),
		"pressure should differ between seeds")


func test_unused_slots_slip_and_are_recorded() -> void:
	var s: WorldState = WorldState.create(1)
	var events: Array[SimEvent] = Sim.sleep(s)
	var slipped: int = 0
	for e: SimEvent in events:
		if e.type == Sim.EVENT_SLOT_SLIPPED:
			slipped += 1
	assert_eq(slipped, 3, "three slots slipped")
	assert_eq(s.day, 2, "day advanced")
	assert_eq(s.slot, 0, "slot reset")


func test_warning_comes_before_the_act() -> void:
	var s: WorldState = _run(3, 40, false)
	var warning_day: int = -1
	var acted_day: int = -1
	for e: SimEvent in s.events:
		if e.type == Sim.EVENT_WARNING and warning_day < 0:
			warning_day = e.day
		if e.type == Sim.EVENT_ACTED and acted_day < 0:
			acted_day = e.day
	assert_true(acted_day > 0, "manager eventually quits when ignored")
	assert_true(warning_day > 0 and warning_day < acted_day,
		"warning (day %d) should come before the act (day %d)" % [warning_day, acted_day])


func test_talking_changes_the_outcome() -> void:
	var ignored: WorldState = _run(3, 40, false)
	var tended: WorldState = _run(3, 40, true)
	assert_true(_count(ignored, Sim.EVENT_ACTED) > 0, "ignored manager quits")
	assert_eq(_count(tended, Sim.EVENT_ACTED), 0, "tended manager stays")
	assert_true(tended.person(&"dean").trust_toward(Person.PLAYER_ID) > 10.0, "trust grew")
	assert_true(tended.person(&"dean").memories.size() > 0, "memories of being talked to")


func _run(seed: int, days: int, talk: bool) -> WorldState:
	var s: WorldState = WorldState.create(seed)
	s.add_person(_manager())
	for _d: int in days:
		if talk:
			Sim.apply(s, {"type": "talk", "person": "dean"})
		Sim.sleep(s)
	return s


static func _count(s: WorldState, type: StringName) -> int:
	var n: int = 0
	for e: SimEvent in s.events:
		if e.type == type:
			n += 1
	return n
