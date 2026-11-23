class_name PreserveSite
extends Node3D
## Ecological Preserve 413-B (faithful megastructure-scale recreation of
## video_reference_450s.jpg & 475s.jpg): a colossal 960 m x 1,000 m x 820 m tall
## pale-concrete biosphere canyon soaring nearly to Floor 77's 900 m roof.
## Features three giant overhead skylight grids, 14 stacked hanging terraces edged
## with pink grow-strips & foliage, an 820 m central luminous pale-blue waterfall
## column, a vast sunlit green meadow with 1,600+ grass tufts, 120+ forest trees,
## grazing deer herds, and 450+ wheeling high-altitude birds.

const ATRIUM_H := 820.0
const PORTAL_HALF := 16.0

var _birds_mm: MultiMesh
var _bird_data: Array = []


static func build(_stack: StackRuntime, site: Dictionary) -> Node3D:
	var r: Array = site.rect # [x0, z0, x1, z1] -> [-2960, -1700, -2000, -700]
	var p := PreserveSite.new()
	var cx := (float(r[0]) + float(r[2])) * 0.5
	var cz := (float(r[1]) + float(r[3])) * 0.5
	p.position = Vector3(cx, 0.0, cz)
	p._build(float(r[2]) - float(r[0]), float(r[3]) - float(r[1]))
	return p


func _build(W: float, D: float) -> void:
	var hw := W * 0.5 # 480 m
	var hd := D * 0.5 # 500 m
	# South portal connects directly from Hydroponic Bay 413-A north bulkhead (stack x = -2590 -> local x = -110).
	var portal_x := -110.0
	var body := StaticBody3D.new()
	body.name = "PreserveCollision"
	add_child(body)

	# 1. Vast 960 x 1,000 m sunlit meadow grass floor & 820 m tall pale-concrete canyon walls.
	SliceMaterials.add_box(self, body, Vector3(0, -0.04, 0), Vector3(W, 0.2, D), &"grass_floor")
	var wt := 6.0
	SliceMaterials.add_box(self, body, Vector3(0, ATRIUM_H * 0.5, -hd + wt * 0.5), Vector3(W, ATRIUM_H, wt), &"preserve_wall")
	SliceMaterials.add_box(self, body, Vector3(-hw + wt * 0.5, ATRIUM_H * 0.5, 0), Vector3(wt, ATRIUM_H, D - 2.0 * wt), &"preserve_wall")
	SliceMaterials.add_box(self, body, Vector3(hw - wt * 0.5, ATRIUM_H * 0.5, 0), Vector3(wt, ATRIUM_H, D - 2.0 * wt), &"preserve_wall")
	# South wall splits cleanly around the 32 m x 14 m archway connecting from Hydroponic Bay 413-A.
	var sw_l := (portal_x - PORTAL_HALF) - (-hw)
	var sw_r := hw - (portal_x + PORTAL_HALF)
	SliceMaterials.add_box(self, body, Vector3(-hw + sw_l * 0.5, ATRIUM_H * 0.5, hd - wt * 0.5), Vector3(sw_l, ATRIUM_H, wt), &"preserve_wall")
	SliceMaterials.add_box(self, body, Vector3(portal_x + PORTAL_HALF + sw_r * 0.5, ATRIUM_H * 0.5, hd - wt * 0.5), Vector3(sw_r, ATRIUM_H, wt), &"preserve_wall")
	SliceMaterials.add_box(self, body, Vector3(portal_x, 14.0 + (ATRIUM_H - 14.0) * 0.5, hd - wt * 0.5), Vector3(PORTAL_HALF * 2.0, ATRIUM_H - 14.0, wt), &"preserve_wall")
	# Monumental horizontal wall relief ribs (staggered cleanly between terrace tiers & trimmed at corners).
	var wall_ribs: Array = []
	for ry_i in range(1, 9):
		var ry := 41.0 + float(ry_i) * 92.0
		wall_ribs.append({ "c": Vector3(0, ry, -hd + wt + 3.0), "s": Vector3(W - 2.0 * wt - 1.0, 6.0, 6.0) })
		wall_ribs.append({ "c": Vector3(0, ry, hd - wt - 3.0), "s": Vector3(W - 2.0 * wt - 1.0, 6.0, 6.0) })
		wall_ribs.append({ "c": Vector3(-hw + wt + 3.0, ry, 0), "s": Vector3(6.0, 6.0, D - 2.0 * wt - 13.0) })
		wall_ribs.append({ "c": Vector3(hw - wt - 3.0, ry, 0), "s": Vector3(6.0, 6.0, D - 2.0 * wt - 13.0) })
	# Overhead ceiling frame holding 3 titanic warm-white skylight grids (cross-beams slightly offset in Y so zero overlap).
	SliceMaterials.add_box(self, null, Vector3(0, ATRIUM_H + 4.0, 0), Vector3(W + 4.0, 8.0, D + 4.0), &"preserve_wall", false)
	var sky_panels: Array = []
	var sky_beams: Array = []
	for sz: float in [-265.0, 0.0, 265.0]:
		sky_panels.append({ "c": Vector3(0, ATRIUM_H - 1.5, sz), "s": Vector3(W * 0.74, 1.5, 175.0) })
		for mx: float in [-260.0, -130.0, 0.0, 130.0, 260.0]:
			sky_beams.append({ "c": Vector3(mx, ATRIUM_H - 4.4, sz), "s": Vector3(7.0, 5.2, 178.0) })
		for mz_off: float in [-55.0, 55.0]:
			sky_beams.append({ "c": Vector3(0.0, ATRIUM_H - 4.8, sz + mz_off), "s": Vector3(W * 0.75, 4.0, 5.5) })
	SliceMaterials.add_multimesh(self, sky_panels, &"sky_panel")
	SliceMaterials.add_multimesh(self, sky_beams, &"preserve_wall")

	# 2. Fourteen stacked colossal hanging concrete terraces edged with pink grow-strips & foliage (450s & 475s).
	var terraces: Array = []
	var pink_strips: Array = []
	var terrace_greens: Array = []
	var tier_cols: Array = []
	var shelf_d := 56.0
	for ti in 14:
		var ty := 64.0 + float(ti) * 46.0
		# North hanging terrace spanning the entire 948 m canyon back wall.
		terraces.append({ "c": Vector3(0, ty, -hd + wt + shelf_d * 0.5), "s": Vector3(W - 2.0 * wt, 6.0, shelf_d) })
		pink_strips.append({ "c": Vector3(0, ty - 3.4, -hd + wt + shelf_d - 2.5), "s": Vector3(W - 2.0 * wt - 14.0, 1.4, 1.4) })
		terrace_greens.append({ "c": Vector3(0, ty + 4.5, -hd + wt + shelf_d - 6.0), "s": Vector3(W - 2.0 * wt - 18.0, 4.2, 10.0) })
		# East and West towering side terraces (exact 450s vertical canyon walls!).
		for sgn: float in [-1.0, 1.0]:
			var tx := sgn * (hw - wt - shelf_d * 0.5)
			terraces.append({ "c": Vector3(tx, ty, 0), "s": Vector3(shelf_d, 6.0, D - 2.0 * wt - 2.0 * shelf_d) })
			pink_strips.append({ "c": Vector3(sgn * (hw - wt - shelf_d + 2.5), ty - 3.4, 0), "s": Vector3(1.4, 1.4, D - 2.0 * wt - 2.0 * shelf_d - 10.0) })
			terrace_greens.append({ "c": Vector3(sgn * (hw - wt - shelf_d + 6.0), ty + 4.5, 0), "s": Vector3(10.0, 4.2, D - 2.0 * wt - 2.0 * shelf_d - 14.0) })
	# Tall slender pale columns rising all 820 m through every terrace deck (exact 475s verticals).
	for cx_col: float in [-340.0, -210.0, -85.0, 85.0, 210.0, 340.0]:
		tier_cols.append({ "c": Vector3(cx_col, ATRIUM_H * 0.5, -hd + wt + shelf_d - 3.0), "s": Vector3(7.5, ATRIUM_H, 7.5) })
	for cz_col: float in [-300.0, -150.0, 0.0, 150.0, 300.0]:
		for sgn: float in [-1.0, 1.0]:
			tier_cols.append({ "c": Vector3(sgn * (hw - wt - shelf_d + 3.0), ATRIUM_H * 0.5, cz_col), "s": Vector3(7.5, ATRIUM_H, 7.5) })
	SliceMaterials.add_multimesh(self, wall_ribs, &"preserve_wall")
	SliceMaterials.add_multimesh(self, terraces, &"preserve_wall")
	SliceMaterials.add_multimesh(self, tier_cols, &"preserve_wall")
	SliceMaterials.add_multimesh(self, pink_strips, &"grow_magenta")
	SliceMaterials.add_multimesh(self, terrace_greens, &"crop_green")

	# 3. Titanic 820 m central luminous pale-blue waterfall / light column (450s & 475s centerpiece).
	var wf_pos := Vector3(0.0, 0.0, -140.0)
	var wf_col := MeshInstance3D.new()
	wf_col.mesh = SliceMaterials.unit_cylinder(16)
	wf_col.position = wf_pos + Vector3(0, ATRIUM_H * 0.5, 0)
	wf_col.scale = Vector3(28.0, ATRIUM_H, 28.0)
	wf_col.material_override = SliceMaterials.get_mat(&"water_beam")
	wf_col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wf_col)
	# Wide flared misty spray cone pouring down into the glowing basin at meadow level.
	var wf_cone := MeshInstance3D.new()
	var cone_m := CylinderMesh.new()
	cone_m.top_radius = 14.0
	cone_m.bottom_radius = 58.0
	cone_m.height = 140.0
	cone_m.radial_segments = 18
	wf_cone.mesh = cone_m
	wf_cone.position = wf_pos + Vector3(0, 70.0, 0)
	wf_cone.material_override = SliceMaterials.get_mat(&"water_beam")
	wf_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wf_cone)
	SliceMaterials.add_box(self, body, wf_pos + Vector3(0, 0.16, 0), Vector3(124.0, 0.30, 124.0), &"water_beam")
	SliceMaterials.add_coronas(self, [
		wf_pos + Vector3(0, 24.0, 0), wf_pos + Vector3(0, 75.0, 0),
		wf_pos + Vector3(0, 180.0, 0), wf_pos + Vector3(0, 360.0, 0), wf_pos + Vector3(0, 560.0, 0),
	], 110.0, &"corona_cool")

	# Broad sunlit daylight illumination across the 1 km meadow & soaring walls.
	var sky_col := Color(1.0, 0.98, 0.90)
	for lx_l: float in [-260.0, 0.0, 260.0]:
		for lz_l: float in [-280.0, 0.0, 280.0]:
			var l := SliceMaterials.make_lamp_light(sky_col, 6.2, 420.0)
			l.position = Vector3(lx_l, 140.0, lz_l)
			l.distance_fade_begin = 900.0
			l.distance_fade_length = 250.0
			add_child(l)
	var wf_l := SliceMaterials.make_lamp_light(Color(0.78, 0.94, 1.0), 6.5, 280.0)
	wf_l.position = wf_pos + Vector3(0, 42.0, 0)
	add_child(wf_l)

	# 4. Vast meadow grass tufts (1,600+), dense forest groves (120+ tall trees), and grazing deer herds (28+).
	var rng := RandomNumberGenerator.new()
	rng.seed = 41375
	var tufts: Array = []
	for i_t in 1600:
		# Concentrate extra foreground grass tufts near the main overlook meadow + scatter across the whole 1 km plain.
		var gx: float
		var gz: float
		if i_t < 650:
			gx = rng.randf_range(-160.0, 160.0)
			gz = rng.randf_range(120.0, 420.0)
		else:
			gx = rng.randf_range(-hw + 65.0, hw - 65.0)
			gz = rng.randf_range(-hd + 75.0, hd - 35.0)
		if Vector2(gx - wf_pos.x, gz - wf_pos.z).length() < 70.0:
			continue
		tufts.append({
			"c": Vector3(gx, 0.40, gz),
			"s": Vector3(rng.randf_range(0.22, 0.45), rng.randf_range(0.45, 0.85), rng.randf_range(0.22, 0.45)),
			"r": Vector3(rng.randf_range(-0.22, 0.22), rng.randf() * TAU, rng.randf_range(-0.22, 0.22)),
		})

	var trunks: Array = []
	var leaves_hi: Array = []
	var leaves_lo: Array = []
	# Framing foreground left tree + deep perimeter forest & distant meadow tree-line (exact 475s composition).
	var tree_spots: Array[Vector3] = [
		Vector3(-12.0, 0, 355.0), Vector3(-28.0, 0, 338.0), Vector3(36.0, 0, 342.0),
		Vector3(-56.0, 0, 290.0), Vector3(64.0, 0, 280.0),
	]
	for _ti in 118:
		var tx := rng.randf_range(-hw + 68.0, hw - 68.0)
		var tz := rng.randf_range(-hd + 76.0, hd - 42.0)
		# Keep the central vista meadow corridor & waterfall basin clear so the 475s sightline stays wide open!
		if Vector2(tx - wf_pos.x, tz - wf_pos.z).length() < 95.0:
			continue
		if absf(tx) < 75.0 and tz > 80.0 and tz < 380.0:
			continue
		if absf(tx - portal_x) < 28.0 and tz > hd - 80.0:
			continue
		tree_spots.append(Vector3(tx, 0.0, tz))
	for tp: Vector3 in tree_spots:
		var th := rng.randf_range(9.5, 20.0)
		var tw := rng.randf_range(1.1, 2.0)
		trunks.append({ "c": tp + Vector3(0, th * 0.5, 0), "s": Vector3(tw, th, tw) })
		SliceMaterials.add_collision_box(body, tp + Vector3(0, 2.5, 0), Vector3(tw + 0.4, 5.0, tw + 0.4))
		for ci in 4:
			var cs := rng.randf_range(5.2, 9.8)
			var off := Vector3(rng.randf_range(-3.8, 3.8), th + rng.randf_range(-2.2, 3.6), rng.randf_range(-3.8, 3.8))
			var leaf := { "c": tp + off, "s": Vector3(cs, cs * 0.76, cs), "r": Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, rng.randf_range(-0.2, 0.2)) }
			if ci % 2 == 0:
				leaves_hi.append(leaf)
			else:
				leaves_lo.append(leaf)
	SliceMaterials.add_multimesh(self, tufts, &"crop_green")
	SliceMaterials.add_multimesh(self, trunks, &"tree_trunk")
	SliceMaterials.add_multimesh(self, leaves_hi, &"crop_green")
	SliceMaterials.add_multimesh(self, leaves_lo, &"crop_dark")

	# Grazing deer herds across the sunlit meadow (foreground 475s herd + distant meadow herds).
	var deer_parts: Array = []
	var deer_spots: Array = [
		[Vector3(2.8, 0.06, 326.0), 0.35],
		[Vector3(-9.5, 0.06, 320.0), -1.1],
		[Vector3(19.0, 0.06, 328.0), -1.5],
		[Vector3(24.5, 0.06, 324.0), 1.2],
		[Vector3(-24.0, 0.06, 285.0), 0.7],
		[Vector3(18.0, 0.06, 272.0), -0.6],
	]
	for _di in 24:
		var dx := rng.randf_range(-240.0, 240.0)
		var dz := rng.randf_range(-260.0, 310.0)
		if Vector2(dx - wf_pos.x, dz - wf_pos.z).length() < 85.0:
			continue
		deer_spots.append([Vector3(dx, 0.06, dz), rng.randf() * TAU])
	for ds: Array in deer_spots:
		var dp: Vector3 = ds[0]
		var dyaw: float = float(ds[1])
		var b := Basis(Vector3.UP, dyaw)
		deer_parts.append({ "c": dp + b * Vector3(0, 1.15, 0), "s": Vector3(0.46, 0.48, 1.25), "r": Vector3(0, dyaw, 0) })
		for lx_d: float in [-0.15, 0.15]:
			for lz_d: float in [-0.45, 0.45]:
				deer_parts.append({ "c": dp + b * Vector3(lx_d, 0.50, lz_d), "s": Vector3(0.10, 0.98, 0.10), "r": Vector3(0, dyaw, 0) })
		deer_parts.append({ "c": dp + b * Vector3(0, 1.56, -0.52), "s": Vector3(0.20, 0.55, 0.22), "r": Vector3(0.25, dyaw, 0) })
		deer_parts.append({ "c": dp + b * Vector3(0, 1.84, -0.68), "s": Vector3(0.22, 0.20, 0.38), "r": Vector3(0, dyaw, 0) })
		deer_parts.append({ "c": dp + b * Vector3(-0.12, 2.08, -0.60), "s": Vector3(0.05, 0.34, 0.05), "r": Vector3(-0.2, dyaw, 0.35) })
		deer_parts.append({ "c": dp + b * Vector3(0.12, 2.08, -0.60), "s": Vector3(0.05, 0.34, 0.05), "r": Vector3(-0.2, dyaw, -0.35) })
	SliceMaterials.add_multimesh(self, deer_parts, &"deer_coat")

	# 5. Swirling high-altitude bird flocks inside the 820 m canyon shaft (exact 450s / 475s detail).
	_build_birds()

	# 6. South entry ranger bench, supply pack & preserve charter plaque beside the archway.
	SliceMaterials.add_box(self, body, Vector3(portal_x + 8.5, 0.28, hd - 16.0), Vector3(3.2, 0.52, 0.8), &"wood")
	add_child(LootContainer.create(
		"CONT-PRESERVE-413", "Preserve Ranger Pack", "crate",
		Vector3(portal_x + 11.5, 0.06, hd - 16.0), 0.0,
		[["ration_tin", 2], ["water_flask", 2], ["bandage_roll", 1], ["dried_strip", 2]], 5, 4))
	SliceMaterials.add_box(self, body, Vector3(portal_x - 8.5, 0.62, hd - 15.5), Vector3(0.95, 1.15, 0.6), &"plate")
	add_child(ReadableNote.create(
		"NOTE-PRESERVE-413", "Ecological Preserve 413-B Charter",
		"STK-0413 — ECOLOGICAL PRESERVE 413-B (FLOOR 77)\n"
		+ "Footprint: 960 x 1,000 m  |  Atrium Height: 820 m  |  14 Hanging Terraces\n\n"
		+ "Maintained as a closed biosphere reserve spanning nearly a square\n"
		+ "kilometre beneath the upper skylight grids. Condensation from the\n"
		+ "60 km steel roofs feeds the central column and irrigates the terraces.\n"
		+ "Travellers from neighbouring stacks may rest here unmolested.",
		Vector3(portal_x - 8.5, 1.24, hd - 15.4), 0.0, "plaque"))


func _build_birds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 45075
	var count := 450
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
		{ "c": Vector3(-135.0, 120.0, 40.0), "r": 58.0, "spd": 0.22 },
		{ "c": Vector3(160.0, 210.0, -70.0), "r": 72.0, "spd": -0.18 },
		{ "c": Vector3(-40.0, 340.0, -20.0), "r": 85.0, "spd": 0.16 },
		{ "c": Vector3(95.0, 480.0, 90.0), "r": 95.0, "spd": -0.15 },
		{ "c": Vector3(-20.0, 620.0, -100.0), "r": 110.0, "spd": 0.14 },
	]
	for i in count:
		var cl: Dictionary = clusters[i % clusters.size()]
		_bird_data.append({
			"center": cl.c,
			"r": float(cl.r) + rng.randf_range(-24.0, 24.0),
			"y_off": rng.randf_range(-18.0, 18.0),
			"phase": rng.randf() * TAU,
			"spd": float(cl.spd) * rng.randf_range(0.82, 1.18),
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
		var p := Vector3(c.x + cos(ang) * r, c.y + float(b.y_off) + sin(ang * 2.0) * 4.5, c.z + sin(ang) * r)
		var sc := Vector3(1.15, 0.22, 0.45)
		_birds_mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, -ang).scaled(sc), p))
