class_name JobDef
extends Resource
## A job the player can work. One .tres per job under content/jobs/.

const WORK_TYPES: Array[StringName] = [&"route", &"ticket", &"task_list"]

@export var id: StringName = &""
## Translation key for the job's name.
@export var name_key: String = ""
## Which Work component runs the shift: route (cab), ticket (burger shop), task_list (labouring).
@export var work_type: StringName = &"route"
## What the job teaches: information, business, contacts.
@export var teaches: StringName = &""
@export var pay_min: int = 0
@export var pay_max: int = 0
@export var energy_cost: int = 20
## Skill (0..1) at which automation unlocks for this job.
@export_range(0.0, 1.0) var auto_unlock_skill: float = 0.7


func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("id is empty")
	if name_key == "":
		errors.append("%s: name_key is empty" % id)
	if not WORK_TYPES.has(work_type):
		errors.append("%s: work_type %s not in %s" % [id, work_type, WORK_TYPES])
	if teaches == &"":
		errors.append("%s: teaches is empty" % id)
	if pay_min < 0 or pay_max < pay_min:
		errors.append("%s: pay range %d..%d is invalid" % [id, pay_min, pay_max])
	if energy_cost < 0:
		errors.append("%s: energy_cost is negative" % id)
	return errors
