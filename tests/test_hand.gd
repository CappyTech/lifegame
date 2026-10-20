extends TestCase

var catalogue: Catalogue = Catalogue.load_all()


func test_catalogue_has_the_core_content() -> void:
	assert_true(catalogue.cards.size() >= 3, "at least three life cards")
	assert_true(catalogue.places.size() >= 8, "places for the map")
	assert_true(catalogue.conversation(&"catch_up") != null, "default conversation")
	assert_true(catalogue.job(&"cab") != null and catalogue.job(&"burger_shop") != null, "both jobs")


func test_deal_pick_and_live() -> void:
	var s: WorldState = WorldState.create(3, catalogue)
	assert_eq(s.phase, &"dealing", "starts dealing")
	Sim.apply(s, {"type": "start", "activity": "cab_shift"})
	assert_true(s.events.is_empty(), "living choices ignored while dealing")
	Sim.apply(s, {"type": "deal"})
	assert_eq(s.hand.size(), 3, "three cards")
	assert_true(s.hand[0] != s.hand[1] and s.hand[1] != s.hand[2] and s.hand[0] != s.hand[2], "distinct cards")
	var first: Array[StringName] = s.hand.duplicate()
	Sim.apply(s, {"type": "reroll"})
	assert_eq(s.rerolls_left, 2, "reroll spent")
	Sim.apply(s, {"type": "pick", "card": "not_in_hand"})
	assert_eq(s.phase, &"dealing", "can only pick from the hand")
	var chosen: StringName = s.hand[0]
	Sim.apply(s, {"type": "pick", "card": String(chosen)})
	assert_eq(s.phase, &"living", "living now")
	assert_eq(s.life_card, chosen, "card recorded")
	assert_true(s.person(&"dean") != null, "Dean is in every town")
	assert_true(s.people.size() >= 2, "an anchor was added")
	assert_eq(s.player_money, catalogue.card(chosen).start_money, "money from the card")
	assert_true(first.size() == 3, "first hand was kept for comparison")


func test_rerolls_run_out() -> void:
	var s: WorldState = WorldState.create(3, catalogue)
	Sim.apply(s, {"type": "deal"})
	for _i: int in 5:
		Sim.apply(s, {"type": "reroll"})
	assert_eq(s.rerolls_left, 0, "three rerolls at most")


func test_dealing_is_deterministic() -> void:
	var a: WorldState = WorldState.create(9, catalogue)
	var b: WorldState = WorldState.create(9, catalogue)
	Sim.apply(a, {"type": "deal"})
	Sim.apply(b, {"type": "deal"})
	assert_eq(a.hand, b.hand, "same seed, same hand")


func test_content_conversations_drive_talk() -> void:
	var s: WorldState = WorldState.create(3, catalogue)
	Sim.apply(s, {"type": "deal"})
	Sim.apply(s, {"type": "pick", "card": String(s.hand[0])})
	Sim.apply(s, {"type": "start", "activity": "talk", "person": "dean"})
	var ids: Array[String] = []
	for c: Dictionary in Talk.choices(s):
		ids.append(str(c["id"]))
	assert_eq(ids, ["chat", "ask", "push"], "Dean's conversation from content")
	Sim.apply(s, {"type": "step", "choice": "push"})
	assert_eq(s.last_outcome["relationships"][0]["key"], "outcome.rel.down", "pushing costs")
	assert_eq(s.last_outcome["reply_key"], "conv.dean_catch_up.push.reply", "reply key carried")
