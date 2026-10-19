extends SceneTree
## Headless test runner. Finds tests/test_*.gd, runs every method starting
## with "test_", prints a summary and exits non-zero on failure.
##
##   godot --headless --path . -s tests/run_tests.gd
##
## On a fresh clone run `godot --headless --path . --import` once first so the
## class_name cache exists.

const TESTS_DIR: String = "res://tests"


func _init() -> void:
	var files: Array[String] = _find_test_files()
	var passed: int = 0
	var failed: int = 0
	for path: String in files:
		var script: GDScript = load(path)
		var instance: Object = script.new()
		if not instance is TestCase:
			print("SKIP %s (does not extend TestCase)" % path)
			continue
		var test: TestCase = instance
		for m: Dictionary in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			test.reset()
			test.call(name)
			if test.failures().is_empty():
				passed += 1
			else:
				failed += 1
				print("FAIL %s::%s" % [path.get_file(), name])
				for f: String in test.failures():
					print("     %s" % f)
	print("%d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _find_test_files() -> Array[String]:
	var out: Array[String] = []
	var dir: DirAccess = DirAccess.open(TESTS_DIR)
	if dir == null:
		push_error("cannot open %s" % TESTS_DIR)
		return out
	for f: String in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd":
			out.append(TESTS_DIR.path_join(f))
	out.sort()
	return out
