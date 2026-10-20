class_name TicketWork
extends PanelContainer
## The burger shop's work component: assemble the ticket in order. Input:
##   {ticket_n, total, items: [ids], done: int, mistakes: int, menu: [ids]}
## Emits item_pressed(id).

signal item_pressed(item_id: String)

@onready var title: Label = %Title
@onready var mistakes_label: Label = %Mistakes
@onready var items: VBoxContainer = %Items
@onready var menu: GridContainer = %Menu

var _menu_built: Array[String] = []


func show_ticket(data: Dictionary) -> void:
	title.text = tr("ui.ticket").format({"n": int(data.get("ticket_n", 1)), "total": int(data.get("total", 1))})
	mistakes_label.text = tr("ui.mistakes").format({"n": int(data.get("mistakes", 0))})
	for child: Node in items.get_children():
		items.remove_child(child)
		child.queue_free()
	var done: int = int(data.get("done", 0))
	var list: Array = data.get("items", [])
	for i: int in list.size():
		var l := Label.new()
		var word: String = tr("ui.menu." + str(list[i]))
		if i < done:
			l.text = word
			l.theme_type_variation = &"Muted"
		elif i == done:
			l.text = "▸ " + word
			l.theme_type_variation = &"Quote"
		else:
			l.text = word
		items.add_child(l)
	var menu_ids: Array = data.get("menu", [])
	var ids: Array[String] = []
	for m: Variant in menu_ids:
		ids.append(str(m))
	if ids != _menu_built:
		_build_menu(ids)


func _build_menu(ids: Array[String]) -> void:
	_menu_built = ids
	for child: Node in menu.get_children():
		menu.remove_child(child)
		child.queue_free()
	var first: Button = null
	for id: String in ids:
		var b := Button.new()
		b.text = tr("ui.menu." + id)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: item_pressed.emit(id))
		menu.add_child(b)
		if first == null:
			first = b
	if first != null:
		first.grab_focus()
