class_name SimEvent
extends RefCounted
## One thing that happened. Events are the source of truth: memories point at
## them and the overnight report is built from them. Append-only.

var id: int = 0
var day: int = 0
var slot: int = 0
var type: StringName = &""
var actors: Array[StringName] = []
var place: StringName = &""
var data: Dictionary = {}


func to_dict() -> Dictionary:
	return {
		"id": id,
		"day": day,
		"slot": slot,
		"type": String(type),
		"actors": actors.map(func(a: StringName) -> String: return String(a)),
		"place": String(place),
		"data": data.duplicate(true),
	}
