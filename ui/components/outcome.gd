class_name OutcomeView
extends PanelContainer
## What changed. Input:
##   {money: int, energy: int, lines: [text], relationships: [text], learned: [text], continue_key}
## Emits continued.

signal continued

@onready var title: Label = %Title
@onready var money_label: Label = %Money
@onready var energy_label: Label = %Energy
@onready var lines: VBoxContainer = %Lines
@onready var rel_title: Label = %RelTitle
@onready var rels: VBoxContainer = %Rels
@onready var learned_title: Label = %LearnedTitle
@onready var learned: VBoxContainer = %Learned
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	title.text = tr("ui.outcome_title")
	rel_title.text = tr("ui.outcome.relationships")
	learned_title.text = tr("ui.outcome.learned")
	continue_button.pressed.connect(func() -> void: continued.emit())


func show_outcome(data: Dictionary) -> void:
	var money: int = int(data.get("money", 0))
	if money > 0:
		money_label.text = tr("ui.outcome.money_up").format({"money": money})
	elif money < 0:
		money_label.text = tr("ui.outcome.money_down").format({"money": -money})
	else:
		money_label.text = tr("ui.outcome.money_same")
	var energy: int = int(data.get("energy", 0))
	energy_label.visible = energy != 0
	energy_label.text = tr("ui.outcome.energy").format({"delta": ("+%d" % energy) if energy > 0 else str(energy)})
	_fill(lines, data.get("lines", []), &"Quote")
	var rel_list: Array = data.get("relationships", [])
	rel_title.visible = not rel_list.is_empty()
	_fill(rels, rel_list, &"")
	var learned_list: Array = data.get("learned", [])
	learned_title.visible = not learned_list.is_empty()
	_fill(learned, learned_list, &"")
	continue_button.text = tr(str(data.get("continue_key", "ui.continue")))
	continue_button.grab_focus()


func _fill(into: VBoxContainer, texts: Array, variation: StringName) -> void:
	for child: Node in into.get_children():
		into.remove_child(child)
		child.queue_free()
	for t: Variant in texts:
		var l := Label.new()
		l.text = str(t)
		l.theme_type_variation = variation
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		into.add_child(l)
