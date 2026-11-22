class_name FoundrySite
extends Node3D
## Foundry hall on the industrial route (frame 025s): a colossal colonnaded hall
## the avenue passes straight through, with a hanging crucible pouring molten
## steel, rows of moulds, workers in silhouette and one shadowed hot light.
## Coordinates are stack-local (this node sits at the stack origin).

const H := 64.0
const HALF_W := 60.0
const PORTAL_HALF := 20.0
const PORTAL_H := 30.0


static func build(stack: StackRuntime, site: Dictionary) -> Node3D:
	var s := FoundrySite.new()
	s._build(site)
	return s


static func build_pipes(stack: StackRuntime, site: Dictionary) -> Node3D:
	var s := Node3D.new()
	var r: Array = site.rect
	var xa := float(r[0])
	var xb := float(r[2])
	var body := StaticBody3D.new()
	s.add_child(body)
	var posts: Array = []
	var lamp_heads: Array = []
	var lamp_glows: Array = []
	for side in [-1.0, 1.0]:
		var z: float = side * 25.0
		var x := xa
		while x < xb:
			var xe := minf(x + 60.0, xb)
			SliceMaterials.add_cylinder(s, Vector3(x, 9.0, z), Vector3(xe, 9.0, z), 1.2, &"structure_world", 8)
			SliceMaterials.add_cylinder(s, Vector3(x, 10.4, z + side * 2.4), Vector3(xe, 10.4, z + side * 2.4), 0.6, &"copper", 6)
			x = xe
		x = xa + 6.0
		while x < xb:
			posts.append({ "c": Vector3(x, 5.0, side * 26.2), "s": Vector3(0.4, 10.0, 0.4) })
			posts.append({ "c": Vector3(x, 7.8, side * 25.0), "s": Vector3(0.3, 0.3, 3.0) })
			SliceMaterials.add_collision_box(body, Vector3(x, 5.0, side * 26.2), Vector3(0.4, 10.0, 0.4))
			x += 24.0
		# Restrained downward work lights at pipe-run transitions so the industrial
		# avenue floor and supports read cleanly without raising global exposure.
		var lx := xa + 18.0
		while lx < xb - 10.0:
			var lp := Vector3(lx, 7.4, side * 23.2)
			lamp_heads.append({ "c": lp, "s": Vector3(0.7, 0.2, 0.5) })
			lamp_glows.append(lp + Vector3(0, -0.2, 0))
			var l := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.8, 22.0)
			l.position = lp + Vector3(0, -0.6, -side * 1.0)
			s.add_child(l)
			lx += 144.0
	# Overhead pipe-bridge gantry with diegetic route sign (ref 375s rhythm).
	var gx := xa + 24.0 if String(site.id) == "SITE-PIPES-A" else (xa + xb) * 0.5
	var gtxt := "FOUNDRY HALL  ·  0.6 KM  →" if String(site.id) == "SITE-PIPES-A" else "EAST EDGE GATE  ·  BR-077-A  →"
	for side in [-1.0, 1.0]:
		posts.append({ "c": Vector3(gx, 6.8, side * 26.6), "s": Vector3(0.9, 13.6, 0.9) })
		SliceMaterials.add_collision_box(body, Vector3(gx, 6.8, side * 26.6), Vector3(0.9, 13.6, 0.9))
	posts.append({ "c": Vector3(gx, 13.1, 0.0), "s": Vector3(1.0, 1.1, 54.0) })
	SliceMaterials.add_cylinder(s, Vector3(gx + 1.1, 11.4, -26.0), Vector3(gx + 1.1, 11.4, 26.0), 0.75, &"structure_world", 8)
	lamp_heads.append({ "c": Vector3(gx, 12.4, 0.0), "s": Vector3(1.2, 0.25, 1.2) })
	lamp_glows.append(Vector3(gx, 12.1, 0.0))
	var gl := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 2.2, 26.0)
	gl.position = Vector3(gx, 11.6, 0.0)
	s.add_child(gl)
	SliceMaterials.add_sign(s, Vector3(gx - 0.55, 13.1, 0.0), gtxt, 0.03, Color(1.0, 0.84, 0.52), -PI * 0.5)
	SliceMaterials.add_multimesh(s, posts, &"structure")
	SliceMaterials.add_multimesh(s, lamp_heads, &"lamp")
	SliceMaterials.add_coronas(s, lamp_glows, 2.4, &"corona_soft")
	return s


func _b(a: Vector3, b: Vector3, mat: StringName, body: StaticBody3D = null, shadow := true) -> MeshInstance3D:
	var mi := SliceMaterials.add_box(self, body, (a + b) * 0.5, (b - a).abs(), mat, body != null)
	if shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


func _build(site: Dictionary) -> void:
	var r: Array = site.rect
	var xa := float(r[0]) + 10.0
	var xb := float(r[2]) - 10.0
	var xm := (xa + xb) * 0.5
	var body := StaticBody3D.new()
	add_child(body)
	var metal := StaticBody3D.new()
	metal.set_meta(&"surface", "metal")
	add_child(metal)

	# Floor, roof, side walls, end walls with portals for the avenue.
	_b(Vector3(xa, -0.1, -HALF_W), Vector3(xb, 0.03, HALF_W), &"concrete_floor", null, false)
	_b(Vector3(xa - 2, H, -HALF_W - 2), Vector3(xb + 2, H + 4, HALF_W + 2), &"industrial_wall", null)
	for side in [-1.0, 1.0]:
		var zi: float = side * HALF_W
		var zo: float = side * (HALF_W + 2.0)
		_b(Vector3(xa - 2, -1, minf(zi, zo)), Vector3(xb + 2, H, maxf(zi, zo)), &"industrial_wall", body)
	for xe in [xa, xb]:
		var xo: float = xe - 2.0 if xe == xa else xe
		var xi: float = xo + 2.0
		_b(Vector3(xo, -1, -HALF_W), Vector3(xi, H, -PORTAL_HALF), &"industrial_wall", body)
		_b(Vector3(xo, -1, PORTAL_HALF), Vector3(xi, H, HALF_W), &"industrial_wall", body)
		_b(Vector3(xo, PORTAL_H, -PORTAL_HALF), Vector3(xi, H, PORTAL_HALF), &"industrial_wall", body)

	# Colonnade with braces and roof trusses (the 025s silhouette).
	var x := xa + 15.0
	while x < xb - 5.0:
		for side in [-1.0, 1.0]:
			var z: float = side * 42.0
			_b(Vector3(x - 2.5, 0, z - 2.5), Vector3(x + 2.5, H - 4.0, z + 2.5), &"structure", body)
			var brace := SliceMaterials.add_box(self, null, Vector3(x, H - 12.0, side * 33.0), Vector3(1.5, 22.0, 1.5), &"structure", false, Vector3(side * 0.75, 0, 0))
			brace.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		_b(Vector3(x - 1.5, H - 6.0, -HALF_W), Vector3(x + 1.5, H, HALF_W), &"structure")
		x += 30.0
	for side in [-1.0, 1.0]:
		_b(Vector3(xa, H - 9.0, side * 42.0 - 1.5), Vector3(xb, H - 5.0, side * 42.0 + 1.5), &"structure")

	# Furnace mouths glowing along both side walls.
	var mouths: Array = []
	x = xa + 30.0
	while x < xb - 20.0:
		for side in [-1.0, 1.0]:
			var zf: float = side * (HALF_W - 0.4)
			mouths.append({ "c": Vector3(x, 3.0, zf), "s": Vector3(6.0, 4.0, 0.9) })
			var ml := SliceMaterials.make_lamp_light(Color(1.0, 0.45, 0.12), 4.0, 34.0)
			ml.position = Vector3(x, 3.0, zf - side * 3.0)
			add_child(ml)
		x += 60.0
	SliceMaterials.add_multimesh(self, mouths, &"molten_slow")

	# Moulds row (background blocks of 025s) and machinery on the other side.
	var moulds: Array = []
	var mould_tops: Array = []
	x = xa + 25.0
	while x < xb - 20.0:
		_b(Vector3(x - 2.0, -0.5, 24.0), Vector3(x + 2.0, 5.0, 29.0), &"structure", metal)
		mould_tops.append({ "c": Vector3(x, 5.03, 26.5), "s": Vector3(3.0, 0.08, 4.0) })
		x += 10.0
	x = xa + 30.0
	while x < xb - 25.0:
		_b(Vector3(x - 4.0, -0.5, -34.0), Vector3(x + 4.0, 9.0 + fmod(x, 7.0), -22.0), &"container_grey", body)
		x += 22.0
	SliceMaterials.add_multimesh(self, mould_tops, &"molten_slow")

	# The crucible: tilted vessel on a cable, pouring into a mould.
	var cx := xm
	var cz := 20.0
	var vessel := SliceMaterials.add_box(self, null, Vector3(cx, 30.0, cz), Vector3(9.0, 9.0, 9.0), &"structure", false, Vector3(0, 0, deg_to_rad(-28.0)))
	vessel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	SliceMaterials.add_box(self, null, Vector3(cx + 2.1, 33.9, cz), Vector3(7.0, 0.3, 7.0), &"molten", false, Vector3(0, 0, deg_to_rad(-28.0)))
	_b(Vector3(cx - 0.3, 35.0, cz - 0.3), Vector3(cx + 0.3, H - 6.0, cz + 0.3), &"structure")
	_b(Vector3(cx - 3.0, H - 9.0, cz - 3.0), Vector3(cx + 3.0, H - 6.0, cz + 3.0), &"structure")
	SliceMaterials.add_cylinder(self, Vector3(cx + 6.2, 31.0, cz), Vector3(cx + 6.2, 4.6, cz), 0.45, &"molten", 6)
	_b(Vector3(cx + 3.7, -0.5, cz - 2.75), Vector3(cx + 8.7, 4.6, cz + 2.75), &"structure", metal)
	SliceMaterials.add_box(self, null, Vector3(cx + 6.2, 4.65, cz), Vector3(4.6, 0.1, 5.0), &"molten", false)
	SliceMaterials.add_coronas(self, [Vector3(cx + 6.2, 6.0, cz), Vector3(cx + 6.2, 18.0, cz), Vector3(cx + 3.5, 34.0, cz)], 9.0, &"corona_molten")
	var hot := OmniLight3D.new()
	hot.position = Vector3(cx + 6.2, 7.0, cz - 2.0)
	hot.light_color = Color(1.0, 0.5, 0.15)
	hot.light_energy = 16.0
	hot.omni_range = 120.0
	hot.omni_attenuation = 1.0
	hot.shadow_enabled = true
	hot.shadow_bias = 0.1
	hot.light_volumetric_fog_energy = 2.0
	add_child(hot)
	_sparks(Vector3(cx + 6.2, 4.8, cz))
	# Warm bounce from the molten light filling the hall (025s reads as a bright
	# orange haze, not a black void). No shadows, very wide.
	var bounce := OmniLight3D.new()
	bounce.position = Vector3(xm, H * 0.6, 0.0)
	bounce.light_color = Color(1.0, 0.55, 0.25)
	bounce.light_energy = 2.2
	bounce.omni_range = 230.0
	bounce.omni_attenuation = 0.6
	bounce.light_volumetric_fog_energy = 0.6
	add_child(bounce)

	# Hanging work lamps along the hall.
	var heads: Array = []
	x = xa + 20.0
	while x < xb - 10.0:
		for side in [-1.0, 1.0]:
			var p := Vector3(x, 24.0, side * 30.0)
			_b(Vector3(x - 0.05, p.y + 0.2, p.z - 0.05), Vector3(x + 0.05, H - 6.0, p.z + 0.05), &"structure", null, false)
			SliceMaterials.add_box(self, null, p, Vector3(0.8, 0.4, 0.8), &"lamp", false)
			heads.append(p + Vector3(0, -0.3, 0))
			var l := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 2.2, 30.0)
			l.position = p + Vector3(0, -0.8, 0)
			add_child(l)
		x += 40.0
	# Localized portal bulkhead lights at both avenue portals (xa, xb) so the
	# massive openings and floor threshold remain readable inside deep shadow.
	for xe in [xa, xb]:
		var dir_in := 1.0 if xe == xa else -1.0
		for side in [-1.0, 1.0]:
			for io in [-1.0, 1.0]:
				var px: float = xe + (io * 1.4 if xe == xb else (io * 1.4 - 1.0))
				var pz: float = side * (PORTAL_HALF + 0.4)
				SliceMaterials.add_box(self, null, Vector3(px, 5.6, pz), Vector3(0.35, 0.9, 0.5), &"lamp", false)
				heads.append(Vector3(px + io * 0.25, 5.6, pz - side * 0.25))
			var pl := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 2.4, 28.0)
			pl.position = Vector3(xe + dir_in * 3.0, 5.4, side * (PORTAL_HALF - 2.0))
			add_child(pl)
		var ol := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 2.2, 30.0)
		ol.position = Vector3(xe - dir_in * 4.0, 7.0, 0.0)
		add_child(ol)
		SliceMaterials.add_box(self, null, Vector3(xe + dir_in * 0.5, PORTAL_H - 0.5, 0.0), Vector3(0.6, 0.4, 4.0), &"lamp", false)
		heads.append(Vector3(xe + dir_in * 0.8, PORTAL_H - 0.8, 0.0))
	# Restrained floor-side work bollards lining the central avenue corridor
	# plus stacked ingot/supply pallets tucked beside the machinery bay.
	var bollards: Array = []
	var b_caps: Array = []
	x = xa + 45.0
	while x < xb - 35.0:
		for side in [-1.0, 1.0]:
			bollards.append({ "c": Vector3(x, 0.6, side * 17.5), "s": Vector3(0.28, 1.2, 0.28) })
			b_caps.append({ "c": Vector3(x, 1.28, side * 17.5), "s": Vector3(0.22, 0.14, 0.22) })
			heads.append(Vector3(x, 1.32, side * 17.5))
			var bl := SliceMaterials.make_lamp_light(Color(1.0, 0.58, 0.22), 0.95, 14.0)
			bl.position = Vector3(x, 1.55, side * 16.5)
			add_child(bl)
		x += 65.0
	SliceMaterials.add_multimesh(self, bollards, &"structure")
	SliceMaterials.add_multimesh(self, b_caps, &"lamp")
	SliceMaterials.add_coronas(self, heads, 2.6, &"corona_soft")
	# Small industrial crate stacks tucked outside the corridor along the north machinery row.
	var crates: Array = []
	x = xa + 52.0
	while x < xb - 45.0:
		crates.append({ "c": Vector3(x, 0.55, -20.0), "s": Vector3(1.6, 1.1, 1.4) })
		crates.append({ "c": Vector3(x + 1.8, 0.4, -20.2), "s": Vector3(1.1, 0.8, 1.1) })
		x += 58.0
	SliceMaterials.add_multimesh(self, crates, &"container_rust")
	_build_service_bypass(xa, xb, xm, body, metal)

	# Workers: silhouettes against the molten light.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(site.id))
	var statics: Array = []
	for i in 12:
		statics.append({ "p": Vector3(cx + rng.randf_range(-40.0, 40.0), 0.0, rng.randf_range(12.0, 22.0)), "yaw": rng.randf_range(-0.6, 0.6) + PI })
	var walkers: Array = []
	for i in 10:
		var z := rng.randf_range(-18.0, 18.0)
		walkers.append({ "a": Vector3(xa + 10.0, 0.0, z), "b": Vector3(xb - 10.0, 0.0, z + rng.randf_range(-4.0, 4.0)) })
	var crowd := Crowd.new()
	add_child(crowd)
	crowd.setup(statics, walkers, rng.randi(), 0.55, 300.0, true)

	# Roar of the pour, positioned at the crucible.
	if ResourceLoader.exists("res://audio/foundry_roar.wav"):
		var roar := AudioStreamPlayer3D.new()
		var s: AudioStreamWAV = (load("res://audio/foundry_roar.wav") as AudioStreamWAV).duplicate()
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = int(s.get_length() * s.mix_rate)
		roar.stream = s
		roar.position = Vector3(cx + 6.2, 6.0, cz)
		roar.unit_size = 28.0
		roar.max_distance = 700.0
		roar.bus = &"World"
		roar.autoplay = true
		add_child(roar)
	if ResourceLoader.exists("res://audio/machinery.wav"):
		var mach := AudioStreamPlayer3D.new()
		var s2: AudioStreamWAV = (load("res://audio/machinery.wav") as AudioStreamWAV).duplicate()
		s2.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s2.loop_end = int(s2.get_length() * s2.mix_rate)
		mach.stream = s2
		mach.position = Vector3(xm - 60.0, 5.0, -28.0)
		mach.unit_size = 25.0
		mach.max_distance = 600.0
		mach.bus = &"World"
		mach.autoplay = true
		add_child(mach)


## Phase 3 route decision (brief §9): a longer, sheltered North Service Bypass
## running outside the foundry's north wall (z = -68.5..-62.2), offering relief
## from the direct foundry floor's radiant heat plus a maintenance loot locker.
func _build_service_bypass(xa: float, xb: float, xm: float, body: StaticBody3D, metal: StaticBody3D) -> void:
	var x0 := xa - 6.0
	var x1 := xb + 6.0
	var z_in := -62.2
	var z_out := -68.5
	var h := 3.6
	# Sheltered concrete walkway and overhead steel roof slab.
	_b(Vector3(x0, -0.1, z_out), Vector3(x1, 0.03, z_in), &"concrete_floor", null, false)
	_b(Vector3(x0, h, z_out - 0.3), Vector3(x1, h + 0.35, z_in), &"structure_world", body, false)
	# Outer north wall with periodic ventilation slits looking out over the city.
	var x := x0
	while x < x1 - 0.5:
		var seg_end := minf(x + 18.0, x1)
		_b(Vector3(x, 0.0, z_out - 0.3), Vector3(seg_end, 1.8, z_out), &"plate", metal, false)
		_b(Vector3(x, 2.8, z_out - 0.3), Vector3(seg_end, h, z_out), &"plate", null, false)
		_b(Vector3(x, 1.8, z_out - 0.3), Vector3(minf(x + 3.0, seg_end), 2.8, z_out), &"plate", metal, false)
		x = seg_end
	# Restrained warm bulkhead lamps along the bypass gallery.
	var bheads: Array = []
	var bglows: Array = []
	x = x0 + 14.0
	while x < x1 - 10.0:
		var lp := Vector3(x, h - 0.2, (z_in + z_out) * 0.5)
		bheads.append({ "c": lp, "s": Vector3(0.45, 0.14, 0.45) })
		bglows.append(lp + Vector3(0, -0.15, 0))
		var bl := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.25, 16.0)
		bl.position = lp + Vector3(0, -0.4, 0)
		add_child(bl)
		x += 48.0
	SliceMaterials.add_multimesh(self, bheads, &"lamp")
	SliceMaterials.add_coronas(self, bglows, 1.5, &"corona_soft")
	# Diegetic junction sign at west approach presenting the route choice.
	_b(Vector3(x0 - 4.0, 0.0, -23.5), Vector3(x0 - 3.7, 3.6, -23.2), &"structure", body, false)
	_b(Vector3(x0 - 4.05, 2.5, -25.8), Vector3(x0 - 3.65, 3.5, -21.0), &"structure", null, false)
	SliceMaterials.add_sign(self, Vector3(x0 - 4.1, 3.0, -23.4),
		"← NORTH SERVICE BYPASS (SHELTERED)\nFOUNDRY FLOOR (HOT / DIRECT) →",
		0.0085, Color(1.0, 0.86, 0.56), -PI * 0.5)
	var jl := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.1, 10.0)
	jl.position = Vector3(x0 - 4.6, 3.3, -23.4)
	add_child(jl)
	# Maintenance loot locker midway along the sheltered bypass.
	add_child(LootContainer.create(
		"CONT-FOUNDRY-BYPASS", "Maintenance Locker", "locker",
		Vector3(xm, 0.03, z_out + 0.45), 0.0,
		[["dried_strip", 1], ["water_flask", 1], ["bandage_roll", 2], ["brass_coil", 2]], 5, 4))
	add_child(ReadableNote.create(
		"NOTE-FOUNDRY-BYPASS", "Foundry Shift Log",
		"FOUNDRY HALL — NORTH SERVICE GALLERY\n\n"
		+ "Crucible pour #4 is running nonstop on the main avenue floor.\n"
		+ "Radiant heat drains water fast if you walk straight past the moulds.\n"
		+ "Crew are advised to take this north gallery and restock at the mid-wall locker.",
		Vector3(x0 + 4.0, 1.45, z_out + 0.06), 0.0, "plaque"))


func _sparks(p: Vector3) -> void:
	var sp := GPUParticles3D.new()
	sp.position = p
	sp.amount = 160
	sp.lifetime = 1.6
	sp.visibility_aabb = AABB(Vector3(-15, -2, -15), Vector3(30, 20, 30))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 70.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 7.0
	pm.gravity = Vector3(0, -9.8, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	sp.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = Color(1.0, 0.7, 0.3)
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	sp.draw_pass_1 = q
	add_child(sp)
