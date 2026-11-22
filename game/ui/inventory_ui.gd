class_name InventoryUI
extends CanvasLayer
## Tarkov-inspired 2D grid inventory UI (brief §8.3): drag-and-drop between
## player pack and loot containers, rotation (R), stacking, right-click use,
## Shift-click quick transfer, and restrained dark rusted-steel presentation.

signal closed

const CELL := 40
const PAD := 2

var player_grid: InventoryGrid
var container_grid: InventoryGrid
var active_container: LootContainer
var survival: SurvivalComponent
var is_open := false

var _backdrop: ColorRect
var _panel: PanelContainer
var _player_box: Control
var _container_wrap: VBoxContainer
var _container_title: Label
var _container_box: Control
var _stats_label: Label
var _tip_title: Label
var _tip_body: Label
var _drag_ghost: Control

var _dragging := false
var _drag_src: InventoryGrid
var _drag_uid := -1
var _drag_item_id := ""
var _drag_count := 0
var _drag_rot := false
var _hover_grid: InventoryGrid
var _hover_cell := Vector2i(-1, -1)
var _player_cells_bg: Control
var _container_cells_bg: Control


func _ready() -> void:
	layer = 25
	visible = false
	_build_ui()


func setup(p_grid: InventoryGrid, p_survival: SurvivalComponent) -> void:
	player_grid = p_grid
	survival = p_survival
	player_grid.changed.connect(_refresh)
	survival.stats_changed.connect(_refresh_stats)
	_refresh()


func open_pack() -> void:
	active_container = null
	container_grid = null
	_set_open(true)


func open_container(c: LootContainer) -> void:
	if container_grid != null and container_grid.changed.is_connected(_refresh):
		container_grid.changed.disconnect(_refresh)
	active_container = c
	container_grid = c.grid
	container_grid.changed.connect(_refresh)
	_set_open(true)


func close_ui() -> void:
	_cancel_drag()
	if container_grid != null and container_grid.changed.is_connected(_refresh):
		container_grid.changed.disconnect(_refresh)
	active_container = null
	container_grid = null
	_set_open(false)
	closed.emit()


func _set_open(v: bool) -> void:
	is_open = v
	visible = v
	if v:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_refresh()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.03, 0.02, 0.015, 0.62)
	add_child(_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.add_child(center)

	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.075, 0.06, 0.95)
	sb.border_color = Color(0.45, 0.34, 0.22, 0.9)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(12)
	_panel.add_theme_stylebox_override(&"panel", sb)
	center.add_child(_panel)

	var root_v := VBoxContainer.new()
	root_v.add_theme_constant_override(&"separation", 8)
	_panel.add_child(root_v)

	# Header bar with title and survival stats.
	var hdr := HBoxContainer.new()
	root_v.add_child(hdr)
	var title := Label.new()
	title.text = "FIELD PACK & SUPPLIES"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override(&"font_size", 12)
	title.add_theme_color_override(&"font_color", Color(1.0, 0.84, 0.56))
	hdr.add_child(title)
	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override(&"font_size", 10)
	_stats_label.add_theme_color_override(&"font_color", Color(0.84, 0.74, 0.60))
	hdr.add_child(_stats_label)

	# Main grids row: Player Pack | Container (when open).
	var grids_row := HBoxContainer.new()
	grids_row.add_theme_constant_override(&"separation", 18)
	root_v.add_child(grids_row)

	var p_wrap := VBoxContainer.new()
	p_wrap.add_theme_constant_override(&"separation", 4)
	grids_row.add_child(p_wrap)
	var p_lbl := Label.new()
	p_lbl.text = "PACK (6 x 5)"
	p_lbl.add_theme_font_size_override(&"font_size", 10)
	p_lbl.add_theme_color_override(&"font_color", Color(0.85, 0.72, 0.52))
	p_wrap.add_child(p_lbl)
	_player_box = Control.new()
	_player_box.custom_minimum_size = Vector2(6 * CELL, 5 * CELL)
	p_wrap.add_child(_player_box)

	_container_wrap = VBoxContainer.new()
	_container_wrap.add_theme_constant_override(&"separation", 4)
	grids_row.add_child(_container_wrap)
	_container_title = Label.new()
	_container_title.add_theme_font_size_override(&"font_size", 10)
	_container_title.add_theme_color_override(&"font_color", Color(0.85, 0.72, 0.52))
	_container_wrap.add_child(_container_title)
	_container_box = Control.new()
	_container_box.custom_minimum_size = Vector2(5 * CELL, 4 * CELL)
	_container_wrap.add_child(_container_box)

	# Tooltip & controls footer.
	var tip_panel := PanelContainer.new()
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.06, 0.05, 0.04, 0.9)
	tsb.border_color = Color(0.28, 0.22, 0.16, 0.8)
	tsb.set_border_width_all(1)
	tsb.set_content_margin_all(6)
	tip_panel.add_theme_stylebox_override(&"panel", tsb)
	root_v.add_child(tip_panel)
	var tip_v := VBoxContainer.new()
	tip_v.add_theme_constant_override(&"separation", 2)
	tip_panel.add_child(tip_v)
	_tip_title = Label.new()
	_tip_title.text = "Hover an item to inspect"
	_tip_title.add_theme_font_size_override(&"font_size", 10)
	_tip_title.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.56))
	tip_v.add_child(_tip_title)
	_tip_body = Label.new()
	_tip_body.text = "[LMB] Drag/Drop   [R] Rotate   [RMB] Use consumable   [Shift+LMB] Quick Transfer   [Tab/Esc] Close"
	_tip_body.add_theme_font_size_override(&"font_size", 9)
	_tip_body.add_theme_color_override(&"font_color", Color(0.76, 0.68, 0.56))
	tip_v.add_child(_tip_body)

	# Floating drag ghost above everything.
	_drag_ghost = Control.new()
	_drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_ghost.visible = false
	add_child(_drag_ghost)


func _refresh() -> void:
	if not is_open or player_grid == null:
		return
	_refresh_stats()
	_rebuild_grid_view(_player_box, player_grid)
	if container_grid != null and active_container != null:
		_container_wrap.visible = true
		_container_title.text = "%s (%d x %d)" % [active_container.display_name.to_upper(), container_grid.cols, container_grid.rows]
		_container_box.custom_minimum_size = Vector2(container_grid.cols * CELL, container_grid.rows * CELL)
		_rebuild_grid_view(_container_box, container_grid)
	else:
		_container_wrap.visible = false


func _refresh_stats() -> void:
	if survival == null or _stats_label == null:
		return
	_stats_label.text = "HP %d   FOOD %d   WATER %d" % [
		int(roundf(survival.health)), int(roundf(survival.hunger)), int(roundf(survival.thirst))]


func _rebuild_grid_view(box: Control, grid: InventoryGrid) -> void:
	for ch in box.get_children():
		ch.queue_free()
	# Background cells.
	var bg := ColorRect.new()
	bg.size = Vector2(grid.cols * CELL, grid.rows * CELL)
	bg.color = Color(0.05, 0.04, 0.035, 0.95)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(bg)
	for gy in grid.rows:
		for gx in grid.cols:
			var cell := Panel.new()
			cell.position = Vector2(gx * CELL, gy * CELL)
			cell.size = Vector2(CELL, CELL)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var csb := StyleBoxFlat.new()
			csb.bg_color = Color(0.08, 0.068, 0.055, 0.9)
			csb.border_color = Color(0.22, 0.18, 0.14, 0.75)
			csb.set_border_width_all(1)
			cell.add_theme_stylebox_override(&"panel", csb)
			box.add_child(cell)
	# Drag placement preview highlight.
	if _dragging and _hover_grid == grid and _hover_cell.x >= 0:
		var dims := grid.item_dims(_drag_item_id, _drag_rot)
		var ignore := _drag_uid if _drag_src == grid else -1
		var ok := grid.can_place(_hover_cell.x, _hover_cell.y, dims.x, dims.y, ignore)
		if not ok:
			var t := grid.get_entry_at(_hover_cell.x, _hover_cell.y)
			if not t.is_empty() and String(t.item_id) == _drag_item_id:
				var max_s := int(ItemDB.get_item(_drag_item_id).get("max_stack", 1))
				if int(t.count) < max_s and (_drag_src != grid or int(t.uid) != _drag_uid):
					ok = true
		var hl := ColorRect.new()
		hl.position = Vector2(_hover_cell.x * CELL + 1, _hover_cell.y * CELL + 1)
		hl.size = Vector2(dims.x * CELL - 2, dims.y * CELL - 2)
		hl.color = Color(0.55, 0.72, 0.34, 0.32) if ok else Color(0.75, 0.24, 0.18, 0.36)
		hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(hl)
	# Placed item tiles.
	for e: Dictionary in grid.entries:
		var is_dragged := _dragging and _drag_src == grid and int(e.uid) == _drag_uid
		var item_def := ItemDB.get_item(String(e.item_id))
		var tile := Panel.new()
		tile.position = Vector2(int(e.x) * CELL + PAD, int(e.y) * CELL + PAD)
		tile.size = Vector2(int(e.w) * CELL - PAD * 2, int(e.h) * CELL - PAD * 2)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tsb := StyleBoxFlat.new()
		var cat_col := ItemDB.category_color(String(item_def.get("category", "")))
		tsb.bg_color = Color(cat_col.r * 0.28, cat_col.g * 0.28, cat_col.b * 0.28, 0.45 if is_dragged else 0.92)
		tsb.border_color = Color(cat_col.r, cat_col.g, cat_col.b, 0.4 if is_dragged else 0.85)
		tsb.set_border_width_all(1)
		tile.add_theme_stylebox_override(&"panel", tsb)
		box.add_child(tile)
		_populate_item_tile(tile, String(e.item_id), int(e.count), bool(e.rotated), is_dragged)


func _populate_item_tile(tile: Control, item_id: String, count: int, rotated: bool, faded: bool) -> void:
	var tex := ItemDB.get_icon(item_id)
	var icon := TextureRect.new()
	icon.texture = tex
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if rotated:
		icon.size = Vector2(tile.size.y - 6, tile.size.x - 6)
		icon.pivot_offset = icon.size * 0.5
		icon.rotation = PI * 0.5
		icon.position = (tile.size - icon.size) * 0.5
	else:
		icon.position = Vector2(3, 3)
		icon.size = tile.size - Vector2(6, 6)
	icon.modulate.a = 0.35 if faded else 1.0
	tile.add_child(icon)
	if count > 1:
		var cl := Label.new()
		cl.text = "x%d" % count
		cl.position = Vector2(tile.size.x - 20, tile.size.y - 14)
		cl.size = Vector2(18, 13)
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cl.add_theme_font_size_override(&"font_size", 9)
		cl.add_theme_color_override(&"font_color", Color(1.0, 0.90, 0.65))
		cl.add_theme_color_override(&"font_shadow_color", Color.BLACK)
		cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(cl)


func _grid_at_mouse(mpos: Vector2) -> Dictionary:
	var pr := _player_box.get_global_rect()
	if pr.has_point(mpos):
		var rel := mpos - pr.position
		return { "grid": player_grid, "cell": Vector2i(int(rel.x / CELL), int(rel.y / CELL)) }
	if container_grid != null and _container_wrap.visible:
		var cr := _container_box.get_global_rect()
		if cr.has_point(mpos):
			var rel := mpos - cr.position
			return { "grid": container_grid, "cell": Vector2i(int(rel.x / CELL), int(rel.y / CELL)) }
	return {}


func _update_drag_ghost(mpos: Vector2) -> void:
	for ch in _drag_ghost.get_children():
		ch.queue_free()
	if not _dragging:
		_drag_ghost.visible = false
		return
	var dims := player_grid.item_dims(_drag_item_id, _drag_rot)
	_drag_ghost.visible = true
	_drag_ghost.size = Vector2(dims.x * CELL - PAD * 2, dims.y * CELL - PAD * 2)
	_drag_ghost.position = mpos - _drag_ghost.size * 0.5
	var tile := Panel.new()
	tile.size = _drag_ghost.size
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.24, 0.18, 0.12, 0.85)
	tsb.border_color = Color(1.0, 0.82, 0.45, 0.95)
	tsb.set_border_width_all(1)
	tile.add_theme_stylebox_override(&"panel", tsb)
	_drag_ghost.add_child(tile)
	_populate_item_tile(tile, _drag_item_id, _drag_count, _drag_rot, false)


func _cancel_drag() -> void:
	_dragging = false
	_drag_src = null
	_drag_uid = -1
	_drag_ghost.visible = false


func _update_tooltip(mpos: Vector2) -> void:
	var hit := _grid_at_mouse(mpos)
	if hit.is_empty():
		if not _dragging:
			_tip_title.text = "Hover an item to inspect"
			_tip_body.text = "[LMB] Drag/Drop   [R] Rotate   [RMB] Use consumable   [Shift+LMB] Quick Transfer   [Tab/Esc] Close"
		return
	var g: InventoryGrid = hit.grid
	var c: Vector2i = hit.cell
	var e := g.get_entry_at(c.x, c.y)
	if e.is_empty():
		return
	var d := ItemDB.get_item(String(e.item_id))
	var tag := " (Consumable — RMB to use)" if ItemDB.is_consumable(String(e.item_id)) else " (%s)" % String(d.get("category", "")).capitalize()
	_tip_title.text = "%s  x%d%s" % [String(d.name), int(e.count), tag]
	_tip_body.text = String(d.get("description", ""))


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed(&"inventory") or event.is_action_pressed(&"release_mouse") or event.is_action_pressed(&"interact"):
		get_viewport().set_input_as_handled()
		close_ui()
		return
	if event.is_action_pressed(&"rotate_item") and _dragging:
		_drag_rot = not _drag_rot
		_update_drag_ghost(get_viewport().get_mouse_position())
		_refresh()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		var mpos := (event as InputEventMouseMotion).position
		_update_tooltip(mpos)
		if _dragging:
			_drag_ghost.position = mpos - _drag_ghost.size * 0.5
			var hit := _grid_at_mouse(mpos)
			var ng: InventoryGrid = hit.grid if not hit.is_empty() else null
			var nc: Vector2i = hit.cell if not hit.is_empty() else Vector2i(-1, -1)
			if ng != _hover_grid or nc != _hover_cell:
				_hover_grid = ng
				_hover_cell = nc
				_refresh()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var mpos := mb.position
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var hit := _grid_at_mouse(mpos)
			if _dragging:
				if not hit.is_empty():
					InventoryGrid.transfer_to_cell(_drag_src, _drag_uid, hit.grid, hit.cell.x, hit.cell.y, _drag_rot)
				_cancel_drag()
				_refresh()
				get_viewport().set_input_as_handled()
				return
			if not hit.is_empty():
				var g: InventoryGrid = hit.grid
				var e := g.get_entry_at(hit.cell.x, hit.cell.y)
				if not e.is_empty():
					# Shift+Click quick transfer between container and player pack.
					if Input.is_key_pressed(KEY_SHIFT) and container_grid != null:
						var dst := container_grid if g == player_grid else player_grid
						var rem := dst.auto_add(String(e.item_id), int(e.count))
						if rem == 0:
							g.remove_entry(int(e.uid))
						elif rem < int(e.count):
							e.count = rem
							g.changed.emit()
						_refresh()
						get_viewport().set_input_as_handled()
						return
					# Pick up item for drag-and-drop.
					_dragging = true
					_drag_src = g
					_drag_uid = int(e.uid)
					_drag_item_id = String(e.item_id)
					_drag_count = int(e.count)
					_drag_rot = bool(e.rotated)
					_hover_grid = g
					_hover_cell = Vector2i(int(e.x), int(e.y))
					_update_drag_ghost(mpos)
					_refresh()
					get_viewport().set_input_as_handled()
					return
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and _dragging:
			# Support hold-and-release drag-and-drop as well as click-pick / click-drop.
			var hit := _grid_at_mouse(mpos)
			if not hit.is_empty():
				var same_spot: bool = (hit.grid == _drag_src and int(_drag_src.get_entry_at(hit.cell.x, hit.cell.y).get("uid", -2)) == _drag_uid)
				if not same_spot:
					InventoryGrid.transfer_to_cell(_drag_src, _drag_uid, hit.grid, hit.cell.x, hit.cell.y, _drag_rot)
					_cancel_drag()
					_refresh()
					get_viewport().set_input_as_handled()
					return
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if _dragging:
				_cancel_drag()
				_refresh()
				get_viewport().set_input_as_handled()
				return
			var hit := _grid_at_mouse(mpos)
			if not hit.is_empty():
				var g: InventoryGrid = hit.grid
				var e := g.get_entry_at(hit.cell.x, hit.cell.y)
				if not e.is_empty() and ItemDB.is_consumable(String(e.item_id)):
					if survival.use_item(String(e.item_id)):
						g.consume_one(int(e.uid))
						_refresh()
				get_viewport().set_input_as_handled()
