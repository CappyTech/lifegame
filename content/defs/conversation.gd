class_name Conversation
extends Resource
## A short choice-shaped exchange. One opener, a few replies, each with
## effects on the speaker. Timed when the moment matters; silence is a
## choice with its own meaning.
##
## Each choice is a Dictionary:
##   id: String            stable id sent back to the sim
##   text_key: String      what you say
##   reply_key: String     what they say back
##   trust: float          change to their trust in you
##   belonging: float      change to their belonging need
##   resentment: float     change to their resentment of you
##   memory_tag: String    memory written to them ("" for none)
##   emotional: bool       emotional memories fade slower
##   energy: int           change to the player's energy

@export var id: StringName = &""
@export var opener_key: String = ""
## 0 means untimed.
@export_range(0.0, 30.0) var timer_seconds: float = 0.0
## What letting the timer run out means. Required when timed.
@export var silence_key: String = ""
@export var silence_memory_tag: String = ""
@export var choices: Array[Dictionary] = []


func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("id is empty")
	if opener_key == "":
		errors.append("%s: opener_key is empty" % id)
	if choices.is_empty():
		errors.append("%s: no choices" % id)
	if timer_seconds > 0.0 and silence_key == "":
		errors.append("%s: timed but silence_key is empty" % id)
	var seen: Dictionary = {}
	for c: Dictionary in choices:
		var cid: String = str(c.get("id", ""))
		if cid == "":
			errors.append("%s: choice without id" % id)
		if seen.has(cid):
			errors.append("%s: duplicate choice id %s" % [id, cid])
		seen[cid] = true
		if str(c.get("text_key", "")) == "":
			errors.append("%s: choice %s has no text_key" % [id, cid])
	return errors


func choice(choice_id: String) -> Dictionary:
	for c: Dictionary in choices:
		if str(c.get("id", "")) == choice_id:
			return c
	return {}
