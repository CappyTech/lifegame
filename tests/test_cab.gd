extends TestCase


func _play_shift(s: WorldState, said: String, route: String) -> void:
	Sim.apply(s, {"type": "start", "activity": "cab_shift"})
	var guard: int = 0
	while not s.activity.is_empty() and guard < 50:
		guard += 1
		match str(s.activity["phase"]):
			"choose_fare":
				Sim.apply(s, {"type": "step", "fare": 0})
			"ride":
				Sim.apply(s, {"type": "step", "choice": said})
			"drive":
				Sim.apply(s, {"type": "step", "route": route})
			"fare_done":
				Sim.apply(s, {"type": "step"})
	assert_true(s.activity.is_empty(), "shift finished within the guard")


func test_three_fares_pay_and_use_one_slot() -> void:
	var s: WorldState = TownBuilder.debug_town(11)
	var money: int = s.player_money
	_play_shift(s, "chat", "main")
	assert_eq(_count(s, Cab.EVENT_FARE_COMPLETED), 3, "three fares")
	assert_eq(s.slot, 1, "one slot used")
	assert_true(s.player_money > money, "earned something")
	assert_eq(s.last_outcome["lines"][0]["key"], "outcome.cab_shift", "shift outcome line")
	assert_near(s.skill(&"cab"), 0.09, 0.0001, "skill grows per fare")
	assert_true(s.player_known > 0, "passengers now know you")


func test_dispatch_deals_three_distinct_cards() -> void:
	var s: WorldState = TownBuilder.debug_town(4)
	var cards: Array[Dictionary] = Cab.deal_fares(s)
	assert_eq(cards.size(), 3, "three cards")
	assert_true(cards[0]["passenger"] != cards[1]["passenger"] and cards[1]["passenger"] != cards[2]["passenger"], "distinct passengers")
	for c: Dictionary in cards:
		assert_true(c["destination"] != s.passers_by[c["passenger"]]["home"], "destination is not their home")
		assert_true(int(c["fare"]) >= 7, "fare at least £7")


func test_quiet_passenger_skips_the_ride() -> void:
	var s: WorldState = TownBuilder.debug_town(4)
	Sim.apply(s, {"type": "start", "activity": "cab_shift"})
	var fares: Array = s.activity["fares"]
	var quiet_idx: int = -1
	for i: int in fares.size():
		if fares[i]["trait"] == "quiet":
			quiet_idx = i
	if quiet_idx < 0:
		return  # this hand had no quiet passenger; nothing to check
	Sim.apply(s, {"type": "step", "fare": quiet_idx})
	assert_eq(s.activity["phase"], "drive", "straight to the drive")


func test_asking_a_regular_can_turn_up_a_rumour() -> void:
	var s: WorldState = TownBuilder.debug_town(5)
	s.passers_by["maureen"]["rides"] = 2
	Sim.apply(s, {"type": "start", "activity": "cab_shift"})
	s.activity["fares"] = [{"passenger": "maureen", "name": "Maureen", "destination": "estate", "zone": 2, "fare": 10, "trait": "regular", "regular": true, "said": ""}]
	Sim.apply(s, {"type": "step", "fare": 0})
	Sim.apply(s, {"type": "step", "choice": "ask"})
	assert_true(s.learned.has("rumour.council_sale"), "rumour learned")
	assert_eq(_count(s, Cab.EVENT_RUMOUR), 1, "rumour event")


func test_auto_shift_only_after_unlock() -> void:
	var s: WorldState = TownBuilder.debug_town(6)
	Sim.apply(s, {"type": "start", "activity": "cab_shift", "auto": true})
	assert_eq(s.activity.get("kind", ""), "cab_shift", "not unlocked: plays by hand")
	Sim.sleep(s)
	s.auto_unlocked.append(&"cab")
	var money: int = s.player_money
	Sim.apply(s, {"type": "start", "activity": "cab_shift", "auto": true})
	assert_true(s.activity.is_empty(), "auto shift resolves at once")
	assert_eq(s.slot, 1, "used the slot")
	assert_true(s.player_money > money, "paid")
	assert_eq(_count(s, Activity.EVENT_TALKED), 0, "nobody talked to")


func test_unlock_fires_once_at_threshold() -> void:
	var s: WorldState = TownBuilder.debug_town(8)
	s.job_skills[&"cab"] = 0.65
	_play_shift(s, "radio", "main")
	assert_true(s.is_auto_unlocked(&"cab"), "unlocked at 0.74")
	assert_eq(_count(s, Activity.EVENT_AUTOMATION_UNLOCKED), 1, "once")
	Sim.sleep(s)
	_play_shift(s, "radio", "main")
	assert_eq(_count(s, Activity.EVENT_AUTOMATION_UNLOCKED), 1, "still once")


func test_shift_is_deterministic() -> void:
	var a: WorldState = TownBuilder.debug_town(12)
	var b: WorldState = TownBuilder.debug_town(12)
	_play_shift(a, "ask", "detour")
	_play_shift(b, "ask", "detour")
	assert_eq(a.to_dict(), b.to_dict(), "same seed, same shift")


static func _count(s: WorldState, type: StringName) -> int:
	var n: int = 0
	for e: SimEvent in s.events:
		if e.type == type:
			n += 1
	return n
