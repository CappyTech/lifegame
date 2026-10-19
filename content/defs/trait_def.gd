class_name TraitDef
extends Resource
## A personality trait. People carry a 0..1 value per trait; options weight
## those values when they are scored. One .tres per trait under content/traits/.

@export var id: StringName = &""
@export var name_key: String = ""
@export var description_key: String = ""


func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("id is empty")
	if name_key == "":
		errors.append("%s: name_key is empty" % id)
	return errors
