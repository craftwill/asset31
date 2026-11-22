class_name HudOverlay
extends CanvasLayer
## Minimal, restrained dark-industrial HUD (brief §8.4, §9): tiny dim reticle,
## contextual interaction prompt, compact bottom-left survival bars, and a
## fading status toast. Stays unobtrusive so the Mantle dominates the frame.

var _root: Control
var _reticle: ColorRect
var _prompt: Label
var _toast: Label
var _toast_timer := 0.0
var _hp_fill: ColorRect
var _food_fill: ColorRect
var _water_fill: ColorRect
var _cond_label: Label
var _hint_label: Label
var _note_layer: PanelContainer
var _note_title: Label
var _note_body: Label
var note_open := false


func _ready() -> void:
	layer = 15
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Tiny 2x2 warm center dot.
	_reticle = ColorRect.new()
	_reticle.size = Vector2(2, 2)
	_reticle.position = Vector2(479, 269)
	_reticle.color = Color(0.92, 0.76, 0.50, 0.45)
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_reticle)

	# Restrained interaction prompt below center.
	_prompt = Label.new()
	_prompt.position = Vector2(280, 290)
	_prompt.size = Vector2(400, 24)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override(&"font_size", 11)
	_prompt.add_theme_color_override(&"font_color", Color(1.0, 0.86, 0.62, 0.92))
	_prompt.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.85))
	_prompt.add_theme_constant_override(&"shadow_offset_x", 1)
	_prompt.add_theme_constant_override(&"shadow_offset_y", 1)
	_prompt.visible = false
	_root.add_child(_prompt)

	# Status toast (item used, saved, loaded).
	_toast = Label.new()
	_toast.position = Vector2(280, 476)
	_toast.size = Vector2(400, 22)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override(&"font_size", 10)
	_toast.add_theme_color_override(&"font_color", Color(1.0, 0.84, 0.55, 0.9))
	_toast.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.9))
	_toast.visible = false
	_root.add_child(_toast)

	# Compact bottom-left survival bars.
	var box := PanelContainer.new()
	box.position = Vector2(12, 474)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.04, 0.58)
	sb.border_color = Color(0.28, 0.22, 0.16, 0.65)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(5)
	box.add_theme_stylebox_override(&"panel", sb)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 3)
	box.add_child(vbox)
	_hp_fill = _add_bar(vbox, "HP", Color(0.76, 0.34, 0.24, 0.85))
	_food_fill = _add_bar(vbox, "FD", Color(0.78, 0.54, 0.24, 0.85))
	_water_fill = _add_bar(vbox, "WT", Color(0.38, 0.60, 0.72, 0.85))

	_cond_label = Label.new()
	_cond_label.position = Vector2(118, 480)
	_cond_label.add_theme_font_size_override(&"font_size", 9)
	_cond_label.add_theme_color_override(&"font_color", Color(0.95, 0.74, 0.42, 0.78))
	_cond_label.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	_cond_label.visible = false
	_root.add_child(_cond_label)

	_hint_label = Label.new()
	_hint_label.position = Vector2(12, 522)
	_hint_label.text = "[Tab] Pack   [E] Interact   [M] Map   [F] Lamp   [F5/F9] Save/Load"
	_hint_label.add_theme_font_size_override(&"font_size", 8)
	_hint_label.add_theme_color_override(&"font_color", Color(0.72, 0.62, 0.48, 0.45))
	_hint_label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.7))
	_root.add_child(_hint_label)

	# Restrained diegetic note/plaque reader modal.
	var note_center := CenterContainer.new()
	note_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	note_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(note_center)
	_note_layer = PanelContainer.new()
	_note_layer.visible = false
	var nsb := StyleBoxFlat.new()
	nsb.bg_color = Color(0.08, 0.068, 0.052, 0.95)
	nsb.border_color = Color(0.48, 0.36, 0.22, 0.9)
	nsb.set_border_width_all(1)
	nsb.set_content_margin_all(14)
	_note_layer.add_theme_stylebox_override(&"panel", nsb)
	note_center.add_child(_note_layer)
	var nv := VBoxContainer.new()
	nv.custom_minimum_size = Vector2(390, 0)
	nv.add_theme_constant_override(&"separation", 8)
	_note_layer.add_child(nv)
	_note_title = Label.new()
	_note_title.add_theme_font_size_override(&"font_size", 12)
	_note_title.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.56))
	nv.add_child(_note_title)
	_note_body = Label.new()
	_note_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_body.add_theme_font_size_override(&"font_size", 10)
	_note_body.add_theme_color_override(&"font_color", Color(0.86, 0.78, 0.66))
	nv.add_child(_note_body)
	var nfoot := Label.new()
	nfoot.text = "[E / Esc] Close"
	nfoot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	nfoot.add_theme_font_size_override(&"font_size", 9)
	nfoot.add_theme_color_override(&"font_color", Color(0.70, 0.58, 0.42))
	nv.add_child(nfoot)


func open_note(title: String, body: String) -> void:
	_note_title.text = title.to_upper()
	_note_body.text = body
	_note_layer.visible = true
	note_open = true
	set_prompt("")


func close_note() -> void:
	_note_layer.visible = false
	note_open = false


func _add_bar(parent: VBoxContainer, code: String, col: Color) -> ColorRect:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 5)
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = code
	lbl.custom_minimum_size = Vector2(18, 8)
	lbl.add_theme_font_size_override(&"font_size", 8)
	lbl.add_theme_color_override(&"font_color", Color(0.80, 0.70, 0.55, 0.72))
	row.add_child(lbl)
	var bg := ColorRect.new()
	bg.custom_minimum_size = Vector2(68, 6)
	bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bg.color = Color(0.14, 0.11, 0.09, 0.85)
	row.add_child(bg)
	var fill := ColorRect.new()
	fill.color = col
	fill.size = Vector2(68, 6)
	bg.add_child(fill)
	return fill


func set_hud_visible(v: bool) -> void:
	visible = v


func set_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.visible = text != ""


func show_toast(text: String, duration := 2.6) -> void:
	_toast.text = text
	_toast.visible = true
	_toast_timer = duration


func update_survival(s: SurvivalComponent) -> void:
	_hp_fill.size.x = 68.0 * clampf(s.health / 100.0, 0.0, 1.0)
	_food_fill.size.x = 68.0 * clampf(s.hunger / 100.0, 0.0, 1.0)
	_water_fill.size.x = 68.0 * clampf(s.thirst / 100.0, 0.0, 1.0)
	_cond_label.visible = s.condition != ""
	match s.condition:
		"SHELTER":
			_cond_label.text = "SHELTERED"
			_cond_label.add_theme_color_override(&"font_color", Color(0.70, 0.82, 0.62, 0.78))
		"HEAT":
			_cond_label.text = "FOUNDRY HEAT"
			_cond_label.add_theme_color_override(&"font_color", Color(1.0, 0.56, 0.24, 0.88))
		"EXPOSED":
			_cond_label.text = "EXPOSED SPAN"
			_cond_label.add_theme_color_override(&"font_color", Color(0.75, 0.84, 0.94, 0.82))


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast.modulate.a = clampf(_toast_timer / 0.5, 0.0, 1.0)
		if _toast_timer <= 0.0:
			_toast.visible = false
