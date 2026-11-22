class_name Crowd
extends Node3D
## Low-poly people as human-scale references (frames 025s, 550s, 500s).
## One MultiMesh per crowd; walkers pace between two points, limbs swing in
## the vertex shader. No collision, no AI: scenery that implies inhabitants.

static var _mesh: ArrayMesh

var _mm: MultiMesh
var _walkers: Array = []   # { a, b, u, dir, speed, seed, dark }
var _statics: Array = []   # { p, yaw, seed, dark }


static func figure_mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# R = part (0 skin, .33 shirt, .66 trousers, 1 hat); G = swinging limb.
	_box(st, Vector3(-0.18, 0.0, -0.09), Vector3(-0.02, 0.88, 0.09), Color(0.66, 0.25, 0))
	_box(st, Vector3(0.02, 0.0, -0.09), Vector3(0.18, 0.88, 0.09), Color(0.66, 0.5, 0))
	_box(st, Vector3(-0.21, 0.86, -0.12), Vector3(0.21, 1.48, 0.12), Color(0.33, 0, 0))
	_box(st, Vector3(-0.34, 0.82, -0.07), Vector3(-0.22, 1.44, 0.07), Color(0.33, 0.75, 0))
	_box(st, Vector3(0.22, 0.82, -0.07), Vector3(0.34, 1.44, 0.07), Color(0.33, 1.0, 0))
	_box(st, Vector3(-0.11, 1.49, -0.11), Vector3(0.11, 1.71, 0.11), Color(0, 0, 0))
	_box(st, Vector3(-0.14, 1.70, -0.15), Vector3(0.14, 1.79, 0.14), Color(1, 0, 0))
	_mesh = st.commit()
	return _mesh


static func _box(st: SurfaceTool, a: Vector3, b: Vector3, col: Color) -> void:
	var c := [
		Vector3(a.x, a.y, a.z), Vector3(b.x, a.y, a.z), Vector3(b.x, b.y, a.z), Vector3(a.x, b.y, a.z),
		Vector3(a.x, a.y, b.z), Vector3(b.x, a.y, b.z), Vector3(b.x, b.y, b.z), Vector3(a.x, b.y, b.z)]
	var faces := [
		[[0, 3, 2, 1], Vector3.FORWARD], [[4, 5, 6, 7], Vector3.BACK],
		[[0, 4, 7, 3], Vector3.LEFT], [[1, 2, 6, 5], Vector3.RIGHT],
		[[3, 7, 6, 2], Vector3.UP], [[0, 1, 5, 4], Vector3.DOWN]]
	for f: Array in faces:
		var idx: Array = f[0]
		var n: Vector3 = f[1]
		for t in [[0, 1, 2], [0, 2, 3]]:
			for k: int in t:
				st.set_color(col)
				st.set_normal(n)
				st.add_vertex(c[idx[k]])


## statics: Array of { "p": Vector3, "yaw": float }  walkers: Array of { "a": Vector3, "b": Vector3 }
func setup(statics: Array, walkers: Array, seed_base: int, dark := 0.0, vis_end := 450.0, shadows := false) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_base
	for s: Dictionary in statics:
		_statics.append({ "p": s.p, "yaw": float(s.get("yaw", rng.randf() * TAU)), "seed": rng.randf(), "dark": dark })
	for w: Dictionary in walkers:
		_walkers.append({ "a": w.a, "b": w.b, "u": rng.randf(), "dir": 1.0 if rng.randf() < 0.5 else -1.0,
			"speed": rng.randf_range(1.0, 1.45), "seed": rng.randf(), "dark": dark })
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	_mm.mesh = figure_mesh()
	_mm.instance_count = _statics.size() + _walkers.size()
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.material_override = SliceMaterials.get_mat(&"figure")
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = vis_end
	add_child(mmi)
	for i in _statics.size():
		var s: Dictionary = _statics[i]
		var sc := rng.randf_range(0.92, 1.06)
		_mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, s.yaw).scaled(Vector3.ONE * sc), s.p))
		_mm.set_instance_custom_data(i, Color(s.seed, 0.0, s.dark, 0.0))
	_update_walkers(0.0)


func _process(delta: float) -> void:
	if not _walkers.is_empty():
		_update_walkers(delta)


func _update_walkers(delta: float) -> void:
	var base := _statics.size()
	for i in _walkers.size():
		var w: Dictionary = _walkers[i]
		var a: Vector3 = w.a
		var b: Vector3 = w.b
		var length := maxf(a.distance_to(b), 0.1)
		var u: float = w.u + float(w.dir) * float(w.speed) * delta / length
		if u > 1.0:
			u = 1.0
			w.dir = -1.0
		elif u < 0.0:
			u = 0.0
			w.dir = 1.0
		w.u = u
		var d := (b - a) * float(w.dir)
		var yaw := atan2(-d.x, -d.z)
		_mm.set_instance_transform(base + i, Transform3D(Basis(Vector3.UP, yaw), a.lerp(b, u)))
		_mm.set_instance_custom_data(base + i, Color(w.seed, float(w.speed) * 5.5, w.dark, 0.0))
