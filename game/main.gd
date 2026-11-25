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
## Synced by Steam Auto-Cloud (WinAppDataRoaming/Asset31, pattern asset31_save.json);
## keep the name and folder stable. See docs/STEAM_CLOUD.md.
const SAVE_PATH := "user://asset31_save.json"
## Where saves lived before user:// was pinned to %APPDATA%/Asset31 (relative to OS.get_data_dir()).
const LEGACY_SAVE_REL := "Godot/app_userdata/Asset31/asset31_save.json"
const RETRO_POST := preload("res://shaders/retro_post.gdshader")
const STREAM_INTERVAL := 0.25
## STK-0413 top floor (frozen plate, Hydroponic Bay 413-A, Preserve 413-B).
const UPPER_LY := 59100.0
## A Mantle day runs from 00:00:00 to 24:39:35.
const DAY_SECONDS := 24.0 * 3600.0 + 39.0 * 60.0 + 35.0

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
	["350s_hydroponics", [6253.0, 59100.05, -112.0], 10.0, 2.0],
	["450s_preserve_up", [6600.0, 59100.08, -836.0], 0.0, 62.0],
	["475s_preserve", [6600.0, 59100.08, -836.0], 4.0, 10.0],
	["000m_crust", [3262.0, 0.08, -176.0], 42.0, 10.0],
	["375s_highway", [-458.2, 41016.05, 0.0], -90.0, -11.0],
	["400s_glass_terrace", [6922.0, 41028.05, 110.0], 112.0, -2.0],
	["twin_stack_horizon", [4420.0, 41000.05, -4.5], -6.0, 4.0],
	["exp077_station", [5988.5, 41000.08, -264.0], 26.0, 2.0],
	["stk0414_overlook", [6016.0, 41000.08, -14648.0], 185.0, 2.0],
	["void_bell_sanctum", [6007.7, 41000.08, -14874.0], 15.0, 10.0],
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
	KEY_EQUAL: ["= · Hydroponic Bay 413-A (350s · 700×600 m)", [6253.0, 59100.05, -112.0], 10.0, 2.0],
	KEY_BACKSPACE: ["Bksp · Shaft Undercroft 76-B (-220 m)", [3260.0, 40780.05, -183.0], 0.0, -14.0],
	KEY_BRACKETLEFT: ["[ · Ecological Preserve 413-B (475s · 1 km × 820 m)", [6600.0, 59100.08, -836.0], 4.0, 10.0],
	KEY_BRACKETRIGHT: ["] · Asset 31 Planetary Crust (0 m)", [3262.0, 0.08, -176.0], 42.0, 10.0],
	KEY_SEMICOLON: ["; · Megablock Highway Overpass (375s)", [-458.2, 41016.05, 0.0], -90.0, -11.0],
	KEY_APOSTROPHE: ["' · Misty Glass Terrace (400s)", [6922.0, 41028.05, 110.0], 112.0, -2.0],
	KEY_COMMA: [", · STK-0413 Deep Residential (enterable rooms)", [7705.0, 41000.05, 312.5], 0.0, 2.0],
	KEY_K: ["K · Squatters' Works 413-U", [7404.5, 41000.05, 627.0], 200.0, 6.0],
	KEY_L: ["L · The Barren Blocks (abandoned extremity)", [7705.0, 41000.05, 1010.0], 180.0, 3.0],
	KEY_U: ["U · Return Line 413-S (never-built extremity)", [7705.0, 41000.05, 2550.0], 150.0, 2.0],
	KEY_P: ["P · The Empty Plates (between city and steel)", [7705.0, 41000.05, 1760.0], 180.0, 2.0],
	KEY_Y: ["Y · The Unclosed Edge (void) & Brink Lift", [7705.0, 41000.05, 2975.0], 180.0, -4.0],
	KEY_T: ["T · Top Floor, Unheated (59,100 m)", [7705.0, 59100.05, 2985.0], 0.0, 0.0],
	KEY_PERIOD: [". · EXP-077 Express Terminal (STA-0413-N)", [5988.5, 41000.08, -264.0], 26.0, 2.0],
	KEY_SLASH: ["/ · STK-0414 South Overlook (17.5 km North)", [6016.0, 41000.08, -14648.0], 185.0, 2.0],
	KEY_BACKSLASH: ["\\ · Great Belfry of the Continuum (Void Bell Sanctum)", [6007.7, 41000.08, -14874.0], 15.0, 10.0],
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
var clock_day := 1
var clock_seconds := 6.0 * 3600.0
var _hud_timer := 0.0
var _retro_mode := 1
var _autopilot := false
var _extra_shots: Array = []
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
	_migrate_legacy_save()
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
		elif st.kind == "void_bell_sanctum":
			add_child(VoidBellSanctum.build())
		elif st.kind == "brink_lift":
			add_child(DeepRelayLift.build_custom({
				"id": st.id, "x": st.position[0], "z": st.position[2],
				"bottom": float(st.position[1]) + 0.05, "top": float(st.top) + 0.05,
				"title": "BRINK LIFT",
				"bottom_name": "Floor 77 Unclosed Edge (41,000 m)",
				"top_name": "Top Floor, Unheated (59,100 m)",
				"strata": [[57000.0, "TOP FLOORS · UNHEATED"], [50000.0, "UPPER MANTLE · SEALED"], [43000.0, "STK-0413 SOUTH FACE · OPEN"], [0.0, "FLOOR 77 · THE BRINK"]],
			}))
		elif st.kind == "frozen_floor":
			for sd: Dictionary in world_def.stacks:
				if sd.id == st.stack:
					add_child(FrozenFloor.build(st, sd))
	add_child(AbyssFloor.build(world_def))
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
			hud.show_toast("Salvaged Relay installed — %s ONLINE" % relay.relay_id, 3.5)
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
	if console.sanctum != null and console.sanctum.has_method(&"activate_console"):
		var smsg := String(console.sanctum.call(&"activate_console", ambience))
		if smsg != "":
			hud.show_toast(smsg, 4.0)
		return
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
	# STK-0413 top floor (59,100 m): the warm bay and preserve, the frozen plate around them.
	if lp[0] >= 6120.0 and lp[0] <= 7080.0 and lp[2] >= -1700.0 and lp[2] <= -700.0 and lp[1] >= UPPER_LY - 40.0 and lp[1] <= UPPER_LY + 860.0:
		return "preserve"
	if lp[0] >= 6140.0 and lp[0] <= 6840.0 and lp[2] >= -700.0 and lp[2] <= -100.0 and absf(lp[1] - UPPER_LY) < 40.0:
		return "hydroponics"
	if lp[1] >= UPPER_LY - 300.0 and lp[0] >= 5900.0 and lp[0] <= 12300.0 and absf(lp[2]) <= 3300.0:
		return "frozen"
	if lp[0] >= 6340.0 and lp[0] <= 6950.0 and lp[2] >= 95.0 and lp[2] <= 430.0 and lp[1] >= 40990.0 and lp[1] <= 41620.0:
		return "glass_terrace"
	if lp[0] >= 5750.0 and lp[0] <= 6230.0 and lp[2] < -14720.0 and lp[2] >= -15200.0 and lp[1] >= 40500.0:
		return "belfry"
	if lp[0] >= 5860.0 and lp[0] <= 6080.0 and lp[2] <= -220.0 and lp[2] >= -14820.0 and lp[1] >= 40500.0:
		return "gap"
	if lp[0] >= 2850.0 and lp[0] <= 6220.0 and absf(lp[2]) <= 450.0 and lp[1] >= 40500.0:
		return "gap"
	# STK-0413 south extremities: the barren blocks, then the never-built blue.
	if lp[0] >= 6040.0 and lp[0] <= 12120.0 and lp[1] >= 40000.0 and lp[1] <= 41950.0:
		if lp[2] >= 2962.0 and lp[2] <= 3900.0:
			return "brink"
		if lp[2] >= 2300.0:
			return "unbuilt"
		if lp[2] >= 1720.0:
			return "plain"
		if lp[2] >= 930.0:
			return "barren"
	# Riding the brink lift up the open south face.
	if lp[1] > 41950.0 and lp[1] < UPPER_LY - 300.0 and absf(lp[0] - 7712.0) < 80.0 and absf(lp[2] - 3004.0) < 80.0:
		return "brink"
	return "default"


func _check_landmark_discovery(lp: PackedFloat64Array) -> void:
	if journal_ui == null:
		return
	var id := ""
	var label := ""
	if lp[1] < 450.0 and lp[0] >= 2400.0 and lp[0] <= 4100.0:
		id = "crust"; label = "Asset 31 Planetary Crust (0 m)"
	elif lp[0] >= 5780.0 and lp[0] <= 6200.0 and lp[2] < -14740.0 and lp[2] >= -15180.0:
		id = "belfry0414"; label = "Great Belfry of the Continuum (Void Bell Sanctum)"
	elif lp[0] >= 5950.0 and lp[0] <= 6060.0 and lp[2] <= -14620.0 and lp[2] >= -14740.0:
		id = "stk0414"; label = "STK-0414 South Terminal (17.5 km North)"
	elif lp[0] >= 5950.0 and lp[0] <= 6040.0 and lp[2] <= -230.0 and lp[2] >= -340.0:
		id = "express_south"; label = "STA-0413-N Inter-Stack Express Terminal"
	elif lp[1] > UPPER_LY - 60.0 and lp[0] >= 6120.0 and lp[0] <= 7080.0 and lp[2] >= -1700.0 and lp[2] <= -700.0:
		id = "preserve"; label = "Ecological Preserve 413-B"
	elif lp[1] > UPPER_LY - 60.0 and lp[0] >= 6140.0 and lp[0] <= 6840.0 and lp[2] >= -700.0 and lp[2] <= -100.0:
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
	# STK-0413 unheated top floor: lethal cold except the bay, the preserve and two way-huts.
	if y > UPPER_LY - 60.0 and x >= 5900.0 and x <= 12300.0 and absf(z) <= 3300.0:
		if x >= 6120.0 and x <= 7080.0 and z >= -1700.0 and z <= -100.0 and y < UPPER_LY + 860.0:
			return "SHELTER"
		if (absf(x - 7716.0) < 2.6 and absf(z - 1520.0) < 2.1) or (absf(x - 7688.0) < 2.6 and absf(z + 52.0) < 2.1):
			return "SHELTER"
		return "EXPOSED"
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
	if (lp[0] >= 6340.0 and lp[0] <= 6940.0 and lp[2] >= 110.0 and lp[2] <= 430.0) \
			or (lp[0] >= 5965.0 and lp[0] <= 6050.0 and lp[2] <= -230.0 and lp[2] >= -14750.0):
		return "SHELTER"
	# Radiant heat near the molten crucible pour on the direct foundry floor.
	if x >= 1855.0 and x <= 1945.0 and z >= -16.0 and z <= 36.0:
		return "HEAT"
	# Never-built extremity of STK-0413: bitter out on the plates, warm against the pipe.
	if x >= 6080.0 and x <= 12080.0 and z >= 1750.0 and z <= 3010.0:
		return "SHELTER" if absf(z - 2562.5) < 4.5 else "EXPOSED"
	# Exposed 3 km inter-stack bridge span.
	if x >= 3045.0 and x <= 6035.0 and absf(z) <= 6.2:
		return "EXPOSED"
	return ""


func _process(delta: float) -> void:
	if not get_tree().paused:
		clock_seconds += delta   # real time: one second is one second
		while clock_seconds >= DAY_SECONDS:
			clock_seconds -= DAY_SECONDS
			clock_day += 1
	if inventory_ui != null and inventory_ui.is_open:
		inventory_ui.update_clock(clock_day, clock_seconds)
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
	if lp[0] >= 5780.0 and lp[0] <= 6200.0 and lp[2] < -14740.0 and lp[2] >= -15180.0:
		return "STK-0414 / Great Belfry of the Continuum (BELFRY-0414)"
	if lp[0] >= 5950.0 and lp[0] <= 6060.0 and lp[2] <= -14620.0 and lp[2] >= -14740.0:
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
	# Streamed-out rooms keep their loot state in InteriorKit; loaded ones override it below.
	var containers := InteriorKit.loot_state.duplicate(true)
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
		"clock": { "day": clock_day, "seconds": clock_seconds },
	}
	# Write to a sibling temp file and swap it in, so a crash mid-write can never
	# leave a truncated save for Steam Cloud to upload over the good copy.
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	var ok := f != null and f.store_string(JSON.stringify(data, "  "))
	if f != null:
		f.close()
	if ok:
		ok = DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path)) == OK
	if not ok:
		push_error("[Asset31] save to %s failed (%s)" % [path, error_string(FileAccess.get_open_error())])
		if hud != null:
			hud.show_toast("Save FAILED")
		return
	print("[Asset31] saved at logical %s" % [lp])
	if hud != null:
		hud.show_toast("Saved expedition state")


## One-time copy of a save written before user:// was pinned to %APPDATA%/Asset31.
## Copies rather than moves, so the old file stays as a backup.
func _migrate_legacy_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		return
	var legacy := OS.get_data_dir().path_join(LEGACY_SAVE_REL)
	if FileAccess.file_exists(legacy):
		var err := DirAccess.copy_absolute(legacy, ProjectSettings.globalize_path(SAVE_PATH))
		print("[Asset31] migrated legacy save from %s (%s)" % [legacy, error_string(err)])


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
		InteriorKit.loot_state.clear()
		for cid: String in cmap:
			if cid.begins_with(InteriorKit.LOOT_PREFIX):
				InteriorKit.loot_state[cid] = cmap[cid]
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
	if data.has("clock"):
		clock_day = maxi(1, int(data.clock.get("day", 1)))
		clock_seconds = clampf(float(data.clock.get("seconds", 0.0)), 0.0, DAY_SECONDS - 1.0)
	if data.has("journal") and journal_ui != null:
		journal_ui.deserialize(data.journal)
	print("[Asset31] loaded logical %s" % [p.logical])
	if hud != null:
		hud.show_toast("Loaded expedition state")
	return true


# ---------------------------------------------------------------- test hooks

func _handle_cmdline() -> void:
	var shots_dir := ""
	var shot_filter := ""
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
		elif arg == "--terracelift":
			# Rides the Glass Terrace east freight lift down and back up.
			survival.enabled = false
			player.input_enabled = false
			for leg in 2:
				var y_from := 41024.06 if leg == 0 else 41000.06
				var y_to := 41000.0 if leg == 0 else 41024.0
				# Step off first: the lift waits for its rider to leave before it will run again.
				_place_player([6921.0, y_from, 155.0], 0.0, 0.0)
				for i in 40:
					await get_tree().physics_frame
				_place_player([6926.62, y_from, 155.0], 0.0, 0.0)
				for i in 1500:
					await get_tree().physics_frame
				var lp := WorldOrigin.to_logical(player.position)
				if absf(lp[1] - y_to) > 0.4:
					push_error("[TerraceLift] FAIL leg %d: player y %.2f, expected %.2f" % [leg, lp[1], y_to])
					get_tree().quit(1)
					return
			print("[TerraceLift] PASS: rode down to the street and back up to the terrace")
			get_tree().quit(0)
			return
		elif arg == "--lifttest":
			_run_lifttest()
			return
		elif arg == "--roomtest":
			_run_roomtest()
			return
		elif arg == "--zfight-lint":
			ZFightLint.run(self, 14)
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
		elif arg == "--showcase":
			_run_tour(SHOWCASE, 0.22)
			return
		elif arg == "--teaser":
			_run_tour(TEASER, 0.8)
			return
		elif arg.begins_with("--motion="):
			_run_motion(arg.get_slice("=", 1))
			return
		elif arg.begins_with("--planet-shots="):
			planet_shots_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--shot-filter="):
			shot_filter = arg.get_slice("=", 1)
		elif arg.begins_with("--shot-at="):
			# Ad-hoc viewpoint: --shot-at=name:x,y,z,yaw_deg,pitch_deg (repeatable, needs --shots=DIR).
			var spec := arg.get_slice("=", 1)
			var nums := spec.get_slice(":", 1).split_floats(",")
			if nums.size() >= 5:
				_extra_shots.append([spec.get_slice(":", 0), [nums[0], nums[1], nums[2]], nums[3], nums[4]])
		elif arg.begins_with("--shots="):
			shots_dir = arg.get_slice("=", 1)
	if planet_shots_dir != "":
		_run_planet_shots(planet_shots_dir)
		return
	if shots_dir != "":
		_run_shots(shots_dir, shot_filter)


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


func _run_shots(dir: String, shot_filter := "") -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	debug_label.visible = false
	hud.set_hud_visible(false)
	survival.enabled = false
	player.input_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var shot_list: Array = _extra_shots if not _extra_shots.is_empty() else SHOTS
	for shot: Array in shot_list:
		if _extra_shots.is_empty() and shot_filter != "" and not String(shot[0]).contains(shot_filter):
			continue
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
	if shot_filter != "" or not _extra_shots.is_empty():
		get_tree().quit(0)
		return
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
	if _environment_condition(PackedFloat64Array([6253.0, UPPER_LY, -340.0])) != "SHELTER":
		fail.call("hydroponics shelter condition check failed")
		return
	if _environment_condition(PackedFloat64Array([6600.0, UPPER_LY, -1100.0])) != "SHELTER":
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
	var belfries := get_tree().get_nodes_in_group(VoidBellSanctum.GROUP)
	if belfries.is_empty():
		fail.call("VoidBellSanctum (BELFRY-0414) missing")
		return
	var belfry := belfries[0] as VoidBellSanctum
	belfry.activate_console(ambience)
	if belfry._strike_timer < 0.0:
		fail.call("VoidBellSanctum strike animation failed to engage")
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_save))
	ZFightLint.run(self, 2)
	print("[Selftest] PASS: %d containers, %d notes, BridgeTram, DeepRelayLift (41 km), PlanetView, Journal, grid inventory, consumables, env zones, save/load round-trip OK." % [conts.size(), notes.size()])
	get_tree().quit(0)


## Enterable-room verification: for door plans around the STK-0413 test district, walks
## the player from the street through the doorway. Fails if a room did not stream in, a
## doorway is blocked, or the player ends up outside the room's footprint.
func _run_roomtest() -> void:
	survival.enabled = false
	player.input_enabled = false
	var stack := stacks[1]
	var centre := Vector3(-1375.0, 0.0, 312.5)
	var plans: Array = []
	for key: Vector2i in stack.door_buildings:
		for b: Dictionary in stack.door_buildings[key]:
			if (b.door.pos as Vector3).distance_to(centre) < 150.0:
				plans.append(b)
	var entered := 0
	var kinds := {}
	var faces := {}
	for b: Dictionary in plans:
		var xf := InteriorKit.xform(b)
		var start := xf * Vector3(0.0, 0.05, -2.2)
		_place_player([stack.lx + start.x, stack.ly + start.y, stack.lz + start.z], 0.0, 0.0)
		for i in 6:
			await get_tree().physics_frame
		if not stack.rooms.has(b.c):
			push_error("[Roomtest] FAIL: room %s did not stream in" % [b.door])
			get_tree().quit(1)
			return
		var room: InteriorRoom = stack.rooms[b.c]
		player.speed_override = 3.0
		player.autopilot_dir = room.global_basis.z
		for i in 110:
			await get_tree().physics_frame
		player.autopilot_dir = Vector3.ZERO
		var local := room.to_local(player.global_position)
		if local.z < 1.5 or local.z > room.d + InteriorKit.WALL_T or local.x < room.x0 or local.x > room.x1:
			push_error("[Roomtest] FAIL: could not walk into room %s (ended at local %s)" % [b.door, local])
			get_tree().quit(1)
			return
		entered += 1
		kinds[int(b.door.tpl)] = true
		faces[int(b.door.face)] = true
	if entered < 20 or faces.size() < 4:
		push_error("[Roomtest] FAIL: only %d rooms / %d facade directions covered" % [entered, faces.size()])
		get_tree().quit(1)
		return
	print("[Roomtest] PASS: walked into %d rooms (%d templates, all %d facade directions)." % [entered, kinds.size(), faces.size()])
	get_tree().quit(0)


## Brink lift verification: rides EL-0413-S from the Floor 77 edge to the top floor and
## back with the real player aboard, then checks the player can step off onto each pier.
func _run_lifttest() -> void:
	survival.enabled = false
	player.input_enabled = false
	var lift: DeepRelayLift = null
	for node in get_tree().get_nodes_in_group(DeepRelayLift.GROUP):
		if (node as DeepRelayLift).relay_id == "EL-0413-S":
			lift = node as DeepRelayLift
	if lift == null:
		push_error("[Lifttest] FAIL: EL-0413-S not found")
		get_tree().quit(1)
		return
	for leg in 2:
		var from_ly := lift.bot_ly if leg == 0 else lift.top_ly
		var to_ly := lift.top_ly if leg == 0 else lift.bot_ly
		_place_player([lift.lx, from_ly + 0.05, lift.lz], 0.0, 0.0)
		for i in 10:
			await get_tree().physics_frame
		var msg := lift.activate_console(0)
		var steps := 0
		while (lift.moving or steps < 5) and steps < 40000:
			await get_tree().physics_frame
			steps += 1
		var lp := WorldOrigin.to_logical(player.position)
		if lift.moving or absf(lift.car_ly - to_ly) > 0.1 or absf(lp[1] - to_ly) > 0.6:
			push_error("[Lifttest] FAIL leg %d (%s): car %.2f, player y %.2f, target %.2f after %d steps" % [leg, msg, lift.car_ly, lp[1], to_ly, steps])
			get_tree().quit(1)
			return
		# Step off west onto the pier and make sure there is ground there.
		player.speed_override = 3.0
		player.autopilot_dir = Vector3(-1, 0, 0)
		for i in 150:
			await get_tree().physics_frame
		player.autopilot_dir = Vector3.ZERO
		var off := WorldOrigin.to_logical(player.position)
		if off[0] > lift.lx - 3.0 or absf(off[1] - to_ly) > 0.8:
			push_error("[Lifttest] FAIL leg %d: could not step onto the pier (ended at %s)" % [leg, off])
			get_tree().quit(1)
			return
		print("[Lifttest] leg %d OK: %s in %.0f s, stepped off at x %.1f y %.2f" % [leg, msg, steps / 60.0, off[0], off[1]])
	print("[Lifttest] PASS")
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
# ~45 s overview of every environment in journey order, each with its own ambience.
# Same row format as TOUR, plus an optional 8th element naming a staged action.
const SHOWCASE := [
	["Home shelter, STK-0412 Floor 77", [-1490.3, 41000.05, 112.7], 1.8, [], 0.0, [[0.0, 180.0, -6.0], [1.8, 140.0, -4.0]]],
	["Market street", [-1470.0, 41000.0, 4.0], 2.4, [[-1440.0, 4.0]], 3.5, []],
	["Foundry hall", [1858.0, 41000.0, -8.0], 2.2, [], 0.0, [[0.0, -122.0, 12.0], [2.2, -100.0, 10.0]]],
	["Deep core elevator EL-DEEP-00: 41 km down", [3271.5, 30000.05, -179.0], 2.8, [], 0.0, [[0.0, 90.0, -8.0], [2.8, 90.0, -30.0]], 0.0, "deep"],
	["Planetary crust, 0 m", [3262.0, 0.08, -176.0], 1.8, [], 0.0, [[0.0, 42.0, 10.0], [1.8, 60.0, 14.0]]],
	["The 3 km bridge between the twin stacks", [4300.0, 41000.0, 0.0], 3.0, [[4400.0, 0.0]], 4.6, [[0.0, -90.0, -10.0], [3.0, -90.0, 30.0]]],
	["Inter-Stack Express station", [5988.5, 41000.08, -264.0], 1.6, [], 0.0, [[0.0, 26.0, 2.0], [1.6, 10.0, 2.0]]],
	["Aboard EXP-077 to the next stack, 396 km/h", [5980.0, 41000.05, -3024.0], 2.4, [], 0.0, [[0.0, 0.0, 0.0], [2.4, -30.0, -4.0]], 0.0, "train"],
	["STK-0413 arrival: the glass terrace", [6922.0, 41028.05, 110.0], 2.0, [], 0.0, [[0.0, 112.0, -2.0], [2.0, 95.0, 0.0]]],
	["Residential blocks: every lit door can be entered", [7705.0, 41000.05, 372.0], 2.8, [[7705.0, 340.0]], 3.5, [[0.0, 60.0, 2.0], [2.8, 110.0, 4.0]]],
	["The barren blocks: power failing", [7705.0, 41000.05, 1150.0], 2.6, [[7705.0, 1190.0]], 4.0, []],
	["The empty plates, looking back", [7705.0, 41000.05, 2050.0], 1.4, [], 0.0, [[0.0, 20.0, 4.0], [1.4, -20.0, 4.0]]],
	["Never-built frames and a squatters' fire", [7705.0, 41000.05, 2350.0], 2.2, [[7705.0, 2385.0]], 4.0, [[0.0, -160.0, 14.0], [2.2, -140.0, 18.0]]],
	["The return pipe: the only warmth", [7700.0, 41000.05, 2550.0], 1.8, [], 0.0, [[0.0, 150.0, 0.0], [1.8, 120.0, 2.0]]],
	["The unclosed edge: the void between stacks", [7700.0, 41000.05, 2999.2], 2.8, [], 0.0, [[0.0, 180.0, -12.0], [2.8, 168.0, -30.0]], 0.0, "bolt"],
	["Brink lift: 18 km up the open face", [7712.0, 50000.05, 3004.0], 2.0, [], 0.0, [[0.0, 180.0, -20.0], [2.0, 180.0, -5.0]], 0.0, "brink"],
	["Top floor, unheated", [7705.0, 59100.05, 2940.0], 2.8, [[7705.0, 2900.0]], 4.6, []],
	["The gate to the hydroponic bay", [6253.0, 59100.05, -40.0], 2.2, [[6253.0, -85.0]], 4.6, []],
	["Hydroponic Bay 413-A", [6253.0, 59100.05, -112.0], 2.0, [], 0.0, [[0.0, 10.0, 2.0], [2.0, -10.0, 2.0]]],
	["Ecological Preserve 413-B", [6600.0, 59100.08, -836.0], 2.2, [], 0.0, [[0.0, 4.0, 10.0], [2.2, 4.0, 40.0]]],
]

# ~80 s teaser for people: slow, no captions, and it stops short of the rewards
# (no crust, no hydroponic bay, no preserve; the frozen floor is only glimpsed).
const TEASER := [
	["", [-1490.3, 41000.05, 112.7], 7.0, [], 0.0, [[0.0, 180.0, -8.0], [3.5, 150.0, -4.0], [7.0, 122.0, 0.0]]],
	["", [-1476.0, 41000.0, 4.0], 7.0, [[-1440.0, 4.0]], 1.8, [[0.0, -90.0, 4.0], [3.5, -70.0, 10.0], [7.0, -100.0, 6.0]]],
	["", [1858.0, 41000.0, -8.0], 6.0, [], 0.0, [[0.0, -128.0, 14.0], [6.0, -100.0, 8.0]]],
	["", [4300.0, 41000.0, 0.0], 9.0, [[4400.0, 0.0]], 1.8, [[0.0, -90.0, -16.0], [9.0, -90.0, 38.0]]],
	["", [3271.5, 34000.05, -179.0], 6.0, [], 0.0, [[0.0, 90.0, -6.0], [6.0, 90.0, -34.0]], 0.0, "deep"],
	["", [7706.5, 41000.05, 349.6], 9.0, [[7692.5, 349.6]], 1.6, [[0.0, 90.0, 2.0], [5.0, 90.0, 0.0], [9.0, 60.0, -4.0]]],
	["", [7705.0, 41000.05, 1130.0], 8.0, [[7705.0, 1190.0]], 1.8, [[0.0, 180.0, 10.0], [4.0, 170.0, 4.0], [8.0, 185.0, 2.0]]],
	["", [7705.0, 41000.05, 2345.0], 7.0, [[7705.0, 2385.0]], 1.8, [[0.0, -165.0, 10.0], [7.0, -138.0, 20.0]]],
	["", [7700.0, 41000.05, 2550.0], 5.0, [], 0.0, [[0.0, 155.0, 0.0], [5.0, 118.0, 3.0]]],
	["", [7700.0, 41000.05, 2999.2], 9.0, [], 0.0, [[0.0, 180.0, -4.0], [4.0, 176.0, -16.0], [9.0, 166.0, -30.0]], 0.0, "bolt"],
	["", [7712.0, 52000.05, 3004.0], 5.0, [], 0.0, [[0.0, 180.0, -24.0], [5.0, 180.0, -4.0]], 0.0, "brink"],
	["", [7705.0, 59100.05, 2950.0], 3.4, [[7705.0, 2900.0]], 1.8, [[0.0, 0.0, 2.0], [3.4, 0.0, 0.0]]],
	["ASSET 31", [7705.0, 59100.05, 2940.0], 7.0, [], 0.0, [[0.0, 0.0, 0.0], [7.0, 0.0, 0.0]], 0.0, "title"],
]

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
	["Great Belfry of the Continuum — The Void Bell (STK-0414)", [6008.2, 41000.08, -14874.0], 9.0, [], 0.0,
		[[0.0, 20.0, 9.0], [9.0, 12.0, 11.5]]],
]


## Puts the transports back at rest between showcase shots.
func _tour_reset_transports() -> void:
	for node in get_tree().get_nodes_in_group(DeepRelayLift.GROUP):
		var r := node as DeepRelayLift
		r._release_rider()
		r.deserialize({ "car_ly": r.top_ly if r.relay_id == "EL-DEEP-00" else r.bot_ly, "moving": false,
			"target_ly": r.top_ly if r.relay_id == "EL-DEEP-00" else r.bot_ly, "vel": 0.0, "accel": 0.0 })
	for node in get_tree().get_nodes_in_group(InterStackExpress.GROUP):
		var ex := node as InterStackExpress
		ex._release_rider()
		ex.deserialize({ "train_lz": InterStackExpress.SOUTH_LZ, "moving": false, "target_lz": InterStackExpress.SOUTH_LZ, "vel": 0.0, "accel": 0.0 })


## Stages a transport mid-journey (or a lightning stroke) for one showcase shot.
func _tour_action(action: String, start: Array, segs_are_showcase := true) -> void:
	match action:
		"deep", "brink":
			var want := "EL-DEEP-00" if action == "deep" else "EL-0413-S"
			for node in get_tree().get_nodes_in_group(DeepRelayLift.GROUP):
				var r := node as DeepRelayLift
				if r.relay_id == want:
					var down := action == "deep"
					r.deserialize({ "car_ly": float(start[1]) - 0.05, "moving": true,
						"target_ly": r.bot_ly if down else r.top_ly,
						"vel": -DeepRelayLift.MAX_SPEED if down else DeepRelayLift.MAX_SPEED, "accel": 0.0 })
		"train":
			for node in get_tree().get_nodes_in_group(InterStackExpress.GROUP):
				var ex := node as InterStackExpress
				ex.deserialize({ "train_lz": float(start[2]) + 24.0, "moving": true, "target_lz": InterStackExpress.NORTH_LZ,
					"vel": -InterStackExpress.MAX_SPEED, "accel": 0.0 })
				ex._vel = -InterStackExpress.MAX_SPEED   # already at cruise
				if ex._traction_audio.stream != null:
					ex._traction_audio.play()
				if ex._wind_audio.stream != null:
					ex._wind_audio.play()
				ex._attach_rider_if_aboard()
		"bolt":
			var abyss := get_node_or_null(^"AbyssFloor") as AbyssFloor
			if abyss != null:
				abyss.strike_soon(0.7 if segs_are_showcase else 5.2, 180.0)


func _run_tour(segs: Array = TOUR, fade_t := 0.5) -> void:
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
	var title := Label.new()
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 40)
	title.add_theme_color_override(&"font_color", Color(1.0, 0.88, 0.65))
	title.visible = false
	layer.add_child(title)
	var credit := Label.new()
	credit.set_anchors_preset(Control.PRESET_FULL_RECT)
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	credit.add_theme_font_size_override(&"font_size", 11)
	credit.add_theme_color_override(&"font_color", Color(0.82, 0.76, 0.66))
	credit.text = "A fan-made playable recreation.  World and original video:\n\"Life Inside a Planet-Sized Megastructure\" by Otherside Narrations (YouTube).\n "
	credit.visible = false
	layer.add_child(credit)
	for seg: Array in segs:
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
		if segs != TOUR:
			_tour_reset_transports()
		_place_player(start, deg_to_rad(yaw0), deg_to_rad(pitch0))
		if seg.size() > 7:
			_tour_action(String(seg[7]), start, segs == SHOWCASE)
		if segs != TOUR and ambience != null:
			# Short shots: cut straight to each place's own ambience instead of fading into it.
			ambience._apply_profile(ambience._profile_at_listener(), true)
		player.speed_override = float(seg[4])
		caption.text = seg[0]
		var is_title := seg.size() > 7 and String(seg[7]) == "title"
		if is_title:
			# End card: the name over the planet seen from orbit, with the credit.
			caption.text = ""
			title.text = String(seg[0])
			title.visible = true
			credit.visible = true
			layer.layer = 60
			if ambience != null:
				ambience._apply_profile("gap", true)
			_open_planet_view(false)
		var wi := 0
		var t := 0.0
		var yaw := deg_to_rad(yaw0)
		while t < dur:
			var dt := get_process_delta_time()
			t += dt
			fade.color.a = clampf(1.0 - t / fade_t, 0.0, 1.0) + clampf((t - (dur - fade_t)) / fade_t, 0.0, 1.0)
			if is_title:
				title.modulate.a = clampf((t - 1.2) / 1.2, 0.0, 1.0)
				credit.modulate.a = clampf((t - 2.6) / 1.2, 0.0, 1.0)
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
