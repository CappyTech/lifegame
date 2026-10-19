class_name TestCase
extends RefCounted
## Base class for tests. Subclasses live in tests/test_*.gd and define
## methods starting with "test_". The runner calls each and collects failures.

var _failures: Array[String] = []


func reset() -> void:
	_failures.clear()


func failures() -> Array[String]:
	return _failures


func fail(message: String) -> void:
	_failures.append(message)


func assert_true(condition: bool, message: String) -> void:
	if not condition:
		fail(message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if not _equal(actual, expected):
		fail("%s expected %s, got %s" % [message, var_to_str(expected), var_to_str(actual)])


func assert_near(actual: float, expected: float, tolerance: float, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		fail("%s expected %s ± %s, got %s" % [message, expected, tolerance, actual])


static func _equal(a: Variant, b: Variant) -> bool:
	if a is float or b is float:
		return is_equal_approx(float(a), float(b))
	if (a is String or a is StringName) and (b is String or b is StringName):
		return String(a) == String(b)
	return a == b
