class_name CityLayout
extends RefCounted
## Deterministic floor layout. The same function feeds near collision, near
## visuals and far visuals, so every LOD shows the same buildings in the same
## place. All positions are stack-local metres (floor top = y 0).

const CHUNK := 500.0
const BLOCK := 62.5
const STREET := 14.0
const STOREY := 3.5
const AVENUE_HALF := 24.0
const EDGE_MARGIN := 24.0
const PILLAR_CLEAR := 14.0
const GATE_PLAZA_RADIUS := 260.0
const INDUSTRIAL_RADIUS := 1100.0
const LAMP_SPACING := 36.0
const LAMP_OFFSET := 28.0

enum Zone { URBAN, RESIDENTIAL, INDUSTRIAL, ABANDONED, UNBUILT }


static func chunk_counts(def: Dictionary) -> Vector2i:
	return Vector2i(int(float(def.size[0]) / CHUNK), int(float(def.size[2]) / CHUNK))


static func chunk_origin(def: Dictionary, key: Vector2i) -> Vector2:
	return Vector2(-float(def.size[0]) * 0.5 + key.x * CHUNK, -float(def.size[2]) * 0.5 + key.y * CHUNK)


static func chunk_key_for(def: Dictionary, x: float, z: float) -> Vector2i:
	var n := chunk_counts(def)
	return Vector2i(
		clampi(int(floor((x + float(def.size[0]) * 0.5) / CHUNK)), 0, n.x - 1),
		clampi(int(floor((z + float(def.size[2]) * 0.5) / CHUNK)), 0, n.y - 1))


## Point on the floor at the centre of the edge gate (stack-local XZ).
static func gate_point(def: Dictionary) -> Vector2:
	var side: String = def.opening.side
	var hw := float(def.size[0]) * 0.5
	var hd := float(def.size[2]) * 0.5
	match side:
		"+x": return Vector2(hw, 0.0)
		"-x": return Vector2(-hw, 0.0)
		"+z": return Vector2(0.0, hd)
		_: return Vector2(0.0, -hd)


static func pillar_positions(def: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var sp := float(def.pillars.spacing)
	var hw := float(def.size[0]) * 0.5
	var hd := float(def.size[2]) * 0.5
	var x := -hw + sp * 0.5
	while x < hw:
		var z := -hd + sp * 0.5
		while z < hd:
			out.append(Vector2(x, z))
			z += sp
		x += sp
	return out


## Authored sites reserve ground: rect = [x0, z0, x1, z1] in stack-local metres.
static func site_rects(def: Dictionary, only_no_lamps := false) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for s: Dictionary in def.get("sites", []):
		if only_no_lamps and not s.get("no_lamps", false):
			continue
		if s.has("level"):
			continue   # built on another level of the stack
		var r: Array = s.rect
		out.append(Rect2(float(r[0]), float(r[1]), float(r[2]) - float(r[0]), float(r[3]) - float(r[1])))
	return out


static func avenue_lamps(def: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var hw := float(def.size[0]) * 0.5
	var blocked := site_rects(def, true)
	var x := -hw + 30.0
	while x < hw - 10.0:
		for z in [-LAMP_OFFSET, LAMP_OFFSET]:
			var p := Vector2(x, z)
			var ok := true
			for r in blocked:
				if r.has_point(p):
					ok = false
					break
			if ok:
				out.append(Vector3(x, 0.0, z))
		x += LAMP_SPACING
	return out


## True when stack-local point `p` lies in a district: a circle (center + radius) or
## a band / rectangle ("rect": [x0, z0, x1, z1]).
static func district_has(district: Dictionary, p: Vector2) -> bool:
	if district.has("rect"):
		var r: Array = district.rect
		return p.x >= float(r[0]) and p.x < float(r[2]) and p.y >= float(r[1]) and p.y < float(r[3])
	return p.distance_to(Vector2(float(district.center[0]), float(district.center[1]))) < float(district.radius)


static func zone_at(def: Dictionary, p: Vector2) -> Zone:
	for district: Dictionary in def.districts:
		if district_has(district, p):
			match String(district.kind):
				"residential": return Zone.RESIDENTIAL
				"industrial": return Zone.INDUSTRIAL
				"abandoned": return Zone.ABANDONED
				"unbuilt": return Zone.UNBUILT
	if p.distance_to(gate_point(def)) < INDUSTRIAL_RADIUS:
		return Zone.INDUSTRIAL
	return Zone.URBAN


## Street lamp posts of abandoned districts as { p, lit } (reference 577s: one warm
## head every hundred metres or so). The power dies with distance: lamps thin out over
## the first stretch and past `LAMPS_DEAD_AFTER` metres every post stands dark.
const LAMPS_DEAD_AFTER := 520.0

static func barren_lamps(def: Dictionary) -> Array:
	var out: Array = []
	var hw := float(def.size[0]) * 0.5
	var hd := float(def.size[2]) * 0.5
	var sp := float(def.pillars.spacing)
	var clear := float(def.pillars.size) * 0.5 + 4.0
	for district: Dictionary in def.districts:
		if district.kind != "abandoned" or not district.has("rect"):
			continue
		var r: Array = district.rect
		var i := 1
		while -hw + float(i) * BLOCK < hw - 1.0:
			var xs := -hw + float(i) * BLOCK
			var z := float(r[1]) + 30.0
			var k := 0
			while z < float(r[3]) - 10.0:
				var h := fposmod(sin(float(i) * 127.1 + float(k) * 311.7) * 43758.5453, 1.0)
				var p := Vector3(xs + (5.6 if i % 2 == 0 else -5.6), 0.0, z)
				var px := roundf((p.x + hw - sp * 0.5) / sp) * sp - hw + sp * 0.5
				var pz := roundf((p.z + hd - sp * 0.5) / sp) * sp - hd + sp * 0.5
				if h < 0.5 and p.x > float(r[0]) + 30.0 and p.x < float(r[2]) - 30.0 \
						and (absf(p.x - px) > clear or absf(p.z - pz) > clear):
					var into := (z - float(r[1])) / LAMPS_DEAD_AFTER
					out.append({ "p": p, "lit": into < 1.0 and h < 0.42 * (1.0 - into * into) })
				z += 96.0
				k += 1
			i += 1
	return out


## Bare steel of the never-built extremity for one chunk: { cols, beams, decks },
## each an Array of { c, s }. Own RNG, so it never disturbs the building layout.
static func generate_frames(def: Dictionary, key: Vector2i) -> Dictionary:
	var cols: Array = []
	var beams: Array = []
	var decks: Array = []
	var org := chunk_origin(def, key)
	var has_unbuilt := false
	var frames_from := -INF
	var camp_pts: Array[Vector2] = []
	for district: Dictionary in def.districts:
		if district.kind == "unbuilt":
			has_unbuilt = true
			# An empty plain of bare plates lies between the last buildings and the first steel.
			frames_from = float(district.get("frames_from", district.rect[1]))
			# Blocks holding an authored squatter frame (UnbuiltZone) get no random steel.
			for camp: Dictionary in district.get("camps", []):
				camp_pts.append(Vector2(float(camp.x) + 1.0, float(camp.z) + 1.0))
	if not has_unbuilt:
		return { "cols": cols, "beams": beams, "decks": decks }
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:F:%d:%d" % [def.id, key.x, key.y])
	var hd := float(def.size[2]) * 0.5
	var n := int(CHUNK / BLOCK)
	var bsz := BLOCK - STREET
	var bay := 12.0
	var lvl_h := 12.0
	for bi in n:
		for bj in n:
			var bx := org.x + bi * BLOCK + STREET * 0.5
			var bz := org.y + bj * BLOCK + STREET * 0.5
			var r_on := rng.randf()
			var nx := 2 + rng.randi() % 3
			var nz := 2 + rng.randi() % 3
			var r_off := Vector2(rng.randf(), rng.randf())
			var r_h := rng.randf()
			var sub := rng.randi()
			# Frames stand in loose clumps with wide bare clearings between them.
			var clump := 0.5 + 0.5 * sin(bx * 0.0113 + 1.3) * cos(bz * 0.0137 - 0.6)
			if zone_at(def, Vector2(bx + bsz * 0.5, bz + bsz * 0.5)) != Zone.UNBUILT or bz < frames_from 					or r_on > 0.08 + 0.5 * clump * clump:
				continue
			var reserved := false
			for cp: Vector2 in camp_pts:
				if Rect2(bx, bz, bsz, bsz).has_point(cp):
					reserved = true
			if reserved or bz + bsz > hd - 12.0:
				continue   # nothing was ever raised on the last strip before the void
			var ox := bx + r_off.x * (bsz - float(nx) * bay)
			var oz := bz + r_off.y * (bsz - float(nz) * bay)
			var levels := 2 + int(pow(r_h, 1.6) * 9.0)
			var srng := RandomNumberGenerator.new()
			srng.seed = sub
			# Column tops: each reaches a random level, the frame is ragged.
			var tops: Array = []
			for ix in nx + 1:
				var row: Array = []
				for iz in nz + 1:
					var t := maxi(1, levels - (srng.randi() % 4 if srng.randf() < 0.5 else 0))
					row.append(t)
					var h := float(t) * lvl_h + srng.randf_range(1.0, 4.0)
					cols.append({ "c": Vector3(ox + float(ix) * bay, h * 0.5 - 0.5, oz + float(iz) * bay), "s": Vector3(0.9, h + 1.0, 0.9) })
				tops.append(row)
			for lv in range(1, levels + 1):
				var y := float(lv) * lvl_h
				for ix in nx + 1:
					for iz in nz + 1:
						if ix < nx and int(tops[ix][iz]) >= lv and int(tops[ix + 1][iz]) >= lv and srng.randf() < 0.85:
							beams.append({ "c": Vector3(ox + (float(ix) + 0.5) * bay, y - 0.35, oz + float(iz) * bay), "s": Vector3(bay - 0.9, 0.7, 0.5) })
						if iz < nz and int(tops[ix][iz]) >= lv and int(tops[ix][iz + 1]) >= lv and srng.randf() < 0.85:
							beams.append({ "c": Vector3(ox + float(ix) * bay, y - 0.42, oz + (float(iz) + 0.5) * bay), "s": Vector3(0.5, 0.7, bay - 0.9) })
				# The odd run of pale decking that did get laid.
				if srng.randf() < 0.3:
					var dx := srng.randi() % nx
					var dz := srng.randi() % nz
					var lx := 1 + srng.randi() % (nx - dx)
					if int(tops[dx][dz]) >= lv and int(tops[dx + lx][dz]) >= lv:
						decks.append({ "c": Vector3(ox + (float(dx) + float(lx) * 0.5) * bay, y + 0.12, oz + (float(dz) + 0.5) * bay), "s": Vector3(float(lx) * bay + 1.2, 0.24, bay * srng.randf_range(0.5, 1.0)) })
	return { "cols": cols, "beams": beams, "decks": decks }


## Returns Array of { "c": Vector3 centre, "s": Vector3 size, "seed": float 0..1 }.
static func generate_chunk(def: Dictionary, key: Vector2i) -> Array:
	var out: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d:%d" % [def.id, key.x, key.y])
	var org := chunk_origin(def, key)
	var ctx := {
		"hw": float(def.size[0]) * 0.5,
		"hd": float(def.size[2]) * 0.5,
		"ceiling": float(def.size[1]),
		"sp": float(def.pillars.spacing),
		"pclear": float(def.pillars.size) * 0.5 + PILLAR_CLEAR,
		"gate": gate_point(def),
		"sites": site_rects(def),
		"districts": def.districts,
		"cool": def.get("palette", "warm") == "cool",
	}
	var n := int(CHUNK / BLOCK)
	var bsz := BLOCK - STREET
	for bi in n:
		for bj in n:
			var bx := org.x + bi * BLOCK + STREET * 0.5
			var bz := org.y + bj * BLOCK + STREET * 0.5
			var block_rect := Rect2(bx, bz, bsz, bsz)
			var zone := zone_at(def, Vector2(bx + bsz * 0.5, bz + bsz * 0.5))
			var r_blk := rng.randf()
			var r_sub := rng.randf()
			if zone == Zone.UNBUILT:
				continue   # never built: bare frames only (generate_frames)
			if zone == Zone.INDUSTRIAL:
				_try_building(out, rng, block_rect, zone, ctx)
			elif zone == Zone.ABANDONED and r_blk < 0.4:
				# Barren blocks: big dead slabs, a canyon of blank walls.
				_try_building(out, rng, block_rect, zone, ctx)
			elif zone == Zone.URBAN and r_blk < 0.08:
				# Full-block civic/megastructure podium + stepped tower silhouette.
				_try_building(out, rng, block_rect, zone, ctx, 1.35)
			elif (zone == Zone.URBAN and r_blk < 0.26) or zone == Zone.ABANDONED:
				# Merged wide slabs along X or Z to break up the uniform 2x2 grid.
				var half := bsz * 0.5
				if r_sub < 0.5:
					_try_building(out, rng, Rect2(bx, bz, bsz, half), zone, ctx)
					_try_building(out, rng, Rect2(bx, bz + half, bsz, half), zone, ctx)
				else:
					_try_building(out, rng, Rect2(bx, bz, half, bsz), zone, ctx)
					_try_building(out, rng, Rect2(bx + half, bz, half, bsz), zone, ctx)
			else:
				var half := bsz * 0.5
				var courtyard_block := zone == Zone.URBAN and r_blk < 0.36
				for li in 2:
					for lj in 2:
						# Open courtyard / sightline gap in ~10% of urban blocks.
						var skip := courtyard_block and ((li + lj) % 2 == (0 if r_sub < 0.5 else 1))
						_try_building(out, rng, Rect2(bx + li * half, bz + lj * half, half, half), zone, ctx, 1.0, skip)
	return out


static func _try_building(out: Array, rng: RandomNumberGenerator, lot: Rect2, zone: Zone, ctx: Dictionary, height_bias := 1.0, skip := false) -> void:
	# Always draw the same number of randoms so exclusions never reshuffle neighbours.
	var r_in := PackedFloat32Array([rng.randf(), rng.randf(), rng.randf(), rng.randf()])
	var r_h := rng.randf()
	var r_mega := rng.randf()
	var r_mh := rng.randf()
	var r_seed := rng.randf()
	var r_set := rng.randf()
	var r_set_h := rng.randf()
	var r_set_in := rng.randf()
	var r_roof := rng.randf()
	var r_roof_p := Vector3(rng.randf(), rng.randf(), rng.randf())
	var r_gap := rng.randf()
	if skip or _excluded(lot, ctx):
		return
	# Occasional lone open pocket inside dense urban areas for silhouette breathing room.
	if zone == Zone.URBAN and height_bias <= 1.0 and r_gap < 0.06:
		return
	var inset_max := 4.0 if zone == Zone.INDUSTRIAL else 2.8
	var il := 1.0 + r_in[0] * inset_max
	var ir := 1.0 + r_in[1] * inset_max
	var it := 1.0 + r_in[2] * inset_max
	var ib := 1.0 + r_in[3] * inset_max
	var fx := lot.size.x - il - ir
	var fz := lot.size.y - it - ib
	var h: float
	var cx := lot.position.x + il + fx * 0.5
	var cz := lot.position.y + it + fz * 0.5
	# Deterministic macro skyline clustering: alternates low-rise breathing pockets
	# (~0.58x) with towering civic/industrial spire ridges (~1.55x) so high vistas
	# like 300s_roof_vista read as layered megastructure districts rather than uniform spikes.
	var cluster_wave := 0.5 + 0.5 * sin(cx * 0.0042 + cz * 0.0029) * cos(cx * 0.0021 - cz * 0.0048)
	var cluster_bias := lerpf(0.58, 1.55, pow(cluster_wave, 1.35))
	match zone:
		Zone.RESIDENTIAL:
			h = 9.0 + floorf(r_h * 8.0) * STOREY
		Zone.INDUSTRIAL:
			h = 12.0 + r_h * 30.0
		Zone.ABANDONED:
			h = 36.0 + pow(r_h, 1.4) * 150.0
		_:
			var mega_chance := 0.009 + 0.018 * pow(cluster_wave, 2.0)
			if r_mega < mega_chance:
				h = 280.0 + r_mh * (float(ctx.ceiling) - 340.0)
			else:
				h = (14.0 + pow(r_h, 2.2) * 165.0) * height_bias * cluster_bias
	h = minf(ceilf(h / STOREY) * STOREY, float(ctx.ceiling) - 40.0)
	# The seed carries the zone in its integer part (read by the facade shader).
	var seed := float(zone) + r_seed * 0.9
	var ground_i := out.size()
	var top := h
	var top_fx := fx
	var top_fz := fz
	var top_cx := cx
	var top_cz := cz
	if zone != Zone.INDUSTRIAL and h > 75.0 and r_set < 0.72:
		# Three-tier stepped megastructure tower (podium -> shaft -> upper crown).
		var h1 := ceilf(h * (0.22 + 0.14 * r_set_h) / STOREY) * STOREY
		var h2 := ceilf(h * (0.58 + 0.16 * r_set_in) / STOREY) * STOREY
		var k1 := 0.14 + 0.10 * r_set_in
		var k2 := 0.14 + 0.12 * r_roof_p.y
		_box(out, cx, -1.0, cz, fx, h1 + 1.0, fz, seed)
		var m_fx := fx * (1.0 - 2.0 * k1)
		var m_fz := fz * (1.0 - 2.0 * k1)
		var m_cx := cx + (r_roof_p.x - 0.5) * fx * k1 * 0.8
		var m_cz := cz + (r_roof_p.z - 0.5) * fz * k1 * 0.8
		_box(out, m_cx, h1 - 0.5, m_cz, m_fx, h2 - h1 + 0.5, m_fz, seed)
		top_fx = maxf(6.0, m_fx * (1.0 - 2.0 * k2))
		top_fz = maxf(6.0, m_fz * (1.0 - 2.0 * k2))
		top_cx = m_cx + (r_roof_p.z - 0.5) * m_fx * k2 * 0.7
		top_cz = m_cz + (r_roof_p.x - 0.5) * m_fz * k2 * 0.7
		_box(out, top_cx, h2 - 0.5, top_cz, top_fx, h - h2 + 0.5, top_fz, seed)
	elif zone != Zone.INDUSTRIAL and h > 28.0 and r_set < 0.52:
		# Two-tier stepped silhouette: a lower body and a narrower upper body.
		var h1 := ceilf(h * (0.42 + 0.32 * r_set_h) / STOREY) * STOREY
		var k := 0.15 + 0.16 * r_set_in
		_box(out, cx, -1.0, cz, fx, h1 + 1.0, fz, seed)
		top_fx = fx * (1.0 - 2.0 * k)
		top_fz = fz * (1.0 - 2.0 * k)
		top_cx = cx + (r_roof_p.x - 0.5) * fx * k
		top_cz = cz + (r_roof_p.z - 0.5) * fz * k
		# Starts 0.5 m inside the lower body so no horizontal faces are coplanar.
		_box(out, top_cx, h1 - 0.5, top_cz, top_fx, h - h1 + 0.5, top_fz, seed)
	else:
		# Buildings sink 1 m into the floor slab so no faces are coplanar with the ground.
		_box(out, cx, -1.0, cz, fx, h + 1.0, fz, seed)
	# Some ground bodies get an enterable room on a street-facing face.
	InteriorKit.plan(out[ground_i], int(zone), r_seed, float(ctx.hw), float(ctx.hd), _door_chance(ctx, Vector2(cx, cz)), bool(ctx.cool))
	if r_roof < 0.65 and top_fx > 6.0 and top_fz > 6.0:
		# Rooftop clutter: plant room / tank / penthouse slab.
		var rw := 2.4 + r_roof_p.y * minf(top_fx * 0.45, 5.5)
		var rd := 2.4 + r_roof_p.x * minf(top_fz * 0.45, 5.5)
		var rh := 2.2 + r_roof * 5.0
		var rx := top_cx + (r_roof_p.x - 0.5) * maxf(top_fx - rw - 1.0, 0.0)
		var rz := top_cz + (r_roof_p.z - 0.5) * maxf(top_fz - rd - 1.0, 0.0)
		_box(out, rx, top - 0.5, rz, rw, rh + 0.5, rd, seed)
		# Slender broadcast / ventilation spire on the tallest megatowers.
		if zone == Zone.URBAN and top > 180.0 and r_roof < 0.42:
			var spire_h := 18.0 + r_mh * 34.0
			_box(out, top_cx, top + rh - 0.5, top_cz, 1.35, spire_h, 1.35, seed)


## Share of buildings with an enterable room here; a district can raise it with "doors".
static func _door_chance(ctx: Dictionary, p: Vector2) -> float:
	for district: Dictionary in ctx.districts:
		if district.has("doors") and district_has(district, p):
			return float(district.doors)
	return InteriorKit.DOOR_CHANCE


## Box from y0 upward with height h.
static func _box(out: Array, cx: float, y0: float, cz: float, sx: float, h: float, sz: float, seed: float) -> void:
	out.append({ "c": Vector3(cx, y0 + h * 0.5, cz), "s": Vector3(sx, h, sz), "seed": seed })


static func _excluded(lot: Rect2, ctx: Dictionary) -> bool:
	var hw: float = ctx.hw
	var hd: float = ctx.hd
	if lot.position.x < -hw + EDGE_MARGIN or lot.end.x > hw - EDGE_MARGIN:
		return true
	if lot.position.y < -hd + EDGE_MARGIN or lot.end.y > hd - EDGE_MARGIN:
		return true
	if lot.position.y < AVENUE_HALF and lot.end.y > -AVENUE_HALF:
		return true
	var c := lot.get_center()
	if c.distance_to(ctx.gate) < GATE_PLAZA_RADIUS:
		return true
	for r: Rect2 in ctx.sites:
		if r.intersects(lot):
			return true
	var sp: float = ctx.sp
	var px := (roundf((c.x + hw - sp * 0.5) / sp)) * sp - hw + sp * 0.5
	var pz := (roundf((c.y + hd - sp * 0.5) / sp)) * sp - hd + sp * 0.5
	var pc: float = ctx.pclear
	var pr := Rect2(px - pc, pz - pc, pc * 2.0, pc * 2.0)
	return pr.intersects(lot)
