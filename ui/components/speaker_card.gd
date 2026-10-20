class_name SpeakerCard
extends PanelContainer
## Who you're dealing with. Input is small and data-shaped:
##   {name, role_key, relationship_key, trait_keys: [..], memory_keys: [..]}

@onready var name_label: Label = %Name
@onready var role_label: Label = %Role
@onready var relationship_label: Label = %Relationship
@onready var traits_label: Label = %Traits
@onready var memories: VBoxContainer = %Memories
@onready var traits_title: Label = %TraitsTitle
@onready var memories_title: Label = %MemoriesTitle


func _ready() -> void:
	traits_title.text = tr("ui.speaker.traits")
	memories_title.text = tr("ui.speaker.memories")


func show_speaker(data: Dictionary) -> void:
	name_label.text = str(data.get("name", ""))
	role_label.text = tr(str(data.get("role_key", "role.passenger")))
	relationship_label.text = tr(str(data.get("relationship_key", "rel.civil")))

	var trait_keys: Array = data.get("trait_keys", [])
	var trait_words: PackedStringArray = []
	for k: Variant in trait_keys:
		trait_words.append(tr(str(k)))
	traits_label.text = ", ".join(trait_words) if not trait_words.is_empty() else tr("ui.speaker.none")

	for child: Node in memories.get_children():
		memories.remove_child(child)
		child.queue_free()
	var memory_keys: Array = data.get("memory_keys", [])
	if memory_keys.is_empty():
		_add_memory(tr("ui.speaker.none"))
	for k: Variant in memory_keys:
		_add_memory(tr(str(k)))


func _add_memory(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"Muted"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	memories.add_child(l)


## Builds the input from a Person. Memory tags become mem.* keys; traits
## above 0.5 are shown.
static func data_for_person(p: Person) -> Dictionary:
	var trait_keys: Array[String] = []
	for t: StringName in p.traits:
		if float(p.traits[t]) >= 0.5:
			trait_keys.append("trait.%s.name" % t)
	var memory_keys: Array[String] = []
	var seen: Dictionary = {}
	for i: int in range(p.memories.size() - 1, -1, -1):
		var tag: String = String(p.memories[i]["tag"])
		if seen.has(tag):
			continue
		seen[tag] = true
		memory_keys.append("mem." + tag)
		if memory_keys.size() >= 4:
			break
	return {
		"name": p.name,
		"role_key": "role." + String(p.role),
		"relationship_key": "rel." + String(People.trust_band(p.trust_toward(Person.PLAYER_ID))),
		"trait_keys": trait_keys,
		"memory_keys": memory_keys,
	}


## Builds the input from a passer-by record and the fare card.
static func data_for_passenger(pax: Dictionary, trait_name: String) -> Dictionary:
	var rides: int = int(pax.get("rides", 0))
	return {
		"name": str(pax.get("name", "")),
		"role_key": "role.regular" if rides >= 2 else "role.passenger",
		"relationship_key": "rel." + String(People.trust_band(float(pax.get("trust", 0.0)))),
		"trait_keys": ["ui.fare_trait." + trait_name],
		"memory_keys": ["mem.chatted"] if rides > 0 else [],
	}
