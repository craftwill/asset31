class_name HomeSite
extends Node3D
## Home pocket (frames 000s and 575s): the player's one-room shelter on the
## ground floor of a residential block, a side street, a courtyard and a
## freight lift to the roof viewpoint. Site-local coordinates: origin at the
## block corner (rect x0, z0); u = +x, v = +z, y up from the floor.

var _body: StaticBody3D        # stone / concrete surfaces
var _metal: StaticBody3D       # plate / wood surfaces (footstep sound)


static func build(stack: StackRuntime, site: Dictionary) -> Node3D:
	var s := HomeSite.new()
	var r: Array = site.rect
	s.position = Vector3(float(r[0]), 0.0, float(r[1]))
	s._build()
	return s


func _ready() -> void:
	pass


func _b(a: Vector3, b: Vector3, mat: StringName, body: StaticBody3D = null, shadow := false) -> MeshInstance3D:
	var mi := SliceMaterials.add_box(self, body, (a + b) * 0.5, (b - a).abs(), mat, body != null)
	if shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


func _build() -> void:
	_body = StaticBody3D.new()
	_body.name = "Collision"
	add_child(_body)
	_metal = StaticBody3D.new()
	_metal.name = "CollisionMetal"
	_metal.set_meta(&"surface", "metal")
	add_child(_metal)
	_building()
	_room()
	_roof()
	_courtyard()
	_street_lamps()
	var lift := Lift.new()
	lift.position = Vector3(9.5, 0.0, 25.7)
	lift.top_height = 42.0
	add_child(lift)
	var crowd := Crowd.new()
	add_child(crowd)
	crowd.setup(
		[{ "p": Vector3(-10.5, 0, 12.0), "yaw": 1.2 }, { "p": Vector3(-3.0, 0, -20.0), "yaw": -2.0 }],
		[{ "a": Vector3(-5.0, 0, -60.0), "b": Vector3(-5.0, 0, 40.0) }, { "a": Vector3(-9.0, 0, 30.0), "b": Vector3(-9.0, 0, -55.0) }],
		1701)


## H1: 20 x 20 m, 42 m (12 storeys). The room is carved out of its NW corner.
func _building() -> void:
	_b(Vector3(1, 3.1, 27.5), Vector3(21, 42, 47.5), &"authored_facade", _body)
	_b(Vector3(1, -1, 27.5), Vector3(21, 3.1, 42.3), &"authored_facade", _body)
	_b(Vector3(4.7, -1, 42.3), Vector3(21, 3.1, 47.5), &"authored_facade", _body)
	# Neighbours inside the block.
	_b(Vector3(24, -1, 1), Vector3(47.5, 24.5, 23), &"authored_concrete", _body)
	_b(Vector3(24, -1, 27.5), Vector3(47.5, 31.5, 47.5), &"authored_facade", _body)


## The shelter, frame 000s: 3 x 4.5 x 2.8 m, riveted plates, bed, table,
## shelf, bucket, hanging bulb, tally marks, a child's drawing of a tree, and
## one window onto the city.
func _room() -> void:
	var m := _metal
	# Floor (2 cm above the slab, never coplanar) and ceiling.
	_b(Vector3(1.4, -0.08, 42.6), Vector3(4.4, 0.03, 47.1), &"floor_wood", m)
	_b(Vector3(1, 2.8, 42.3), Vector3(4.7, 3.1, 47.5), &"plate", null, true)
	# West wall with the door (v 42.9..43.9).
	_b(Vector3(1, 0, 42.3), Vector3(1.4, 2.8, 42.9), &"plate", m, true)
	_b(Vector3(1, 0, 43.9), Vector3(1.4, 2.8, 47.5), &"plate", m, true)
	_b(Vector3(1, 2.1, 42.9), Vector3(1.4, 2.8, 43.9), &"plate", m, true)
	# North wall with the window (u 2.2..3.6, y 1.1..2.1).
	_b(Vector3(1.4, 0, 47.1), Vector3(2.2, 2.8, 47.5), &"plate", m, true)
	_b(Vector3(3.6, 0, 47.1), Vector3(4.7, 2.8, 47.5), &"plate", m, true)
	_b(Vector3(2.2, 0, 47.1), Vector3(3.6, 1.1, 47.5), &"plate", m, true)
	_b(Vector3(2.2, 2.1, 47.1), Vector3(3.6, 2.8, 47.5), &"plate", m, true)
	# East and south walls.
	_b(Vector3(4.4, 0, 42.3), Vector3(4.7, 2.8, 47.1), &"plate", m, true)
	_b(Vector3(1.4, 0, 42.3), Vector3(4.4, 2.8, 42.6), &"plate", m, true)
	# Window: mullions, glass.
	_b(Vector3(2.875, 1.1, 47.2), Vector3(2.925, 2.1, 47.4), &"structure", null, true)
	_b(Vector3(2.2, 1.575, 47.2), Vector3(3.6, 1.625, 47.4), &"structure", null, true)
	_b(Vector3(2.2, 1.1, 47.28), Vector3(3.6, 2.1, 47.32), &"glass", m)
	# Door leaf, swung open against the south wall.
	_b(Vector3(1.45, 0.02, 42.62), Vector3(2.4, 2.07, 42.68), &"wood", null, true)
	# Bed along the west wall.
	_b(Vector3(1.4, 0.02, 44.2), Vector3(2.3, 0.45, 46.95), &"wood", m, true)
	_b(Vector3(1.45, 0.45, 44.25), Vector3(2.25, 0.62, 46.9), &"fabric", null, true)
	_b(Vector3(1.5, 0.62, 46.4), Vector3(2.2, 0.72, 46.85), &"fabric", null, true)
	_b(Vector3(1.45, 0.62, 44.3), Vector3(2.27, 0.67, 45.95), &"fabric_dark", null, true)
	# Wall drawings above the bed: tally marks, tree drawing, note.
	_b(Vector3(1.4, 1.4, 44.35), Vector3(1.415, 1.95, 45.25), &"tally")
	_b(Vector3(1.4, 1.45, 45.4), Vector3(1.42, 2.0, 45.9), &"poster_tree")
	_b(Vector3(1.4, 1.08, 45.45), Vector3(1.42, 1.33, 45.85), &"note")
	add_child(ReadableNote.create(
		"NOTE-HOME", "Pinned Note",
		"FLOOR 77 — STK-0412\n\n"
		+ "Water pressure dropped again in the lower blocks.\n"
		+ "Freight span BR-077-A across to STK-0413 is still open—3 km over the gap.\n"
		+ "Pack tins and water from the cabinet before heading east through the foundry.\n"
		+ "(Press [M] for the Floor 77 sector diagram, [F] for your work-lamp.)",
		Vector3(1.44, 1.21, 45.65), PI * 0.5, "invisible"))
	# Table, legs, crate seat, plate and cup.
	_b(Vector3(3.0, 0.72, 44.4), Vector3(3.9, 0.78, 45.3), &"wood", m, true)
	for lp in [Vector2(3.05, 44.45), Vector2(3.8, 44.45), Vector2(3.05, 45.2), Vector2(3.8, 45.2)]:
		_b(Vector3(lp.x, 0.02, lp.y), Vector3(lp.x + 0.05, 0.72, lp.y + 0.05), &"wood", null, true)
	_b(Vector3(3.2, 0.02, 43.55), Vector3(3.65, 0.47, 44.0), &"wood", m, true)
	SliceMaterials.add_cylinder(self, Vector3(3.35, 0.78, 44.85), Vector3(3.35, 0.795, 44.85), 0.12, &"ceramic", 10)
	SliceMaterials.add_cylinder(self, Vector3(3.62, 0.78, 44.7), Vector3(3.62, 0.87, 44.7), 0.04, &"metal_light", 8)
	# Shelf with tins on the east wall.
	_b(Vector3(4.15, 1.7, 44.0), Vector3(4.4, 1.73, 45.2), &"wood", null, true)
	for v in [44.25, 44.42, 44.9]:
		SliceMaterials.add_cylinder(self, Vector3(4.28, 1.73, v), Vector3(4.28, 1.84, v), 0.04, &"metal_light", 8)
	# Bucket and a pipe running along the east wall.
	SliceMaterials.add_cylinder(self, Vector3(4.05, 0.02, 46.7), Vector3(4.05, 0.32, 46.7), 0.15, &"metal_light", 8)
	SliceMaterials.add_cylinder(self, Vector3(4.33, 0.9, 42.6), Vector3(4.33, 0.9, 47.1), 0.04, &"copper", 6)
	# Lootable starter cabinet tucked against the east wall south of the table.
	add_child(LootContainer.create(
		"CONT-HOME-CABINET", "Shelter Cabinet", "cabinet",
		Vector3(4.08, 0.03, 43.2), -PI * 0.5,
		[["ration_tin", 2], ["condensate_can", 2], ["bandage_roll", 1]], 4, 3))
	# Hanging bulb: the only light in the room (shadowed).
	_b(Vector3(2.89, 2.25, 45.59), Vector3(2.91, 2.8, 45.61), &"structure")
	_b(Vector3(2.85, 2.15, 45.55), Vector3(2.95, 2.25, 45.65), &"bulb")
	SliceMaterials.add_coronas(self, [Vector3(2.9, 2.2, 45.6)], 0.6)
	var bulb := OmniLight3D.new()
	bulb.position = Vector3(2.9, 2.12, 45.6)
	bulb.light_color = Color(1.0, 0.72, 0.42)
	bulb.light_energy = 1.1
	bulb.omni_range = 7.0
	bulb.omni_attenuation = 1.4
	bulb.shadow_enabled = true
	bulb.shadow_bias = 0.03
	add_child(bulb)
	# Lamp over the door, outside.
	_b(Vector3(0.75, 2.45, 43.3), Vector3(0.95, 2.6, 43.5), &"lamp")
	SliceMaterials.add_coronas(self, [Vector3(0.7, 2.5, 43.4)], 1.0)
	var door_light := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.2, 7.0)
	door_light.position = Vector3(0.6, 2.3, 43.4)
	add_child(door_light)


## Roof viewpoint with parapet (opening on the south edge for the lift).
func _roof() -> void:
	var y := 42.0
	var top := 43.1
	_b(Vector3(1.3, y, 47.2), Vector3(20.7, top, 47.5), &"authored_facade", _body)
	_b(Vector3(1, y, 27.8), Vector3(1.3, top, 47.5), &"authored_facade", _body)
	_b(Vector3(20.7, y, 27.8), Vector3(21, top, 47.5), &"authored_facade", _body)
	_b(Vector3(1, y, 27.5), Vector3(8, top, 27.8), &"authored_facade", _body)
	_b(Vector3(11, y, 27.5), Vector3(21, top, 27.8), &"authored_facade", _body)
	# Roof clutter: water tank on legs, plant room, antenna with a red beacon.
	for lg in [Vector2(14.6, 30.6), Vector2(17.4, 30.6), Vector2(14.6, 33.4), Vector2(17.4, 33.4)]:
		_b(Vector3(lg.x - 0.1, y, lg.y - 0.1), Vector3(lg.x + 0.1, y + 1.5, lg.y + 0.1), &"structure", _body)
	SliceMaterials.add_cylinder(self, Vector3(16, y + 1.5, 32), Vector3(16, y + 4.5, 32), 1.6, &"container_rust", 10)
	_b(Vector3(3, y, 30), Vector3(6, y + 2.6, 34), &"container_grey", _body)
	_b(Vector3(18.9, y, 44.9), Vector3(19.1, y + 9.0, 45.1), &"structure")
	_b(Vector3(18.85, y + 9.0, 44.85), Vector3(19.15, y + 9.25, 45.15), &"beacon_red")
	SliceMaterials.add_coronas(self, [Vector3(19, y + 9.1, 45)], 1.4)
	var roof_lamp := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.0, 9.0)
	roof_lamp.position = Vector3(9.5, y + 2.6, 28.5)
	add_child(roof_lamp)
	_b(Vector3(9.3, y + 2.6, 28.0), Vector3(9.7, y + 2.75, 28.3), &"lamp")
	SliceMaterials.add_coronas(self, [Vector3(9.5, y + 2.65, 28.15)], 1.0)


func _courtyard() -> void:
	_b(Vector3(1, -1, 2), Vector3(6, 3.5, 10), &"plate", _metal)
	_b(Vector3(1.2, 3.5, 1.6), Vector3(6.4, 3.65, 10.4), &"structure", null)
	_b(Vector3(14, 0.02, 3), Vector3(15.2, 1.2, 4.6), &"container_teal", _body)
	_b(Vector3(15.6, 0.02, 3), Vector3(16.8, 1.2, 4.6), &"container_rust", _body)
	_b(Vector3(3, 0.02, 18), Vector3(5, 0.45, 18.5), &"wood", _body)
	# Lived-in courtyard & wall-base signs of use (tucked against walls, clear of routes).
	_b(Vector3(6.3, 0.02, 5.2), Vector3(7.4, 0.85, 6.4), &"wood_dark", _body)
	_b(Vector3(6.5, 0.85, 5.4), Vector3(7.2, 1.4, 6.1), &"wood")
	SliceMaterials.add_cylinder(self, Vector3(6.7, 0.02, 7.6), Vector3(6.7, 0.92, 7.6), 0.3, &"container_rust", 8)
	_b(Vector3(0.25, 0.02, 31.0), Vector3(0.95, 0.65, 32.1), &"wood_dark", _body)
	_b(Vector3(0.3, 0.02, 32.3), Vector3(0.9, 0.35, 33.4), &"concrete", _body)
	# Subtle localized lamp and diegetic label at the freight lift landing.
	_b(Vector3(7.2, 2.55, 25.4), Vector3(7.6, 2.75, 26.0), &"lamp")
	SliceMaterials.add_coronas(self, [Vector3(7.4, 2.55, 25.7)], 1.1)
	var lift_l := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.3, 9.0)
	lift_l.position = Vector3(7.4, 2.35, 25.7)
	add_child(lift_l)
	SliceMaterials.add_sign(self, Vector3(7.35, 2.05, 27.4), "ROOF LIFT", 0.008, Color(1.0, 0.85, 0.55), PI)
	# Lootable courtyard supply crate beside the freight lift landing.
	add_child(LootContainer.create(
		"CONT-COURTYARD-CRATE", "Courtyard Crate", "crate",
		Vector3(12.2, 0.0, 25.8), 0.0,
		[["water_flask", 1], ["fuse_cell", 1], ["brass_coil", 1]], 5, 4))
	# Overhead laundry lines strung high across the side street (frame 575s lived-in rhythm).
	var cloths: Dictionary = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 5750
	for ln in [[9.5, 22.0], [13.5, 56.0], [8.8, -18.0]]:
		var ly: float = ln[0]
		var lv: float = ln[1]
		_b(Vector3(-13.2, ly - 0.02, lv - 0.02), Vector3(1.0, ly + 0.02, lv + 0.02), &"structure")
		for i in 6:
			var lu := -11.5 + i * 2.1 + rng.randf_range(-0.3, 0.3)
			var mat: StringName = [&"cloth_beige", &"cloth_red", &"cloth_teal", &"fabric_dark"][rng.randi() % 4]
			if not cloths.has(mat):
				cloths[mat] = []
			var lh := rng.randf_range(0.65, 1.15)
			cloths[mat].append({ "c": Vector3(lu, ly - lh * 0.5, lv), "s": Vector3(rng.randf_range(0.55, 0.95), lh, 0.03) })
	for mat: StringName in cloths:
		SliceMaterials.add_multimesh(self, cloths[mat], mat)


## Side street lamps (frame 575s: sparse, warm, single heads).
func _street_lamps() -> void:
	var heads: Array = []
	for v in [-45.0, 0.0, 45.0, 90.0]:
		var base := Vector3(-12.6, 0, v)
		_b(base + Vector3(-0.1, 0, -0.1), base + Vector3(0.1, 6.2, 0.1), &"structure", _body)
		_b(base + Vector3(-0.1, 6.0, -0.05), base + Vector3(1.4, 6.12, 0.05), &"structure")
		_b(base + Vector3(1.2, 5.85, -0.2), base + Vector3(1.6, 6.0, 0.2), &"lamp")
		heads.append(base + Vector3(1.4, 5.8, 0))
		var l := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 2.0, 15.0)
		l.position = base + Vector3(1.4, 5.6, 0)
		add_child(l)
	SliceMaterials.add_coronas(self, heads, 2.0)
