class_name UiText
extends RefCounted
## Turns sim entries (string keys plus params) into text. The only place
## the UI formats report and outcome entries, so the fallback rule lives
## once: a specific key (report.person_acted.quit) falls back to its parent
## (report.person_acted) when the specific one has no string yet.


static func entry(e: Dictionary) -> String:
	return keyed(str(e.get("key", "")), e.get("params", {}))


static func keyed(key: String, params: Dictionary = {}) -> String:
	var text: String = TranslationServer.translate(key)
	if text == key and key.count(".") >= 2:
		var parent: String = key.substr(0, key.rfind("."))
		var parent_text: String = TranslationServer.translate(parent)
		if parent_text != parent:
			text = parent_text
	return text.format(params)


## Outcome dictionary from the sim, ready for OutcomeView.show_outcome.
static func outcome(raw: Dictionary, continue_key: String = "ui.continue") -> Dictionary:
	var lines: Array[String] = []
	for l: Variant in raw.get("lines", []):
		lines.append(entry(l))
	var rels: Array[String] = []
	for r: Variant in raw.get("relationships", []):
		var d: Dictionary = r
		rels.append(keyed(str(d.get("key", "")), {"name": str(d.get("name", ""))}))
	var learned: Array[String] = []
	for k: Variant in raw.get("learned", []):
		learned.append(keyed(str(k)))
	return {
		"money": int(raw.get("money", 0)),
		"energy": int(raw.get("energy", 0)),
		"lines": lines,
		"relationships": rels,
		"learned": learned,
		"continue_key": continue_key,
	}


## Conversation choices for ConversationView from sim/content choices.
static func choices(raw: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c: Dictionary in raw:
		out.append({"id": str(c.get("id", "")), "text": keyed(str(c.get("text_key", "")))})
	return out
