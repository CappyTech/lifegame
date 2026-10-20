class_name Catalogue
extends RefCounted
## Every content Resource, loaded once and looked up by id. The sim reads
## from this; it never loads files itself. Loading order is sorted by path
## so iteration over any of these dictionaries is deterministic.

const ROOT: String = "res://content"

var jobs: Dictionary = {}
var traits: Dictionary = {}
var places: Dictionary = {}
var cards: Dictionary = {}
var conversations: Dictionary = {}


static func load_all() -> Catalogue:
	var c := Catalogue.new()
	for path: String in _find_tres(ROOT):
		var res: Resource = load(path)
		if res == null:
			push_error("could not load %s" % path)
			continue
		c._add(res)
	return c


func _add(res: Resource) -> void:
	if res is JobDef:
		jobs[(res as JobDef).id] = res
	elif res is TraitDef:
		traits[(res as TraitDef).id] = res
	elif res is PlaceDef:
		places[(res as PlaceDef).id] = res
	elif res is LifeCard:
		cards[(res as LifeCard).id] = res
	elif res is Conversation:
		conversations[(res as Conversation).id] = res


func job(id: StringName) -> JobDef:
	return jobs.get(id)


func place(id: StringName) -> PlaceDef:
	return places.get(id)


func card(id: StringName) -> LifeCard:
	return cards.get(id)


func conversation(id: StringName) -> Conversation:
	return conversations.get(id)


## Place ids sorted, for seeded picks.
func place_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k: StringName in places:
		out.append(k)
	out.sort()
	return out


func card_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k: StringName in cards:
		out.append(k)
	out.sort()
	return out


static func _find_tres(root: String) -> Array[String]:
	var out: Array[String] = []
	var dir: DirAccess = DirAccess.open(root)
	if dir == null:
		return out
	for d: String in dir.get_directories():
		out.append_array(_find_tres(root.path_join(d)))
	for f: String in dir.get_files():
		if f.ends_with(".tres"):
			out.append(root.path_join(f))
	out.sort()
	return out
