class_name GlassTerraceSite
extends Node3D
## Colossal misty glass/grid curtain wall & brutalist observation terrace (frame 400s).
## Sits on STK-0413 south of the West Arrival Plaza (rect [-2740, 110, -2140, 430],
## world x in [6340, 6940], z in [110, 430]).
## Features a walkable concrete ramp from the Arrival Plaza up to a cantilevered
## pale-concrete observation terrace at y = +24 m lined with repeating boxy
## dark-vented buttresses overlooking the dark amber city below, directly facing a
## 540 x 440 m translucent silver-grid glass curtain wall with towering 3D pale
## concrete megatowers and lush green botanical podiums rising behind the mist.

const TERRACE_Y := 24.0


static func build(stack: StackRuntime, site: Dictionary) -> Node3D:
	var s := GlassTerraceSite.new()
	s._build(site)
	return s


func _build(site: Dictionary) -> void:
	var r: Array = site.rect
	var xa := float(r[0])   # -2740 (west, adjacent to Arrival Plaza)
	var za := float(r[1])   # +110  (north edge overlooking dark amber STK-0413 city)
	var xb := float(r[2])   # -2140 (east)
	var zb := float(r[3])   # +430  (south backdrop behind curtain wall)
	var xm := (xa + xb) * 0.5
	var body := StaticBody3D.new()
	add_child(body)

	var concrete: Array = []
	var steel: Array = []
	var towers_geo: Array = []
	var foliage: Array = []
	var foliage_dark: Array = []
	var sky_panels: Array = []

	# 1. Smooth walkable pale-concrete access ramp climbing from Arrival Plaza (x = -2734, y = 0)
	#    up to the cantilevered observation terrace (x = -2634, y = TERRACE_Y = 24 m, 13.5 deg slope).
	var ramp_x0 := xa + 6.0
	var ramp_x1 := xa + 106.0
	var ramp_z := za + 28.0
	var ramp_w := 14.0
	var rlen := sqrt(100.0 * 100.0 + TERRACE_Y * TERRACE_Y)
	var pitch := atan2(TERRACE_Y, 100.0)
	SliceMaterials.add_box(self, body, Vector3((ramp_x0 + ramp_x1) * 0.5, TERRACE_Y * 0.5 - 0.9, ramp_z), Vector3(rlen + 1.2, 1.8, ramp_w), &"terrace_concrete", true, Vector3(0.0, 0.0, pitch))
	for ri in 4:
		var px_r := lerpf(ramp_x0 + 22.0, ramp_x1 - 6.0, float(ri) / 3.0)
		var ph_r := lerpf(5.0, TERRACE_Y - 1.5, (px_r - ramp_x0) / 100.0)
		concrete.append({ "c": Vector3(px_r, ph_r * 0.5, ramp_z), "s": Vector3(3.2, ph_r, ramp_w - 2.0) })
		SliceMaterials.add_collision_box(body, Vector3(px_r, ph_r * 0.5, ramp_z), Vector3(3.2, ph_r, ramp_w - 2.0))
	for rs: float in [-1.0, 1.0]:
		var rz := ramp_z + rs * (ramp_w * 0.5 - 0.35)
		SliceMaterials.add_box(self, body, Vector3((ramp_x0 + ramp_x1) * 0.5, TERRACE_Y * 0.5 + 0.55, rz), Vector3(rlen - 1.5, 1.1, 0.7), &"terrace_concrete", true, Vector3(0.0, 0.0, pitch))

	# 2. Brutalist pale-concrete cantilevered observation terrace (x in [-2635, -2155], z in [120, 178], y = 24 m).
	var tx0 := ramp_x1 - 2.0
	var tx1 := xb - 15.0
	var tz0 := za + 10.0   # 120 (north drop overlooking dark amber STK-0413 city)
	var tz1 := za + 68.0   # 178 (meets the colossal curtain wall base)
	var txm := (tx0 + tx1) * 0.5
	var tzm := (tz0 + tz1) * 0.5
	var tw := tx1 - tx0
	var td := tz1 - tz0
	# Deep pale-concrete cantilever beam along the north drop edge (iconic 400s diagonal fascia).
	SliceMaterials.add_box(self, body, Vector3(txm, TERRACE_Y - 2.2, tzm), Vector3(tw, 4.4, td), &"terrace_concrete")
	# Cantilevered east observation spur at y = +28 m (looking WSW diagonally along the terrace ledge,
	# framing the misty glass curtain wall on the upper-left and the dark amber city dropping below right — ref 400s).
	var spur_cx := tx1 - 2.0
	var spur_cz := tz0 - 8.0
	SliceMaterials.add_box(self, body, Vector3(spur_cx, TERRACE_Y + 3.2, spur_cz), Vector3(26.0, 1.6, 18.0), &"terrace_concrete")
	# Low concrete safety curbs around the overlook spur's north & east outer drop edges (non-overlapping corner).
	SliceMaterials.add_box(self, body, Vector3(spur_cx, TERRACE_Y + 4.45, spur_cz - 8.65), Vector3(26.0, 0.9, 0.7), &"terrace_concrete")
	SliceMaterials.add_box(self, body, Vector3(spur_cx + 12.65, TERRACE_Y + 4.45, spur_cz + 0.36), Vector3(0.7, 0.9, 17.24), &"terrace_concrete")
	# Short stairs connecting the main terrace (y = 24) cleanly up to the east overlook spur (y = 28).
	for si in 8:
		var st_x := tx1 - 15.0 - float(si) * 0.9
		var st_y := TERRACE_Y + 4.0 - float(si) * 0.5
		concrete.append({ "c": Vector3(st_x, st_y - 0.22, tz0 + 3.5), "s": Vector3(0.95, 0.44, 4.8) })
		SliceMaterials.add_collision_box(body, Vector3(st_x, st_y - 0.22, tz0 + 3.5), Vector3(0.95, 0.44, 4.8))
	# Substructure support piers dropping down to the dark city floor below (solid collision).
	var px := tx0 + 24.0
	while px <= tx1 - 20.0:
		concrete.append({ "c": Vector3(px, (TERRACE_Y - 4.4) * 0.5, tz0 + 6.0), "s": Vector3(5.0, TERRACE_Y - 4.4, 7.0) })
		SliceMaterials.add_collision_box(body, Vector3(px, (TERRACE_Y - 4.4) * 0.5, tz0 + 6.0), Vector3(5.0, TERRACE_Y - 4.4, 7.0))
		px += 44.0

	# Repeating boxy brutalist concrete vent buttresses mounted cleanly along the outer north fascia
	# with dark recessed rectangular intake vents (exact 400s repeating parapet rhythm — all solid!).
	var bx := tx0 + 14.0
	while bx <= tx1 - 22.0:
		# Outer cantilevered concrete vent housing on the north face (z = tz0 - 2.2), top flush with parapet.
		concrete.append({ "c": Vector3(bx, TERRACE_Y - 1.5, tz0 - 2.2), "s": Vector3(4.8, 5.4, 4.6) })
		SliceMaterials.add_collision_box(body, Vector3(bx, TERRACE_Y - 1.5, tz0 - 2.2), Vector3(4.8, 5.4, 4.6))
		# Dark recessed rectangular intake louver on the exterior north face & east side.
		steel.append({ "c": Vector3(bx, TERRACE_Y - 1.1, tz0 - 4.55), "s": Vector3(3.1, 3.2, 0.25) })
		steel.append({ "c": Vector3(bx + 2.45, TERRACE_Y - 1.1, tz0 - 2.2), "s": Vector3(0.2, 3.2, 2.8) })
		bx += 18.0
	# Solid continuous north terrace parapet wall (stops cleanly before the east overlook stairs so you can walk up).
	var p_len := (tx1 - 15.5) - tx0
	var p_cx := tx0 + p_len * 0.5
	SliceMaterials.add_box(self, body, Vector3(p_cx, TERRACE_Y + 0.65, tz0 + 0.6), Vector3(p_len, 1.3, 1.2), &"terrace_concrete")

	# 3. Colossal 540 m wide x 430 m tall Translucent Silver-Grid Curtain Wall (z = tz1 + 2 = 180).
	#    No thick black foreground columns — the analytical silver-gray grid shader defines the giant glass facade!
	var wall_z := tz1 + 2.0
	var wall_w := 540.0
	var wall_h := 430.0
	SliceMaterials.add_box(self, body, Vector3(xm + 12.0, wall_h * 0.5, wall_z), Vector3(wall_w, wall_h, 0.4), &"curtain_wall")
	# Subtle pale horizontal sky-gallery floor rails right behind the glass (400s misty horizontal seams).
	for hy: float in [24.0, 110.0, 195.0, 280.0, 365.0]:
		concrete.append({ "c": Vector3(xm + 12.0, hy, wall_z + 1.4), "s": Vector3(wall_w, 1.4, 2.2) })
	# Dark exterior baffle wall on the west end (x = xa + 2) so daylight interiors NEVER leak out
	# into STK-0413's cool dark West Arrival gate vista!
	SliceMaterials.add_box(self, body, Vector3(xa + 4.0, wall_h * 0.5, wall_z + 120.0), Vector3(8.0, wall_h + 20.0, 240.0), &"industrial_wall")

	# 4. Towering 3D Pale-Concrete Megastructure Towers & Lush Green Botanical Podium Ledges
	#    standing RIGHT BEHIND the translucent glass curtain wall (z = 194..395) — ref 400s!
	var rng := RandomNumberGenerator.new()
	rng.seed = 413400
	var towers := [
		[-2620.0, 224.0, 68.0, 410.0, 52.0],
		[-2535.0, 248.0, 82.0, 450.0, 64.0],
		[-2440.0, 218.0, 64.0, 385.0, 50.0],
		[-2355.0, 255.0, 90.0, 460.0, 68.0],
		[-2260.0, 226.0, 74.0, 420.0, 56.0],
		[-2180.0, 242.0, 68.0, 400.0, 54.0],
		[-2580.0, 330.0, 108.0, 470.0, 74.0],
		[-2410.0, 345.0, 122.0, 480.0, 80.0],
		[-2235.0, 335.0, 104.0, 465.0, 72.0],
	]
	for t: Array in towers:
		var tx: float = t[0]
		var tz: float = t[1]
		var tw_t: float = t[2]
		var th_t: float = t[3]
		var td_t: float = t[4]
		# Windowed pale concrete megatower rising cleanly behind the misty curtain wall.
		towers_geo.append({ "c": Vector3(tx, th_t * 0.5, tz), "s": Vector3(tw_t, th_t, td_t), "seed": rng.randf() * 0.9 })
		# Lush green stepped botanical podiums & hanging terrace gardens right behind the lower glass (400s).
		var base_z := tz - td_t * 0.5 - 8.0
		concrete.append({ "c": Vector3(tx, 21.4, base_z), "s": Vector3(tw_t * 0.92, 4.0, 17.6) })
		foliage.append({ "c": Vector3(tx, 27.5, base_z - 1.5), "s": Vector3(tw_t * 0.86, 7.5, 14.0) })
		foliage_dark.append({ "c": Vector3(tx + 5.0, 33.0, base_z + 2.5), "s": Vector3(tw_t * 0.62, 6.0, 10.0) })
		# Second mid-level terraced garden band behind the glass.
		if rng.randf() < 0.72:
			concrete.append({ "c": Vector3(tx, 66.0, base_z + 3.0), "s": Vector3(tw_t * 0.78, 3.0, 12.0) })
			foliage.append({ "c": Vector3(tx, 70.5, base_z + 2.5), "s": Vector3(tw_t * 0.72, 6.2, 9.5) })
	# Continuous pale misty sky-wall backdrop behind the towers (z = zb - 8) + hidden overhead skylight glow
	# (kept strictly behind wall_z + 40 and below y = 425 so nothing peeks over STK-0413's arrival portal).
	concrete.append({ "c": Vector3(xm + 12.0, 230.0, zb - 8.0), "s": Vector3(wall_w + 40.0, 460.0, 14.0) })
	for sx_p: float in [xm - 160.0, xm + 12.0, xm + 185.0]:
		sky_panels.append({ "c": Vector3(sx_p, 422.0, wall_z + 115.0), "s": Vector3(135.0, 2.0, 150.0) })

	SliceMaterials.add_multimesh(self, concrete, &"terrace_concrete")
	SliceMaterials.add_multimesh(self, towers_geo, &"terrace_tower")
	SliceMaterials.add_multimesh(self, steel, &"structure")
	if not foliage.is_empty():
		SliceMaterials.add_multimesh(self, foliage, &"crop_green")
	if not foliage_dark.is_empty():
		SliceMaterials.add_multimesh(self, foliage_dark, &"crop_dark")
	SliceMaterials.add_multimesh(self, sky_panels, &"sky_panel")

	# 5. Soft misty daylight illumination on the terrace concrete and behind the curtain wall.
	for lx: float in [txm - 170.0, txm, txm + 170.0]:
		var tl := OmniLight3D.new()
		tl.position = Vector3(lx, TERRACE_Y + 30.0, tz0 + 18.0)
		tl.light_color = Color(0.88, 0.91, 0.88)
		tl.light_energy = 7.0
		tl.omni_range = 210.0
		tl.omni_attenuation = 0.6
		tl.light_volumetric_fog_energy = 0.45
		add_child(tl)
		var bl := OmniLight3D.new()
		bl.position = Vector3(lx, 140.0, wall_z + 36.0)
		bl.light_color = Color(0.86, 0.90, 0.87)
		bl.light_energy = 11.5
		bl.omni_range = 340.0
		bl.omni_attenuation = 0.55
		bl.light_volumetric_fog_energy = 0.45
		add_child(bl)

	# 6. Explorer plaque & expedition cache on the terrace overlooking the glass curtain.
	add_child(ReadableNote.create(
		"NOTE-GLASS-413", "Glass Curtain Sector 413-S Survey",
		"STK-0413  ·  SOUTH OBSERVATION TERRACE (+24 M)\n\n"
		+ "The 430-metre translucent curtain wall seals the pale brutalist towers and "
		+ "terraced botanical scrubbers of Sector 413-S above the dark amber lower city.\n"
		+ "Step onto the northwest overlook spur to view the full glass curtain and "
		+ "the city blocks dropping away below.",
		Vector3(tx0 + 18.0, TERRACE_Y + 1.45, tz0 + 1.4), 0.0, "plaque"))
	add_child(LootContainer.create(
		"CONT-GLASS-413", "Terrace Survey Case", "crate",
		Vector3(tx0 + 26.0, TERRACE_Y + 0.02, tz0 + 2.2), 0.0,
		[["water_flask", 2], ["ration_tin", 1], ["bandage_roll", 1], ["brass_coil", 2]], 5, 4))
