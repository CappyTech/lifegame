extends TestCase


func test_first_night_report_lists_slipped_slots_and_talk() -> void:
	var s: WorldState = TownBuilder.debug_town(5)
	Sim.apply(s, {"type": "talk", "person": "dean"})
	Sim.sleep(s)
	var keys: Array[String] = []
	for entry: Dictionary in Report.build(s, 1):
		keys.append(entry["key"])
	assert_eq(keys, ["report.talked", "report.slot_slipped.afternoon", "report.slot_slipped.evening"], "report keys")
	var first: Dictionary = Report.build(s, 1)[0]
	assert_eq(first["params"]["name"], "Dean", "uses display name")
	assert_true(int(first["event_id"]) > 0, "entry points at its event")


func test_empty_day_is_quiet() -> void:
	var s: WorldState = WorldState.create(1)
	assert_eq(Report.build(s, 3)[0]["key"], "report.quiet", "no events")


func test_acts_carry_option_specific_key() -> void:
	var s: WorldState = TownBuilder.debug_town(3)
	for _d: int in 30:
		Sim.sleep(s)
	var found: bool = false
	for day: int in range(1, 31):
		for entry: Dictionary in Report.build(s, day):
			if entry["key"] == "report.person_acted.quit":
				found = true
	assert_true(found, "Dean quits within 30 ignored days and the report says so")


func test_debug_town_is_deterministic() -> void:
	assert_eq(TownBuilder.debug_town(9).to_dict(), TownBuilder.debug_town(9).to_dict(), "same seed")
