class_name PlanetView
extends Node3D
## Orbital space view of Asset 31 / the Mantle (faithful 1:1 recreation of reference
## frames 075s and 625s). Self-contained 3D scene usable both standalone
## (res://scenes/planet_view.tscn) and embedded in main.gd via a dedicated SubViewport
## (own_world_3d = true) so it stays completely isolated from the interior Mantle city.

signal exit_requested

const PLANET_SHELL_SHADER := preload("res://shaders/planet_shell.gdshader")
const CORRIDOR_SHADER := preload("res://shaders/planet_corridor.gdshader")
const HUB_SHADER := preload("res://shaders/planet_hub.gdshader")
const STAR_SHADER := preload("res://shaders/space_star.gdshader")

const PLANET_RADIUS := 10.0
const CORRIDOR_RADIUS := 10.06
const HUB_RADIUS := 10.10
const SURFACE_LIGHT_RADIUS := 10.04
const STARFIELD_RADIUS := 420.0

# Exact reference camera presets: [distance, yaw_deg, pitch_deg, fov, screen_offset_world]
# 075s: wide establishing orbital view (planet slightly right-of-center, ~56% height).
# 625s: closer orbital view (planet near center, ~80% height).
const PRESET_075S := {
	"dist": 51.5,
	"yaw": 0.0,
	"pitch": 0.0,
	"fov": 42.0,
	"target_offset": Vector3(-1.65, -0.75, 0.0),
}
const PRESET_625S := {
	"dist": 34.0,
	"yaw": 0.0,
	"pitch": 0.0,
	"fov": 42.0,
	"target_offset": Vector3(0.10, 0.25, 0.0),
}

var planet_root: Node3D
var camera: Camera3D
var env: Environment

var auto_rotate := true
var rotation_speed := 0.018 # gentle majestic ~1.0 deg/s orbital turn
var interactive := true

var _orbit_yaw := 0.0
var _orbit_pitch := 0.0
var _orbit_dist := 48.0
var _target_offset := Vector3(-1.2, -0.55, 0.0)
var _dragging := false
var _standalone := false
var _hint_layer: CanvasLayer
var _hint_label: Label


func _ready() -> void:
	_standalone = (get_tree().current_scene == self)
	_build_environment()
	_build_starfield()
	_build_planet()
	_build_camera()
	apply_preset_075s()
	if _standalone:
		_build_standalone_overlay()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _build_environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.005, 0.006, 0.011)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.BLACK
	env.ambient_light_energy = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.fog_enabled = false
	env.volumetric_fog_enabled = false
	env.glow_enabled = true
	env.glow_intensity = 0.24
	env.glow_strength = 0.85
	env.glow_bloom = 0.02
	env.glow_hdr_threshold = 1.15
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.04
	env.adjustment_saturation = 0.96
	var we := WorldEnvironment.new()
	we.name = "SpaceEnvironment"
	we.environment = env
	add_child(we)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "OrbitalCamera"
	camera.near = 0.2
	camera.far = 1200.0
	camera.fov = 42.0
	add_child(camera)
	camera.current = true


func apply_preset_075s() -> void:
	_apply_preset(PRESET_075S)


func apply_preset_625s() -> void:
	_apply_preset(PRESET_625S)


func _apply_preset(p: Dictionary) -> void:
	_orbit_dist = float(p.dist)
	_orbit_yaw = deg_to_rad(float(p.yaw))
	_orbit_pitch = deg_to_rad(float(p.pitch))
	_target_offset = p.target_offset
	if camera != null:
		camera.fov = float(p.fov)
	if planet_root != null:
		planet_root.rotation = Vector3.ZERO
	_update_camera_transform()


func set_planet_yaw(yaw_rad: float) -> void:
	if planet_root != null:
		planet_root.rotation.y = yaw_rad


func _update_camera_transform() -> void:
	if camera == null:
		return
	var dir := Vector3(
		sin(_orbit_yaw) * cos(_orbit_pitch),
		sin(_orbit_pitch),
		cos(_orbit_yaw) * cos(_orbit_pitch)
	)
	var eye := dir * _orbit_dist
	var basis := Basis.looking_at(-dir, Vector3.UP)
	var offset_world := basis * _target_offset
	camera.position = eye + offset_world
	camera.basis = basis


func _process(delta: float) -> void:
	if planet_root != null and auto_rotate:
		planet_root.rotation.y += rotation_speed * delta
	if interactive and _is_active_input():
		var yaw_in := Input.get_axis(&"move_left", &"move_right")
		var pitch_in := Input.get_axis(&"move_back", &"move_forward")
		if absf(yaw_in) > 0.01 or absf(pitch_in) > 0.01:
			_orbit_yaw += yaw_in * 0.9 * delta
			_orbit_pitch = clampf(_orbit_pitch + pitch_in * 0.7 * delta, -1.35, 1.35)
			_target_offset = _target_offset.lerp(Vector3.ZERO, clampf(delta * 3.0, 0.0, 1.0))
			_update_camera_transform()


func _is_active_input() -> bool:
	if _standalone:
		return true
	return visible


func handle_input_event(event: InputEvent) -> bool:
	if not interactive:
		return false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
			return true
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_orbit_dist = clampf(_orbit_dist * 0.92, 16.5, 95.0)
			_update_camera_transform()
			return true
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_orbit_dist = clampf(_orbit_dist * 1.08, 16.5, 95.0)
			_update_camera_transform()
			return true
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		_orbit_yaw -= mm.relative.x * 0.0055
		_orbit_pitch = clampf(_orbit_pitch + mm.relative.y * 0.0055, -1.35, 1.35)
		_target_offset = _target_offset.lerp(Vector3.ZERO, 0.12)
		_update_camera_transform()
		return true
	elif event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			var code := ke.physical_keycode if ke.physical_keycode != KEY_NONE else ke.keycode
			if code == KEY_1:
				auto_rotate = false
				apply_preset_075s()
				return true
			elif code == KEY_2:
				auto_rotate = false
				apply_preset_625s()
				return true
			elif code == KEY_SPACE:
				auto_rotate = not auto_rotate
				return true
			elif code == KEY_R:
				apply_preset_075s()
				return true
			elif code == KEY_H and _hint_layer != null:
				_hint_layer.visible = not _hint_layer.visible
				return true
			elif code == KEY_ESCAPE or code == KEY_P:
				if not _standalone:
					exit_requested.emit()
					return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if _standalone:
		if handle_input_event(event):
			get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ starfield

func _build_starfield() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31075625
	var count := 2200
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	mm.mesh = q
	mm.instance_count = count

	for i in count:
		# Uniform distribution on the celestial sphere.
		var u := rng.randf_range(-1.0, 1.0)
		var theta := rng.randf_range(0.0, TAU)
		var r_xy := sqrt(maxf(0.0, 1.0 - u * u))
		var dir := Vector3(r_xy * cos(theta), u, r_xy * sin(theta))
		var pos := dir * STARFIELD_RADIUS

		# Mostly dim pinpoint stars with a sparse fraction of crisp bright stars (075s/625s).
		var roll := rng.randf()
		var bright := 0.24 + pow(roll, 2.6) * 1.05
		var px_sz := 1.85 + pow(roll, 3.2) * 1.35
		var warm := rng.randf_range(0.18, 0.68)

		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.01), pos))
		mm.set_instance_custom_data(i, Color(bright, warm, px_sz, 1.0))

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Starfield"
	mmi.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = STAR_SHADER
	mat.set_shader_parameter(&"global_energy", 1.05)
	mat.set_shader_parameter(&"softness", 5.4)
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.extra_cull_margin = STARFIELD_RADIUS
	add_child(mmi)


# --------------------------------------------------------------------- planet

func _build_planet() -> void:
	planet_root = Node3D.new()
	planet_root.name = "Asset31Planet"
	add_child(planet_root)

	# 1. Solid outer steel Mantle shell (smooth sphere with custom matte solar terminator).
	var sphere := SphereMesh.new()
	sphere.radius = PLANET_RADIUS
	sphere.height = PLANET_RADIUS * 2.0
	sphere.radial_segments = 96
	sphere.rings = 48

	var shell := MeshInstance3D.new()
	shell.name = "MantleShell"
	shell.mesh = sphere
	var shell_mat := ShaderMaterial.new()
	shell_mat.shader = PLANET_SHELL_SHADER
	shell_mat.set_shader_parameter(&"sun_dir", Vector3(0.95, 0.20, 0.22).normalized())
	shell_mat.set_shader_parameter(&"lit_color", Color(0.248, 0.236, 0.218))
	shell_mat.set_shader_parameter(&"dark_color", Color(0.002, 0.002, 0.003))
	shell_mat.set_shader_parameter(&"light_energy", 1.0)
	shell.material_override = shell_mat
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	planet_root.add_child(shell)

	# 2. Planetary arterial hub & corridor network (1:1 front hemisphere + seamless 360° back).
	var net := _build_network_data()
	_build_corridors(net.hubs, net.edges)
	_build_hubs(net.hubs)
	_build_surface_micro_lights()


## Returns { "hubs": Array[Dictionary], "edges": Array[Array] }.
## Front-hemisphere hubs (0..18) match the exact projected positions and connections
## measured from video_reference_075s.jpg and video_reference_625s.jpg; back-hemisphere
## hubs (19..30) seamlessly continue the same geodesic network around the full 360° globe.
func _build_network_data() -> Dictionary:
	# Hub dict: dir (Vector3 unit), spokes (3/4/6), rot (rad), size (world), intensity, halo
	var hubs: Array[Dictionary] = [
		# --- Front hemisphere (exact reference match to 075s / 625s) ---
		_hub(_sdir(-0.07, -0.10, true), 6, 0.36, 1.65, 1.05, 0.80),    # 0  V_center (equatorial central star)
		_hub(_sdir(0.35, 0.43, true), 6, 0.18, 1.38, 1.10, 0.75),      # 1  V_ur (upper-right inner hub)
		_hub(_sdir(0.33, -0.57, true), 6, 0.25, 1.42, 1.10, 0.75),     # 2  V_dr (lower-right inner hub)
		_hub(_sdir(0.71, -0.09, true), 6, 0.06, 2.30, 1.55, 1.05),     # 3  V_right (prominent right 6-star)
		_hub(_sdir(-0.24, 0.62, true), 4, 0.04, 1.50, 1.10, 0.80),     # 4  V_tl (upper-left terminator X-hub)
		_hub(_sdir(-0.23, -0.80, true), 4, -0.08, 1.35, 1.00, 0.85),   # 5  V_botl (lower-left terminator hub)
		_hub(_sdir(0.38, 0.77, true), 4, 0.32, 1.30, 1.05, 0.80),      # 6  V_top (upper limb hub)
		_hub(_sdir(0.35, -0.84, true), 4, 0.20, 1.24, 1.00, 0.80),     # 7  V_bot (lower limb hub)
		_hub(_sdir(-0.62, 0.33, true), 3, 0.45, 1.18, 0.95, 0.75),     # 8  V_ul (dark-side upper-left Y-hub)
		_hub(_sdir(-0.60, -0.51, true), 3, -0.45, 1.15, 0.95, 0.80),   # 9  V_ll (dark-side lower-left hub)
		_hub(_sdir(-0.81, -0.08, true), 6, 0.18, 1.55, 1.15, 1.00),    # 10 V_farleft (dark left-limb crossing)
		_hub(_sdir(0.79, -0.52, true), 4, 0.30, 1.15, 0.90, 0.75),     # 11 V_fardr (lower-right limb hub)
		_hub(_sdir(-0.92, 0.27, true), 4, 0.15, 1.12, 0.85, 0.85),     # 12 V_far_ul (far-left upper limb hub)
		_hub(_sdir(-0.90, -0.38, true), 4, -0.15, 1.10, 0.85, 0.85),   # 13 V_far_ll (far-left lower limb hub)

		# --- Horizon / limb continuation anchors (cleanly route limb arcs around the sphere) ---
		_hub(Vector3(-0.78, 0.61, -0.15).normalized(), 4, 0.2, 0.90, 0.70, 0.65, false), # 14 top-left limb
		_hub(Vector3(-0.78, -0.61, -0.15).normalized(), 4, 0.2, 0.90, 0.70, 0.65, false),# 15 bot-left limb
		_hub(Vector3(0.74, 0.63, -0.22).normalized(), 4, 0.1, 0.95, 0.75, 0.65, false),  # 16 top-right limb
		_hub(Vector3(0.97, -0.07, -0.22).normalized(), 6, 0.1, 1.15, 0.90, 0.75),        # 17 right equator limb
		_hub(Vector3(-0.04, 0.99, -0.10).normalized(), 4, 0.3, 0.90, 0.70, 0.60, false), # 18 north crown arc anchor
		_hub(Vector3(0.04, -0.99, -0.10).normalized(), 4, 0.3, 0.90, 0.70, 0.60, false), # 19 south crown arc anchor
		_hub(Vector3(-0.97, -0.08, -0.22).normalized(), 6, 0.2, 1.15, 0.90, 0.75),       # 20 far-left equator limb

		# --- Back hemisphere (seamless geodesic continuation for 360° orbit & rotation) ---
		_hub(Vector3(0.08, -0.06, -0.99).normalized(), 6, 0.25, 1.75, 1.25, 0.90),       # 21 back center
		_hub(Vector3(-0.36, 0.45, -0.82).normalized(), 6, 0.12, 1.42, 1.10, 0.75),       # 22 back ul
		_hub(Vector3(-0.34, -0.56, -0.75).normalized(), 6, 0.20, 1.42, 1.10, 0.75),      # 23 back ll
		_hub(Vector3(0.42, 0.48, -0.77).normalized(), 6, 0.15, 1.48, 1.15, 0.80),        # 24 back ur
		_hub(Vector3(0.40, -0.54, -0.74).normalized(), 6, 0.30, 1.48, 1.15, 0.80),       # 25 back lr
		_hub(Vector3(0.78, 0.22, -0.58).normalized(), 4, 0.10, 1.32, 1.00, 0.75),        # 26 back mid-right upper
		_hub(Vector3(-0.74, -0.08, -0.67).normalized(), 6, 0.05, 1.68, 1.20, 0.85),      # 27 back mid-left eq
		_hub(Vector3(0.00, 0.78, -0.62).normalized(), 4, 0.22, 1.32, 1.00, 0.75),        # 28 back north
		_hub(Vector3(0.02, -0.80, -0.60).normalized(), 4, -0.18, 1.32, 1.00, 0.75),      # 29 back south
	]

	# Edges: [hub_a, hub_b, tier]  (tier 1.0 = primary bright corridor, 0.0 = secondary faint beaded arc)
	var edges: Array = [
		# --- Front hemisphere PRIMARY bright corridors (exact 075s / 625s web) ---
		[0, 1, 1.0],   # center -> ur
		[0, 2, 1.0],   # center -> dr
		[1, 4, 1.0],   # ur -> tl
		[1, 6, 1.0],   # ur -> top
		[4, 8, 1.0],   # tl -> ul
		[8, 10, 1.0],  # ul -> farleft
		[10, 9, 1.0],  # farleft -> ll
		[9, 5, 1.0],   # ll -> botl
		[5, 2, 1.0],   # botl -> dr
		[2, 7, 1.0],   # dr -> bot
		[2, 3, 1.0],   # dr -> right
		[3, 11, 1.0],  # right -> fardr
		[11, 7, 1.0],  # fardr -> bot
		[6, 18, 1.0],  # top -> north crown (top lit limb arc)
		[6, 16, 1.0],  # top -> top-right limb arc
		[10, 12, 1.0], # farleft -> far_ul
		[12, 14, 1.0], # far_ul -> top-left outer arc
		[10, 13, 1.0], # farleft -> far_ll
		[13, 15, 1.0], # far_ll -> bot-left outer arc
		[7, 19, 1.0],  # bot -> south crown (bottom limb continuation)

		# --- Front hemisphere SECONDARY faint beaded arcs (exact 075s / 625s) ---
		[10, 0, 0.0],  # farleft -> center (faint equatorial line across dark side)
		[0, 3, 0.0],   # center -> right (faint equatorial line across lit side)
		[3, 17, 0.0],  # right -> right equator limb
		[10, 20, 0.0], # farleft -> far-left equator limb
		[4, 6, 0.0],   # tl -> top (faint upper arc)
		[5, 7, 0.0],   # botl -> bot (faint lower arc)
		[11, 17, 0.0], # fardr -> right equator limb (subtle limb tie)

		# --- Seamless 360° back-hemisphere web (same visual rhythm & density) ---
		[14, 18, 1.0], [14, 22, 1.0], [15, 19, 1.0], [15, 23, 1.0],
		[16, 26, 1.0], [16, 24, 1.0], [18, 28, 1.0], [19, 29, 1.0],
		[20, 12, 1.0], [20, 13, 1.0], [20, 27, 0.0],
		[17, 26, 1.0], [17, 25, 1.0],
		[21, 22, 1.0], [21, 23, 1.0], [21, 24, 1.0], [21, 25, 1.0],
		[22, 28, 1.0], [24, 28, 1.0], [23, 29, 1.0], [25, 29, 1.0],
		[22, 27, 1.0], [23, 27, 1.0], [24, 26, 1.0], [25, 11, 1.0],
		[27, 21, 0.0], [21, 17, 0.0], [22, 24, 0.0], [23, 25, 0.0],
	]

	return { "hubs": hubs, "edges": edges }


static func _sdir(sx: float, sy: float, front: bool) -> Vector3:
	var r2 := sx * sx + sy * sy
	var sz := sqrt(maxf(0.001, 1.0 - r2))
	if not front:
		sz = -sz
	return Vector3(sx, sy, sz).normalized()


static func _hub(dir: Vector3, spokes: int, rot: float, size: float, intensity: float, halo: float, has_star := true) -> Dictionary:
	return {
		"dir": dir.normalized(),
		"spokes": spokes,
		"rot": rot,
		"size": size,
		"intensity": intensity,
		"halo": halo,
		"has_star": has_star,
	}


func _build_corridors(hubs: Array[Dictionary], edges: Array) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	const SUBDIV := 32
	for e: Array in edges:
		var da: Vector3 = hubs[int(e[0])].dir
		var db: Vector3 = hubs[int(e[1])].dir
		var tier := float(e[2])
		var angle := da.angle_to(db)
		if angle < 0.001:
			continue
		var arc_total := angle * CORRIDOR_RADIUS

		var pts: Array[Vector3] = []
		var tans: Array[Vector3] = []
		pts.resize(SUBDIV + 1)
		tans.resize(SUBDIV + 1)
		for i in SUBDIV + 1:
			var t := float(i) / float(SUBDIV)
			var d := _slerp_vec(da, db, t)
			pts[i] = d * CORRIDOR_RADIUS
		for i in SUBDIV + 1:
			var prev := pts[maxi(i - 1, 0)]
			var next := pts[mini(i + 1, SUBDIV)]
			tans[i] = (next - prev).normalized()

		for i in SUBDIV:
			var t0 := float(i) / float(SUBDIV)
			var t1 := float(i + 1) / float(SUBDIV)
			var s0 := t0 * arc_total
			var s1 := t1 * arc_total
			var p0 := pts[i]
			var p1 := pts[i + 1]
			var n0 := p0.normalized()
			var n1 := p1.normalized()
			var tg0 := tans[i]
			var tg1 := tans[i + 1]

			# Quad (p0,-1) -> (p0,+1) -> (p1,+1) -> (p1,-1); vertex shader expands along view-perp.
			_emit_ribbon_vert(st, p0, n0, tg0, Vector2(s0, -1.0), Vector2(t0, tier))
			_emit_ribbon_vert(st, p0, n0, tg0, Vector2(s0, 1.0), Vector2(t0, tier))
			_emit_ribbon_vert(st, p1, n1, tg1, Vector2(s1, 1.0), Vector2(t1, tier))

			_emit_ribbon_vert(st, p0, n0, tg0, Vector2(s0, -1.0), Vector2(t0, tier))
			_emit_ribbon_vert(st, p1, n1, tg1, Vector2(s1, 1.0), Vector2(t1, tier))
			_emit_ribbon_vert(st, p1, n1, tg1, Vector2(s1, -1.0), Vector2(t1, tier))

	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "ArterialCorridors"
	mi.mesh = mesh
	var mat := ShaderMaterial.new()
	mat.shader = CORRIDOR_SHADER
	mat.set_shader_parameter(&"primary_color", Color(1.0, 0.90, 0.68))
	mat.set_shader_parameter(&"secondary_color", Color(0.96, 0.80, 0.54))
	mat.set_shader_parameter(&"primary_energy", 1.55)
	mat.set_shader_parameter(&"secondary_energy", 0.50)
	mat.set_shader_parameter(&"base_half_width", 0.028)
	mat.set_shader_parameter(&"min_px_half_width", 0.62)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	planet_root.add_child(mi)


static func _emit_ribbon_vert(st: SurfaceTool, pos: Vector3, normal: Vector3, tangent: Vector3, uv: Vector2, uv2: Vector2) -> void:
	st.set_normal(normal)
	st.set_tangent(Plane(tangent, 1.0))
	st.set_uv(uv)
	st.set_uv2(uv2)
	st.add_vertex(pos)


static func _slerp_vec(a: Vector3, b: Vector3, t: float) -> Vector3:
	var d := clampf(a.dot(b), -1.0, 1.0)
	var omega := acos(d)
	if omega < 0.0001:
		return a.lerp(b, t).normalized()
	var s := sin(omega)
	return (a * sin((1.0 - t) * omega) + b * sin(t * omega)) / s


func _build_hubs(hubs: Array[Dictionary]) -> void:
	var visible_hubs: Array[Dictionary] = []
	for h: Dictionary in hubs:
		if bool(h.get("has_star", true)):
			visible_hubs.append(h)

	# Tangent-plane 3D starburst hubs (foreshorten physically with sphere curvature).
	var star_mm := MultiMesh.new()
	star_mm.transform_format = MultiMesh.TRANSFORM_3D
	star_mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	star_mm.mesh = q
	star_mm.instance_count = visible_hubs.size()

	# Subtle small warm core glow so grazing limb hubs remain luminous without looking blobby.
	var core_mm := MultiMesh.new()
	core_mm.transform_format = MultiMesh.TRANSFORM_3D
	core_mm.use_custom_data = true
	core_mm.mesh = q
	core_mm.instance_count = visible_hubs.size()

	for i in visible_hubs.size():
		var h: Dictionary = visible_hubs[i]
		var n: Vector3 = h.dir
		var up_ref := Vector3.UP if absf(n.y) < 0.92 else Vector3.RIGHT
		var t_x := up_ref.cross(n).normalized()
		var t_y := n.cross(t_x).normalized()
		var sz := float(h.size)
		var basis := Basis(t_x * sz, t_y * sz, n)
		star_mm.set_instance_transform(i, Transform3D(basis, n * HUB_RADIUS))
		star_mm.set_instance_custom_data(i, Color(float(h.spokes), float(h.rot), float(h.intensity), float(h.halo)))

		var core_sz := sz * 0.16
		core_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * core_sz), n * (HUB_RADIUS + 0.03)))
		core_mm.set_instance_custom_data(i, Color(float(h.intensity) * 0.65, 0.90, 2.8, 1.0))

	var star_mmi := MultiMeshInstance3D.new()
	star_mmi.name = "HubStarbursts"
	star_mmi.multimesh = star_mm
	var star_mat := ShaderMaterial.new()
	star_mat.shader = HUB_SHADER
	star_mat.set_shader_parameter(&"core_color", Color(1.0, 0.96, 0.84))
	star_mat.set_shader_parameter(&"ray_color", Color(1.0, 0.78, 0.42))
	star_mat.set_shader_parameter(&"global_energy", 1.55)
	star_mmi.material_override = star_mat
	star_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	planet_root.add_child(star_mmi)

	var core_mmi := MultiMeshInstance3D.new()
	core_mmi.name = "HubCoreHalos"
	core_mmi.multimesh = core_mm
	var core_mat := ShaderMaterial.new()
	core_mat.shader = STAR_SHADER
	core_mat.set_shader_parameter(&"global_energy", 0.34)
	core_mat.set_shader_parameter(&"softness", 4.4)
	core_mmi.material_override = core_mat
	core_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	planet_root.add_child(core_mmi)


func _build_surface_micro_lights() -> void:
	# Sparse 1-pixel pale-warm surface lights scattered across Asset 31's Mantle shell
	# (visible across both the lit charcoal hemisphere and the dark shadow side in 075s/625s).
	var rng := RandomNumberGenerator.new()
	rng.seed = 3100412
	var count := 240
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	mm.mesh = q
	mm.instance_count = count

	for i in count:
		var u := rng.randf_range(-1.0, 1.0)
		var theta := rng.randf_range(0.0, TAU)
		var r_xy := sqrt(maxf(0.0, 1.0 - u * u))
		var dir := Vector3(r_xy * cos(theta), u, r_xy * sin(theta))
		var roll := rng.randf()
		var bright := 0.22 + pow(roll, 2.4) * 0.78
		var px_sz := 1.70 + pow(roll, 3.0) * 0.95
		var warm := rng.randf_range(0.35, 0.85)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.005), dir * SURFACE_LIGHT_RADIUS))
		mm.set_instance_custom_data(i, Color(bright, warm, px_sz, 1.0))

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "SurfaceMicroLights"
	mmi.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = STAR_SHADER
	mat.set_shader_parameter(&"global_energy", 0.88)
	mat.set_shader_parameter(&"softness", 5.8)
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	planet_root.add_child(mmi)


func _build_standalone_overlay() -> void:
	_hint_layer = CanvasLayer.new()
	_hint_layer.layer = 12
	add_child(_hint_layer)
	_hint_label = Label.new()
	_hint_label.position = Vector2(12, 520)
	_hint_label.text = "ASSET 31  ·  ORBITAL VIEW   |   [Drag / WASD] Orbit   [Scroll] Zoom   [1] 075s Wide   [2] 625s Close   [Space] Rotate   [H] Hide UI"
	_hint_label.add_theme_font_size_override(&"font_size", 8)
	_hint_label.add_theme_color_override(&"font_color", Color(0.82, 0.74, 0.60, 0.55))
	_hint_label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.85))
	_hint_layer.add_child(_hint_label)
