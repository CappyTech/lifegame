class_name LifeCard
extends Resource
## A starting life. Three are dealt; the player picks one or rerolls.
## The card shows surface facts only; hidden facts are discovered by living.

const ANCHORS: Array[StringName] = [&"uncle_chippy", &"mum_council_friend", &"mate_cab_office", &"nan_estate"]

@export var id: StringName = &""
@export var title_key: String = ""
## Shown on the card: family, home, a key relationship, money.
@export var surface_keys: Array[String] = []
## Not shown; surfaces through play.
@export var hidden_keys: Array[String] = []
@export var start_money: int = 100
@export_range(0, 100) var start_energy: int = 80
## Which anchor template this life adds to the town.
@export var anchor: StringName = &"mate_cab_office"


func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("id is empty")
	if title_key == "":
		errors.append("%s: title_key is empty" % id)
	if surface_keys.size() < 2:
		errors.append("%s: needs at least two surface facts" % id)
	if not ANCHORS.has(anchor):
		errors.append("%s: anchor %s not in %s" % [id, anchor, ANCHORS])
	if start_money < 0:
		errors.append("%s: start_money is negative" % id)
	return errors
