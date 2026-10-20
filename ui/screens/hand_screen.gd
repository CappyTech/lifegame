extends Control
## The starting hand: three life cards, take one or deal again.

var game: Node

@onready var title: Label = %Title
@onready var subtitle: Label = %Subtitle
@onready var cards: HBoxContainer = %Cards
@onready var reroll_button: Button = %RerollButton
@onready var no_rerolls: Label = %NoRerolls


func _ready() -> void:
	title.text = tr("ui.hand_title")
	subtitle.text = tr("ui.hand_subtitle")
	no_rerolls.text = tr("ui.no_rerolls")
	reroll_button.pressed.connect(func() -> void: game.call("apply", {"type": "reroll"}))


func refresh(state: WorldState) -> void:
	for child: Node in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	var first: Button = null
	for card_id: StringName in state.hand:
		var card: LifeCard = state.catalogue.card(card_id)
		if card == null:
			continue
		var b: Button = _add_card(card)
		if first == null:
			first = b
	reroll_button.visible = state.rerolls_left > 0
	reroll_button.text = tr("ui.deal_again").format({"n": state.rerolls_left})
	no_rerolls.visible = state.rerolls_left <= 0
	if first != null:
		first.grab_focus()


func _add_card(card: LifeCard) -> Button:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"Paper"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var heading := Label.new()
	heading.text = tr(card.title_key)
	heading.theme_type_variation = &"Heading"
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(heading)
	box.add_child(HSeparator.new())
	for key: String in card.surface_keys:
		var l := Label.new()
		l.text = tr(key)
		l.theme_type_variation = &"Quote"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var take := Button.new()
	take.text = tr("ui.take_life")
	take.theme_type_variation = &"Primary"
	take.pressed.connect(func() -> void: game.call("apply", {"type": "pick", "card": String(card.id)}))
	box.add_child(take)
	return take
