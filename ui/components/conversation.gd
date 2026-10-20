class_name ConversationView
extends PanelContainer
## What's said. Their line, your choices, an optional timer, and what
## silence means. Input:
##   {opener: String, choices: [{id, text}], timer_seconds: float, silence_text: String}
## Emits chosen(id). When the timer runs out, chosen("silence").
## show_reply(text) swaps the choices for their response and a Carry on.

signal chosen(choice_id: String)
signal continued

@onready var opener: Label = %Opener
@onready var choices: VBoxContainer = %Choices
@onready var timer_bar: ProgressBar = %TimerBar
@onready var silence_hint: Label = %SilenceHint
@onready var reply: Label = %Reply
@onready var continue_button: Button = %ContinueButton

var _timer_total: float = 0.0
var _timer_left: float = 0.0
var _timing: bool = false


func _ready() -> void:
	continue_button.text = tr("ui.continue")
	continue_button.pressed.connect(func() -> void: continued.emit())
	set_process(false)


func show_conversation(data: Dictionary) -> void:
	opener.text = str(data.get("opener", ""))
	reply.visible = false
	continue_button.visible = false
	_clear_choices()
	var first: Button = null
	for c: Variant in data.get("choices", []):
		var d: Dictionary = c
		var b := Button.new()
		b.text = str(d.get("text", ""))
		b.theme_type_variation = &"Choice"
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_choice.bind(str(d.get("id", ""))))
		choices.add_child(b)
		if first == null:
			first = b
	_timer_total = float(data.get("timer_seconds", 0.0))
	_timer_left = _timer_total
	_timing = _timer_total > 0.0
	timer_bar.visible = _timing
	silence_hint.visible = _timing
	if _timing:
		silence_hint.text = str(data.get("silence_text", tr("ui.silence_hint")))
		timer_bar.max_value = _timer_total
		timer_bar.value = _timer_total
	set_process(_timing)
	if first != null:
		first.grab_focus()


func show_reply(text: String) -> void:
	_stop_timer()
	_clear_choices()
	reply.visible = text != ""
	reply.text = text
	continue_button.visible = true
	continue_button.grab_focus()


func _process(delta: float) -> void:
	if not _timing:
		return
	_timer_left -= delta
	timer_bar.value = maxf(0.0, _timer_left)
	if _timer_left <= 0.0:
		_stop_timer()
		chosen.emit("silence")


func _on_choice(id: String) -> void:
	_stop_timer()
	chosen.emit(id)


func _stop_timer() -> void:
	_timing = false
	set_process(false)
	timer_bar.visible = false
	silence_hint.visible = false


func _clear_choices() -> void:
	for child: Node in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
