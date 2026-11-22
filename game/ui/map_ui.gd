class_name MapUI
extends CanvasLayer
## Diegetic Floor 77 sector route diagram (brief §9): weathered blueprint
## scratched with known landmarks, distances, shelters, and route choices.
## Deliberately omits a GPS player arrow or objective marker to preserve
## navigation and mystery.

signal closed

var is_open := false
var _region_label: Label
var _bearing_label: Label
var _canvas: Control


class _DiagramCanvas extends Control:
	func _draw() -> void:
		var w := size.x
		var h := size.y
		# Background grid lines (faint blueprint ruling).
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.046, 0.036, 0.96), true)
		var grid_col := Color(0.22, 0.17, 0.12, 0.35)
		for gx in range(0, int(w), 32):
			draw_line(Vector2(gx, 0), Vector2(gx, h), grid_col, 1.0)
		for gy in range(0, int(h), 32):
			draw_line(Vector2(0, gy), Vector2(w, gy), grid_col, 1.0)
		# STK-0412 footprint (left) and STK-0413 western edge (right).
		var stk_col := Color(0.45, 0.34, 0.22, 0.85)
		var stk_fill := Color(0.11, 0.09, 0.07, 0.9)
		var cool_col := Color(0.46, 0.56, 0.68, 0.85)
		var stk1 := Rect2(22, 24, 290, 210)
		var stk2 := Rect2(458, 24, 88, 210)
		draw_rect(stk1, stk_fill, true)
		draw_rect(stk1, stk_col, false, 1.5)
		draw_rect(stk2, Color(0.08, 0.10, 0.12, 0.9), true)
		draw_rect(stk2, cool_col, false, 1.5)
		# Main East-West Avenue + Foundry Hall + Sheltered North Bypass.
		var ave_y := 130.0
		draw_line(Vector2(44, ave_y), Vector2(312, ave_y), Color(0.75, 0.55, 0.28, 0.75), 3.0)
		# Side street down from Home Shelter to Market.
		draw_line(Vector2(96, 86), Vector2(96, ave_y), Color(0.72, 0.54, 0.30, 0.75), 2.0)
		# Market highlight.
		draw_rect(Rect2(76, ave_y - 9, 46, 18), Color(0.88, 0.66, 0.34, 0.25), true)
		draw_rect(Rect2(76, ave_y - 9, 46, 18), Color(0.92, 0.70, 0.36, 0.8), false, 1.0)
		# Foundry Hall (hot direct) + North Service Bypass (sheltered loop above).
		draw_rect(Rect2(222, ave_y - 16, 44, 32), Color(0.85, 0.36, 0.12, 0.32), true)
		draw_rect(Rect2(222, ave_y - 16, 44, 32), Color(0.95, 0.48, 0.18, 0.9), false, 1.2)
		var bypass_pts := PackedVector2Array([Vector2(218, ave_y), Vector2(218, ave_y - 28), Vector2(270, ave_y - 28), Vector2(270, ave_y)])
		draw_polyline(bypass_pts, Color(0.62, 0.78, 0.52, 0.85), 1.6)
		# East Edge Gate + 3.0 km Bridge BR-077-A + south TRAM-077 rail spur + 1.5 km Mid-Span Shelter.
		draw_line(Vector2(312, ave_y), Vector2(458, ave_y), Color(0.95, 0.72, 0.30, 0.95), 3.0)
		draw_line(Vector2(312, ave_y + 7), Vector2(458, ave_y + 7), Color(0.74, 0.64, 0.44, 0.72), 1.3)
		for gx_p in [336, 360, 385, 410, 434]:
			draw_line(Vector2(gx_p, ave_y - 5), Vector2(gx_p, ave_y + 9), Color(0.88, 0.68, 0.34, 0.7), 1.0)
		# Mid-span shelter marker on north side of bridge.
		draw_rect(Rect2(382, ave_y - 13, 10, 8), Color(0.62, 0.78, 0.52, 0.9), true)
		# Hydroponic Bay 413-A & Ecological Preserve 413-B (north of STK-0413 West Arrival).
		draw_rect(Rect2(486, 74, 38, 22), Color(0.86, 0.34, 0.78, 0.25), true)
		draw_rect(Rect2(486, 74, 38, 22), Color(0.96, 0.52, 0.88, 0.85), false, 1.2)
		draw_rect(Rect2(482, 42, 46, 30), Color(0.32, 0.78, 0.42, 0.25), true)
		draw_rect(Rect2(482, 42, 46, 30), Color(0.54, 0.94, 0.62, 0.85), false, 1.2)
		# Mining Shaft 77-N (cylindrical shaft north of East Edge Gate) + catwalk spur.
		draw_line(Vector2(312, 74), Vector2(338, 74), Color(0.90, 0.68, 0.32, 0.85), 2.0)
		draw_arc(Vector2(344, 74), 16.0, 0.0, TAU, 24, Color(0.92, 0.66, 0.30, 0.9), 1.5)
		draw_arc(Vector2(344, 74), 10.0, 0.0, TAU, 16, Color(0.92, 0.66, 0.30, 0.45), 1.0)
		# Gap elevator shafts.
		draw_rect(Rect2(364, 188, 7, 7), Color(0.82, 0.60, 0.32, 0.7), false, 1.0)
		draw_rect(Rect2(420, 44, 7, 7), Color(0.82, 0.60, 0.32, 0.7), false, 1.0)
		# Shelter booth markers (home, gate, arrival).
		for sp in [Vector2(96, 84), Vector2(298, 108), Vector2(468, 108)]:
			draw_rect(Rect2(sp.x - 3, sp.y - 3, 6, 6), Color(0.62, 0.78, 0.52, 0.95), true)
		# Compass rose (North is UP = -Z in world space).
		var rc := Vector2(526, 214)
		draw_line(rc + Vector2(0, 12), rc + Vector2(0, -14), Color(0.9, 0.74, 0.46, 0.85), 1.2)
		draw_line(rc + Vector2(-10, 0), rc + Vector2(10, 0), Color(0.7, 0.58, 0.38, 0.6), 1.0)
		draw_line(rc + Vector2(0, -14), rc + Vector2(-4, -8), Color(0.9, 0.74, 0.46, 0.85), 1.2)
		draw_line(rc + Vector2(0, -14), rc + Vector2(4, -8), Color(0.9, 0.74, 0.46, 0.85), 1.2)


func _ready() -> void:
	layer = 24
	visible = false
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.02, 0.015, 0.65)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.085, 0.072, 0.056, 0.96)
	sb.border_color = Color(0.48, 0.36, 0.22, 0.92)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override(&"panel", sb)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 6)
	panel.add_child(v)

	var hdr := HBoxContainer.new()
	v.add_child(hdr)
	var title := Label.new()
	title.text = "FLOOR 77 ROUTE DIAGRAM  ·  41,000 M ELEVATION"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override(&"font_size", 11)
	title.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.56))
	hdr.add_child(title)
	_bearing_label = Label.new()
	_bearing_label.add_theme_font_size_override(&"font_size", 10)
	_bearing_label.add_theme_color_override(&"font_color", Color(0.84, 0.74, 0.58))
	hdr.add_child(_bearing_label)

	_canvas = _DiagramCanvas.new()
	_canvas.custom_minimum_size = Vector2(560, 256)
	v.add_child(_canvas)

	# Static blueprint labels positioned over the schematic canvas.
	var labels := [
		[Vector2(30, 30), "STK-0412 (HOME STACK)", Color(0.88, 0.74, 0.50)],
		[Vector2(464, 30), "STK-0413", Color(0.72, 0.84, 0.96)],
		[Vector2(66, 66), "Home Shelter + Lift", Color(0.72, 0.86, 0.62)],
		[Vector2(72, 146), "Market St.", Color(0.92, 0.74, 0.44)],
		[Vector2(198, 86), "North Bypass (Sheltered)", Color(0.68, 0.84, 0.58)],
		[Vector2(214, 152), "Foundry (Hot)", Color(0.96, 0.56, 0.28)],
		[Vector2(272, 142), "East Gate", Color(0.88, 0.74, 0.50)],
		[Vector2(364, 58), "Shaft 77-N\n↓ Crust 0 m", Color(0.92, 0.72, 0.42)],
		[Vector2(338, 140), "BR-077-A (3.0 km)\n+ TRAM-077 Spur", Color(0.95, 0.78, 0.44)],
		[Vector2(356, 102), "1.5 km Shelter", Color(0.70, 0.86, 0.60)],
		[Vector2(476, 98), "Bay 413-A + Preserve", Color(0.78, 0.96, 0.82)],
		[Vector2(462, 138), "West Arrival", Color(0.72, 0.84, 0.96)],
		[Vector2(522, 186), "N", Color(0.95, 0.80, 0.52)],
	]
	for item: Array in labels:
		var l := Label.new()
		l.position = item[0]
		l.text = item[1]
		l.add_theme_font_size_override(&"font_size", 8)
		l.add_theme_color_override(&"font_color", item[2])
		l.add_theme_color_override(&"font_shadow_color", Color.BLACK)
		_canvas.add_child(l)

	var ftr := HBoxContainer.new()
	v.add_child(ftr)
	_region_label = Label.new()
	_region_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_region_label.add_theme_font_size_override(&"font_size", 9)
	_region_label.add_theme_color_override(&"font_color", Color(0.82, 0.72, 0.56))
	ftr.add_child(_region_label)
	var close_lbl := Label.new()
	close_lbl.text = "Green = Shelter/Cache   |   [M / Esc] Close"
	close_lbl.add_theme_font_size_override(&"font_size", 9)
	close_lbl.add_theme_color_override(&"font_color", Color(0.68, 0.58, 0.44))
	ftr.add_child(close_lbl)


func open_map(sector_name: String, yaw_rad: float) -> void:
	is_open = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_region_label.text = "Sector: %s   (No GPS signal inside the Mantle)" % sector_name
	_bearing_label.text = "Facing: %s" % _compass(yaw_rad)
	_canvas.queue_redraw()


func close_map() -> void:
	is_open = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


static func _compass(yaw_rad: float) -> String:
	# Forward is -Z (North = 0 deg), +X is East (-90 deg).
	var deg := fposmod(-rad_to_deg(yaw_rad), 360.0)
	var dirs := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	return dirs[int(round(deg / 45.0)) % 8]


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed(&"toggle_map") or event.is_action_pressed(&"release_mouse"):
		get_viewport().set_input_as_handled()
		close_map()
