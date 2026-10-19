extends TestCase
## Loads every .tres under content/ and runs its validate(). Also checks that
## every name_key used by content exists in the string table.

const CONTENT_DIR: String = "res://content"
const STRINGS_CSV: String = "res://strings/strings.csv"


func test_every_content_resource_validates() -> void:
	var paths: Array[String] = _find_tres(CONTENT_DIR)
	assert_true(paths.size() > 0, "found content resources")
	var ids: Dictionary = {}
	for path: String in paths:
		var res: Resource = load(path)
		if res == null:
			fail("%s failed to load" % path)
			continue
		if not res.has_method("validate"):
			fail("%s has no validate()" % path)
			continue
		for err: String in res.call("validate"):
			fail("%s: %s" % [path, err])
		var id: StringName = res.get("id")
		var kind: String = res.get_script().get_global_name()
		var key: String = "%s/%s" % [kind, id]
		if ids.has(key):
			fail("duplicate %s in %s and %s" % [key, ids[key], path])
		ids[key] = path


func test_content_string_keys_exist() -> void:
	var keys: Dictionary = _string_keys()
	for path: String in _find_tres(CONTENT_DIR):
		var res: Resource = load(path)
		for prop: Dictionary in res.get_property_list():
			var name: String = prop["name"]
			if name.ends_with("_key"):
				var key: String = res.get(name)
				if key != "" and not keys.has(key):
					fail("%s: %s '%s' missing from %s" % [path, name, key, STRINGS_CSV])


func _string_keys() -> Dictionary:
	var keys: Dictionary = {}
	var f: FileAccess = FileAccess.open(STRINGS_CSV, FileAccess.READ)
	assert_true(f != null, "string table opens")
	if f == null:
		return keys
	f.get_csv_line()  # header
	while not f.eof_reached():
		var row: PackedStringArray = f.get_csv_line()
		if row.size() > 0 and row[0] != "":
			keys[row[0]] = true
	return keys


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
