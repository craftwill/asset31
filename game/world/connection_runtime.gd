class_name ConnectionRuntime
extends WorldAnchor
## A physical route between two world points (bridge for now). Anchored at its
## midpoint; local +X runs from endpoint a to endpoint b. Deck top = local y 0.

var def: Dictionary
var length := 0.0


static func build(conn_def: Dictionary) -> ConnectionRuntime:
	var c := ConnectionRuntime.new()
	c.def = conn_def
	c.name = conn_def.id
	var a: Array = conn_def.a
	var b: Array = conn_def.b
	c.lx = (float(a[0]) + float(b[0])) * 0.5
	c.ly = float(a[1])
	c.lz = (float(a[2]) + float(b[2])) * 0.5
	var dx := float(b[0]) - float(a[0])
	var dz := float(b[2]) - float(a[2])
	c.length = sqrt(dx * dx + dz * dz)
	c.rotation.y = atan2(-dz, dx)
	match String(conn_def.kind):
		"bridge":
			c._build_bridge()
		_:
			push_error("Unsupported connection kind: %s" % conn_def.kind)
	return c


func _build_bridge() -> void:
	var L := length
	var w := float(def.width)
	var dt := float(def.deck_thickness)
	var body := StaticBody3D.new()
	body.name = "Collision"
	add_child(body)
	body.set_meta(&"surface", "metal")
	SliceMaterials.add_box(self, body, Vector3(0, -dt * 0.5, 0), Vector3(L, dt, w), &"bridge_deck")
	# Open railing with a glowing handrail (frame 125s). Collision is a solid
	# plane at the railing (people cannot squeeze between posts and mid-rail).
	var posts: Array = []
	for s in [-1.0, 1.0]:
		var zr: float = s * (w * 0.5 - 0.1)
		SliceMaterials.add_collision_box(body, Vector3(0, 0.58, zr), Vector3(L, 1.15, 0.1))
		SliceMaterials.add_box(self, null, Vector3(0, 1.11, zr), Vector3(L, 0.07, 0.07), &"rail_glow", false)
		SliceMaterials.add_box(self, null, Vector3(0, 0.55, zr), Vector3(L, 0.05, 0.05), &"structure", false)
		SliceMaterials.add_box(self, null, Vector3(0, -dt - 3.0, s * (w * 0.5 - 1.2)), Vector3(L, 6.0, 1.6), &"structure", false)
		var px := -L * 0.5 + 1.0
		while px < L * 0.5:
			posts.append({ "c": Vector3(px, 0.54, zr), "s": Vector3(0.07, 1.08, 0.07) })
			px += 2.0
	SliceMaterials.add_multimesh(self, posts, &"structure", 600.0)
	# Piers descending into the lower Mantle.
	var pd := float(def.pier_depth)
	var spacing := float(def.pier_spacing)
	var piers: Array = []
	var x := -L * 0.5 + spacing * 0.5
	while x < L * 0.5:
		piers.append({ "c": Vector3(x, -dt - 6.0 - pd * 0.5, 0), "s": Vector3(8.0, pd, w - 2.0) })
		piers.append({ "c": Vector3(x, -dt - 3.0, 0), "s": Vector3(4.0, 6.0, w - 2.4) })
		x += spacing
	SliceMaterials.add_multimesh(self, piers, &"structure")
	# Route lamps: readable line of light across the gap.
	var ls := float(def.lamp_spacing)
	var poles: Array = []
	var heads: Array = []
	var glows: Array = []
	var i := 0
	x = -L * 0.5 + ls * 0.5
	while x < L * 0.5:
		var side := -1.0 if i % 2 == 0 else 1.0
		var base := Vector3(x, 0, side * (w * 0.5 - 0.5))
		poles.append({ "c": base + Vector3(0, 2.0, 0), "s": Vector3(0.15, 4.0, 0.15) })
		heads.append({ "c": base + Vector3(0, 4.05, 0), "s": Vector3(0.5, 0.2, 0.5) })
		glows.append(base + Vector3(0, 3.9, 0))
		var light := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.8, 13.0)
		light.position = base + Vector3(0, 3.8, -side * 0.5)
		add_child(light)
		x += ls
		i += 1
	SliceMaterials.add_multimesh(self, poles, &"structure", 800.0)
	SliceMaterials.add_multimesh(self, heads, &"lamp")
	SliceMaterials.add_coronas(self, glows, 1.8)


func contains_local(p: Vector3) -> bool:
	return absf(p.x) <= length * 0.5 and absf(p.z) <= float(def.width) and p.y > -50.0 and p.y < 50.0
