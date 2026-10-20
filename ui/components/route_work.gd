class_name RouteWork
extends PanelContainer
## The cab's work component: pick a route. Input:
##   {title_key, hint_key, routes: [{id, label_key, hint_key}]}
## Emits chosen(id).

signal chosen(route_id: String)

@onready var title: Label = %Title
@onready var hint: Label = %Hint
@onready var routes: VBoxContainer = %Routes


func show_routes(data: Dictionary) -> void:
	title.text = tr(str(data.get("title_key", "ui.the_drive")))
	hint.text = tr(str(data.get("hint_key", "ui.the_drive_hint")))
	for child: Node in routes.get_children():
		routes.remove_child(child)
		child.queue_free()
	var first: Button = null
	for r: Variant in data.get("routes", []):
		var d: Dictionary = r
		var b := Button.new()
		b.text = "%s\n%s" % [tr(str(d.get("label_key", ""))), tr(str(d.get("hint_key", "")))]
		b.theme_type_variation = &"Choice"
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func() -> void: chosen.emit(str(d.get("id", ""))))
		routes.add_child(b)
		if first == null:
			first = b
	if first != null:
		first.grab_focus()
