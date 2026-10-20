extends Control
## The day screen. The overnight report on the left as the heart of the
## screen; the plan for today as three slot rows on the right, with the
## people who matter under it. Everything shown comes from WorldState and
## Report; every button sends one choice Dictionary to the game.

const SLOT_NAME_WIDTH: float = 112.0

var game: Node
var state: WorldState

@onready var report_title: Label = %ReportTitle
@onready var report_subtitle: Label = %ReportSubtitle
@onready var report_lines: VBoxContainer = %ReportLines
@onready var plan_title: Label = %PlanTitle
@onready var slots: VBoxContainer = %Slots
@onready var people_title: Label = %PeopleTitle
@onready var people_lines: VBoxContainer = %PeopleLines
@onready var sleep_button: Button = %SleepButton


func _ready() -> void:
	report_title.text = tr("ui.report_title")
	report_subtitle.text = tr("ui.report_subtitle")
	plan_title.text = tr("ui.today")
	people_title.text = tr("ui.people")
	sleep_button.text = tr("ui.sleep")
	sleep_button.pressed.connect(func() -> void: game.call("sleep"))


func refresh(with_state: WorldState) -> void:
	state = with_state
	var day_over: bool = state.slot >= WorldState.SLOTS_PER_DAY
	_refresh_report()
	_refresh_slots(day_over)
	_refresh_people()
	if day_over:
		sleep_button.grab_focus()


func _refresh_report() -> void:
	_clear(report_lines)
	if state.day <= 1:
		_add_label(report_lines, tr("ui.report_first_night"), &"NightBody")
		return
	for entry: Dictionary in Report.build(state, state.day - 1):
		_add_label(report_lines, UiText.entry(entry), &"NightBody")


## One row per slot: the slot name on the left; on the right either what
## was done (past), the choices (now) or a quiet "later".
func _refresh_slots(day_over: bool) -> void:
	_clear(slots)
	var done_today: Dictionary = Report.today_by_slot(state)
	var first_choice: Button = null
	for i: int in WorldState.SLOTS_PER_DAY:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		slots.add_child(row)

		var slot_name := Label.new()
		slot_name.text = tr("ui.slot." + Report.SLOT_KEYS[i])
		slot_name.theme_type_variation = &"Caption" if i != state.slot else &"Muted"
		slot_name.custom_minimum_size.x = SLOT_NAME_WIDTH
		slot_name.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(slot_name)

		var content := VBoxContainer.new()
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_theme_constant_override("separation", 4)
		row.add_child(content)

		if i < state.slot or day_over:
			var text: String = UiText.entry(done_today[i]) if done_today.has(i) else tr("ui.slot_nothing")
			_add_label(content, text, &"")
		elif i == state.slot:
			first_choice = _add_choices(content)
		else:
			_add_label(content, tr("ui.later"), &"Caption")

	if first_choice != null:
		first_choice.grab_focus()


func _add_choices(into: Container) -> Button:
	var first: Button = null
	for p: Person in state.people:
		var b: Button = _add_choice(into, tr("ui.talk_to").format({"name": p.name}), {"type": "start", "activity": "talk", "person": String(p.id)})
		if first == null:
			first = b
	_add_choice(into, tr("ui.cab_shift"), {"type": "start", "activity": "cab_shift"})
	if state.is_auto_unlocked(&"cab"):
		_add_choice(into, tr("ui.cab_shift_auto"), {"type": "start", "activity": "cab_shift", "auto": true})
	_add_choice(into, tr("ui.burger_shift"), {"type": "start", "activity": "burger_shift"})
	if state.is_auto_unlocked(&"burger_shop"):
		_add_choice(into, tr("ui.burger_shift_auto"), {"type": "start", "activity": "burger_shift", "auto": true})
	_add_choice(into, tr("ui.rest"), {"type": "rest"})
	_add_choice(into, tr("ui.do_nothing"), {})
	return first


func _refresh_people() -> void:
	_clear(people_lines)
	for p: Person in state.people:
		var row := HBoxContainer.new()
		people_lines.add_child(row)
		var who := Label.new()
		who.text = p.name
		who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(who)
		var band := Label.new()
		band.text = tr("rel." + String(People.trust_band(p.trust_toward(Person.PLAYER_ID))))
		band.theme_type_variation = &"Muted"
		row.add_child(band)


func _add_choice(into: Container, label: String, choice: Dictionary) -> Button:
	var b := Button.new()
	b.text = label
	b.theme_type_variation = &"Choice"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func() -> void: game.call("apply", choice))
	into.add_child(b)
	return b


func _add_label(into: Container, text: String, variation: StringName) -> void:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	into.add_child(l)


func _clear(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
