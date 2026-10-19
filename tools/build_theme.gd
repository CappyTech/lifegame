extends SceneTree
## Builds res://ui/theme.tres from res://tokens/design-tokens.json so scenes
## never hard-code colours or sizes.
##
##   godot --headless --path . -s tools/build_theme.gd

const TOKENS_PATH: String = "res://tokens/design-tokens.json"
const THEME_PATH: String = "res://ui/theme.tres"


func _init() -> void:
	var text: String = FileAccess.get_file_as_string(TOKENS_PATH)
	var tokens: Variant = JSON.parse_string(text)
	if not tokens is Dictionary:
		push_error("could not parse %s" % TOKENS_PATH)
		quit(1)
		return
	var theme: Theme = _build(tokens as Dictionary)
	DirAccess.make_dir_recursive_absolute("res://ui")
	var err: Error = ResourceSaver.save(theme, THEME_PATH)
	if err != OK:
		push_error("could not save theme: %s" % error_string(err))
		quit(1)
		return
	print("wrote %s" % THEME_PATH)
	quit(0)


func _build(tokens: Dictionary) -> Theme:
	var colour: Dictionary = tokens["colour"]
	var spacing: Dictionary = tokens["spacing"]
	var type_sizes: Dictionary = tokens["type"]
	var radius: Dictionary = tokens["radius"]

	var theme := Theme.new()
	theme.default_font_size = int(type_sizes["body"])

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(colour["surface"])
	panel.set_corner_radius_all(int(radius["panel"]))
	panel.set_content_margin_all(float(spacing["md"]))
	theme.set_stylebox("panel", "PanelContainer", panel)

	theme.set_color("font_color", "Label", Color(colour["text"]))
	theme.set_font_size("font_size", "Label", int(type_sizes["body"]))

	theme.set_color("font_color", "Button", Color(colour["text"]))
	theme.set_color("font_hover_color", "Button", Color(colour["accent"]))
	theme.set_font_size("font_size", "Button", int(type_sizes["body"]))

	theme.set_constant("separation", "VBoxContainer", int(spacing["sm"]))
	theme.set_constant("separation", "HBoxContainer", int(spacing["sm"]))

	# Keep every token reachable by name for scenes that need one directly.
	for name: String in colour:
		theme.set_color(name, "Tokens", Color(colour[name]))
	for name: String in spacing:
		theme.set_constant(name, "Tokens", int(spacing[name]))
	for name: String in type_sizes:
		theme.set_font_size(name, "Tokens", int(type_sizes[name]))
	return theme
