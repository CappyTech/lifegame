class_name ContextPanel
extends PanelContainer
## Why this moment matters. Input:
##   {activity_key, place_key ("" for home), mood_key ("" to hide), pressure_keys: [..]}

@onready var title: Label = %Title
@onready var activity_label: Label = %Activity
@onready var place_label: Label = %Place
@onready var mood_label: Label = %Mood
@onready var pressures: VBoxContainer = %Pressures


func _ready() -> void:
	title.text = tr("ui.context.title")


func show_context(data: Dictionary) -> void:
	activity_label.text = tr(str(data.get("activity_key", "")))
	var place_key: String = str(data.get("place_key", ""))
	place_label.text = tr("ui.context.place").format({"place": tr(place_key)}) if place_key != "" else tr("ui.context.home")
	var mood_key: String = str(data.get("mood_key", ""))
	mood_label.visible = mood_key != ""
	mood_label.text = tr(mood_key) if mood_key != "" else ""
	for child: Node in pressures.get_children():
		pressures.remove_child(child)
		child.queue_free()
	for k: Variant in data.get("pressure_keys", []):
		var l := Label.new()
		l.text = tr(str(k))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pressures.add_child(l)


static func mood_key_for(p: Person) -> String:
	return "mood." + String(People.mood(p))
