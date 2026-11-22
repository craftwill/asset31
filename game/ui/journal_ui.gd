class_name JournalUI
extends CanvasLayer
## Minimal dark-industrial Field Log & Controls Reference (J key).
## Tracks canon landmarks physically visited and in-world plaques/notes read
## without ever showing objective arrows or spoilers.

signal closed

const LANDMARKS := [
	["home", "STK-0412 · Home Shelter (Floor 77, 41,000 m)"],
	["market", "STK-0412 · Market Street"],
	["foundry", "STK-0412 · Foundry Hall / North Service Bypass"],
	["edge", "STK-0412 · East Edge Gate & TRAM-077 Spur"],
	["shaft", "EL-CYL-77 · Mining Shaft 77-N & Undercroft 76-B"],
	["crust", "CRUST-00 · Asset 31 Planetary Surface (0 m)"],
	["gap", "BR-077-A · 3.0 km Inter-Stack Span & 1.5 km Shelter"],
	["arrival", "STK-0413 · West Arrival Gate"],
	["hydroponics", "STK-0413 · Hydroponic Bay 413-A"],
	["preserve", "STK-0413 · Ecological Preserve 413-B (220 m Atrium)"],
]

var is_open := false
var discovered: Dictionary = {}   # id -> true
var read_notes: Dictionary = {}   # note_id -> { "title": String, "body": String }

var _landmarks_lbl: Label
var _notes_lbl: Label
var _stats_lbl: Label


func _ready() -> void:
	layer = 25
	visible = false
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.02, 0.015, 0.68)
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
	panel.custom_minimum_size = Vector2(580, 0)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 7)
	panel.add_child(v)

	var hdr := HBoxContainer.new()
	v.add_child(hdr)
	var title := Label.new()
	title.text = "ASSET 31  ·  FIELD EXPEDITION LOG"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override(&"font_size", 11)
	title.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.56))
	hdr.add_child(title)
	_stats_lbl = Label.new()
	_stats_lbl.add_theme_font_size_override(&"font_size", 10)
	_stats_lbl.add_theme_color_override(&"font_color", Color(0.84, 0.74, 0.58))
	hdr.add_child(_stats_lbl)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override(&"separation", 16)
	v.add_child(cols)

	_landmarks_lbl = Label.new()
	_landmarks_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_landmarks_lbl.add_theme_font_size_override(&"font_size", 9)
	_landmarks_lbl.add_theme_color_override(&"font_color", Color(0.90, 0.82, 0.68))
	cols.add_child(_landmarks_lbl)

	_notes_lbl = Label.new()
	_notes_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_notes_lbl.add_theme_font_size_override(&"font_size", 9)
	_notes_lbl.add_theme_color_override(&"font_color", Color(0.84, 0.78, 0.66))
	cols.add_child(_notes_lbl)

	var sep := HSeparator.new()
	v.add_child(sep)

	var help := Label.new()
	help.text = "CONTROLS:  [WASD] Move  [Shift] Sprint  [E] Interact / Repair / Read  [Tab / I] Pack  [M] Route Diagram  [J] Field Log  [F] Work-Lamp  [F5 / F9] Save / Load\n" \
		+ "PREVIEW JUMPS (Ctrl+key):  1 Home · 2 Street · 3 Vista · 4 Market · 5/6/7 Foundry · 8 Rail Tram · 9 Shaft 77-N · Bksp Undercroft · 0 Bridge 1.5km · - Arrival · = Hydroponics · [ Preserve · ] Crust 0m"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD
	help.add_theme_font_size_override(&"font_size", 8)
	help.add_theme_color_override(&"font_color", Color(0.72, 0.64, 0.50))
	v.add_child(help)


func mark_discovered(id: String) -> bool:
	if discovered.has(id):
		return false
	discovered[id] = true
	return true


func record_note(note_id: String, title: String, body: String) -> void:
	read_notes[note_id] = { "title": title, "body": body }


func open_journal() -> void:
	is_open = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()


func close_journal() -> void:
	is_open = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func _refresh() -> void:
	var lines: Array[String] = ["LANDMARKS LOGGED:"]
	var found_n := 0
	for item: Array in LANDMARKS:
		var id := String(item[0])
		if discovered.has(id):
			found_n += 1
			lines.append("  [x] %s" % String(item[1]))
		else:
			lines.append("  [ ] ──────────────")
	_landmarks_lbl.text = "\n".join(lines)

	var nlines: Array[String] = ["IN-WORLD NOTES & PLAQUES READ:"]
	if read_notes.is_empty():
		nlines.append("  (none recorded yet — inspect plaques with [E])")
	else:
		for k: String in read_notes:
			var nd: Dictionary = read_notes[k]
			nlines.append("  • %s" % String(nd.get("title", k)))
	_notes_lbl.text = "\n".join(nlines)
	_stats_lbl.text = "Landmarks %d/%d  ·  Notes %d  ·  [J / Esc] Close" % [found_n, LANDMARKS.size(), read_notes.size()]


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed(&"toggle_journal") or event.is_action_pressed(&"release_mouse"):
		close_journal()
		get_viewport().set_input_as_handled()


func serialize() -> Dictionary:
	return {
		"discovered": discovered.keys(),
		"read_notes": read_notes,
	}


func deserialize(d: Dictionary) -> void:
	discovered.clear()
	for k in d.get("discovered", []):
		discovered[String(k)] = true
	read_notes.clear()
	var rn: Variant = d.get("read_notes", {})
	if rn is Dictionary:
		read_notes = (rn as Dictionary).duplicate(true)
