extends TestCase

var catalogue: Catalogue = Catalogue.load_all()


func _town(seed: int) -> WorldState:
	var s: WorldState = WorldState.create(seed, catalogue)
	Sim.apply(s, {"type": "deal"})
	# Pick the card that brings Carol so every anchor path is reachable.
	var card: StringName = s.hand[0]
	for c: StringName in s.hand:
		if c == &"comfortable_expectations":
			card = c
	Sim.apply(s, {"type": "pick", "card": String(card)})
	return s


func test_when_conditions() -> void:
	var ctx: Dictionary = {"trust": 30.0, "band": "warm", "mood": "tired", "tags": {"talked": true}, "learned": ["rumour.council_sale"], "warned": {&"quit": true}, "rides": 2, "day": 5, "needs": {&"rest": 20.0}, "met": true}
	assert_true(Activity.when_ok(ctx, {}), "empty always holds")
	assert_true(Activity.when_ok(ctx, {"trust_min": 30}), "trust_min inclusive")
	assert_true(not Activity.when_ok(ctx, {"trust_max": 29.99}), "trust_max")
	assert_true(Activity.when_ok(ctx, {"band": ["warm", "close"]}), "band")
	assert_true(Activity.when_ok(ctx, {"mood": ["tired"]}), "mood")
	assert_true(Activity.when_ok(ctx, {"has_memory": "talked", "lacks_memory": "pushed"}), "memories")
	assert_true(not Activity.when_ok(ctx, {"lacks_memory": "talked"}), "lacks fails when held")
	assert_true(Activity.when_ok(ctx, {"learned": "rumour.council_sale"}), "learned")
	assert_true(Activity.when_ok(ctx, {"warned": "quit"}), "warned")
	assert_true(Activity.when_ok(ctx, {"rides_min": 2, "rides_max": 2}), "rides")
	assert_true(not Activity.when_ok(ctx, {"first_meeting": true}), "not a first meeting")
	assert_true(Activity.when_ok(ctx, {"need_below": {"rest": 40}}), "need_below")
	assert_true(not Activity.when_ok(ctx, {"need_above": {"rest": 40}}), "need_above")


func test_openers_react_to_the_person() -> void:
	var s: WorldState = _town(31)
	var dean: Person = s.person(&"dean")
	Sim.apply(s, {"type": "start", "activity": "talk", "person": "dean"})
	assert_eq(Talk.opener_key(s), "conv.dean_catch_up.opener", "default opener")
	dean.needs[&"rest"] = 10.0
	assert_eq(Talk.opener_key(s), "conv.dean_catch_up.opener.2", "tired Dean is miles away")
	dean.memories.append({"about": Person.PLAYER_ID, "event_id": 1, "tag": &"dismissed", "weight": 1.0, "emotional": true})
	assert_eq(Talk.opener_key(s), "conv.dean_catch_up.opener.1", "dismissed outranks tired")


func test_choices_hide_and_appear() -> void:
	var s: WorldState = _town(32)
	Sim.apply(s, {"type": "start", "activity": "talk", "person": "dean"})
	assert_eq(_ids(Talk.choices(s)), ["chat", "ask", "push"], "first visit")
	Sim.apply(s, {"type": "step", "choice": "push"})
	Sim.sleep(s)
	s.learned.append("rumour.council_sale")
	Sim.apply(s, {"type": "start", "activity": "talk", "person": "dean"})
	assert_eq(_ids(Talk.choices(s)), ["chat", "ask", "push_again", "tip_off"], "after pushing, with a rumour to share")


func test_asking_properly_opens_a_second_beat() -> void:
	var s: WorldState = _town(33)
	var dean: Person = s.person(&"dean")
	Sim.apply(s, {"type": "start", "activity": "talk", "person": "dean"})
	Sim.apply(s, {"type": "step", "choice": "ask"})
	assert_true(not s.activity.is_empty(), "still talking")
	assert_eq(s.activity["conversation"], "dean_opens_up", "second beat")
	assert_eq(s.activity["last_reply_key"], "conv.dean_catch_up.ask.reply", "reply to show first")
	assert_eq(s.slot, 0, "slot not spent yet")
	Sim.apply(s, {"type": "step", "choice": "head_office"})
	assert_true(s.activity.is_empty(), "done after the second beat")
	assert_eq(s.slot, 1, "one slot for the whole talk")
	assert_true(s.learned.has("learned.dean.franchise"), "learned something")
	assert_eq(s.last_outcome["learned"], ["learned.dean.franchise"], "outcome lists it")
	assert_eq((s.last_outcome["relationships"] as Array).size(), 1, "one line for Dean, not two")
	assert_eq(dean.memory_weight(&"asked_after_them"), 2.0, "both beats remembered")


func test_carol_keeps_the_rumour_until_trusted() -> void:
	var s: WorldState = _town(34)
	var carol: Person = s.person(&"carol")
	assert_true(carol != null, "Carol is in this life")
	Sim.apply(s, {"type": "start", "activity": "talk", "person": "carol"})
	assert_true(_ids(Talk.choices(s)).has("work") and not _ids(Talk.choices(s)).has("work_trusted"), "trust 20: forms and meetings")
	Sim.apply(s, {"type": "step", "choice": "work"})
	assert_true(not s.learned.has("rumour.council_sale"), "nothing learned yet")
	carol.adjust_trust(Person.PLAYER_ID, 10.0)
	Sim.sleep(s)
	Sim.apply(s, {"type": "start", "activity": "talk", "person": "carol"})
	assert_true(_ids(Talk.choices(s)).has("work_trusted"), "trust 30: she lowers her voice")
	Sim.apply(s, {"type": "step", "choice": "work_trusted"})
	assert_eq(s.activity["conversation"], "carol_council", "second beat")
	Sim.apply(s, {"type": "step", "choice": "thanks"})
	assert_true(s.learned.has("rumour.council_sale"), "rumour learned from Carol")
	assert_true(_has_event(s, Activity.EVENT_LEARNED), "learning is an event")


func test_passengers_talk_like_themselves() -> void:
	var s: WorldState = _town(35)
	assert_eq(Cab.ride_conversation(s, "chatty"), &"ride_chatty", "chatty passengers")
	assert_eq(Cab.ride_conversation(s, "late_lads"), &"ride_late_lads", "the lads")
	assert_eq(Cab.ride_conversation(s, "regular"), &"ride_regular", "regulars")
	assert_eq(Cab.ride_conversation(s, "quiet"), &"ride", "no quiet conversation; generic")
	var pax: Dictionary = {"name": "Maureen", "trait": "regular", "home": "council", "knows": "", "rides": 0, "trust": 0.0}
	var conv: Conversation = catalogue.conversation(&"ride_regular")
	assert_eq(Activity.opener_key(conv, Activity.context_for_passenger(s, pax)), "conv.ride_regular.opener.2", "first ride: where's Tony")
	pax["rides"] = 3
	assert_eq(Activity.opener_key(conv, Activity.context_for_passenger(s, pax)), "conv.ride_regular.opener.1", "later: the usual")
	assert_eq(Activity.reply_key(conv.choice("chat"), Activity.context_for_passenger(s, pax)), "conv.ride_regular.chat.reply.1", "regular's reply after rides")


func test_every_next_points_at_a_conversation() -> void:
	for id: StringName in catalogue.conversations:
		var conv: Conversation = catalogue.conversation(id)
		for c: Dictionary in conv.choices:
			var next: String = str(c.get("next", ""))
			if next != "":
				assert_true(catalogue.conversation(StringName(next)) != null, "%s.%s -> %s exists" % [id, c["id"], next])


func _ids(choices: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for c: Dictionary in choices:
		out.append(str(c["id"]))
	return out


static func _has_event(s: WorldState, type: StringName) -> bool:
	for e: SimEvent in s.events:
		if e.type == type:
			return true
	return false
