class_name Person
extends RefCounted
## An independent agent in the town. Plain data plus a few accessors; all the
## behaviour lives in People and Sim so it stays testable and deterministic.

const PLAYER_ID: StringName = &"player"

var id: StringName = &""
var role: StringName = &""

## Need name -> 0..100. Low means unmet.
var needs: Dictionary = {
	&"money": 60.0,
	&"belonging": 60.0,
	&"ambition": 60.0,
	&"rest": 60.0,
}

## Trait name -> 0..1. Fixed for life.
var traits: Dictionary = {}

## Other person id -> {"trust": -100..100, "resentment": 0..100}.
var relationships: Dictionary = {}

## Each memory: {"about": StringName, "event_id": int, "tag": StringName,
## "weight": float, "emotional": bool}.
var memories: Array[Dictionary] = []

## Options this person weighs every night. Each option is a Dictionary:
##   id: StringName           what they would do
##   size: "small"|"medium"|"big"
##   base: float              flat starting score
##   needs: {need: weight}    weight * urgency(need)
##   traits: {trait: weight}  weight * trait
##   trust: {who: weight}     weight * trust toward who
##   resentment: {who: weight}
##   memories: {tag: weight}  weight * total weight of memories with that tag
## Options are content in all but name; they come from role templates later.
var options: Array[Dictionary] = []

## Option id -> accumulated pressure.
var pressure: Dictionary = {}

## Option id -> true once the half-threshold warning has shown.
var warned: Dictionary = {}


func relationship_with(other: StringName) -> Dictionary:
	if not relationships.has(other):
		relationships[other] = {"trust": 0.0, "resentment": 0.0}
	return relationships[other]


func trust_toward(other: StringName) -> float:
	return float(relationship_with(other)["trust"])


func resentment_toward(other: StringName) -> float:
	return float(relationship_with(other)["resentment"])


func adjust_trust(other: StringName, delta: float) -> void:
	var rel: Dictionary = relationship_with(other)
	rel["trust"] = clampf(float(rel["trust"]) + delta, -100.0, 100.0)


func adjust_resentment(other: StringName, delta: float) -> void:
	var rel: Dictionary = relationship_with(other)
	rel["resentment"] = clampf(float(rel["resentment"]) + delta, 0.0, 100.0)


func adjust_need(need: StringName, delta: float) -> void:
	needs[need] = clampf(float(needs.get(need, 60.0)) + delta, 0.0, 100.0)


func memory_weight(tag: StringName) -> float:
	var total: float = 0.0
	for m: Dictionary in memories:
		if m["tag"] == tag:
			total += float(m["weight"])
	return total


func pressure_on(option_id: StringName) -> float:
	return float(pressure.get(option_id, 0.0))


func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"role": String(role),
		"needs": needs.duplicate(),
		"traits": traits.duplicate(),
		"relationships": relationships.duplicate(true),
		"memories": memories.duplicate(true),
		"options": options.duplicate(true),
		"pressure": pressure.duplicate(),
		"warned": warned.duplicate(),
	}


static func from_dict(d: Dictionary) -> Person:
	var p := Person.new()
	p.id = StringName(d.get("id", ""))
	p.role = StringName(d.get("role", ""))
	p.needs = _keyed(d.get("needs", {}), p.needs)
	p.traits = _keyed(d.get("traits", {}), {})
	for who: Variant in d.get("relationships", {}):
		var rel: Dictionary = d["relationships"][who]
		p.relationships[StringName(who)] = {
			"trust": float(rel.get("trust", 0.0)),
			"resentment": float(rel.get("resentment", 0.0)),
		}
	for m: Variant in d.get("memories", []):
		p.memories.append(_memory_from(m))
	for o: Variant in d.get("options", []):
		p.options.append(_option_from(o))
	p.pressure = _keyed(d.get("pressure", {}), {})
	for k: Variant in d.get("warned", {}):
		p.warned[StringName(k)] = bool(d["warned"][k])
	return p


## Copies a {name: number} dictionary onto defaults, converting keys to
## StringName and values to float.
static func _keyed(src: Dictionary, defaults: Dictionary) -> Dictionary:
	var out: Dictionary = defaults.duplicate()
	for k: Variant in src:
		out[StringName(k)] = float(src[k])
	return out


static func _memory_from(m: Dictionary) -> Dictionary:
	return {
		"about": StringName(m.get("about", "")),
		"event_id": int(m.get("event_id", 0)),
		"tag": StringName(m.get("tag", "")),
		"weight": float(m.get("weight", 1.0)),
		"emotional": bool(m.get("emotional", false)),
	}


static func _option_from(o: Dictionary) -> Dictionary:
	return {
		"id": StringName(o.get("id", "")),
		"size": StringName(o.get("size", "small")),
		"base": float(o.get("base", 0.0)),
		"needs": _keyed(o.get("needs", {}), {}),
		"traits": _keyed(o.get("traits", {}), {}),
		"trust": _keyed(o.get("trust", {}), {}),
		"resentment": _keyed(o.get("resentment", {}), {}),
		"memories": _keyed(o.get("memories", {}), {}),
	}
