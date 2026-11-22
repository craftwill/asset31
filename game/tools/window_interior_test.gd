extends Node3D
## Standalone proof-of-concept test scene for the Procedural Window Interior
## System. Builds one representative Asset31 building facade with a 7x4 grid of
## flat window planes covering all 7 room categories and curtain/blind states,
## then captures multi-angle and multi-distance views when run with --shots=DIR.

const WINDOW_SHADER := preload("res://shaders/window_plane.gdshader")


func _ready() -> void:
	var atmo := Atmosphere.new()
	add_child(atmo)

	# Dark ground slab + representative Asset31 facade block (no real rooms behind it).
	SliceMaterials.add_box(self, null, Vector3(0, -0.5, 0), Vector3(160, 1.0, 160), &"ground", false)
	SliceMaterials.add_box(self, null, Vector3(0, 9.0, -6.0), Vector3(32.0, 18.0, 12.0), &"industrial_wall", false)

	# One MultiMesh of 28 flat QuadMesh window planes (7 columns = 7 categories, 4 rows = curtain states).
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2(2.2, 1.9)
	mm.mesh = q
	mm.instance_count = 28

	# Rows: 0 = open, 1 = partial curtain, 2 = blinds, 3 = procedural auto mix.
	var curt_rows := [1.10, 1.45, 1.70, 0.0]
	var idx := 0
	for row in 4:
		for col in 7:
			var wx := -12.0 + col * 4.0
			var wy := 2.4 + row * 3.5
			# Flat plane sits 3 cm proud of the facade front wall (z = 0.0) so zero z-fighting.
			mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY, Vector3(wx, wy, 0.03)))
			var seed := float(idx + 1) / 31.0
			var zone := 1.0 if col == 0 else (2.0 if col == 3 else 0.0)
			var cat_val := float(col + 1) # 1..7 -> categories 0..6
			var curt_val: float = curt_rows[row]
			mm.set_instance_custom_data(idx, Color(seed, zone, cat_val, curt_val))
			idx += 1

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = WINDOW_SHADER
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

	# Street lamp so facade wall reads in the same warm dark Mantle lighting.
	var l := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 2.2, 26.0)
	l.position = Vector3(-6.0, 6.0, 9.0)
	add_child(l)
	var l2 := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.8, 26.0)
	l2.position = Vector3(8.0, 6.0, 9.0)
	add_child(l2)

	var cam := Camera3D.new()
	cam.near = 0.12
	cam.far = 2000.0
	cam.fov = 65.0
	cam.position = Vector3(0.0, 6.5, 16.0)
	add_child(cam)
	cam.look_at(Vector3(0.0, 7.2, 0.0), Vector3.UP)
	cam.current = true

	var shots_dir := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.get_slice("=", 1)
	if shots_dir != "":
		_capture_views(cam, shots_dir)


func _capture_views(cam: Camera3D, dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var views := [
		["front_near", Vector3(0.0, 6.8, 13.0), Vector3(0.0, 7.2, 0.0)],
		["angle_left", Vector3(-13.5, 4.5, 10.0), Vector3(-2.0, 7.0, 0.0)],
		["angle_right", Vector3(13.5, 4.5, 10.0), Vector3(2.0, 7.0, 0.0)],
		["street_low", Vector3(-5.0, 1.7, 9.5), Vector3(-3.0, 6.5, 0.0)],
		["mid_dist", Vector3(4.0, 9.0, 42.0), Vector3(0.0, 7.5, 0.0)],
	]
	for v: Array in views:
		cam.position = v[1]
		cam.look_at(v[2], Vector3.UP)
		for i in 12:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join("%s.png" % v[0]))
	get_tree().quit(0)
