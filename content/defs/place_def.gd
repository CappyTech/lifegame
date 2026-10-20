class_name PlaceDef
extends Resource
## A place on the town map. One .tres per place under content/places/.

const KINDS: Array[StringName] = [&"estate", &"street", &"civic", &"shop", &"pub", &"transport", &"work"]

@export var id: StringName = &""
@export var name_key: String = ""
@export var kind: StringName = &"shop"
## Position on the town grid (12 x 8).
@export var map_x: int = 0
@export var map_y: int = 0
## Distance band from the cab office: 0 is the office itself, 3 is the edge of town.
@export_range(0, 3) var fare_zone: int = 1


func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("id is empty")
	if name_key == "":
		errors.append("%s: name_key is empty" % id)
	if not KINDS.has(kind):
		errors.append("%s: kind %s not in %s" % [id, kind, KINDS])
	if map_x < 0 or map_x > 11 or map_y < 0 or map_y > 7:
		errors.append("%s: map position %d,%d off the 12x8 grid" % [id, map_x, map_y])
	return errors
