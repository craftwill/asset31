extends Node3D
## Slice entry point: builds the world from data, spawns the player, drives
## streaming, atmosphere, ambience, the retro output layer, the dev overlay
## and quick save/load.
##
## Command-line (after `--`):
##   --autopilot[=speed]   walk the data route (room -> market -> foundry -> bridge
##                         -> neighbour stack), report, quit
##   --shots=DIR           render the reference-matched viewpoints to DIR/*.png and quit
##   --no-post / --snap=N  disable dither / set vertex snap mode (0 off, 1 subtle, 2 heavy)

const WORLD_DATA := "res://data/world/mantle_slice.json"
const SAVE_PATH := "user://asset31_save.json"
const RETRO_POST := preload("res://shaders/retro_post.gdshader")
const STREAM_INTERVAL := 0.25

# name (reference frame), logical position, yaw deg, pitch deg
const SHOTS := [
	["000s_room", [-1490.3, 41000.02, 112.65], 180.0, -8.0],
	["575s_side_street", [-1500.0, 41000.0, 150.0], 0.0, 3.0],
	["550s_market", [-1460.0, 41000.0, 4.0], 90.0, 6.0],
	["300s_roof_vista", [-1481.0, 41042.0, 98.5], -59.0, -6.0],
	["025s_foundry", [1858.0, 41000.0, -8.0], -122.0, 12.0],
	["edge_gate", [2965.0, 41000.0, 14.0], -90.0, 3.0],
	["125s_bridge_shaft", [3600.0, 41000.0, 4.5], -148.0, 4.0],
	["225s_gap_down", [4300.0, 41000.0, -5.6], -30.0, -38.0],
	["375s_look_back", [4300.0, 41000.0, 3.0], 90.0, 10.0],
	["500s_arrival", [6200.0, 41000.0, 35.0], 100.0, 14.0],
]

var world_def: Dictionary
var stacks: Array[StackRuntime] = []
var connections: Array[ConnectionRuntime] = []
var player: PlayerController
var atmosphere: Atmosphere
var ambience: AmbienceManager
var post_material: ShaderMaterial
var debug_label: Label
var _stream_timer := 0.0
var _retro_mode := 1
var _autopilot := false
var _route: Array = []
var _route_i := 0
var _autopilot_log_timer := 0.0
var _autopilot_t := 0.0
var _autopilot_best := INF
var _autopilot_stall := 0.0


func _enter_tree() -> void:
	InputSetup.ensure()


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	world_def = JSON.parse_string(FileAccess.get_file_as_string(WORLD_DATA))
	atmosphere = Atmosphere.new()
	atmosphere.name = "Atmosphere"
	add_child(atmosphere)
	var buildings := 0
	for sd: Dictionary in world_def.stacks:
		var s := StackRuntime.build(sd)
		add_child(s)
		stacks.append(s)
		buildings += s.building_count
	for cd: Dictionary in world_def.connections:
		var c := ConnectionRuntime.build(cd)
		add_child(c)
		connections.append(c)
	for st: Dictionary in world_def.get("structures", []):
		if st.kind == "elevator_shaft":
			add_child(ElevatorShaft.build(st))
	_spawn_player()
	atmosphere.follow(player)
	ambience = AmbienceManager.new()
	ambience.name = "Ambience"
	add_child(ambience)
	ambience.setup(world_def, player.camera)
	player.footstep.connect(ambience.footstep)
	_build_overlays()
	_apply_retro_mode()
	_update_streaming()
	print("[Asset31] world built in %d ms: %d stacks, %d buildings, %d connections" % [
		Time.get_ticks_msec() - t0, stacks.size(), buildings, connections.size()])
	_handle_cmdline()


func _spawn_player() -> void:
	player = PlayerController.new()
	player.name = "Player"
	player.add_to_group(&"player")
	add_child(player)
	player.fatal_fall.connect(_on_fatal_fall)
	var ps: Dictionary = world_def.player_start
	_place_player(ps.position, deg_to_rad(float(ps.yaw_deg)), 0.0)
	WorldOrigin.tracked = player
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _place_player(logical: Array, yaw: float, pitch: float) -> void:
	WorldOrigin.recenter_on_logical(float(logical[0]), float(logical[1]), float(logical[2]))
	player.position = WorldOrigin.to_render_arr(logical)
	player.velocity = Vector3.ZERO
	player.set_look(yaw, pitch)
	_update_streaming()


func _build_overlays() -> void:
	var post_layer := CanvasLayer.new()
	post_layer.layer = 10
	add_child(post_layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_material = ShaderMaterial.new()
	post_material.shader = RETRO_POST
	rect.material = post_material
	post_layer.add_child(rect)

	var dbg_layer := CanvasLayer.new()
	dbg_layer.layer = 20
	add_child(dbg_layer)
	debug_label = Label.new()
	debug_label.position = Vector2(6, 4)
	debug_label.add_theme_font_size_override(&"font_size", 9)
	debug_label.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.6))
	debug_label.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	debug_label.visible = OS.is_debug_build()
	dbg_layer.add_child(debug_label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_debug"):
		debug_label.visible = not debug_label.visible
	elif event.is_action_pressed(&"cycle_retro"):
		_retro_mode = (_retro_mode + 1) % 3
		_apply_retro_mode()
	elif event.is_action_pressed(&"toggle_post"):
		post_material.set_shader_parameter(&"enabled", not bool(post_material.get_shader_parameter(&"enabled")))
	elif event.is_action_pressed(&"quick_save"):
		_save()
	elif event.is_action_pressed(&"quick_load"):
		_load()


## 0 = vertex snap off, 1 = subtle (render-res grid), 2 = heavy (PS1-like 320x180 grid).
func _apply_retro_mode() -> void:
	var res := Vector2(960, 540) if _retro_mode < 2 else Vector2(320, 180)
	RenderingServer.global_shader_parameter_set(&"retro_snap_resolution", res)
	RenderingServer.global_shader_parameter_set(&"retro_snap_strength", 0.0 if _retro_mode == 0 else 1.0)


func _physics_process(delta: float) -> void:
	_stream_timer -= delta
	if _stream_timer <= 0.0:
		_stream_timer = STREAM_INTERVAL
		_update_streaming()
	if _autopilot:
		_autopilot_step(delta)


func _process(_delta: float) -> void:
	if debug_label.visible:
		debug_label.text = _debug_text()


func _update_streaming() -> void:
	if player == null:
		return
	var lp := WorldOrigin.to_logical(player.position)
	for s in stacks:
		s.update_streaming(lp)


func _region_name(lp: PackedFloat64Array) -> String:
	for s in stacks:
		var p := s.logical_to_local(lp)
		if absf(p.x) <= s.size_x() * 0.5 and absf(p.z) <= s.size_z() * 0.5:
			return "%s / %s" % [s.def.id, s.def.floors[0].name]
	for c in connections:
		if c.contains_local(c.logical_to_local(lp)):
			return "%s (%s)" % [c.def.id, c.def.name]
	return "open Mantle"


func _debug_text() -> String:
	var lp := WorldOrigin.to_logical(player.position)
	var ap: Array = world_def.arrival_point
	var to_arrival := Vector2(float(ap[0]) - lp[0], float(ap[2]) - lp[2]).length()
	var near := 0
	for s in stacks:
		near += s.loaded.size()
	var hv := Vector2(player.velocity.x, player.velocity.z).length()
	return "\n".join([
		"ASSET31 dev  [F3 overlay  F5 save  F9 load  F6 snap:%s  F7 dither]" % ["off", "subtle", "heavy"][_retro_mode],
		"fps %d   draws %d   prims %dk" % [
			Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0)],
		"logical  x %.2f  y %.2f  z %.2f m" % [lp[0], lp[1], lp[2]],
		"render   %s   origin sector %s   rebases %d" % [player.position.snapped(Vector3.ONE * 0.01), WorldOrigin.origin_sector, WorldOrigin.rebase_count],
		"region   %s" % _region_name(lp),
		"altitude %.0f m above original surface (roof %d m)" % [lp[1], int(world_def.mantle_roof_altitude)],
		"to STK-0413 arrival  %.2f km   speed %.1f m/s   near chunks %d" % [to_arrival / 1000.0, hv, near],
	])


func _on_fatal_fall(height: float) -> void:
	print("[Asset31] fatal fall (%.0f m) - returning to last safe ground" % height)
	if player.last_safe_logical.size() == 3:
		var p := player.last_safe_logical
		_place_player([p[0], p[1] + 0.2, p[2]], player.rotation.y, player.get_pitch())


func _save() -> void:
	var lp := WorldOrigin.to_logical(player.position)
	var data := {
		"version": 1,
		"player": { "logical": [lp[0], lp[1], lp[2]], "yaw": player.rotation.y, "pitch": player.get_pitch() },
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  "))
	print("[Asset31] saved at logical %s" % [lp])


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	var p: Dictionary = data.player
	_place_player(p.logical, float(p.yaw), float(p.pitch))
	print("[Asset31] loaded logical %s" % [p.logical])


# ---------------------------------------------------------------- test hooks

func _handle_cmdline() -> void:
	var shots_dir := ""
	for arg in OS.get_cmdline_user_args():
		if arg == "--no-post":
			post_material.set_shader_parameter(&"enabled", false)
		elif arg.begins_with("--snap="):
			_retro_mode = int(arg.get_slice("=", 1))
			_apply_retro_mode()
		elif arg.begins_with("--autopilot"):
			_autopilot = true
			_route = world_def.route
			player.input_enabled = false
			player.speed_override = float(arg.get_slice("=", 1)) if arg.contains("=") else player.sprint_speed
			print("[Autopilot] start, speed %.1f m/s, %d waypoints" % [player.speed_override, _route.size()])
		elif arg == "--tour":
			_run_tour()
			return
		elif arg.begins_with("--motion="):
			_run_motion(arg.get_slice("=", 1))
			return
		elif arg.begins_with("--shots="):
			shots_dir = arg.get_slice("=", 1)
	if shots_dir != "":
		_run_shots(shots_dir)


func _autopilot_step(delta: float) -> void:
	_autopilot_t += delta
	_autopilot_log_timer -= delta
	var lp := WorldOrigin.to_logical(player.position)
	var ap: Array = world_def.arrival_point
	var wp: Array = _route[_route_i]
	var to := Vector2(float(wp[0]) - lp[0], float(wp[1]) - lp[2])
	if to.length() < 0.6 and _route_i < _route.size() - 1:
		_route_i += 1
		_autopilot_best = INF
		print("[Autopilot] waypoint %d reached at t=%.0fs (%s)" % [_route_i, _autopilot_t, _region_name(lp)])
		return
	var dir := to.normalized()
	player.autopilot_dir = Vector3(dir.x, 0, dir.y)
	# Stall detection: no progress toward the waypoint for 20 s.
	if to.length() < _autopilot_best - 0.5:
		_autopilot_best = to.length()
		_autopilot_stall = 0.0
	else:
		_autopilot_stall += delta
	if _autopilot_log_timer <= 0.0:
		_autopilot_log_timer = 30.0
		print("[Autopilot] t=%5.0fs  logical x=%8.1f y=%8.2f z=%7.2f  sector=%s  region=%s  sound=%s" % [
			_autopilot_t, lp[0], lp[1], lp[2], WorldOrigin.origin_sector, _region_name(lp), ambience.current_profile])
	if _route_i == _route.size() - 1 and lp[0] >= float(ap[0]) - 0.6 and player.is_on_floor():
		print("[Autopilot] ARRIVED at %s after %.0f s simulated (%d rebases). Altitude drift %.3f m." % [
			_region_name(lp), _autopilot_t, WorldOrigin.rebase_count, lp[1] - float(ap[1])])
		get_tree().quit(0)
	elif _autopilot_stall >= 20.0 or absf(lp[1] - float(ap[1])) > 50.0:
		print("[Autopilot] FAILED: stuck or fell at logical %s heading to waypoint %d" % [lp, _route_i])
		get_tree().quit(1)


func _run_shots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	debug_label.visible = false
	player.input_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for shot: Array in SHOTS:
		_place_player(shot[1], deg_to_rad(shot[2]), deg_to_rad(shot[3]))
		for i in 40:
			await get_tree().process_frame
		var t0 := Time.get_ticks_usec()
		for i in 120:
			await get_tree().process_frame
		var ms := (Time.get_ticks_usec() - t0) / 120000.0
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path := dir.path_join("%s.png" % shot[0])
		img.save_png(path)
		print("[Shots] %-20s %6.2f ms/frame (%4d fps)  draws %4d  prims %5dk" % [
			shot[0], ms, int(1000.0 / ms),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0)])
	get_tree().quit(0)


func _exit_tree() -> void:
	SliceMaterials.clear_caches()


## Moves the camera slowly along the market street and saves consecutive
## frames, to inspect ground stability (swimming, z-fighting, crawling).
func _run_motion(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	debug_label.visible = false
	player.input_enabled = false
	_place_player([-1720.0, 41000.0, 9.0], deg_to_rad(-80.0), deg_to_rad(-12.0))
	for i in 40:
		await get_tree().process_frame
	for f in 8:
		player.position += Vector3(0.11, 0, 0.0)
		player.rotation.y += deg_to_rad(0.35)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join("m%02d.png" % f))
	get_tree().quit(0)


# ---------------------------------------------------------------- review tour
# Each segment: caption, start (logical), duration s, walk waypoints [x, z]
# (logical), walk speed, look keys [t, yaw_deg, pitch_deg] (empty = look along
# the walking direction).
const TOUR := [
	["Home shelter  (ref 000s)", [-1490.3, 41000.05, 112.7], 12.0, [[-1491.0, 112.9], [-1494.5, 112.9], [-1499.0, 112.9]], 1.6,
		[[0.0, 180.0, -6.0], [3.0, 122.0, -2.0], [5.5, 165.0, -14.0], [7.5, 92.0, 0.0], [12.0, 90.0, 0.0]], 7.5],
	["Side street to the market  (refs 575s, 550s)", [-1500.0, 41000.0, 38.0], 17.0, [[-1500.0, 6.0], [-1430.0, 4.0]], 4.4, []],
	["Roof of the home block  (refs 300s, 100s)", [-1481.0, 41042.0, 98.5], 8.0, [], 0.0,
		[[0.0, -25.0, -6.0], [8.0, -100.0, -3.0]]],
	["Foundry hall on the industrial route  (ref 025s)", [1790.0, 41000.0, -4.0], 12.0, [[1868.0, -4.0]], 3.5,
		[[0.0, -90.0, 6.0], [5.0, -110.0, 14.0], [12.0, -98.0, 8.0]]],
	["Stack edge gate and bridge  (refs 125s, 225s)", [2985.0, 41000.0, 2.5], 14.0, [[3060.0, 2.5]], 4.6,
		[[0.0, -90.0, 4.0], [5.5, -90.0, 2.0], [9.5, -150.0, -22.0], [14.0, -138.0, 0.0]]],
	["Looking back at the home stack  (ref 375s)", [4300.0, 41000.0, 3.0], 7.0, [], 0.0,
		[[0.0, 70.0, 6.0], [7.0, 110.0, 14.0]]],
	["Elevator shaft in the gap  (refs 175s, 225s)", [4300.0, 41000.0, -4.6], 6.0, [], 0.0,
		[[0.0, -15.0, -10.0], [6.0, -40.0, -38.0]]],
	["Arrival in the neighbouring stack  (ref 500s)", [6065.0, 41000.0, 1.0], 9.0, [[6150.0, 1.0]], 3.0,
		[[0.0, -90.0, 10.0], [9.0, -60.0, 14.0]]],
]


func _run_tour() -> void:
	debug_label.visible = false
	player.input_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade)
	var caption := Label.new()
	caption.position = Vector2(14, 510)
	caption.add_theme_font_size_override(&"font_size", 12)
	caption.add_theme_color_override(&"font_color", Color(1.0, 0.88, 0.65))
	caption.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override(&"shadow_offset_x", 1)
	caption.add_theme_constant_override(&"shadow_offset_y", 1)
	layer.add_child(caption)
	for seg: Array in TOUR:
		var start: Array = seg[1]
		var dur: float = seg[2]
		var walk: Array = seg[3]
		var keys: Array = seg[5]
		var walk_delay: float = seg[6] if seg.size() > 6 else 0.0
		var yaw0: float = keys[0][1] if not keys.is_empty() else 0.0
		var pitch0: float = keys[0][2] if not keys.is_empty() else 0.0
		if keys.is_empty() and not walk.is_empty():
			var d := Vector2(float(walk[0][0]) - float(start[0]), float(walk[0][1]) - float(start[2]))
			yaw0 = rad_to_deg(atan2(-d.x, -d.y))
		_place_player(start, deg_to_rad(yaw0), deg_to_rad(pitch0))
		player.speed_override = float(seg[4])
		caption.text = seg[0]
		var wi := 0
		var t := 0.0
		var yaw := deg_to_rad(yaw0)
		while t < dur:
			var dt := get_process_delta_time()
			t += dt
			fade.color.a = clampf(1.0 - t / 0.5, 0.0, 1.0) + clampf((t - (dur - 0.5)) / 0.5, 0.0, 1.0)
			var lp := WorldOrigin.to_logical(player.position)
			var dir := Vector3.ZERO
			if wi < walk.size() and t >= walk_delay:
				var to := Vector2(float(walk[wi][0]) - lp[0], float(walk[wi][1]) - lp[2])
				if to.length() < 0.5:
					wi += 1
				else:
					dir = Vector3(to.normalized().x, 0, to.normalized().y)
			player.autopilot_dir = dir
			if keys.is_empty():
				if dir != Vector3.ZERO:
					yaw = lerp_angle(yaw, atan2(-dir.x, -dir.z), 1.0 - exp(-3.0 * dt))
				player.set_look(yaw, deg_to_rad(4.0))
			else:
				var k := _tour_key(keys, t)
				player.set_look(deg_to_rad(k.x), deg_to_rad(k.y))
			await get_tree().process_frame
		player.autopilot_dir = Vector3.ZERO
		player.velocity = Vector3.ZERO
	get_tree().quit(0)


func _tour_key(keys: Array, t: float) -> Vector2:
	for i in range(keys.size() - 1):
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if t <= float(b[0]):
			var u := smoothstep(float(a[0]), float(b[0]), t)
			return Vector2(lerpf(a[1], b[1], u), lerpf(a[2], b[2], u))
	var last: Array = keys[keys.size() - 1]
	return Vector2(last[1], last[2])
