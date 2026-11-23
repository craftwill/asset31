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
	["foundry_bypass", [1678.0, 41000.0, -16.0], -90.0, 4.0],
	["175s_mining_shaft", [3257.0, 41000.0, -185.0], -126.0, -18.0],
	["175s_undercroft", [3260.0, 40780.05, -187.4], 0.0, -42.0],
	["bridge_midspan", [4524.0, 41000.0, 1.0], -78.0, 4.0],
	["tram_spur", [3045.5, 41000.05, 1.2], -132.0, -4.0],
	["350s_hydroponics", [6253.0, 41000.05, -112.0], 10.0, 2.0],
	["450s_preserve_up", [6600.0, 41000.08, -836.0], 0.0, 62.0],
	["475s_preserve", [6600.0, 41000.08, -836.0], 4.0, 10.0],
	["000m_crust", [3262.0, 0.08, -176.0], 42.0, 10.0],
	["375s_highway", [-458.2, 41016.05, 0.0], -90.0, -11.0],
	["400s_glass_terrace", [6922.0, 41028.05, 110.0], 112.0, -2.0],
	["twin_stack_horizon", [4420.0, 41000.05, -4.5], -6.0, 4.0],
	["exp077_station", [5988.5, 41000.08, -264.0], 26.0, 2.0],
	["stk0414_overlook", [6016.0, 41000.08, -14648.0], 185.0, 2.0],
]

# Quick-jump preview locations (Ctrl+1..0, -, =, Bksp, [, ], ;, ', ., /): [label, logical_pos, yaw_deg, pitch_deg]
const TELEPORTS := {
	KEY_1: ["1 · Home Shelter", [-1490.3, 41000.05, 112.7], 180.0, -6.0],
	KEY_2: ["2 · Side Street & Lift", [-1498.5, 41000.0, 96.0], -80.0, 4.0],
	KEY_3: ["3 · Roof Vista", [-1481.0, 41042.0, 98.5], -59.0, -6.0],
	KEY_4: ["4 · Market Street", [-1460.0, 41000.0, 4.0], 90.0, 6.0],
	KEY_5: ["5 · Foundry Approach (Route Choice)", [1678.0, 41000.0, -16.0], -90.0, 4.0],
	KEY_6: ["6 · Foundry Hall", [1858.0, 41000.0, -8.0], -122.0, 12.0],
	KEY_7: ["7 · Foundry North Bypass", [1892.0, 41000.05, -65.4], -90.0, 2.0],
	KEY_8: ["8 · East Edge Gate & Rail Tram", [3045.5, 41000.05, 1.2], -132.0, -4.0],
	KEY_9: ["9 · Mining Shaft 77-N Hub (175s)", [3257.0, 41000.0, -185.0], -126.0, -18.0],
	KEY_0: ["0 · Bridge Mid-Span Shelter (1.5 km)", [4536.0, 41000.0, 0.0], -78.0, 4.0],
	KEY_MINUS: ["- · STK-0413 Arrival", [6105.0, 41000.0, 4.0], -90.0, 10.0],
	KEY_EQUAL: ["= · Hydroponic Bay 413-A (350s · 700×600 m)", [6253.0, 41000.05, -112.0], 10.0, 2.0],
	KEY_BACKSPACE: ["Bksp · Shaft Undercroft 76-B (-220 m)", [3260.0, 40780.05, -183.0], 0.0, -14.0],
	KEY_BRACKETLEFT: ["[ · Ecological Preserve 413-B (475s · 1 km × 820 m)", [6600.0, 41000.08, -836.0], 4.0, 10.0],
	KEY_BRACKETRIGHT: ["] · Asset 31 Planetary Crust (0 m)", [3262.0, 0.08, -176.0], 42.0, 10.0],
	KEY_SEMICOLON: ["; · Megablock Highway Overpass (375s)", [-458.2, 41016.05, 0.0], -90.0, -11.0],
	KEY_APOSTROPHE: ["' · Misty Glass Terrace (400s)", [6922.0, 41028.05, 110.0], 112.0, -2.0],
	KEY_PERIOD: [". · EXP-077 Express Terminal (STA-0413-N)", [5988.5, 41000.08, -264.0], 26.0, 2.0],
	KEY_SLASH: ["/ · STK-0414 South Overlook (17.5 km North)", [6016.0, 41000.08, -14648.0], 185.0, 2.0],
}

var world_def: Dictionary
var stacks: Array[StackRuntime] = []
var connections: Array[ConnectionRuntime] = []
var player: PlayerController
var atmosphere: Atmosphere
var ambience: AmbienceManager
var survival: SurvivalComponent
var player_inventory: InventoryGrid
var interaction: InteractionSystem
var hud: HudOverlay
var inventory_ui: InventoryUI
var map_ui: MapUI
var journal_ui: JournalUI
var planet_layer: CanvasLayer
var planet_vp: SubViewport
var planet_view: PlanetView
var planet_ui_layer: CanvasLayer
var planet_open := false
var post_material: ShaderMaterial
var debug_label: Label
var _stream_timer := 0.0
var _hud_timer := 0.0
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
	for arg in OS.get_cmdline_user_args():
		if arg == "--zfight-lint" or arg == "--selftest":
			SliceMaterials.record_lint = true
	ItemDB.ensure_loaded()
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
		elif st.kind == "mining_shaft":
			add_child(MiningShaft.build(st))
		elif st.kind == "mining_surface":
			add_child(MiningSurface.build(st))
		elif st.kind == "deep_relay":
			var p: Array = st.position
			add_child(DeepRelayLift.build(float(p[0]), float(p[2])))
		elif st.kind == "distant_stack":
			add_child(DistantStack.build(st))
		elif st.kind == "inter_stack_express":
			add_child(InterStackExpress.build())
	_spawn_player()
	_setup_gameplay()
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


func _setup_gameplay() -> void:
	player_inventory = InventoryGrid.new(6, 5)
	player_inventory.auto_add("ration_tin", 1)
	player_inventory.auto_add("condensate_can", 1)
	survival = SurvivalComponent.new()
	survival.name = "Survival"
	add_child(survival)
	player.hard_landing.connect(survival.apply_fall_injury)
	interaction = InteractionSystem.new()
	interaction.name = "Interaction"
	add_child(interaction)
	interaction.setup(player.camera)
	hud = HudOverlay.new()
	hud.name = "HUD"
	add_child(hud)
	hud.update_survival(survival)
	survival.stats_changed.connect(func() -> void: hud.update_survival(survival))
	survival.status_message.connect(func(msg: String) -> void: hud.show_toast(msg))
	interaction.prompt_changed.connect(func(txt: String) -> void: hud.set_prompt(txt))
	inventory_ui = InventoryUI.new()
	inventory_ui.name = "InventoryUI"
	add_child(inventory_ui)
	inventory_ui.setup(player_inventory, survival)
	map_ui = MapUI.new()
	map_ui.name = "MapUI"
	add_child(map_ui)
	journal_ui = JournalUI.new()
	journal_ui.name = "JournalUI"
	add_child(journal_ui)
	journal_ui.mark_discovered("home")
	interaction.container_activated.connect(_open_container_ui)
	interaction.note_activated.connect(_open_note_ui)
	interaction.tram_console_activated.connect(_on_tram_console_activated)
	interaction.relay_console_activated.connect(_on_relay_console_activated)
	interaction.express_console_activated.connect(_on_express_console_activated)
	inventory_ui.closed.connect(_on_modal_closed)
	map_ui.closed.connect(_on_modal_closed)
	journal_ui.closed.connect(_on_modal_closed)
	_build_planet_view_layer()


func _build_planet_view_layer() -> void:
	planet_layer = CanvasLayer.new()
	planet_layer.name = "PlanetViewLayer"
	planet_layer.layer = 8
	planet_layer.visible = false
	add_child(planet_layer)

	var svc := SubViewportContainer.new()
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	planet_layer.add_child(svc)

	planet_vp = SubViewport.new()
	planet_vp.name = "PlanetSubViewport"
	planet_vp.own_world_3d = true
	planet_vp.size = Vector2i(960, 540)
	planet_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	svc.add_child(planet_vp)

	planet_view = PlanetView.new()
	planet_view.name = "PlanetView"
	planet_view.exit_requested.connect(_close_planet_view)
	planet_vp.add_child(planet_view)

	planet_ui_layer = CanvasLayer.new()
	planet_ui_layer.name = "PlanetUILayer"
	planet_ui_layer.layer = 16
	planet_ui_layer.visible = false
	add_child(planet_ui_layer)

	var hint := Label.new()
	hint.position = Vector2(12, 520)
	hint.text = "ASSET 31  ·  ORBITAL VIEW (SPACE)   |   [Drag/WASD] Orbit   [Scroll] Zoom   [1] 075s Wide   [2] 625s Close   [Space] Rotate   [H] Hide UI   [P/Esc] Mantle"
	hint.add_theme_font_size_override(&"font_size", 8)
	hint.add_theme_color_override(&"font_color", Color(0.84, 0.76, 0.62, 0.56))
	hint.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.85))
	planet_ui_layer.add_child(hint)


func _open_planet_view(show_ui := true) -> void:
	if planet_open:
		return
	planet_open = true
	player.input_enabled = false
	interaction.enabled = false
	if hud != null:
		hud.set_prompt("")
		hud.set_hud_visible(false)
	planet_layer.visible = true
	planet_ui_layer.visible = show_ui
	planet_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	planet_view.visible = true
	get_viewport().disable_3d = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_planet_view() -> void:
	if not planet_open:
		return
	planet_open = false
	get_viewport().disable_3d = false
	planet_layer.visible = false
	planet_ui_layer.visible = false
	planet_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	planet_view.visible = false
	if hud != null and not _autopilot:
		hud.set_hud_visible(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_on_modal_closed()


func _open_container_ui(c: LootContainer) -> void:
	player.input_enabled = false
	interaction.enabled = false
	hud.set_prompt("")
	inventory_ui.open_container(c)


func _open_pack_ui() -> void:
	player.input_enabled = false
	interaction.enabled = false
	hud.set_prompt("")
	inventory_ui.open_pack()


func _open_map_ui() -> void:
	player.input_enabled = false
	interaction.enabled = false
	hud.set_prompt("")
	var lp := WorldOrigin.to_logical(player.position)
	map_ui.open_map(_region_name(lp), player.rotation.y)


func _open_journal_ui() -> void:
	player.input_enabled = false
	interaction.enabled = false
	hud.set_prompt("")
	journal_ui.open_journal()


func _open_note_ui(note: ReadableNote) -> void:
	player.input_enabled = false
	interaction.enabled = false
	if journal_ui != null:
		journal_ui.record_note(note.note_id, note.title, note.body_text)
	hud.open_note(note.title, note.body_text)


func _on_relay_console_activated(console: RelayConsole) -> void:
	if console.relay == null:
		return
	var relay := console.relay
	if not relay.powered:
		if player_inventory.consume_item_id("salvaged_relay"):
			relay.power_on()
			hud.show_toast("Salvaged Relay installed — EL-DEEP-00 (41 km Descent) ONLINE", 3.5)
		else:
			hud.show_toast("Needs Salvaged Relay (check Undercroft Cache, Bridge Shelter, or Arrival Locker)", 3.5)
		return
	var msg := relay.activate_console(console.station_side)
	if msg != "":
		hud.show_toast(msg, 3.0)


func _on_tram_console_activated(console: TramConsole) -> void:
	if console.tram == null:
		return
	var tram := console.tram
	if not tram.powered:
		if player_inventory.consume_item_id("fuse_cell"):
			tram.power_on()
			hud.show_toast("Fuse Cell installed — TRAM-077 ONLINE", 3.2)
		else:
			hud.show_toast("Needs Fuse Cell (check Gate Shelter, Foundry Bypass, or Shaft Undercroft)", 3.5)
		return
	var msg := tram.activate_console(console.station_side)
	if msg != "":
		hud.show_toast(msg, 2.8)


func _on_express_console_activated(console: ExpressConsole) -> void:
	if console.express == null:
		return
	var msg := console.express.activate_console(console.station_side)
	if msg != "":
		hud.show_toast(msg, 3.6)


func _on_modal_closed() -> void:
	if not _autopilot:
		player.input_enabled = true
		interaction.enabled = true


func _place_player(logical: Array, yaw: float, pitch: float) -> void:
	for node in get_tree().get_nodes_in_group(DeepRelayLift.GROUP):
		var r := node as DeepRelayLift
		if r != null:
			r._release_rider()
	for node in get_tree().get_nodes_in_group(InterStackExpress.GROUP):
		var ex := node as InterStackExpress
		if ex != null:
			ex._release_rider()
	player.riding_transport = false
	WorldOrigin.recenter_on_logical(float(logical[0]), float(logical[1]), float(logical[2]))
	player.position = WorldOrigin.to_render_arr(logical)
	player.velocity = Vector3.ZERO
	player.reset_fall_tracking()
	player.set_look(yaw, pitch)
	_update_streaming()
	if atmosphere != null:
		atmosphere.set_mood(_atmosphere_mood(PackedFloat64Array([float(logical[0]), float(logical[1]), float(logical[2])])), 0.0, true)


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


func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var fke := event as InputEventKey
		if fke.pressed and not fke.echo:
			var fcode := fke.physical_keycode if fke.physical_keycode != KEY_NONE else fke.keycode
			if fcode == KEY_F11 or (fcode == KEY_ENTER and fke.alt_pressed):
				_toggle_fullscreen()
				get_viewport().set_input_as_handled()
				return
	if planet_open:
		if event is InputEventKey:
			var pke := event as InputEventKey
			if pke.pressed and not pke.echo:
				var pcode := pke.physical_keycode if pke.physical_keycode != KEY_NONE else pke.keycode
				if pcode == KEY_H:
					planet_ui_layer.visible = not planet_ui_layer.visible
					get_viewport().set_input_as_handled()
					return
				elif pcode == KEY_F7:
					post_material.set_shader_parameter(&"enabled", not bool(post_material.get_shader_parameter(&"enabled")))
					get_viewport().set_input_as_handled()
					return
				elif pcode == KEY_F3:
					debug_label.visible = not debug_label.visible
					get_viewport().set_input_as_handled()
					return
		if planet_view.handle_input_event(event):
			get_viewport().set_input_as_handled()
		return
	if (inventory_ui != null and inventory_ui.is_open) or (map_ui != null and map_ui.is_open) or (journal_ui != null and journal_ui.is_open):
		return
	if hud != null and hud.note_open:
		if event.is_action_pressed(&"interact") or event.is_action_pressed(&"release_mouse") or event.is_action_pressed(&"inventory"):
			hud.close_note()
			_on_modal_closed()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo and ke.ctrl_pressed and not _autopilot:
			var code := ke.physical_keycode if ke.physical_keycode != KEY_NONE else ke.keycode
			if code >= KEY_KP_0 and code <= KEY_KP_9:
				code = KEY_0 + (code - KEY_KP_0)
			elif code == KEY_KP_SUBTRACT:
				code = KEY_MINUS
			elif code == KEY_KP_ADD:
				code = KEY_EQUAL
			if TELEPORTS.has(code):
				var t: Array = TELEPORTS[code]
				_place_player(t[1], deg_to_rad(float(t[2])), deg_to_rad(float(t[3])))
				if hud != null:
					hud.show_toast("Teleport: %s" % String(t[0]))
				get_viewport().set_input_as_handled()
				return
			elif code == KEY_B and ambience != null:
				ambience.trigger_void_bell()
				if hud != null:
					hud.show_toast("The Void Bell tolls across the Mantle chasm...", 4.0)
				get_viewport().set_input_as_handled()
				return
	if event.is_action_pressed(&"interact") and player.input_enabled:
		interaction.try_interact()
	elif event.is_action_pressed(&"inventory") and player.input_enabled:
		_open_pack_ui()
	elif event.is_action_pressed(&"toggle_map") and player.input_enabled:
		_open_map_ui()
	elif event.is_action_pressed(&"toggle_journal") and player.input_enabled:
		_open_journal_ui()
	elif event.is_action_pressed(&"toggle_planet_view") and player.input_enabled:
		_open_planet_view()
	elif event.is_action_pressed(&"toggle_lamp") and player.input_enabled:
		player.work_lamp.visible = not player.work_lamp.visible
		if hud != null:
			hud.show_toast("Work-lamp %s" % ("ON" if player.work_lamp.visible else "OFF"), 1.4)
	elif event.is_action_pressed(&"toggle_debug"):
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
	if survival != null and survival.enabled and player != null and not planet_open:
		var lp := WorldOrigin.to_logical(player.position)
		var sprinting := player.input_enabled and Input.is_action_pressed(&"sprint") and Vector2(player.velocity.x, player.velocity.z).length() > 2.2
		survival.tick(delta, sprinting, _environment_condition(lp))
		if atmosphere != null:
			atmosphere.set_mood(_atmosphere_mood(lp), delta)
		_hud_timer -= delta
		if _hud_timer <= 0.0:
			_hud_timer = 0.5
			hud.update_survival(survival)
			_check_landmark_discovery(lp)
	elif player != null and atmosphere != null:
		atmosphere.set_mood(_atmosphere_mood(WorldOrigin.to_logical(player.position)), delta)
	if _autopilot:
		_autopilot_step(delta)


func _atmosphere_mood(lp: PackedFloat64Array) -> String:
	if lp[1] < 600.0:
		return "crust"
	if lp[0] >= 6120.0 and lp[0] <= 7080.0 and lp[2] >= -1700.0 and lp[2] <= -700.0 and lp[1] >= 40960.0 and lp[1] <= 41860.0:
		return "preserve"
	if lp[0] >= 6140.0 and lp[0] <= 6840.0 and lp[2] >= -700.0 and lp[2] <= -100.0 and absf(lp[1] - 41000.0) < 40.0:
		return "hydroponics"
	if lp[0] >= 6340.0 and lp[0] <= 6950.0 and lp[2] >= 95.0 and lp[2] <= 430.0 and lp[1] >= 40990.0 and lp[1] <= 41620.0:
		return "glass_terrace"
	if lp[0] >= 5860.0 and lp[0] <= 6080.0 and lp[2] <= -220.0 and lp[2] >= -14820.0 and lp[1] >= 40500.0:
		return "gap"
	if lp[0] >= 2850.0 and lp[0] <= 6220.0 and absf(lp[2]) <= 450.0 and lp[1] >= 40500.0:
		return "gap"
	return "default"


func _check_landmark_discovery(lp: PackedFloat64Array) -> void:
	if journal_ui == null:
		return
	var id := ""
	var label := ""
	if lp[1] < 450.0 and lp[0] >= 2400.0 and lp[0] <= 4100.0:
		id = "crust"; label = "Asset 31 Planetary Crust (0 m)"
	elif lp[0] >= 5950.0 and lp[0] <= 6060.0 and lp[2] <= -14620.0 and lp[2] >= -14750.0:
		id = "stk0414"; label = "STK-0414 South Terminal (17.5 km North)"
	elif lp[0] >= 5950.0 and lp[0] <= 6040.0 and lp[2] <= -230.0 and lp[2] >= -340.0:
		id = "express_south"; label = "STA-0413-N Inter-Stack Express Terminal"
	elif lp[0] >= 6120.0 and lp[0] <= 7080.0 and lp[2] >= -1700.0 and lp[2] <= -700.0:
		id = "preserve"; label = "Ecological Preserve 413-B"
	elif lp[0] >= 6140.0 and lp[0] <= 6840.0 and lp[2] >= -700.0 and lp[2] <= -100.0:
		id = "hydroponics"; label = "Hydroponic Bay 413-A"
	elif lp[0] >= 6340.0 and lp[0] <= 6940.0 and lp[2] >= 110.0 and lp[2] <= 430.0:
		id = "glass_terrace"; label = "Glass Curtain Terrace 413-S"
	elif lp[0] >= 6040.0 and lp[0] <= 6400.0 and absf(lp[2]) <= 400.0:
		id = "arrival"; label = "STK-0413 West Arrival"
	elif lp[0] >= 3100.0 and lp[0] <= 3420.0 and lp[2] >= -340.0 and lp[2] <= -20.0:
		id = "shaft"; label = "Mining Shaft 77-N"
	elif lp[0] >= 3040.0 and lp[0] <= 6040.0 and absf(lp[2]) <= 15.0:
		id = "gap"; label = "BR-077-A Inter-Stack Span"
	elif lp[0] >= 2740.0 and lp[0] <= 3040.0 and absf(lp[2]) <= 300.0:
		id = "edge"; label = "East Edge Gate"
	elif lp[0] >= 1690.0 and lp[0] <= 2110.0 and absf(lp[2]) <= 72.0:
		id = "foundry"; label = "Foundry Hall"
	elif lp[0] >= -1100.0 and lp[0] <= 1100.0 and absf(lp[2]) <= 42.0:
		id = "highway"; label = "Trunk Route 77-E (Megablock Highway)"
	elif lp[0] >= -1900.0 and lp[0] <= -1100.0 and absf(lp[2]) <= 32.0:
		id = "market"; label = "Market Street"
	if id != "" and journal_ui.mark_discovered(id) and hud != null:
		hud.show_toast("Logged Landmark: %s  [J]" % label, 3.0)


func _environment_condition(lp: PackedFloat64Array) -> String:
	var x := lp[0]
	var y := lp[1]
	var z := lp[2]
	# Asset 31 Planetary Crust Survey Shelter Booth (0 m).
	if absf(y) < 12.0 and x >= 3249.0 and x <= 3257.0 and z >= -192.0 and z <= -186.0:
		return "SHELTER"
	if absf(y - 41000.0) > 40.0:
		return ""
	# Home shelter room.
	if x >= -1491.6 and x <= -1488.6 and z >= 112.1 and z <= 116.6:
		return "SHELTER"
	# Foundry sheltered north service bypass.
	if x >= 1694.0 and x <= 2106.0 and z >= -68.8 and z <= -62.0:
		return "SHELTER"
	# Departure / arrival shelter booths.
	if (x >= 2972.0 and x <= 2980.0 and z >= -48.0 and z <= -40.0) \
			or (x >= 6099.0 and x <= 6108.0 and z >= -48.0 and z <= -40.0):
		return "SHELTER"
	# Bridge mid-span windbreak shelter alcove (bridge midpoint x = 4540, shelter sx = +12).
	if x >= 4546.0 and x <= 4558.0 and z >= -10.8 and z <= -6.0:
		return "SHELTER"
	# Hydroponic Bay 413-A, Ecological Preserve 413-B, Glass Curtain Terrace 413-S & EXP-077 terminals/train.
	if (lp[0] >= 6120.0 and lp[0] <= 7080.0 and lp[2] >= -1700.0 and lp[2] <= -100.0) \
			or (lp[0] >= 6340.0 and lp[0] <= 6940.0 and lp[2] >= 110.0 and lp[2] <= 430.0) \
			or (lp[0] >= 5965.0 and lp[0] <= 6050.0 and lp[2] <= -230.0 and lp[2] >= -14750.0):
		return "SHELTER"
	# Radiant heat near the molten crucible pour on the direct foundry floor.
	if x >= 1855.0 and x <= 1945.0 and z >= -16.0 and z <= 36.0:
		return "HEAT"
	# Exposed 3 km inter-stack bridge span.
	if x >= 3045.0 and x <= 6035.0 and absf(z) <= 6.2:
		return "EXPOSED"
	return ""


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
	if lp[1] < 450.0 and lp[0] >= 2400.0 and lp[0] <= 4100.0:
		return "CRUST-00 (Asset 31 Planetary Surface · 0 m)"
	if lp[0] >= 6120.0 and lp[0] <= 7080.0 and lp[2] >= -1700.0 and lp[2] <= -700.0:
		return "STK-0413 / Ecological Preserve 413-B"
	if lp[0] >= 5950.0 and lp[0] <= 6060.0 and lp[2] <= -14620.0 and lp[2] >= -14750.0:
		return "STK-0414 / South Terminal STA-0414-S (17.5 km North)"
	if lp[0] >= 5950.0 and lp[0] <= 6040.0 and lp[2] <= -230.0 and lp[2] >= -340.0:
		return "STA-0413-N (Inter-Stack Express EXP-077)"
	if lp[0] >= 5960.0 and lp[0] <= 6010.0 and lp[2] < -340.0 and lp[2] > -14620.0:
		return "VD-077-N (Abyssal Express Viaduct · EXP-077)"
	if lp[0] >= 6140.0 and lp[0] <= 6840.0 and lp[2] >= -700.0 and lp[2] <= -100.0:
		return "STK-0413 / Hydroponic Bay 413-A"
	if lp[0] >= 6340.0 and lp[0] <= 6940.0 and lp[2] >= 110.0 and lp[2] <= 430.0:
		return "STK-0413 / Glass Curtain Terrace 413-S"
	if lp[0] >= -1100.0 and lp[0] <= 1100.0 and absf(lp[2]) <= 40.0 and absf(lp[1] - 41000.0) < 60.0:
		return "STK-0412 / Trunk Route 77-E"
	for s in stacks:
		var p := s.logical_to_local(lp)
		if absf(p.x) <= s.size_x() * 0.5 and absf(p.z) <= s.size_z() * 0.5:
			return "%s / %s" % [s.def.id, s.def.floors[0].name]
	for c in connections:
		if c.contains_local(c.logical_to_local(lp)):
			return "%s (%s)" % [c.def.id, c.def.name]
	if lp[0] >= 3040.0 and lp[0] <= 3420.0 and lp[2] >= -340.0 and lp[2] <= -20.0:
		if lp[1] < 40820.0:
			return "EL-CYL-77 (Undercroft 76-B)"
		return "EL-CYL-77 (Mining Shaft 77-N)"
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
		"ASSET31 dev  [F3 overlay  F5 save  F9 load  F6 snap:%s  F7 dither  Ctrl+1..0 jump]" % ["off", "subtle", "heavy"][_retro_mode],
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


func _save(path := SAVE_PATH) -> void:
	var lp := WorldOrigin.to_logical(player.position)
	var containers := {}
	for node in get_tree().get_nodes_in_group(LootContainer.GROUP):
		var c := node as LootContainer
		if c != null:
			containers[c.container_id] = c.serialize()
	var trams := {}
	for node in get_tree().get_nodes_in_group(BridgeTram.GROUP):
		var t := node as BridgeTram
		if t != null:
			trams[t.tram_id] = t.serialize()
	var relays := {}
	for node in get_tree().get_nodes_in_group(DeepRelayLift.GROUP):
		var r := node as DeepRelayLift
		if r != null:
			relays[r.relay_id] = r.serialize()
	var expresses := {}
	for node in get_tree().get_nodes_in_group(InterStackExpress.GROUP):
		var ex := node as InterStackExpress
		if ex != null:
			expresses[ex.express_id] = ex.serialize()
	var data := {
		"version": 2,
		"player": { "logical": [lp[0], lp[1], lp[2]], "yaw": player.rotation.y, "pitch": player.get_pitch() },
		"survival": survival.serialize(),
		"inventory": player_inventory.serialize(),
		"containers": containers,
		"trams": trams,
		"relays": relays,
		"expresses": expresses,
		"journal": journal_ui.serialize() if journal_ui != null else {},
	}
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  "))
	print("[Asset31] saved at logical %s" % [lp])
	if hud != null:
		hud.show_toast("Saved expedition state")


func _load(path := SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		return false
	var p: Dictionary = data.player
	_place_player(p.logical, float(p.yaw), float(p.pitch))
	if data.has("survival"):
		survival.deserialize(data.survival)
		hud.update_survival(survival)
	if data.has("inventory"):
		player_inventory.deserialize(data.inventory)
	if data.has("containers"):
		var cmap: Dictionary = data.containers
		for node in get_tree().get_nodes_in_group(LootContainer.GROUP):
			var c := node as LootContainer
			if c != null and cmap.has(c.container_id):
				c.deserialize(cmap[c.container_id])
	if data.has("trams"):
		var tmap: Dictionary = data.trams
		for node in get_tree().get_nodes_in_group(BridgeTram.GROUP):
			var t := node as BridgeTram
			if t != null and tmap.has(t.tram_id):
				t.deserialize(tmap[t.tram_id])
	if data.has("relays"):
		var rmap: Dictionary = data.relays
		for node in get_tree().get_nodes_in_group(DeepRelayLift.GROUP):
			var r := node as DeepRelayLift
			if r != null and rmap.has(r.relay_id):
				r.deserialize(rmap[r.relay_id])
	if data.has("expresses"):
		var emap: Dictionary = data.expresses
		for node in get_tree().get_nodes_in_group(InterStackExpress.GROUP):
			var ex := node as InterStackExpress
			if ex != null and emap.has(ex.express_id):
				ex.deserialize(emap[ex.express_id])
	if data.has("journal") and journal_ui != null:
		journal_ui.deserialize(data.journal)
	print("[Asset31] loaded logical %s" % [p.logical])
	if hud != null:
		hud.show_toast("Loaded expedition state")
	return true


# ---------------------------------------------------------------- test hooks

func _handle_cmdline() -> void:
	var shots_dir := ""
	var planet_shots_dir := ""
	for arg in OS.get_cmdline_user_args():
		if arg == "--no-post":
			post_material.set_shader_parameter(&"enabled", false)
		elif arg.begins_with("--snap="):
			_retro_mode = int(arg.get_slice("=", 1))
			_apply_retro_mode()
		elif arg == "--selftest":
			_run_selftest()
			return
		elif arg == "--zfight-lint":
			ZFightLint.run(self, 5)
			get_tree().quit(0)
			return
		elif arg.begins_with("--autopilot"):
			_autopilot = true
			survival.enabled = false
			hud.set_hud_visible(false)
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
		elif arg.begins_with("--planet-shots="):
			planet_shots_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--shots="):
			shots_dir = arg.get_slice("=", 1)
	if planet_shots_dir != "":
		_run_planet_shots(planet_shots_dir)
		return
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
	hud.set_hud_visible(false)
	survival.enabled = false
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
	# Also capture one UI verification shot showing the Tarkov grid inventory open in the home shelter.
	_place_player(SHOTS[0][1], deg_to_rad(SHOTS[0][2]), deg_to_rad(SHOTS[0][3]))
	var home_cab: LootContainer = null
	for node in get_tree().get_nodes_in_group(LootContainer.GROUP):
		if (node as LootContainer).container_id == "CONT-HOME-CABINET":
			home_cab = node as LootContainer
			break
	if home_cab != null:
		inventory_ui.open_container(home_cab)
		for i in 10:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join("ui_inventory.png"))
		inventory_ui.close_ui()
	map_ui.open_map("STK-0412 / Floor 77", deg_to_rad(-90.0))
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("ui_map.png"))
	map_ui.close_map()
	await _capture_planet_shots(dir)
	get_tree().quit(0)


func _run_planet_shots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	debug_label.visible = false
	hud.set_hud_visible(false)
	survival.enabled = false
	player.input_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await _capture_planet_shots(dir)
	get_tree().quit(0)


func _capture_planet_shots(dir: String) -> void:
	_open_planet_view(false)
	planet_view.auto_rotate = false
	var presets := [
		["075s_planet_wide", 0],
		["625s_planet_close", 1],
	]
	for item: Array in presets:
		if int(item[1]) == 0:
			planet_view.apply_preset_075s()
		else:
			planet_view.apply_preset_625s()
		for i in 20:
			await get_tree().process_frame
		var t0 := Time.get_ticks_usec()
		for i in 90:
			await get_tree().process_frame
		var ms := (Time.get_ticks_usec() - t0) / 90000.0
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(dir.path_join("%s.png" % String(item[0])))
		print("[Shots] %-20s %6.2f ms/frame (%4d fps)  draws %4d  prims %5dk" % [
			String(item[0]), ms, int(1000.0 / maxf(ms, 0.001)),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0)])
	_close_planet_view()


## Automated Phase 3/4/5 verification: containers, notes, grid inventory
## drag/rotation/stacking, consumables, env conditions, and save/load round-trip.
func _run_selftest() -> void:
	var fail := func(msg: String) -> void:
		push_error("[Selftest] FAIL: %s" % msg)
		get_tree().quit(1)
	var conts := get_tree().get_nodes_in_group(LootContainer.GROUP)
	if conts.size() < 10:
		fail.call("expected >= 10 loot containers, got %d" % conts.size())
		return
	var notes := get_tree().get_nodes_in_group(&"readable_notes")
	if notes.size() < 8:
		fail.call("expected >= 8 readable notes, got %d" % notes.size())
		return
	var tram_nodes := get_tree().get_nodes_in_group(BridgeTram.GROUP)
	if tram_nodes.is_empty():
		fail.call("BridgeTram missing")
		return
	var tram := tram_nodes[0] as BridgeTram
	var relay_nodes := get_tree().get_nodes_in_group(DeepRelayLift.GROUP)
	if relay_nodes.is_empty():
		fail.call("DeepRelayLift missing")
		return
	var relay := relay_nodes[0] as DeepRelayLift
	var home_cab: LootContainer = null
	for node in conts:
		var c := node as LootContainer
		if c.container_id == "CONT-HOME-CABINET":
			home_cab = c
	if home_cab == null or home_cab.grid.entries.is_empty():
		fail.call("CONT-HOME-CABINET missing or empty")
		return
	# Verify grid rotation, placement collision, stacking, and cross-grid transfer.
	var g := InventoryGrid.new(4, 3)
	var u1 := g.place_item("water_flask", 0, 0, false, 1) # 1x2
	if u1 < 0 or g.can_place(0, 1, 1, 1):
		fail.call("grid collision check failed")
		return
	var u2 := g.place_item("water_flask", 1, 0, true, 1) # rotated 2x1
	if u2 < 0 or g.can_place(2, 0, 1, 1):
		fail.call("grid rotation check failed")
		return
	if not InventoryGrid.transfer_to_cell(g, u2, g, 0, 0, false):
		fail.call("stack merge failed")
		return
	if g.entries.size() != 1 or int(g.entries[0].count) != 2:
		fail.call("expected merged stack of 2")
		return
	# Verify transfer from home cabinet -> player pack.
	var start_pack := player_inventory.total_item_count()
	var cab_e := home_cab.grid.entries[0]
	var cab_uid := int(cab_e.uid)
	if not InventoryGrid.transfer_to_cell(home_cab.grid, cab_uid, player_inventory, 3, 0, false):
		fail.call("container->player transfer failed")
		return
	if player_inventory.total_item_count() <= start_pack:
		fail.call("player pack count did not increase after transfer")
		return
	# Verify survival consumption + environmental condition zones.
	survival.hunger = 50.0
	survival.thirst = 40.0
	survival.health = 65.0
	if not survival.use_item("ration_tin") or survival.hunger <= 70.0:
		fail.call("ration_tin consumption failed")
		return
	if not survival.use_item("water_flask") or survival.thirst <= 80.0:
		fail.call("water_flask consumption failed")
		return
	if not survival.use_item("bandage_roll") or survival.health <= 90.0:
		fail.call("bandage_roll consumption failed")
		return
	if _environment_condition(PackedFloat64Array([-1490.0, 41000.0, 114.0])) != "SHELTER":
		fail.call("home shelter condition check failed")
		return
	if _environment_condition(PackedFloat64Array([1900.0, 41000.0, -65.0])) != "SHELTER":
		fail.call("foundry bypass shelter condition check failed")
		return
	if _environment_condition(PackedFloat64Array([1900.0, 41000.0, 10.0])) != "HEAT":
		fail.call("foundry heat condition check failed")
		return
	if _environment_condition(PackedFloat64Array([4200.0, 41000.0, 0.0])) != "EXPOSED":
		fail.call("bridge exposed condition check failed")
		return
	if _environment_condition(PackedFloat64Array([4552.0, 41000.0, -8.0])) != "SHELTER":
		fail.call("mid-span bridge shelter condition check failed")
		return
	if _environment_condition(PackedFloat64Array([6253.0, 41000.0, -340.0])) != "SHELTER":
		fail.call("hydroponics shelter condition check failed")
		return
	if _environment_condition(PackedFloat64Array([6600.0, 41000.0, -1100.0])) != "SHELTER":
		fail.call("preserve shelter condition check failed")
		return
	if _environment_condition(PackedFloat64Array([3253.0, 0.1, -189.0])) != "SHELTER":
		fail.call("crust shelter condition check failed")
		return
	# Verify Fuse Cell repair & BridgeTram + Salvaged Relay & DeepRelayLift dispatch + persistence.
	player_inventory.auto_add("fuse_cell", 1)
	if not player_inventory.consume_item_id("fuse_cell"):
		fail.call("fuse_cell consume failed")
		return
	tram.power_on()
	tram.activate_console(0)
	if not tram.powered or not tram.moving:
		fail.call("BridgeTram failed to engage after Fuse Cell install")
		return
	# Verify DeepRelayLift full 41 km round-trip (41,000 m -> 0 m -> 41,000 m) with real player aboard
	# across ~80 vertical rebases AND verify human-safe G-limits (|a| <= 4.6 m/s^2, felt 0.53..1.47 G).
	_place_player([relay.lx, DeepRelayLift.TOP_LY + 0.05, relay.lz], 0.0, 0.0)
	relay.car_ly = DeepRelayLift.TOP_LY
	relay.target_ly = DeepRelayLift.TOP_LY
	relay.moving = false
	relay._vel = 0.0
	relay._accel = 0.0
	relay.car_anchor.set_logical(relay.lx, relay.car_ly, relay.lz)
	relay.power_on()
	relay.activate_console(0)
	if not relay.powered or not relay.moving or relay.target_ly > 1.0:
		fail.call("DeepRelayLift failed to start 41 km descent from Floor 77")
		return
	var dt := 1.0 / 60.0
	var steps := 0
	var max_abs_a := 0.0
	var max_floor_err := 0.0
	while relay.moving and steps < 18000:
		var prev_v := relay._vel
		WorldOrigin._physics_process(dt)
		relay._physics_process(dt)
		player._physics_process(dt)
		max_abs_a = maxf(max_abs_a, absf(relay._vel - prev_v) / dt)
		max_floor_err = maxf(max_floor_err, absf(player.global_position.y - relay.car_anchor.global_position.y - 0.02))
		steps += 1
	var lp_bot := WorldOrigin.to_logical(player.position)
	if relay.moving or player.riding_transport or absf(relay.car_ly - DeepRelayLift.BOT_LY) > 0.1 or absf(lp_bot[1] - DeepRelayLift.BOT_LY) > 0.1:
		fail.call("DeepRelayLift 41 km descent rider mismatch: car=%.2f player_y=%.2f steps=%d" % [relay.car_ly, lp_bot[1], steps])
		return
	var down_s := steps * dt
	# Now ride all 41 km back UP to Floor 77 (41,000 m).
	relay.activate_console(0)
	if not relay.moving or absf(relay.target_ly - DeepRelayLift.TOP_LY) > 1.0:
		fail.call("DeepRelayLift failed to start 41 km ascent from Crust 0 m")
		return
	steps = 0
	while relay.moving and steps < 18000:
		var prev_v := relay._vel
		WorldOrigin._physics_process(dt)
		relay._physics_process(dt)
		player._physics_process(dt)
		max_abs_a = maxf(max_abs_a, absf(relay._vel - prev_v) / dt)
		max_floor_err = maxf(max_floor_err, absf(player.global_position.y - relay.car_anchor.global_position.y - 0.02))
		steps += 1
	var lp_top := WorldOrigin.to_logical(player.position)
	if relay.moving or player.riding_transport or absf(relay.car_ly - DeepRelayLift.TOP_LY) > 0.1 or absf(lp_top[1] - DeepRelayLift.TOP_LY) > 0.1:
		fail.call("DeepRelayLift 41 km ascent rider mismatch: car=%.2f player_y=%.2f steps=%d" % [relay.car_ly, lp_top[1], steps])
		return
	if max_abs_a > DeepRelayLift.MAX_ACCEL + 0.5 or max_floor_err > 0.05:
		fail.call("DeepRelayLift safety check failed: max_a=%.2f m/s^2, max_floor_err=%.3f m" % [max_abs_a, max_floor_err])
		return
	print("[Selftest] DeepRelayLift 41 km round-trip OK: %.0f s down, %.0f s up, peak |a| = %.2f m/s^2 (%.2f G delta), max floor error = %.4f m" % [down_s, steps * dt, max_abs_a, max_abs_a / 9.81, max_floor_err])
	# Verify InterStackExpress (EXP-077) full 14.4 km round-trip (STA-0413-N -> STA-0414-S -> STA-0413-N)
	# with human-safe <= 0.17 G S-curve kinematics and zero floor/rider error across 28 WorldOrigin rebases!
	var expresses := get_tree().get_nodes_in_group(InterStackExpress.GROUP)
	if expresses.is_empty():
		fail.call("InterStackExpress EXP-077 missing")
		return
	var exp := expresses[0] as InterStackExpress
	# Flush queued Near_* chunks from earlier synchronous selftest teleports before running EXP-077 loop.
	for s in stacks:
		for k in s.loaded.keys():
			s.loaded[k].free()
		s.loaded.clear()
	_place_player([InterStackExpress.TRACK_LX, InterStackExpress.TRACK_LY + 0.05, InterStackExpress.SOUTH_LZ - 20.0], 0.0, 0.0)
	exp.activate_console(0)
	if not exp.moving or not player.riding_transport or absf(exp.target_lz - InterStackExpress.NORTH_LZ) > 1.0:
		fail.call("EXP-077 failed to depart STA-0413-N with rider")
		return
	var ex_steps := 0
	var ex_max_a := 0.0
	var ex_max_err := 0.0
	while exp.moving and ex_steps < 18000:
		var pv := exp._vel
		WorldOrigin._physics_process(dt)
		exp._physics_process(dt)
		player._physics_process(dt)
		ex_max_a = maxf(ex_max_a, absf(exp._vel - pv) / dt)
		ex_max_err = maxf(ex_max_err, absf(player.global_position.y - exp.train_anchor.global_position.y - 0.02))
		ex_steps += 1
	var lp_n := WorldOrigin.to_logical(player.position)
	if exp.moving or player.riding_transport or absf(exp.train_lz - InterStackExpress.NORTH_LZ) > 0.1 or absf(lp_n[2] - (InterStackExpress.NORTH_LZ - 20.0)) > 0.2:
		fail.call("EXP-077 north transit rider mismatch: train_lz=%.2f player_z=%.2f steps=%d" % [exp.train_lz, lp_n[2], ex_steps])
		return
	var north_s := ex_steps * dt
	exp.activate_console(0)
	if not exp.moving or absf(exp.target_lz - InterStackExpress.SOUTH_LZ) > 1.0:
		fail.call("EXP-077 failed to depart STA-0414-S southbound")
		return
	ex_steps = 0
	while exp.moving and ex_steps < 18000:
		var pv := exp._vel
		WorldOrigin._physics_process(dt)
		exp._physics_process(dt)
		player._physics_process(dt)
		ex_max_a = maxf(ex_max_a, absf(exp._vel - pv) / dt)
		ex_max_err = maxf(ex_max_err, absf(player.global_position.y - exp.train_anchor.global_position.y - 0.02))
		ex_steps += 1
	var lp_s := WorldOrigin.to_logical(player.position)
	if exp.moving or player.riding_transport or absf(exp.train_lz - InterStackExpress.SOUTH_LZ) > 0.1 or absf(lp_s[2] - (InterStackExpress.SOUTH_LZ - 20.0)) > 0.2:
		fail.call("EXP-077 south return rider mismatch: train_lz=%.2f player_z=%.2f steps=%d" % [exp.train_lz, lp_s[2], ex_steps])
		return
	if ex_max_a > InterStackExpress.MAX_ACCEL + 0.35 or ex_max_err > 0.05:
		fail.call("EXP-077 safety check failed: max_a=%.2f m/s^2, max_floor_err=%.3f m" % [ex_max_a, ex_max_err])
		return
	print("[Selftest] EXP-077 14.4 km round-trip OK: %.0f s north, %.0f s south, peak |a| = %.2f m/s^2 (%.2f G), max floor error = %.4f m" % [north_s, ex_steps * dt, ex_max_a, ex_max_a / 9.81, ex_max_err])
	# Verify save/load round-trip across origin rebases, survival, inventory, tram, deep relay, journal, and looted containers.
	var tmp_save := "user://asset31_selftest_save.json"
	_place_player([3262.0, 0.08, -176.0], 0.7, 0.1)
	journal_ui.mark_discovered("crust")
	home_cab.mark_opened()
	var saved_cab_n := home_cab.grid.total_item_count()
	var saved_pack_n := player_inventory.total_item_count()
	_save(tmp_save)
	# Mutate everything before loading back.
	_place_player([0.0, 41000.0, 0.0], 0.0, 0.0)
	survival.hunger = 10.0
	player_inventory.clear()
	home_cab.grid.clear()
	home_cab.opened = false
	tram.powered = false
	tram.moving = false
	relay.powered = false
	relay.moving = false
	journal_ui.discovered.clear()
	if not _load(tmp_save):
		fail.call("save/load failed to read file")
		return
	var lp := WorldOrigin.to_logical(player.position)
	if absf(lp[0] - 3262.0) > 0.05 or absf(lp[1] - 0.08) > 0.05 or absf(lp[2] - (-176.0)) > 0.05:
		fail.call("loaded logical position mismatch: %s" % [lp])
		return
	if absf(survival.hunger - 82.0) > 0.5:
		fail.call("loaded survival hunger mismatch: %.2f" % survival.hunger)
		return
	if player_inventory.total_item_count() != saved_pack_n or home_cab.grid.total_item_count() != saved_cab_n or not home_cab.opened or not tram.powered or not relay.powered or not journal_ui.discovered.has("crust"):
		fail.call("loaded inventory/container/tram/relay/journal state mismatch")
		return
	if planet_view == null or planet_view.planet_root == null or planet_view.camera == null:
		fail.call("PlanetView missing or incomplete")
		return
	if ambience == null or ambience._bell_stream == null or AudioServer.get_bus_index(&"VoidBell") == -1:
		fail.call("The Void Bell (religious_long_bell.mp3) or VoidBell FX bus missing")
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_save))
	ZFightLint.run(self, 2)
	print("[Selftest] PASS: %d containers, %d notes, BridgeTram, DeepRelayLift (41 km), PlanetView, Journal, grid inventory, consumables, env zones, save/load round-trip OK." % [conts.size(), notes.size()])
	get_tree().quit(0)


func _exit_tree() -> void:
	SliceMaterials.clear_caches()


## Saves consecutive motion frames at three stability-critical viewpoints
## (market ground/tube, roof vista distant lights/LOD, bridge wall/handrail).
func _run_motion(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	debug_label.visible = false
	hud.set_hud_visible(false)
	survival.enabled = false
	player.input_enabled = false
	var seqs := [
		["market", [-1720.0, 41000.0, 9.0], -80.0, -12.0, Vector3(0.11, 0, 0), 0.35],
		["vista", [-1481.0, 41042.0, 98.5], -59.0, -6.0, Vector3(0.06, 0, 0.04), 0.45],
		["bridge", [4300.0, 41000.0, 3.0], 90.0, 10.0, Vector3(-0.18, 0, 0), 0.3],
	]
	for seq: Array in seqs:
		_place_player(seq[1], deg_to_rad(float(seq[2])), deg_to_rad(float(seq[3])))
		for i in 30:
			await get_tree().process_frame
		for f in 6:
			player.position += seq[4] as Vector3
			player.rotation.y += deg_to_rad(float(seq[5]))
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(dir.path_join("%s_%02d.png" % [seq[0], f]))
	# Also verify orbital PlanetView stability during slow planetary rotation.
	_open_planet_view(false)
	planet_view.auto_rotate = false
	planet_view.apply_preset_625s()
	for i in 12:
		await get_tree().process_frame
	for f in 6:
		planet_view.set_planet_yaw(deg_to_rad(float(f) * 0.6))
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join("planet_%02d.png" % f))
	_close_planet_view()
	get_tree().quit(0)


# ---------------------------------------------------------------- review tour
# Each segment: caption, start (logical), duration s, walk waypoints [x, z]
# (logical), walk speed, look keys [t, yaw_deg, pitch_deg] (empty = look along
# the walking direction).
const TOUR := [
	["Home shelter  (ref 000s)", [-1490.3, 41000.05, 112.7], 12.0, [[-1491.0, 112.9], [-1494.5, 112.9], [-1499.0, 112.9]], 1.6,
		[[0.0, 180.0, -6.0], [3.0, 122.0, -2.0], [5.5, 165.0, -14.0], [7.5, 92.0, 0.0], [12.0, 90.0, 0.0]], 7.5],
	["Side street to the market  (refs 575s, 550s)", [-1500.0, 41000.0, 38.0], 17.0, [[-1500.0, 6.0], [-1430.0, 4.0]], 4.4, []],
	["Trunk Route 77-E Megablock Highway  (ref 375s)", [-458.2, 41016.05, 0.0], 8.0, [], 0.0,
		[[0.0, -90.0, -14.0], [8.0, -90.0, 6.0]]],
	["Roof of the home block  (refs 300s, 100s)", [-1481.0, 41042.0, 98.5], 8.0, [], 0.0,
		[[0.0, -25.0, -6.0], [8.0, -100.0, -3.0]]],
	["Industrial approach & sheltered bypass choice", [1670.0, 41000.0, -16.0], 7.0, [[1688.0, -16.0]], 2.6,
		[[0.0, -90.0, 4.0], [4.0, -72.0, 3.0], [7.0, -96.0, 5.0]]],
	["Foundry hall on the industrial route  (ref 025s)", [1790.0, 41000.0, -4.0], 12.0, [[1868.0, -4.0]], 3.5,
		[[0.0, -90.0, 6.0], [5.0, -110.0, 14.0], [12.0, -98.0, 8.0]]],
	["Stack edge gate and bridge  (refs 125s, 225s)", [2985.0, 41000.0, 2.5], 14.0, [[3060.0, 2.5]], 4.6,
		[[0.0, -90.0, 4.0], [5.5, -90.0, 2.0], [9.5, -150.0, -22.0], [14.0, -138.0, 0.0]]],
	["Twin-Stack Canyon & 17.5 km Distant STK-0414", [4420.0, 41000.05, -4.5], 8.0, [], 0.0,
		[[0.0, -32.0, 4.0], [8.0, 14.0, 4.0]]],
	["Bridge mid-span gantry & shelter  (1.5 km)", [4516.0, 41000.0, 1.0], 8.0, [[4550.0, 1.0]], 4.0,
		[[0.0, -86.0, 6.0], [4.5, -62.0, 4.0], [8.0, -25.0, 2.0]]],
	["Arrival in STK-0413  (ref 500s)", [6065.0, 41000.0, 1.0], 9.0, [[6150.0, 1.0]], 3.0,
		[[0.0, -90.0, 10.0], [9.0, -60.0, 14.0]]],
	["Misty Glass Curtain Terrace 413-S  (ref 400s)", [6922.0, 41028.05, 110.0], 8.0, [], 0.0,
		[[0.0, 122.0, -4.0], [8.0, 96.0, 8.0]]],
	["Inter-Stack Express EXP-077 Terminal (STA-0413-N)", [5988.5, 41000.08, -264.0], 8.0, [], 0.0,
		[[0.0, 40.0, 0.0], [8.0, 8.0, 4.0]]],
	["STK-0414 South Overlook — 17.5 km Back at Twin-Stack", [6016.0, 41000.08, -14648.0], 8.0, [], 0.0,
		[[0.0, 170.0, 2.0], [8.0, 200.0, 2.0]]],
]


func _run_tour() -> void:
	debug_label.visible = false
	hud.set_hud_visible(false)
	survival.enabled = false
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
