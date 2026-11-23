class_name DistantStack
extends WorldAnchor
## Atmospheric far-distant megastructure stack placed 15–20 km across the Mantle
## abyss (e.g. planned STK-0414 at ~17.5 km). Preserves true planetary-scale
## horizontal depth beyond the close 3 km STK-0412/STK-0413 Twin-Stack Landmark
## at minimal draw-call cost (~4 draws per stack).

var def: Dictionary


static func build(sdef: Dictionary) -> DistantStack:
	var d := DistantStack.new()
	d.def = sdef
	d.name = String(sdef.get("id", "STK-DIST"))
	var p: Array = sdef.position
	d.lx = float(p[0])
	d.ly = float(p[1])
	d.lz = float(p[2])
	d._build()
	return d


func _build() -> void:
	var sx := float(def.get("width", 5200.0))
	var sz := float(def.get("depth", 5200.0))
	var below := float(def.get("below_depth", 7500.0))
	var above := float(def.get("above_height", 7500.0))
	var h := below + above
	var cy := (above - below) * 0.5
	var cool := String(def.get("palette", "warm")) == "cool"
	var wall_mat := &"stack_wall_cool" if cool else &"stack_wall"
	var variant := int(def.get("silhouette", 0))

	# 1. Stepped colossal megastructure massing (distinct macro silhouette per stack).
	var bodies: Array = []
	bodies.append({ "c": Vector3(0.0, cy, 0.0), "s": Vector3(sx, h, sz), "seed": float(variant) * 0.17 })
	if variant % 3 == 0:
		# Broad flank wings + recessed central notch + high crown block (STK-0414 profile).
		bodies.append({ "c": Vector3(-sx * 0.36, cy + 400.0, 0.0), "s": Vector3(sx * 0.34, h + 1800.0, sz * 1.12), "seed": 0.31 })
		bodies.append({ "c": Vector3(sx * 0.36, cy - 300.0, 0.0), "s": Vector3(sx * 0.34, h + 1200.0, sz * 1.08), "seed": 0.47 })
		bodies.append({ "c": Vector3(0.0, above + 950.0, 0.0), "s": Vector3(sx * 0.44, 2100.0, sz * 0.44), "seed": 0.63 })
	elif variant % 3 == 1:
		# Twin monumental industrial silos / cooling shafts rising above the main bulk (STK-0415 profile).
		bodies.append({ "c": Vector3(-sx * 0.24, above + 1100.0, -sz * 0.12), "s": Vector3(sx * 0.26, 2600.0, sz * 0.28), "seed": 0.22 })
		bodies.append({ "c": Vector3(sx * 0.24, above + 850.0, sz * 0.14), "s": Vector3(sx * 0.24, 2100.0, sz * 0.26), "seed": 0.54 })
	else:
		# Tiered ziggurat megastructure with cantilevered lower apron.
		bodies.append({ "c": Vector3(0.0, cy - 1600.0, 0.0), "s": Vector3(sx * 1.22, h * 0.55, sz * 1.22), "seed": 0.19 })
		bodies.append({ "c": Vector3(0.0, above + 700.0, 0.0), "s": Vector3(sx * 0.58, 1700.0, sz * 0.58), "seed": 0.71 })
	SliceMaterials.add_multimesh(self, bodies, wall_mat)

	# 2. Dark structural buttress ribs, deep horizontal mechanical bands & distant viaduct stub.
	var steel: Array = []
	for by: float in [-3600.0, -1800.0, 0.0, 1800.0, 3600.0]:
		steel.append({ "c": Vector3(0.0, by, 0.0), "s": Vector3(sx + 160.0, 140.0, sz + 160.0) })
	for bx_f: float in [-0.42, -0.14, 0.14, 0.42]:
		steel.append({ "c": Vector3(bx_f * sx, cy, 0.0), "s": Vector3(130.0, h + 200.0, sz + 180.0) })
	# Optional colossal elevated viaduct truss arm reaching out into the void (100s/125s distant scale cue).
	var arm_dir: Array = def.get("viaduct_dir", [])
	if arm_dir.size() == 2:
		var dx := float(arm_dir[0])
		var dz := float(arm_dir[1])
		var dir2 := Vector2(dx, dz).normalized()
		var arm_len := float(def.get("viaduct_len", 5200.0))
		var start_r := maxf(sx, sz) * 0.5
		var mid := Vector3(dir2.x * (start_r + arm_len * 0.5), 180.0, dir2.y * (start_r + arm_len * 0.5))
		var yaw := atan2(-dir2.x, -dir2.y)
		steel.append({ "c": mid, "s": Vector3(120.0, 140.0, arm_len), "r": Vector3(0.0, yaw, 0.0) })
		for pi in 3:
			var pr := start_r + arm_len * (0.25 + float(pi) * 0.30)
			steel.append({ "c": Vector3(dir2.x * pr, -2600.0, dir2.y * pr), "s": Vector3(85.0, 5600.0, 85.0) })
	SliceMaterials.add_multimesh(self, steel, &"structure")

	# 3. Restrained glowing portal/crown beacons so the distant silhouette reads through 15-20 km haze.
	var beacons: Array = []
	var crowns: Array = []
	for cx_s: float in [-sx * 0.46, sx * 0.46]:
		for cz_s: float in [-sz * 0.46, sz * 0.46]:
			beacons.append({ "c": Vector3(cx_s, above + 160.0, cz_s), "s": Vector3(36.0, 36.0, 36.0) })
	# Subtle horizontal warm/cool amber datum band near Floor 77 elevation (y = 0).
	crowns.append({ "c": Vector3(0.0, 45.0, 0.0), "s": Vector3(sx + 175.0, 26.0, sz + 175.0) })
	SliceMaterials.add_multimesh(self, beacons, &"beacon_red")
	SliceMaterials.add_multimesh(self, crowns, &"lamp_cool" if cool else &"rail_glow")
