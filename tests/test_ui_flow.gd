extends TestCase
## Plays the game through the real scenes, headless: instantiates
## ui/game.tscn, then presses buttons by their text the way a player would.
## No frames are processed, so everything must work from signals alone.

const GAME: PackedScene = preload("res://ui/game.tscn")
const MAX_PRESSES: int = 400

var game: Control
var presses: int = 0


func _start(seed: int) -> void:
	game = GAME.instantiate()
	game.set("debug_seed", seed)
	tree.root.add_child(game)
	presses = 0


func _stop() -> void:
	tree.root.remove_child(game)
	game.free()
	game = null


func _state() -> WorldState:
	return game.get("state")


## Visible, enabled buttons in tree order.
func _buttons(node: Node = null) -> Array[Button]:
	var out: Array[Button] = []
	if node == null:
		node = game
	if node is Button and (node as Button).is_visible_in_tree() and not (node as Button).disabled:
		out.append(node)
	for c: Node in node.get_children():
		out.append_array(_buttons(c))
	return out


func _press_text(text: String) -> bool:
	for b: Button in _buttons():
		if b.text == text or b.text.begins_with(text):
			presses += 1
			b.pressed.emit()
			return true
	return false


func _press_first() -> bool:
	var bs: Array[Button] = _buttons()
	if bs.is_empty():
		return false
	presses += 1
	bs[0].pressed.emit()
	return true


func _button_texts() -> Array[String]:
	var out: Array[String] = []
	for b: Button in _buttons():
		out.append(b.text)
	return out


func _on_day_screen() -> bool:
	for b: Button in _buttons():
		if b.text == tr("ui.sleep"):
			return true
	return false


func _continue_until_day() -> void:
	var guard: int = 0
	while not _on_day_screen() and guard < 60:
		guard += 1
		if not (_press_text(tr("ui.continue")) or _press_text(tr("ui.next_fare"))):
			break
	assert_true(_on_day_screen(), "back on the day screen; buttons were %s" % [_button_texts()])


func test_hand_deal_and_reroll() -> void:
	_start(21)
	assert_eq(_state().phase, &"dealing", "starts on the hand")
	var takes: int = 0
	for t: String in _button_texts():
		if t == tr("ui.take_life"):
			takes += 1
	assert_eq(takes, 3, "three cards to take")
	assert_true(_press_text(tr("ui.deal_again").substr(0, 10)), "deal again button")
	assert_eq(_state().rerolls_left, 2, "reroll spent")
	assert_true(_press_text(tr("ui.take_life")), "take a life")
	assert_eq(_state().phase, &"living", "living")
	assert_true(_on_day_screen(), "day screen after picking")
	_stop()


func test_talk_flow() -> void:
	_start(22)
	_press_text(tr("ui.take_life"))
	var dean: Person = _state().person(&"dean")
	var trust: float = dean.trust_toward(Person.PLAYER_ID)
	assert_true(_press_text(tr("ui.talk_to").format({"name": "Dean"})), "talk to Dean")
	assert_eq(_state().activity.get("kind", ""), "talk", "talk activity")
	assert_true(_press_first(), "a reply")
	assert_true(_state().activity.is_empty(), "talk done after one reply")
	assert_true(_press_text(tr("ui.continue")), "carry on past the reply")
	assert_true(_press_text(tr("ui.continue")), "carry on past the outcome")
	assert_true(_on_day_screen(), "back on the day")
	assert_true(dean.trust_toward(Person.PLAYER_ID) >= trust, "trust did not fall from a chat")
	assert_eq(_state().slot, 1, "afternoon now")
	_stop()


func test_cab_shift_flow() -> void:
	_start(23)
	_press_text(tr("ui.take_life"))
	var money: int = _state().player_money
	assert_true(_press_text(tr("ui.cab_shift")), "start cab shift")
	var guard: int = 0
	while not _state().activity.is_empty() and guard < 60:
		guard += 1
		var phase: String = str(_state().activity["phase"])
		match phase:
			"choose_fare":
				assert_true(_press_first(), "a fare card")
			"ride":
				assert_true(_press_first(), "a ride choice")
			"drive":
				if not _press_text(tr("ui.route.main")):
					assert_true(_press_text(tr("ui.continue")), "reply carry on or route")
			"fare_done":
				assert_true(_press_text(tr("ui.next_fare")) or _press_text(tr("ui.continue")), "drop-off continue")
	assert_true(_state().activity.is_empty(), "shift finished (phase stuck at %s)" % str(_state().activity.get("phase", "")))
	_continue_until_day()
	assert_true(_state().player_money >= money, "money did not go down")
	assert_eq(_state().slot, 1, "one slot used")
	_stop()


func test_burger_shift_flow() -> void:
	_start(24)
	_press_text(tr("ui.take_life"))
	assert_true(_press_text(tr("ui.burger_shift")), "start burger shift")
	assert_true(_press_text(tr("ui.shift.evening")), "evening shift")
	assert_true(_press_first(), "engage choice")
	var guard: int = 0
	while not _state().activity.is_empty() and guard < 80:
		guard += 1
		var a: Dictionary = _state().activity
		if str(a["phase"]) != "work":
			break
		if _press_text(tr("ui.continue")):
			continue
		var tickets: Array = a["tickets"]
		var wanted: String = str(tickets[int(a["ticket"])][int(a["item"])])
		assert_true(_press_text(tr("ui.menu." + wanted)), "menu button for %s" % wanted)
	assert_true(_state().activity.is_empty(), "shift finished")
	assert_eq(_count(Burger.EVENT_TICKET_MISTAKE), 0, "no mistakes when following the ticket")
	_continue_until_day()
	_stop()


func test_a_full_week_through_the_scenes() -> void:
	_start(25)
	_press_text(tr("ui.take_life"))
	for day: int in 7:
		# Morning: cab. Afternoon: burger. Evening: rest.
		_play_cab()
		_play_burger()
		assert_true(_press_text(tr("ui.rest")), "rest")
		assert_true(_press_text(tr("ui.sleep")), "sleep")
		assert_eq(_state().day, day + 2, "day advanced")
		assert_true(_on_day_screen(), "day screen after sleep")
	assert_eq(_state().day, 8, "a week played")
	assert_true(_state().player_money > 0, "earned money")
	assert_true(presses < MAX_PRESSES, "flow did not loop")
	_stop()


func _play_cab() -> void:
	if not _press_text(tr("ui.cab_shift")):
		fail("no cab shift button; saw %s" % [_button_texts()])
		return
	var guard: int = 0
	while not _state().activity.is_empty() and guard < 60:
		guard += 1
		if _press_text(tr("ui.continue")) or _press_text(tr("ui.next_fare")):
			continue
		if not _press_first():
			break
	_continue_until_day()


func _play_burger() -> void:
	if not _press_text(tr("ui.burger_shift")):
		fail("no burger shift button; saw %s" % [_button_texts()])
		return
	_press_text(tr("ui.shift.lunch"))
	_press_first()
	var guard: int = 0
	while not _state().activity.is_empty() and guard < 80:
		guard += 1
		if _press_text(tr("ui.continue")):
			continue
		var a: Dictionary = _state().activity
		if str(a["phase"]) != "work":
			break
		var tickets: Array = a["tickets"]
		var wanted: String = str(tickets[int(a["ticket"])][int(a["item"])])
		_press_text(tr("ui.menu." + wanted))
	_continue_until_day()


func _count(type: StringName) -> int:
	var n: int = 0
	for e: SimEvent in _state().events:
		if e.type == type:
			n += 1
	return n
