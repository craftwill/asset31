class_name PreserveSite
extends Node3D
## Ecological Preserve 413-B (faithful recreation of video_reference_450s.jpg & 475s.jpg).
## A 220 m tall pale-concrete megastructure atrium inside STK-0413 directly north of
## Hydroponic Bay 413-A: three giant overhead skylight grids, 8 stacked hanging terraces
## edged with magenta grow-strips, a central pale-blue atmospheric waterfall/light column,
## green meadow with grass tufts, low-poly trees, grazing deer silhouettes, and orbiting
## high-altitude bird flocks.

const ATRIUM_H := 220.0
const PORTAL_HALF := 9.0

var _birds_mm: MultiMesh
var _bird_data: Array = []


static func build(_stack: StackRuntime, site: Dictionary) -> Node3D:
	var r: Array = site.rect # [x0, z0, x1, z1]
	var p := PreserveSite.new()
	var cx := (float(r[0]) + float(r[2])) * 0.5
	var cz := (float(r[1]) + float(r[3])) * 0.5
	p.position = Vector3(cx, 0.0, cz)
	p._build(float(r[2]) - float(r[0]), float(r[3]) - float(r[1]))
	return p


func _build(W: float, D: float) -> void:
	var hw := W * 0.5
	var hd := D * 0.5
	var body := StaticBody3D.new()
	body.name = "PreserveCollision"
	add_child(body)

	# 1. Lush meadow grass floor (y = 0.06 above stack slab) + pale concrete 220 m atrium walls.
	SliceMaterials.add_box(self, body, Vector3(0, -0.04, 0), Vector3(W, 0.2, D), &"grass_floor")
	var wt := 3.0
	SliceMaterials.add_box(self, body, Vector3(0, ATRIUM_H * 0.5, -hd + wt * 0.5), Vector3(W, ATRIUM_H, wt), &"preserve_wall")
	SliceMaterials.add_box(self, body, Vector3(-hw + wt * 0.5, ATRIUM_H * 0.5, 0), Vector3(wt, ATRIUM_H, D - 2.0 * wt), &"preserve_wall")
	SliceMaterials.add_box(self, body, Vector3(hw - wt * 0.5, ATRIUM_H * 0.5, 0), Vector3(wt, ATRIUM_H, D - 2.0 * wt), &"preserve_wall")
	# South wall splits cleanly around the 18 m x 9 m archway connecting from Hydroponic Bay 413-A.
	var sw := hw - PORTAL_HALF
	SliceMaterials.add_box(self, body, Vector3(-PORTAL_HALF - sw * 0.5, ATRIUM_H * 0.5, hd - wt * 0.5), Vector3(sw, ATRIUM_H, wt), &"preserve_wall")
	SliceMaterials.add_box(self, body, Vector3(PORTAL_HALF + sw * 0.5, ATRIUM_H * 0.5, hd - wt * 0.5), Vector3(sw, ATRIUM_H, wt), &"preserve_wall")
	SliceMaterials.add_box(self, body, Vector3(0, 9.0 + (ATRIUM_H - 9.0) * 0.5, hd - wt * 0.5), Vector3(PORTAL_HALF * 2.0, ATRIUM_H - 9.0, wt), &"preserve_wall")
	# Overhead dark ceiling frame holding 3 monumental warm-white skylight grids (exact 450s ceiling).
	SliceMaterials.add_box(self, null, Vector3(0, ATRIUM_H + 2.0, 0), Vector3(W + 2.0, 4.0, D + 2.0), &"preserve_wall", false)
	var sky_panels: Array = []
	var sky_beams: Array = []
	for sz: float in [-58.0, 0.0, 58.0]:
		sky_panels.append({ "c": Vector3(0, ATRIUM_H - 0.8, sz), "s": Vector3(W * 0.72, 0.8, 38.0) })
		for mx: float in [-50.0, -25.0, 0.0, 25.0, 50.0]:
			sky_beams.append({ "c": Vector3(mx, ATRIUM_H - 1.6, sz), "s": Vector3(2.2, 1.8, 38.5) })
	SliceMaterials.add_multimesh(self, sky_panels, &"sky_panel")
	SliceMaterials.add_multimesh(self, sky_beams, &"preserve_wall")

	# 2. Eight stacked hanging concrete terraces edged with pink grow-strips & foliage (450s & 475s).
	var terraces: Array = []
	var pink_strips: Array = []
	var terrace_greens: Array = []
	var tier_cols: Array = []
	var shelf_d := 16.0
	for ti in 8:
		var ty := 28.0 + float(ti) * 23.0
		# North terrace spanning across the back wall.
		terraces.append({ "c": Vector3(0, ty, -hd + wt + shelf_d * 0.5), "s": Vector3(W - 2.0 * wt, 2.4, shelf_d) })
		pink_strips.append({ "c": Vector3(0, ty - 1.4, -hd + wt + shelf_d - 1.2), "s": Vector3(W - 2.0 * wt - 8.0, 0.48, 0.48) })
		terrace_greens.append({ "c": Vector3(0, ty + 1.8, -hd + wt + shelf_d - 2.2), "s": Vector3(W - 2.0 * wt - 10.0, 1.5, 3.2) })
		# East and West side terraces.
		for sgn: float in [-1.0, 1.0]:
			var tx := sgn * (hw - wt - shelf_d * 0.5)
			terraces.append({ "c": Vector3(tx, ty, 0), "s": Vector3(shelf_d, 2.4, D - 2.0 * wt - 2.0 * shelf_d) })
			pink_strips.append({ "c": Vector3(sgn * (hw - wt - shelf_d + 1.2), ty - 1.4, 0), "s": Vector3(0.48, 0.48, D - 2.0 * wt - 2.0 * shelf_d - 4.0) })
			terrace_greens.append({ "c": Vector3(sgn * (hw - wt - shelf_d + 2.2), ty + 1.8, 0), "s": Vector3(3.2, 1.5, D - 2.0 * wt - 2.0 * shelf_d - 6.0) })
	# Tall slender pale columns rising vertically through all 8 terrace decks (exact 475s verticals).
	for cx: float in [-76.0, -44.0, -14.0, 14.0, 44.0, 76.0]:
		tier_cols.append({ "c": Vector3(cx, ATRIUM_H * 0.5, -hd + wt + shelf_d - 1.0), "s": Vector3(2.2, ATRIUM_H, 2.2) })
	for cz: float in [-60.0, -20.0, 20.0, 60.0]:
		for sgn: float in [-1.0, 1.0]:
			tier_cols.append({ "c": Vector3(sgn * (hw - wt - shelf_d + 1.0), ATRIUM_H * 0.5, cz), "s": Vector3(2.2, ATRIUM_H, 2.2) })
	SliceMaterials.add_multimesh(self, terraces, &"preserve_wall")
	SliceMaterials.add_multimesh(self, tier_cols, &"preserve_wall")
	SliceMaterials.add_multimesh(self, pink_strips, &"grow_magenta")
	SliceMaterials.add_multimesh(self, terrace_greens, &"crop_green")

	# 3. Colossal central luminous pale-blue waterfall / light shaft pouring down to the meadow (450s / 475s).
	var wf_pos := Vector3(0.0, 0.0, -32.0)
	var wf_col := MeshInstance3D.new()
	wf_col.mesh = SliceMaterials.unit_cylinder(12)
	wf_col.position = wf_pos + Vector3(0, ATRIUM_H * 0.5, 0)
	wf_col.scale = Vector3(9.5, ATRIUM_H, 9.5)
	wf_col.material_override = SliceMaterials.get_mat(&"water_beam")
	wf_col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wf_col)
	# Tapered misty spray cone flaring cleanly into the glowing basin at meadow level.
	var wf_cone := MeshInstance3D.new()
	var cone_m := CylinderMesh.new()
	cone_m.top_radius = 4.8
	cone_m.bottom_radius = 15.0
	cone_m.height = 30.0
	cone_m.radial_segments = 14
	wf_cone.mesh = cone_m
	wf_cone.position = wf_pos + Vector3(0, 15.0, 0)
	wf_cone.material_override = SliceMaterials.get_mat(&"water_beam")
	wf_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wf_cone)
	SliceMaterials.add_box(self, body, wf_pos + Vector3(0, 0.14, 0), Vector3(34.0, 0.25, 34.0), &"water_beam")
	SliceMaterials.add_coronas(self, [
		wf_pos + Vector3(0, 8.0, 0), wf_pos + Vector3(0, 22.0, 0),
		wf_pos + Vector3(0, 56.0, 0), wf_pos + Vector3(0, 110.0, 0),
	], 40.0, &"corona_cool")

	# Bright, calm daylight-like atrium illumination (warm-white overhead + cool mist base).
	var sky_col := Color(0.98, 0.96, 0.90)
	for lx: float in [-48.0, 0.0, 48.0]:
		for lz: float in [-50.0, 10.0, 62.0]:
			var l := SliceMaterials.make_lamp_light(sky_col, 4.6, 120.0)
			l.position = Vector3(lx, 42.0, lz)
			l.distance_fade_begin = 260.0
			add_child(l)
	var wf_l := SliceMaterials.make_lamp_light(Color(0.76, 0.92, 1.0), 4.0, 90.0)
	wf_l.position = wf_pos + Vector3(0, 14.0, 0)
	add_child(wf_l)

	# 4. Meadow grass tufts, low-poly trees, and grazing deer silhouettes (475s).
	var rng := RandomNumberGenerator.new()
	rng.seed = 41375
	var tufts: Array = []
	for _i in 320:
		var gx := rng.randf_range(-hw + 16.0, hw - 16.0)
		var gz := rng.randf_range(-hd + 24.0, hd - 16.0)
		if Vector2(gx - wf_pos.x, gz - wf_pos.z).length() < 20.0:
			continue
		tufts.append({
			"c": Vector3(gx, 0.34, gz),
			"s": Vector3(rng.randf_range(0.18, 0.36), rng.randf_range(0.35, 0.65), rng.randf_range(0.18, 0.36)),
			"r": Vector3(rng.randf_range(-0.18, 0.18), rng.randf() * TAU, rng.randf_range(-0.18, 0.18)),
		})
	var trunks: Array = []
	var leaves_hi: Array = []
	var leaves_lo: Array = []
	# Framing foreground left tree + scattered perimeter/meadow trees (exact 475s framing).
	var tree_spots: Array = [
		Vector3(-9.5, 0, 74.0), Vector3(-24.0, 0, 62.0), Vector3(22.0, 0, 68.0),
		Vector3(-42.0, 0, 32.0), Vector3(44.0, 0, 26.0), Vector3(-56.0, 0, -14.0),
		Vector3(54.0, 0, -24.0), Vector3(-38.0, 0, -56.0), Vector3(36.0, 0, -64.0),
		Vector3(-72.0, 0, 58.0), Vector3(72.0, 0, 52.0), Vector3(-76.0, 0, -48.0),
		Vector3(74.0, 0, -52.0), Vector3(-18.0, 0, -76.0), Vector3(22.0, 0, -74.0),
	]
	for tp: Vector3 in tree_spots:
		var th := rng.randf_range(5.2, 8.8)
		trunks.append({ "c": tp + Vector3(0, th * 0.5, 0), "s": Vector3(0.85, th, 0.85) })
		SliceMaterials.add_collision_box(body, tp + Vector3(0, 2.0, 0), Vector3(1.0, 4.0, 1.0))
		for ci in 4:
			var cs := rng.randf_range(2.6, 4.4)
			var off := Vector3(rng.randf_range(-1.8, 1.8), th + rng.randf_range(-1.2, 1.8), rng.randf_range(-1.8, 1.8))
			var leaf := { "c": tp + off, "s": Vector3(cs, cs * 0.78, cs), "r": Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, rng.randf_range(-0.2, 0.2)) }
			if ci % 2 == 0:
				leaves_hi.append(leaf)
			else:
				leaves_lo.append(leaf)
	SliceMaterials.add_multimesh(self, tufts, &"crop_green")
	SliceMaterials.add_multimesh(self, trunks, &"tree_trunk")
	SliceMaterials.add_multimesh(self, leaves_hi, &"crop_green")
	SliceMaterials.add_multimesh(self, leaves_lo, &"crop_dark")

	# Low-poly grazing deer silhouettes across the meadow (exact 475s touch!).
	var deer_parts: Array = []
	var deer_spots := [
		[Vector3(2.5, 0.06, 46.0), 0.35],
		[Vector3(-7.0, 0.06, 42.0), -1.1],
		[Vector3(16.5, 0.06, 48.0), -1.5],
		[Vector3(21.0, 0.06, 45.0), 1.2],
		[Vector3(-19.0, 0.06, 20.0), 0.7],
		[Vector3(14.0, 0.06, 12.0), -0.6],
	]
	for ds: Array in deer_spots:
		var dp: Vector3 = ds[0]
		var dyaw: float = float(ds[1])
		var b := Basis(Vector3.UP, dyaw)
		# Body, 4 slender legs, neck, head, small antlers.
		deer_parts.append({ "c": dp + b * Vector3(0, 1.15, 0), "s": Vector3(0.46, 0.48, 1.25), "r": Vector3(0, dyaw, 0) })
		for lx_d: float in [-0.15, 0.15]:
			for lz_d: float in [-0.45, 0.45]:
				deer_parts.append({ "c": dp + b * Vector3(lx_d, 0.50, lz_d), "s": Vector3(0.10, 0.98, 0.10), "r": Vector3(0, dyaw, 0) })
		deer_parts.append({ "c": dp + b * Vector3(0, 1.56, -0.52), "s": Vector3(0.20, 0.55, 0.22), "r": Vector3(0.25, dyaw, 0) })
		deer_parts.append({ "c": dp + b * Vector3(0, 1.84, -0.68), "s": Vector3(0.22, 0.20, 0.38), "r": Vector3(0, dyaw, 0) })
		deer_parts.append({ "c": dp + b * Vector3(-0.12, 2.08, -0.60), "s": Vector3(0.05, 0.34, 0.05), "r": Vector3(-0.2, dyaw, 0.35) })
		deer_parts.append({ "c": dp + b * Vector3(0.12, 2.08, -0.60), "s": Vector3(0.05, 0.34, 0.05), "r": Vector3(-0.2, dyaw, -0.35) })
	SliceMaterials.add_multimesh(self, deer_parts, &"deer_coat")

	# 5. Swirling high-altitude bird flocks inside the 220 m shaft (exact 450s / 475s detail).
	_build_birds()

	# 6. South entry ranger bench, harvest/ranger supply pack & preserve charter plaque.
	SliceMaterials.add_box(self, body, Vector3(6.5, 0.28, hd - 11.0), Vector3(2.8, 0.52, 0.7), &"wood")
	add_child(LootContainer.create(
		"CONT-PRESERVE-413", "Preserve Ranger Pack", "crate",
		Vector3(9.0, 0.06, hd - 11.0), 0.0,
		[["ration_tin", 2], ["water_flask", 2], ["bandage_roll", 1], ["dried_strip", 2]], 5, 4))
	SliceMaterials.add_box(self, body, Vector3(-6.2, 0.62, hd - 10.5), Vector3(0.95, 1.15, 0.6), &"plate")
	add_child(ReadableNote.create(
		"NOTE-PRESERVE-413", "Ecological Preserve 413-B Charter",
		"STK-0413 — ECOLOGICAL PRESERVE 413-B (FLOOR 77)\n"
		+ "Atrium Height: 220 m  |  Artificial Daylight Cycle: 14 hrs\n\n"
		+ "Maintained as a closed biosphere reserve above the industrial\n"
		+ "stacks. Condensation collected from the 60 km steel roofs feeds\n"
		+ "the central column and irrigates the eight hanging terraces.\n"
		+ "Travellers from neighbouring stacks may rest here unmolested.",
		Vector3(-6.2, 1.24, hd - 10.4), 0.0, "plaque"))


func _build_birds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 45075
	var count := 90
	_birds_mm = MultiMesh.new()
	_birds_mm.transform_format = MultiMesh.TRANSFORM_3D
	_birds_mm.mesh = SliceMaterials.unit_box()
	_birds_mm.instance_count = count
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _birds_mm
	mmi.material_override = SliceMaterials.get_mat(&"structure")
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	var clusters := [
		{ "c": Vector3(-38.0, 56.0, -10.0), "r": 22.0, "spd": 0.24 },
		{ "c": Vector3(44.0, 96.0, -34.0), "r": 26.0, "spd": -0.20 },
		{ "c": Vector3(0.0, 148.0, 12.0), "r": 32.0, "spd": 0.18 },
	]
	for i in count:
		var cl: Dictionary = clusters[i % 3]
		_bird_data.append({
			"center": cl.c,
			"r": float(cl.r) + rng.randf_range(-9.0, 9.0),
			"y_off": rng.randf_range(-6.0, 6.0),
			"phase": rng.randf() * TAU,
			"spd": float(cl.spd) * rng.randf_range(0.85, 1.15),
		})
	_update_birds(0.0)


func _process(_delta: float) -> void:
	if _birds_mm != null:
		_update_birds(Time.get_ticks_msec() / 1000.0)


func _update_birds(t: float) -> void:
	for i in _bird_data.size():
		var b: Dictionary = _bird_data[i]
		var ang := float(b.phase) + t * float(b.spd)
		var c: Vector3 = b.center
		var r := float(b.r)
		var p := Vector3(c.x + cos(ang) * r, c.y + float(b.y_off) + sin(ang * 2.0) * 2.0, c.z + sin(ang) * r)
		var sc := Vector3(0.65, 0.14, 0.28)
		_birds_mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, -ang).scaled(sc), p))
