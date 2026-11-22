class_name LootContainer
extends StaticBody3D
## Reusable interactable loot container placed in the world (crate, cabinet,
## locker, cache). Identified by a stable `container_id` so save/load persists
## its grid contents and opened state regardless of floating-origin rebases.

const GROUP := &"loot_containers"

var container_id := ""
var display_name := "Supply Crate"
var style := "crate"
var grid: InventoryGrid
var opened := false
var _status_lamp: MeshInstance3D


static func create(id: String, label: String, p_style: String, pos: Vector3, rot_y: float, initial_items: Array, cols := 5, rows := 4) -> LootContainer:
	var c := LootContainer.new()
	c.name = id
	c.container_id = id
	c.display_name = label
	c.style = p_style
	c.position = pos
	c.rotation.y = rot_y
	c.grid = InventoryGrid.new(cols, rows)
	for entry: Array in initial_items:
		c.grid.auto_add(String(entry[0]), int(entry[1]))
	c._build_mesh()
	c.add_to_group(GROUP)
	c.grid.changed.connect(c._update_indicator)
	return c


func _build_mesh() -> void:
	set_meta(&"surface", "metal")
	match style:
		"cabinet":
			# Modest steel wall/floor cabinet with drawer seams (home room).
			SliceMaterials.add_box(self, self, Vector3(0, 0.42, 0), Vector3(0.62, 0.84, 0.46), &"plate")
			SliceMaterials.add_box(self, null, Vector3(0, 0.855, 0), Vector3(0.66, 0.03, 0.50), &"structure", false)
			SliceMaterials.add_box(self, null, Vector3(0, 0.62, 0.24), Vector3(0.24, 0.035, 0.03), &"metal_light", false)
			SliceMaterials.add_box(self, null, Vector3(0, 0.28, 0.24), Vector3(0.24, 0.035, 0.03), &"metal_light", false)
			_status_lamp = SliceMaterials.add_box(self, null, Vector3(0.22, 0.78, 0.24), Vector3(0.05, 0.03, 0.02), &"rail_glow", false)
		"locker":
			# Tall industrial maintenance locker.
			SliceMaterials.add_box(self, self, Vector3(0, 0.92, 0), Vector3(0.76, 1.84, 0.54), &"container_grey")
			SliceMaterials.add_box(self, null, Vector3(0, 1.86, 0), Vector3(0.80, 0.04, 0.58), &"structure", false)
			SliceMaterials.add_box(self, null, Vector3(0.26, 0.95, 0.28), Vector3(0.04, 0.22, 0.04), &"metal_light", false)
			_status_lamp = SliceMaterials.add_box(self, null, Vector3(-0.24, 1.72, 0.28), Vector3(0.06, 0.04, 0.02), &"rail_glow", false)
		"cache":
			# Heavy expedition footlocker / shelter cache.
			SliceMaterials.add_box(self, self, Vector3(0, 0.32, 0), Vector3(1.1, 0.64, 0.62), &"container_teal")
			SliceMaterials.add_box(self, null, Vector3(0, 0.66, 0), Vector3(1.14, 0.06, 0.66), &"structure", false)
			SliceMaterials.add_box(self, null, Vector3(-0.32, 0.52, 0.32), Vector3(0.10, 0.14, 0.04), &"metal_light", false)
			SliceMaterials.add_box(self, null, Vector3(0.32, 0.52, 0.32), Vector3(0.10, 0.14, 0.04), &"metal_light", false)
			_status_lamp = SliceMaterials.add_box(self, null, Vector3(0.0, 0.62, 0.33), Vector3(0.08, 0.03, 0.02), &"rail_glow", false)
		_:
			# Rugged wooden / riveted supply crate.
			SliceMaterials.add_box(self, self, Vector3(0, 0.38, 0), Vector3(0.88, 0.76, 0.64), &"wood_dark")
			SliceMaterials.add_box(self, null, Vector3(0, 0.78, 0), Vector3(0.92, 0.05, 0.68), &"structure", false)
			SliceMaterials.add_box(self, null, Vector3(0, 0.38, 0.33), Vector3(0.84, 0.06, 0.03), &"structure", false)
			_status_lamp = SliceMaterials.add_box(self, null, Vector3(0.0, 0.72, 0.33), Vector3(0.07, 0.03, 0.02), &"rail_glow", false)
	_update_indicator()


func mark_opened() -> void:
	opened = true
	_update_indicator()


func prompt_text() -> String:
	var state := " (empty)" if grid.entries.is_empty() else (" (searched)" if opened else "")
	return "[E] Open %s%s" % [display_name, state]


func _update_indicator() -> void:
	if _status_lamp != null:
		_status_lamp.visible = not grid.entries.is_empty()


func serialize() -> Dictionary:
	return {
		"opened": opened,
		"items": grid.serialize(),
	}


func deserialize(d: Dictionary) -> void:
	opened = bool(d.get("opened", false))
	grid.deserialize(d.get("items", []))
	_update_indicator()
