class_name Conversation
extends Resource
## A short choice-shaped exchange that reacts to the person and the past.
## One opener (picked by condition), a few replies (some only shown when a
## condition holds), their response (also by condition), and optionally a
## next conversation for a second beat. Timed when the moment matters;
## silence is a choice with its own meaning.
##
## Conditions ("when") are Dictionaries checked against a context the sim
## builds from the speaker. Known keys:
##   trust_min, trust_max: float      their trust in you
##   band: [String]                   trust band words: cold wary civil warm close
##   mood: [String]                   fine low tired skint
##   has_memory, lacks_memory: String memory tag they hold about you
##   learned, not_learned: String     something the player knows
##   warned: String                   option id whose overnight warning has shown
##   rides_min, rides_max: int        passengers: rides with you so far
##   min_day: int
##   first_meeting: bool              true when they hold no memory of you
##   need_below, need_above: {need: value}
##
## Openers: [{text_key, when}], first match wins; opener_key is the fallback.
##
## Each choice is a Dictionary:
##   id: String            stable id sent back to the sim
##   text_key: String      what you say
##   when: Dictionary      shown only when this holds (optional)
##   reply_key: String     their response (fallback)
##   replies: [{text_key, when}]   conditional responses, first match wins
##   next: String          conversation id for the next beat (optional)
##   learn_key: String     something the player now knows (optional)
##   trust, belonging, resentment: float   changes to them
##   memory_tag: String    memory written to them ("" for none)
##   emotional: bool       emotional memories fade slower
##   energy: int           change to the player's energy

const CONDITION_KEYS: Array[String] = [
	"trust_min", "trust_max", "band", "mood", "has_memory", "lacks_memory",
	"learned", "not_learned", "warned", "rides_min", "rides_max", "min_day",
	"first_meeting", "need_below", "need_above",
]

@export var id: StringName = &""
@export var opener_key: String = ""
@export var openers: Array[Dictionary] = []
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
	for o: Dictionary in openers:
		if str(o.get("text_key", "")) == "":
			errors.append("%s: opener without text_key" % id)
		errors.append_array(_validate_when(o.get("when", {}), "opener"))
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
		errors.append_array(_validate_when(c.get("when", {}), "choice " + cid))
		for r: Variant in c.get("replies", []):
			if not r is Dictionary:
				errors.append("%s: choice %s has a reply that is not a dictionary" % [id, cid])
				continue
			var rd: Dictionary = r
			if str(rd.get("text_key", "")) == "":
				errors.append("%s: choice %s has a reply without text_key" % [id, cid])
			errors.append_array(_validate_when(rd.get("when", {}), "reply of " + cid))
	return errors


func _validate_when(when: Variant, where: String) -> Array[String]:
	var errors: Array[String] = []
	if not when is Dictionary:
		errors.append("%s: %s has a non-dictionary when" % [id, where])
		return errors
	for k: Variant in when:
		if not CONDITION_KEYS.has(str(k)):
			errors.append("%s: %s uses unknown condition '%s'" % [id, where, k])
	return errors


func choice(choice_id: String) -> Dictionary:
	for c: Dictionary in choices:
		if str(c.get("id", "")) == choice_id:
			return c
	return {}
