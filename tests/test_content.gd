extends TestCase
## Loads every .tres under content/ and runs its validate(). Also checks that
## every string key referenced by content or scripts exists in the table.

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


## Any property named *_key or *_keys, and any "*_key" entry inside an
## exported Array[Dictionary], must exist in the string table.
func test_content_string_keys_exist() -> void:
	var keys: Dictionary = _string_keys()
	for path: String in _find_tres(CONTENT_DIR):
		var res: Resource = load(path)
		for prop: Dictionary in res.get_property_list():
			var name: String = prop["name"]
			var value: Variant = res.get(name)
			if name.ends_with("_key") and value is String:
				_check_key(keys, str(value), path, name)
			elif name.ends_with("_keys") and value is Array:
				for k: Variant in value:
					_check_key(keys, str(k), path, name)
			elif value is Array:
				for entry: Variant in value:
					if entry is Dictionary:
						for k: Variant in entry:
							if str(k).ends_with("_key"):
								_check_key(keys, str(entry[k]), path, "%s.%s" % [name, k])


## Every literal "ui.*", "report.*", "rel.*", "outcome.*", "mem.*",
## "mood.*", "role.*" key in a script must exist in the string table.
## Keys built at runtime fall back to their parent key, which this also
## catches when the literal prefix is itself a key.
func test_script_string_keys_exist() -> void:
	var keys: Dictionary = _string_keys()
	var re := RegEx.create_from_string('"((?:ui|report|rel|outcome|mem|mood|role|conv)\\.[a-z0-9_.]+)"')
	for path: String in _find_scripts("res://ui") + _find_scripts("res://sim"):
		var src: String = FileAccess.get_file_as_string(path)
		for m: RegExMatch in re.search_all(src):
			var key: String = m.get_string(1)
			if key.ends_with("."):
				continue  # prefix for a key built at runtime
			if not keys.has(key):
				fail("%s: string key '%s' missing from %s" % [path, key, STRINGS_CSV])


func _check_key(keys: Dictionary, key: String, path: String, where: String) -> void:
	if key != "" and not keys.has(key):
		fail("%s: %s '%s' missing from %s" % [path, where, key, STRINGS_CSV])


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


static func _find_scripts(root: String) -> Array[String]:
	var out: Array[String] = []
	var dir: DirAccess = DirAccess.open(root)
	if dir == null:
		return out
	for d: String in dir.get_directories():
		out.append_array(_find_scripts(root.path_join(d)))
	for f: String in dir.get_files():
		if f.ends_with(".gd"):
			out.append(root.path_join(f))
	out.sort()
	return out
