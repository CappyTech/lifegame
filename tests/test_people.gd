extends TestCase


func test_urgency_matches_design_examples() -> void:
	assert_near(People.urgency(80.0), 4.0, 0.001, "need 80")
	assert_near(People.urgency(50.0), 25.0, 0.001, "need 50")
	assert_near(People.urgency(20.0), 64.0, 0.001, "need 20")
	assert_near(People.urgency(100.0), 0.0, 0.001, "need 100")


func test_pressure_leaks_a_quarter_and_adds_excess() -> void:
	assert_near(People.next_pressure(0.0, 30.0), 0.0, 0.001, "carry on adds nothing")
	assert_near(People.next_pressure(0.0, 40.0), 10.0, 0.001, "excess over 30")
	assert_near(People.next_pressure(20.0, 25.0), 15.0, 0.001, "leaks with no excess")
	assert_near(People.next_pressure(20.0, 42.0), 27.0, 0.001, "leak plus excess")


func test_score_uses_needs_traits_trust_and_memories() -> void:
	var p := Person.new()
	p.id = &"dean"
	p.needs[&"money"] = 40.0
	p.traits[&"loyal"] = 0.4
	p.adjust_trust(Person.PLAYER_ID, 20.0)
	p.memories.append({"about": Person.PLAYER_ID, "event_id": 1, "tag": &"talked", "weight": 2.0, "emotional": false})
	var option: Dictionary = {
		"id": &"quit", "size": &"big", "base": 10.0,
		"needs": {&"money": 0.5},
		"traits": {&"loyal": -25.0},
		"trust": {Person.PLAYER_ID: -0.1},
		"resentment": {},
		"memories": {&"talked": -1.5},
	}
	# 10 + 36*0.5 - 0.4*25 - 20*0.1 - 2*1.5 = 10 + 18 - 10 - 2 - 3 = 13
	assert_near(People.score_option(p, option, 0.0), 13.0, 0.001, "score")
	assert_near(People.score_option(p, option, 2.5), 15.5, 0.001, "score with noise")


func test_needs_drift_and_clamp() -> void:
	var p := Person.new()
	p.needs[&"money"] = 1.0
	People.drift_needs(p)
	assert_near(float(p.needs[&"money"]), 0.0, 0.001, "money clamps at 0")
	assert_near(float(p.needs[&"belonging"]), 57.0, 0.001, "belonging drifts by 3")


func test_memories_fade_and_are_forgotten() -> void:
	var p := Person.new()
	p.memories.append({"about": &"x", "event_id": 1, "tag": &"a", "weight": 0.05, "emotional": false})
	p.memories.append({"about": &"x", "event_id": 2, "tag": &"b", "weight": 1.0, "emotional": true})
	People.fade_memories(p)
	assert_eq(p.memories.size(), 1, "faint memory dropped")
	assert_near(float(p.memories[0]["weight"]), 0.995, 0.0001, "emotional memory fades slowly")
