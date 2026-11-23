class_name StackRuntime
extends WorldAnchor
## One stack: shell (walls, slab, ceiling, pillars), city visuals for the whole
## floor (instanced, LOD by visibility range), and near-only streamed detail
## (building collision + practical lights) around the player.

const LOAD_RADIUS := 380.0
const UNLOAD_RADIUS := 560.0
const SMALL_BUILDING_HEIGHT := 40.0
const SMALL_VIS_END := 4200.0

var def: Dictionary
var layouts: Dictionary = {}   # Vector2i -> Array[building]
var lamps: Dictionary = {}     # Vector2i -> Array[Vector3]
var loaded: Dictionary = {}    # Vector2i -> Node3D
var building_count := 0


static func build(stack_def: Dictionary) -> StackRuntime:
	var s := StackRuntime.new()
	s.def = stack_def
	s.name = stack_def.id
	s.lx = float(stack_def.origin[0])
	s.ly = float(stack_def.origin[1])
	s.lz = float(stack_def.origin[2])
	s._build_shell()
	s._build_city()
	s._build_sites()
	return s


func size_x() -> float: return float(def.size[0])
func size_z() -> float: return float(def.size[2])
func floor_height() -> float: return float(def.size[1])


func contains_local(p: Vector3) -> bool:
	return absf(p.x) <= size_x() * 0.5 + float(def.wall_thickness) \
		and absf(p.z) <= size_z() * 0.5 + float(def.wall_thickness) \
		and p.y > -float(def.below_depth) and p.y < floor_height() + float(def.above_height)


func _build_shell() -> void:
	var w := size_x()
	var d := size_z()
	var h := floor_height()
	var t := float(def.wall_thickness)
	var slab := float(def.slab_thickness)
	var y0 := -float(def.below_depth)
	var y1 := h + float(def.above_height)
	var shell := Node3D.new()
	shell.name = "Shell"
	add_child(shell)
	var body := StaticBody3D.new()
	body.name = "ShellCollision"
	shell.add_child(body)

	# Floor collision (visual floor = ground tiles below).
	SliceMaterials.add_collision_box(body, Vector3(0, -slab * 0.5, 0), Vector3(w, slab, d))
	# Ceiling slab with lamp grid on its underside.
	SliceMaterials.add_box(shell, body, Vector3(0, h + slab * 0.5, 0), Vector3(w, slab, d), &"ceiling")

	# Walls sit outside the w x d footprint. X walls cover the corners; Z walls
	# fit between them, so no faces overlap or z-fight.
	var gate: Dictionary = def.opening
	for side: String in ["+x", "-x", "+z", "-z"]:
		var along_x := side.ends_with("z")
		var sgn := 1.0 if side.begins_with("+") else -1.0
		var normal_c := sgn * ((d if along_x else w) * 0.5 + t * 0.5)
		var span := w if along_x else d + 2.0 * t
		if gate.side == side:
			var ow := float(gate.width)
			var oh := float(gate.height)
			var seg := (span - ow) * 0.5
			var seg_c := ow * 0.5 + seg * 0.5
			_wall_piece(shell, body, along_x, normal_c, -seg_c, seg, y0, y1, t, wall_mat())
			_wall_piece(shell, body, along_x, normal_c, seg_c, seg, y0, y1, t, wall_mat())
			_wall_piece(shell, body, along_x, normal_c, 0.0, ow, oh, y1, t, wall_mat())
			_wall_piece(shell, body, along_x, normal_c, 0.0, ow, y0, -slab, t, wall_mat())
			_wall_piece(shell, body, along_x, normal_c, 0.0, ow, -slab, 0.0, t, &"ground")
			_build_exterior_relief(shell, along_x, sgn, normal_c, span, ow, oh, y0, y1, t)
		else:
			_wall_piece(shell, body, along_x, normal_c, 0.0, span, y0, y1, t, wall_mat())

	# Structural pillars, floor to ceiling (skip sites that supply their own architecture, e.g. Preserve/Hydroponics).
	var ps := float(def.pillars.size)
	var no_pillar_rects: Array[Rect2] = []
	for s: Dictionary in def.get("sites", []):
		if bool(s.get("no_pillars", false)):
			var r: Array = s.rect
			no_pillar_rects.append(Rect2(float(r[0]) - ps, float(r[1]) - ps, (float(r[2]) - float(r[0])) + ps * 2.0, (float(r[3]) - float(r[1])) + ps * 2.0))
	for p: Vector2 in CityLayout.pillar_positions(def):
		var blocked := false
		for nr: Rect2 in no_pillar_rects:
			if nr.has_point(p):
				blocked = true
				break
		if not blocked:
			SliceMaterials.add_box(shell, body, Vector3(p.x, h * 0.5, p.y), Vector3(ps, h, ps), &"structure")


func _wall_piece(parent: Node3D, body: StaticBody3D, along_x: bool, normal_c: float, u_c: float, u_len: float, ya: float, yb: float, t: float, mat: StringName) -> void:
	var c: Vector3
	var s: Vector3
	if along_x:
		c = Vector3(u_c, (ya + yb) * 0.5, normal_c)
		s = Vector3(u_len, yb - ya, t)
	else:
		c = Vector3(normal_c, (ya + yb) * 0.5, u_c)
		s = Vector3(t, yb - ya, u_len)
	SliceMaterials.add_box(parent, body, c, s, mat)


## Monumental 3D exterior architectural relief on the opposing Twin-Stack walls
## (STK-0412 +X face and STK-0413 -X face): heavy vertical structural buttresses,
## 900 m horizontal mechanical service ledges, and portal flank pylons. Preserves
## the exact 3 km gap & gate geometry while replacing flat planes with 3D cliff depth.
func _build_exterior_relief(parent: Node3D, along_x: bool, sgn: float, normal_c: float, span: float, ow: float, oh: float, y0: float, y1: float, t: float) -> void:
	if along_x:
		return
	var outer_x := normal_c + sgn * (t * 0.5)
	var steel: Array = []
	var beacons: Array = []
	var h_total := y1 - y0
	var cy := (y0 + y1) * 0.5
	# Twin monumental portal flank buttresses framing the 600 x 420 m gate opening.
	for ps: float in [-1.0, 1.0]:
		var pz := ps * (ow * 0.5 + 22.0)
		steel.append({ "c": Vector3(outer_x + sgn * 16.0, cy, pz), "s": Vector3(32.0, h_total, 36.0) })
		beacons.append({ "c": Vector3(outer_x + sgn * 33.0, oh + 36.0, pz), "s": Vector3(3.2, 3.2, 3.2) })
	# Heavy exterior lintel header & upper structural brow truss spanning the 600 m opening (recessed inside buttress outer faces).
	steel.append({ "c": Vector3(outer_x + sgn * 16.0, oh + 18.0, 0.0), "s": Vector3(28.0, 32.0, ow + 74.0) })
	steel.append({ "c": Vector3(outer_x + sgn * 12.0, oh + 220.0, 0.0), "s": Vector3(20.0, 26.0, ow + 74.0) })
	# Repeating vertical structural buttress fins across the 6 km opposing cliff face.
	var half_span := span * 0.5 - 120.0
	var bz := -half_span
	while bz <= half_span:
		if absf(bz) > ow * 0.5 + 160.0:
			steel.append({ "c": Vector3(outer_x + sgn * 13.0, cy, bz), "s": Vector3(26.0, h_total, 24.0) })
			beacons.append({ "c": Vector3(outer_x + sgn * 27.0, 420.0, bz), "s": Vector3(2.8, 2.8, 2.8) })
		bz += 520.0
	# Horizontal 900 m mechanical/ventilation service ledges matching the facade floor bands (offset +1.5 m from vertical fin back-plane).
	var ly := -4500.0
	while ly <= 5400.0:
		var in_gate := ly >= -60.0 and ly <= oh + 40.0
		if in_gate:
			var wing_len := half_span - (ow * 0.5 + 40.0)
			var wing_c := ow * 0.5 + 40.0 + wing_len * 0.5
			for ps: float in [-1.0, 1.0]:
				steel.append({ "c": Vector3(outer_x + sgn * 11.5, ly, ps * wing_c), "s": Vector3(20.0, 36.0, wing_len) })
		else:
			steel.append({ "c": Vector3(outer_x + sgn * 11.5, ly, 0.0), "s": Vector3(20.0, 36.0, span - 80.0) })
		ly += 900.0
	SliceMaterials.add_multimesh(parent, steel, &"structure")
	SliceMaterials.add_multimesh(parent, beacons, &"beacon_red")


func _build_city() -> void:
	var city := Node3D.new()
	city.name = "City"
	add_child(city)
	var slab := float(def.slab_thickness)
	var n := CityLayout.chunk_counts(def)
	var tiles: Array = []
	for i in n.x:
		for j in n.y:
			var key := Vector2i(i, j)
			var o := CityLayout.chunk_origin(def, key)
			var c := CityLayout.CHUNK
			tiles.append({ "c": Vector3(o.x + c * 0.5, -slab * 0.5, o.y + c * 0.5), "s": Vector3(c, slab, c), "seed": 0.0 })
			var items := CityLayout.generate_chunk(def, key)
			layouts[key] = items
			building_count += items.size()
			var small: Array = []
			var big: Array = []
			for b: Dictionary in items:
				if (b.c as Vector3).y + (b.s as Vector3).y * 0.5 < SMALL_BUILDING_HEIGHT:
					small.append(b)
				else:
					big.append(b)
			var chunk := Node3D.new()
			chunk.name = "Chunk_%d_%d" % [i, j]
			city.add_child(chunk)
			# Same buildings at every distance: small ones dither-fade into fog
			# before culling, large silhouettes never disappear.
			if not small.is_empty():
				SliceMaterials.add_multimesh(chunk, small, building_small_mat(), SMALL_VIS_END)
			if not big.is_empty():
				SliceMaterials.add_multimesh(chunk, big, building_mat())
	SliceMaterials.add_multimesh(city, tiles, &"ground")

	# Avenue lamps toward the edge gate.
	var poles: Array = []
	var heads: Array = []
	for p: Vector3 in CityLayout.avenue_lamps(def):
		poles.append({ "c": p + Vector3(0, 3.0, 0), "s": Vector3(0.25, 6.0, 0.25) })
		heads.append({ "c": p + Vector3(0, 6.1, 0), "s": Vector3(0.7, 0.3, 0.7) })
		var key := CityLayout.chunk_key_for(def, p.x, p.z)
		if not lamps.has(key):
			lamps[key] = []
		lamps[key].append(p)
	# Per-pixel shader dither-fade handles distant poles; omit MultiMesh visibility_range_end
	# because a 6 km MultiMesh's AABB center is at x=0 and would cull poles near stack edges.
	SliceMaterials.add_multimesh(city, poles, &"structure_fade_far")
	SliceMaterials.add_multimesh(city, heads, &"lamp")
	var glow: Array = []
	for hd: Dictionary in heads:
		glow.append((hd.c as Vector3) + Vector3(0, -0.2, 0))
	SliceMaterials.add_coronas(city, glow, 2.2)


## Loads/unloads near detail around the player. `player_logical` is [x, y, z].
func update_streaming(player_logical: PackedFloat64Array) -> void:
	var p := logical_to_local(player_logical)
	var vertical_ok := p.y > -300.0 and p.y < floor_height() + 300.0
	for key: Vector2i in layouts:
		var o := CityLayout.chunk_origin(def, key)
		var r := Rect2(o, Vector2(CityLayout.CHUNK, CityLayout.CHUNK))
		var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
		var dz := maxf(maxf(r.position.y - p.z, 0.0), p.z - r.end.y)
		var dist := sqrt(dx * dx + dz * dz)
		var is_loaded := loaded.has(key)
		if vertical_ok and dist < LOAD_RADIUS and not is_loaded:
			_load_chunk(key)
		elif (not vertical_ok or dist > UNLOAD_RADIUS) and is_loaded:
			loaded[key].queue_free()
			loaded.erase(key)


func _load_chunk(key: Vector2i) -> void:
	var root := Node3D.new()
	root.name = "Near_%d_%d" % [key.x, key.y]
	var body := StaticBody3D.new()
	root.add_child(body)
	for b: Dictionary in layouts[key]:
		SliceMaterials.add_collision_box(body, b.c, b.s)
	for lp: Vector3 in lamps.get(key, []):
		SliceMaterials.add_collision_box(body, lp + Vector3(0, 3.0, 0), Vector3(0.25, 6.0, 0.25))
		var light := SliceMaterials.make_lamp_light()
		light.position = lp + Vector3(0, 5.7, 0)
		root.add_child(light)
	add_child(root)
	loaded[key] = root


func is_cool() -> bool:
	return def.get("palette", "warm") == "cool"


func building_mat() -> StringName:
	return &"building_cool" if is_cool() else &"building"


func building_small_mat() -> StringName:
	return &"building_small_cool" if is_cool() else &"building_small"


func wall_mat() -> StringName:
	return &"stack_wall_cool" if is_cool() else &"stack_wall"


## Authored places (home, market, foundry, gate plazas). Each builder returns
## a Node3D in stack-local space; see world/sites/.
func _build_sites() -> void:
	for site: Dictionary in def.get("sites", []):
		var node: Node3D = null
		match String(site.kind):
			"home": node = HomeSite.build(self, site)
			"market": node = MarketSite.build(self, site)
			"highway": node = HighwaySite.build(self, site)
			"foundry": node = FoundrySite.build(self, site)
			"gate_departure", "gate_arrival": node = GateSite.build(self, site)
			"pipes": node = FoundrySite.build_pipes(self, site)
			"hydroponics": node = HydroponicSite.build(self, site)
			"preserve": node = PreserveSite.build(self, site)
			"glass_terrace": node = GlassTerraceSite.build(self, site)
			_: push_error("Unknown site kind %s" % site.kind)
		if node != null:
			node.name = site.id
			add_child(node)
