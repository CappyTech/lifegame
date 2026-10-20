extends TestCase


func _play_shift(s: WorldState, shift: String, engage: String, perfect: bool) -> void:
	Sim.apply(s, {"type": "start", "activity": "burger_shift"})
	Sim.apply(s, {"type": "step", "shift": shift})
	Sim.apply(s, {"type": "step", "choice": engage})
	var guard: int = 0
	while not s.activity.is_empty() and guard < 200:
		guard += 1
		var tickets: Array = s.activity["tickets"]
		var wanted: String = str(tickets[int(s.activity["ticket"])][int(s.activity["item"])])
		var item: String = wanted
		if not perfect and guard % 3 == 0:
			item = "shake" if wanted != "shake" else "fries"
		Sim.apply(s, {"type": "step", "item": item})
	assert_true(s.activity.is_empty(), "shift finished within the guard")


func test_perfect_lunch_pays_wage_plus_full_tips() -> void:
	var s: WorldState = TownBuilder.debug_town(21)
	var money: int = s.player_money
	_play_shift(s, "lunch", "owner", true)
	assert_eq(s.player_money - money, 55 + 12, "£55 wage plus £2 per ticket for six tickets")
	assert_eq(_count(s, Burger.EVENT_TICKET_DONE), 6, "six tickets done")
	assert_eq(_count(s, Burger.EVENT_TICKET_MISTAKE), 0, "no mistakes")
	assert_eq(s.slot, 1, "one slot used")
	assert_near(s.skill(&"burger_shop"), 0.06, 0.0001, "full skill gain")


func test_mistakes_cost_tips_and_trust() -> void:
	var clean: WorldState = TownBuilder.debug_town(22)
	var messy: WorldState = TownBuilder.debug_town(22)
	_play_shift(clean, "evening", "head_down", true)
	_play_shift(messy, "evening", "head_down", false)
	assert_true(messy.player_money < clean.player_money, "mistakes cost tips")
	assert_true(_count(messy, Burger.EVENT_TICKET_MISTAKE) > 0, "mistakes recorded")
	assert_true(messy.person(&"dean").trust_toward(Person.PLAYER_ID) < clean.person(&"dean").trust_toward(Person.PLAYER_ID), "Dean trusts the messy one less")


func test_talking_to_the_owner_writes_a_memory() -> void:
	var s: WorldState = TownBuilder.debug_town(23)
	_play_shift(s, "evening", "owner", true)
	assert_eq(s.person(&"dean").memory_weight(&"talked"), 1.0, "Dean remembers the chat")
	assert_eq(_count(s, Activity.EVENT_TALKED), 1, "talked event")


func test_auto_shift_after_unlock() -> void:
	var s: WorldState = TownBuilder.debug_town(24)
	s.auto_unlocked.append(&"burger_shop")
	s.job_skills[&"burger_shop"] = 0.8
	var money: int = s.player_money
	Sim.apply(s, {"type": "start", "activity": "burger_shift", "auto": true})
	assert_true(s.activity.is_empty(), "resolved at once")
	assert_true(s.player_money > money, "paid")
	assert_eq(s.last_outcome["lines"][0]["key"], "outcome.burger_shift_auto", "auto outcome")


func test_warned_owner_pulls_you_aside_once() -> void:
	var s: WorldState = TownBuilder.debug_town(25, Catalogue.load_all())
	var dean: Person = s.person(&"dean")
	dean.warned[&"quit"] = true
	dean.pressure[&"quit"] = 30.0
	Sim.apply(s, {"type": "start", "activity": "burger_shift"})
	Sim.apply(s, {"type": "step", "shift": "evening"})
	assert_eq(s.activity["conversation"], "manager_word", "the word, not the usual opener")
	Sim.apply(s, {"type": "step", "choice": "hear_out"})
	assert_eq(dean.memory_weight(&"heard_out"), 1.0, "Dean remembers being heard")
	assert_near(dean.pressure_on(&"quit"), 15.0, 0.001, "pressure halved")
	Sim.sleep(s)
	Sim.apply(s, {"type": "start", "activity": "burger_shift"})
	Sim.apply(s, {"type": "step", "shift": "evening"})
	assert_eq(s.activity["conversation"], "burger_engage", "only once")


func test_silence_during_the_word_is_remembered() -> void:
	var s: WorldState = TownBuilder.debug_town(26, Catalogue.load_all())
	var dean: Person = s.person(&"dean")
	dean.warned[&"quit"] = true
	Sim.apply(s, {"type": "start", "activity": "burger_shift"})
	Sim.apply(s, {"type": "step", "shift": "lunch"})
	Sim.apply(s, {"type": "step", "choice": "silence"})
	assert_eq(dean.memory_weight(&"brushed_off"), 1.0, "silence writes brushed_off")
	assert_eq(s.activity["phase"], "work", "shift carries on")


static func _count(s: WorldState, type: StringName) -> int:
	var n: int = 0
	for e: SimEvent in s.events:
		if e.type == type:
			n += 1
	return n
