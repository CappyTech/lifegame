extends SceneTree
## Builds res://ui/theme.tres from res://tokens/design-tokens.json. The
## Theme is generated, never hand-edited: change the tokens or this script.
##
##   godot --headless --path . -s tools/build_theme.gd
##
## Type variations the scenes may use:
##   Label:          Display, Heading, Caption, Muted,
##                   NightHeading, NightBody, NightMuted,
##                   MastheadTitle, MastheadMuted
##   PanelContainer: Paper, Night, Masthead
##   Button:         (default), Primary, Choice
##   HSeparator:     Rule, NightRule
##   Label (cont.):  Quote (serif body, for what people say)

const TOKENS_PATH: String = "res://tokens/design-tokens.json"
const THEME_PATH: String = "res://ui/theme.tres"

var colour: Dictionary
var fonts: Dictionary
var type_sizes: Dictionary
var spacing: Dictionary
var radius: Dictionary
var border: Dictionary

var serif: SystemFont
var sans: SystemFont


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
	colour = tokens["colour"]
	fonts = tokens["font"]
	type_sizes = tokens["type"]
	spacing = tokens["spacing"]
	radius = tokens["radius"]
	border = tokens["border"]

	serif = _font(fonts["serif"])
	sans = _font(fonts["sans"])

	var theme := Theme.new()
	theme.default_font = sans
	theme.default_font_size = _size("body")

	_labels(theme)
	_panels(theme)
	_buttons(theme)
	_separators(theme)
	_bars(theme)
	_tokens(theme)
	return theme


func _font(names: Array) -> SystemFont:
	var f := SystemFont.new()
	var packed := PackedStringArray()
	for n: Variant in names:
		packed.append(str(n))
	f.font_names = packed
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return f


func _c(name: String) -> Color:
	return Color(str(colour[name]))


func _size(name: String) -> int:
	return int(type_sizes[name])


func _sp(name: String) -> int:
	return int(spacing[name])


func _label_variation(theme: Theme, name: String, font: Font, size: int, col: Color) -> void:
	theme.add_type(name)
	theme.set_type_variation(name, "Label")
	theme.set_font("font", name, font)
	theme.set_font_size("font_size", name, size)
	theme.set_color("font_color", name, col)


func _labels(theme: Theme) -> void:
	theme.set_font("font", "Label", sans)
	theme.set_font_size("font_size", "Label", _size("body"))
	theme.set_color("font_color", "Label", _c("ink"))
	theme.set_constant("line_spacing", "Label", 4)

	_label_variation(theme, "Display", serif, _size("display"), _c("ink"))
	_label_variation(theme, "Heading", serif, _size("heading"), _c("ink"))
	_label_variation(theme, "Caption", sans, _size("caption"), _c("ink_muted"))
	_label_variation(theme, "Muted", sans, _size("body"), _c("ink_muted"))
	_label_variation(theme, "Quote", serif, _size("body") + 2, _c("ink"))
	_label_variation(theme, "NightHeading", serif, _size("heading"), _c("night_ink"))
	_label_variation(theme, "NightBody", serif, _size("body"), _c("night_ink"))
	_label_variation(theme, "NightMuted", sans, _size("small"), _c("night_muted"))
	_label_variation(theme, "MastheadTitle", serif, _size("heading"), _c("paper"))
	_label_variation(theme, "MastheadMuted", sans, _size("small"), _c("night_muted"))


func _flat(bg: Color, pad_x: int, pad_y: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(radius["panel"]))
	s.content_margin_left = pad_x
	s.content_margin_right = pad_x
	s.content_margin_top = pad_y
	s.content_margin_bottom = pad_y
	return s


func _panels(theme: Theme) -> void:
	var paper: StyleBoxFlat = _flat(_c("paper"), _sp("lg"), _sp("lg"))
	paper.border_color = _c("rule")
	paper.set_border_width_all(int(border["hairline"]))
	theme.set_stylebox("panel", "PanelContainer", paper)

	theme.add_type("Paper")
	theme.set_type_variation("Paper", "PanelContainer")
	theme.set_stylebox("panel", "Paper", paper)

	theme.add_type("Night")
	theme.set_type_variation("Night", "PanelContainer")
	var night: StyleBoxFlat = _flat(_c("night_surface"), _sp("xl"), _sp("xl"))
	night.border_color = _c("night")
	night.set_border_width_all(int(border["hairline"]))
	theme.set_stylebox("panel", "Night", night)

	theme.add_type("Masthead")
	theme.set_type_variation("Masthead", "PanelContainer")
	var masthead: StyleBoxFlat = _flat(_c("ink"), _sp("xl"), _sp("md"))
	masthead.border_color = _c("accent")
	masthead.border_width_bottom = int(border["rule"]) * 2
	theme.set_stylebox("panel", "Masthead", masthead)


func _button_box(bg: Color, border_col: Color, width: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = _flat(bg, _sp("md"), _sp("sm") + 2)
	s.set_corner_radius_all(int(radius["button"]))
	s.border_color = border_col
	s.set_border_width_all(width)
	return s


func _buttons(theme: Theme) -> void:
	var hair: int = int(border["hairline"])
	theme.set_font("font", "Button", sans)
	theme.set_font_size("font_size", "Button", _size("body"))
	theme.set_stylebox("normal", "Button", _button_box(_c("paper"), _c("ink"), hair))
	theme.set_stylebox("hover", "Button", _button_box(_c("paper_deep"), _c("ink"), hair))
	theme.set_stylebox("pressed", "Button", _button_box(_c("ink"), _c("ink"), hair))
	theme.set_stylebox("disabled", "Button", _button_box(_c("paper"), _c("rule"), hair))
	var focus: StyleBoxFlat = _button_box(Color.TRANSPARENT, _c("focus"), int(border["focus"]))
	focus.draw_center = false
	theme.set_stylebox("focus", "Button", focus)
	theme.set_color("font_color", "Button", _c("ink"))
	theme.set_color("font_hover_color", "Button", _c("ink"))
	theme.set_color("font_pressed_color", "Button", _c("paper"))
	theme.set_color("font_focus_color", "Button", _c("ink"))
	theme.set_color("font_disabled_color", "Button", _c("ink_muted"))

	theme.add_type("Primary")
	theme.set_type_variation("Primary", "Button")
	theme.set_font("font", "Primary", serif)
	theme.set_font_size("font_size", "Primary", _size("heading"))
	theme.set_stylebox("normal", "Primary", _button_box(_c("accent"), _c("accent"), hair))
	theme.set_stylebox("hover", "Primary", _button_box(_c("accent_deep"), _c("accent_deep"), hair))
	theme.set_stylebox("pressed", "Primary", _button_box(_c("ink"), _c("ink"), hair))
	theme.set_color("font_color", "Primary", _c("accent_ink"))
	theme.set_color("font_hover_color", "Primary", _c("accent_ink"))
	theme.set_color("font_pressed_color", "Primary", _c("paper"))
	theme.set_color("font_focus_color", "Primary", _c("accent_ink"))

	# Choice: a quiet row with a rule underneath; fills on hover.
	theme.add_type("Choice")
	theme.set_type_variation("Choice", "Button")
	var normal: StyleBoxFlat = _button_box(_c("paper"), _c("rule"), 0)
	normal.border_width_bottom = hair
	theme.set_stylebox("normal", "Choice", normal)
	var hover: StyleBoxFlat = _button_box(_c("paper_deep"), _c("ink"), 0)
	hover.border_width_bottom = hair
	theme.set_stylebox("hover", "Choice", hover)
	theme.set_stylebox("pressed", "Choice", _button_box(_c("ink"), _c("ink"), 0))


func _separators(theme: Theme) -> void:
	var rule := StyleBoxLine.new()
	rule.color = _c("rule")
	rule.thickness = int(border["hairline"])
	theme.set_stylebox("separator", "HSeparator", rule)
	theme.set_constant("separation", "HSeparator", _sp("md"))

	theme.add_type("Rule")
	theme.set_type_variation("Rule", "HSeparator")
	theme.set_stylebox("separator", "Rule", rule)

	theme.add_type("NightRule")
	theme.set_type_variation("NightRule", "HSeparator")
	var night := StyleBoxLine.new()
	night.color = _c("night_rule")
	night.thickness = int(border["hairline"])
	theme.set_stylebox("separator", "NightRule", night)

	theme.set_constant("separation", "VBoxContainer", _sp("sm"))
	theme.set_constant("separation", "HBoxContainer", _sp("md"))


func _bars(theme: Theme) -> void:
	var bg: StyleBoxFlat = _flat(_c("rule"), 0, 0)
	var fill: StyleBoxFlat = _flat(_c("accent"), 0, 0)
	theme.set_stylebox("background", "ProgressBar", bg)
	theme.set_stylebox("fill", "ProgressBar", fill)


## Every token reachable by name under the "Tokens" type, for the few
## places (a ColorRect background, a margin) that need a raw value.
func _tokens(theme: Theme) -> void:
	theme.add_type("Tokens")
	for name: String in colour:
		theme.set_color(name, "Tokens", _c(name))
	for name: String in spacing:
		theme.set_constant(name, "Tokens", _sp(name))
	for name: String in border:
		theme.set_constant("border_" + name, "Tokens", int(border[name]))
	for name: String in type_sizes:
		theme.set_font_size(name, "Tokens", _size(name))
	theme.set_font("serif", "Tokens", serif)
	theme.set_font("sans", "Tokens", sans)
