extends Control
## Stage 1 day screen: status bar, overnight report, and the plan for the
## current slot. Everything shown comes from WorldState and Report; every
## button sends one choice Dictionary to Sim.

const DEBUG_SEED: int = 1

var state: WorldState

@onready var day_label: Label = %DayLabel
@onready var slot_label: Label = %SlotLabel
@onready var money_label: Label = %MoneyLabel
@onready var energy_label: Label = %EnergyLabel
@onready var report_lines: VBoxContainer = %ReportLines
@onready var plan_title: Label = %PlanTitle
@onready var choices: VBoxContainer = %Choices
@onready var sleep_button: Button = %SleepButton


func _ready() -> void:
	state = TownBuilder.debug_town(DEBUG_SEED)
	sleep_button.pressed.connect(_on_sleep)
	_refresh()


func _refresh() -> void:
	day_label.text = tr("ui.day").format({"day": state.day})
	money_label.text = tr("ui.money").format({"money": state.player_money})
	energy_label.text = tr("ui.energy").format({"energy": state.player_energy})
	var day_over: bool = state.slot >= WorldState.SLOTS_PER_DAY
	slot_label.text = tr("ui.slot.done") if day_over else tr("ui.slot." + Report.SLOT_KEYS[state.slot])
	_refresh_report()
	_refresh_plan(day_over)


func _refresh_report() -> void:
	for child: Node in report_lines.get_children():
		child.queue_free()
	if state.day <= 1:
		_add_line(report_lines, tr("ui.report_first_night"))
		return
	for entry: Dictionary in Report.build(state, state.day - 1):
		_add_line(report_lines, _format_entry(entry))


func _refresh_plan(day_over: bool) -> void:
	for child: Node in choices.get_children():
		child.queue_free()
	plan_title.text = tr("ui.plan_done") if day_over else tr("ui.plan_title")
	sleep_button.visible = true
	if day_over:
		sleep_button.grab_focus()
		return
	var first: Button = null
	for p: Person in state.people:
		var b: Button = _add_choice(tr("ui.talk_to").format({"name": p.name}), {"type": "talk", "person": String(p.id)})
		if first == null:
			first = b
	_add_choice(tr("ui.rest"), {"type": "rest"})
	_add_choice(tr("ui.do_nothing"), {})
	if first != null:
		first.grab_focus()


func _add_choice(label: String, choice: Dictionary) -> Button:
	var b := Button.new()
	b.text = label
	b.pressed.connect(_on_choice.bind(choice))
	choices.add_child(b)
	return b


func _add_line(into: VBoxContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	into.add_child(l)


## Translates a report entry. Falls back from a specific key
## (report.person_acted.quit) to its generic parent when the specific one
## has no string yet, so new options never show a raw key.
func _format_entry(entry: Dictionary) -> String:
	var key: String = entry["key"]
	var text: String = tr(key)
	if text == key and key.count(".") >= 2:
		var parent: String = key.substr(0, key.rfind("."))
		text = tr(parent)
	return text.format(entry["params"])


func _on_choice(choice: Dictionary) -> void:
	Sim.apply(state, choice)
	_refresh()


func _on_sleep() -> void:
	Sim.sleep(state)
	_refresh()
