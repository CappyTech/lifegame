class_name TownMap
extends PanelContainer
## Where you are. Draws the town as a 12 x 8 grid of places, or zooms to
## the shop floor. Input:
##   {mode: "town"|"shop", places: [{id, label, x, y, kind}], position: id,
##    destination: id, marked: [ids], stations: [{id, label, x, y}], active_station: id}
## Everything is drawn from theme tokens; nothing is hard-coded.

const GRID_W: int = 12
const GRID_H: int = 8

var _data: Dictionary = {"mode": "town", "places": [], "marked": []}

@onready var title: Label = %Title
@onready var canvas: Control = %Canvas


func _ready() -> void:
	canvas.draw.connect(_draw_canvas)
	title.text = tr("ui.map_title")


func show_map(data: Dictionary) -> void:
	_data = data
	title.text = tr("ui.shop_floor") if str(data.get("mode", "town")) == "shop" else tr("ui.map_title")
	canvas.queue_redraw()


## Town data from the catalogue.
static func town_places(catalogue: Catalogue) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if catalogue == null:
		return out
	for id: StringName in catalogue.place_ids():
		var p: PlaceDef = catalogue.place(id)
		out.append({"id": String(id), "label": p.name_key, "x": p.map_x, "y": p.map_y, "kind": String(p.kind)})
	return out


static func shop_stations() -> Array[Dictionary]:
	return [
		{"id": "grill", "label": "ui.station.grill", "x": 2, "y": 1},
		{"id": "fryer", "label": "ui.station.fryer", "x": 5, "y": 1},
		{"id": "drinks", "label": "ui.station.drinks", "x": 8, "y": 1},
		{"id": "pass", "label": "ui.station.pass", "x": 5, "y": 5},
	]


static func station_for_item(item: String) -> String:
	match item:
		"burger", "cheeseburger":
			return "grill"
		"fries":
			return "fryer"
		"drink", "shake":
			return "drinks"
	return "pass"


func _draw_canvas() -> void:
	var area: Vector2 = canvas.size
	var cell: Vector2 = Vector2(area.x / GRID_W, area.y / GRID_H)
	var paper_deep: Color = get_theme_color("paper_deep", "Tokens")
	var rule: Color = get_theme_color("rule", "Tokens")
	var ink: Color = get_theme_color("ink", "Tokens")
	var muted: Color = get_theme_color("ink_muted", "Tokens")
	var accent: Color = get_theme_color("accent", "Tokens")
	var paper: Color = get_theme_color("paper", "Tokens")
	var font: Font = get_theme_font("sans", "Tokens")
	var font_size: int = get_theme_font_size("caption", "Tokens")

	canvas.draw_rect(Rect2(Vector2.ZERO, area), paper_deep)
	var shop: bool = str(_data.get("mode", "town")) == "shop"
	var spots: Array = _data.get("stations", []) if shop else _data.get("places", [])

	# Streets: a loose grid, lighter than the places on it.
	for gx: int in range(1, GRID_W):
		canvas.draw_line(Vector2(gx * cell.x, 0), Vector2(gx * cell.x, area.y), rule, 1.0)
	for gy: int in range(1, GRID_H):
		canvas.draw_line(Vector2(0, gy * cell.y), Vector2(area.x, gy * cell.y), rule, 1.0)

	var position_id: String = str(_data.get("position", ""))
	var destination_id: String = str(_data.get("destination", _data.get("active_station", "")))
	var marked: Array = _data.get("marked", [])
	var centres: Dictionary = {}

	for s: Variant in spots:
		var d: Dictionary = s
		var id: String = str(d["id"])
		var origin: Vector2 = Vector2(int(d["x"]) * cell.x, int(d["y"]) * cell.y)
		var box: Rect2 = Rect2(origin + cell * 0.1, cell * Vector2(1.8, 0.8))
		centres[id] = box.get_center()
		var fill: Color = paper
		var border: Color = ink
		if id == destination_id:
			fill = accent
		elif marked.has(id):
			border = accent
		canvas.draw_rect(box, fill)
		canvas.draw_rect(box, border, false, 2.0 if (id == destination_id or marked.has(id)) else 1.0)
		var label: String = tr(str(d.get("label", id)))
		var text_colour: Color = paper if id == destination_id else ink
		canvas.draw_string(font, box.position + Vector2(8, box.size.y * 0.62), label, HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 12, font_size, text_colour)

	# Route line from where you are to where you're going.
	if centres.has(position_id) and centres.has(destination_id) and position_id != destination_id:
		var a: Vector2 = centres[position_id]
		var b: Vector2 = centres[destination_id]
		var elbow: Vector2 = Vector2(b.x, a.y)
		canvas.draw_line(a, elbow, muted, 3.0)
		canvas.draw_line(elbow, b, muted, 3.0)

	if centres.has(position_id):
		var c: Vector2 = centres[position_id] + Vector2(cell.x * 0.9, -cell.y * 0.4)
		canvas.draw_circle(c, 7.0, accent)
		canvas.draw_circle(c, 7.0, ink, false, 1.5)
