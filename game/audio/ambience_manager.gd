class_name AmbienceManager
extends Node
## Layered spatial ambience. Looping beds crossfade by zone (data:
## ambience_zones / ambience_profiles in mantle_slice.json); reverb follows
## the space; sparse distant one-shots (metal resonance, impacts, a far horn)
## are placed in 3D around the listener; footsteps per surface.

const BED_LAYERS := [
	"rumble", "vent", "room_tone", "wind", "market", "machinery",
	"cable_tension", "elec_hum", "bridge_vib", "water_fall", "drill_drone",
]
const VOID_BELL_PATH := "res://audio/religion/religious_long_bell.mp3"
const FADE_TIME := 2.5
const SILENT_DB := -60.0

var zones: Array = []      # { "min": PackedFloat64Array, "max": ..., "profile": String, "vol": float }
var profiles: Dictionary = {}
var current_profile := ""
var _beds: Dictionary = {}           # layer -> AudioStreamPlayer
var _target_db: Dictionary = {}      # layer -> dB
var _target_pitch := 1.0
var _reverb: AudioEffectReverb
var _bell_bus_idx := -1
var _bell_lpf: AudioEffectLowPassFilter
var _bell_stream: AudioStream
var _bell_timer := 95.0
var _bell_first_exterior_primed := false
var _bell_sub_pending := -1.0
var _bell_sub_pitch := 0.5
var _bell_target_db := -18.0
var _bell_target_cutoff := 800.0
var _oneshots: Dictionary = {}       # name -> AudioStream
var _steps: Dictionary = { "stone": [], "metal": [] }
var _step_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _music_tracks: Dictionary = {}
var _music_cooldown := 35.0
var _discovered_music: Dictionary = {}
var _listener: Node3D
var _zone_timer := 0.0
var _oneshot_timer := 6.0
var _rng := RandomNumberGenerator.new()


func setup(world_def: Dictionary, listener: Node3D) -> void:
	_listener = listener
	_rng.randomize()
	profiles = world_def.get("ambience_profiles", {})
	for z: Dictionary in world_def.get("ambience_zones", []):
		var b: Array = z.box
		zones.append({
			"min": PackedFloat64Array([b[0], b[1], b[2]]),
			"max": PackedFloat64Array([b[3], b[4], b[5]]),
			"profile": String(z.profile),
			"vol": (float(b[3]) - float(b[0])) * (float(b[4]) - float(b[1])) * (float(b[5]) - float(b[2])),
		})
	_setup_buses()
	for layer: String in BED_LAYERS:
		var p := AudioStreamPlayer.new()
		p.stream = _load_loop("res://audio/%s.wav" % layer)
		p.bus = &"Ambience"
		p.volume_db = SILENT_DB
		add_child(p)
		if p.stream != null:
			p.play(_rng.randf() * 5.0)
		_beds[layer] = p
		_target_db[layer] = SILENT_DB
	for n in ["metal_ring_0", "metal_ring_1", "metal_ring_2", "impact_far", "horn_far", "creak", "cable_groan"]:
		var path := "res://audio/%s.wav" % n
		if ResourceLoader.exists(path):
			_oneshots[n] = load(path)
	for i in 4:
		for kind in ["stone", "metal"]:
			var path := "res://audio/step_%s_%d.wav" % [kind, i]
			if ResourceLoader.exists(path):
				_steps[kind].append(load(path))
	_step_player = AudioStreamPlayer.new()
	_step_player.bus = &"World"
	_step_player.volume_db = -14.0
	_step_player.max_polyphony = 3
	add_child(_step_player)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Ambience"
	_music_player.volume_db = -21.0
	add_child(_music_player)
	for mname in ["music_vista", "music_arrival", "music_crust"]:
		var mpath := "res://audio/%s.wav" % mname
		if ResourceLoader.exists(mpath):
			_music_tracks[mname] = load(mpath)
	if ResourceLoader.exists(VOID_BELL_PATH):
		_bell_stream = load(VOID_BELL_PATH)
	_bell_timer = _rng.randf_range(110.0, 190.0)
	_apply_profile(_profile_at_listener(), true)


func _setup_buses() -> void:
	if AudioServer.get_bus_index(&"World") == -1:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, &"World")
		AudioServer.set_bus_send(i, &"Master")
		_reverb = AudioEffectReverb.new()
		_reverb.room_size = 0.8
		_reverb.damping = 0.5
		_reverb.wet = 0.35
		_reverb.dry = 1.0
		_reverb.spread = 1.0
		AudioServer.add_bus_effect(i, _reverb)
	else:
		_reverb = AudioServer.get_bus_effect(AudioServer.get_bus_index(&"World"), 0)
	if AudioServer.get_bus_index(&"Ambience") == -1:
		AudioServer.add_bus()
		var j := AudioServer.bus_count - 1
		AudioServer.set_bus_name(j, &"Ambience")
		AudioServer.set_bus_send(j, &"Master")
		# Safety limiter: a loud low bed must never clip the output (it gates everything else).
		var lim := AudioEffectHardLimiter.new()
		lim.ceiling_db = -1.0
		lim.pre_gain_db = 0.0
		AudioServer.add_bus_effect(j, lim)
	# Dedicated acoustic post-processing bus for The Void Bell (Continuum sacred gong):
	# zone-reactive LowPass -> colossal twin-stack canyon Delay echoes -> cavernous Reverb -> Compressor.
	_bell_bus_idx = AudioServer.get_bus_index(&"VoidBell")
	if _bell_bus_idx == -1:
		AudioServer.add_bus()
		_bell_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_bell_bus_idx, &"VoidBell")
		AudioServer.set_bus_send(_bell_bus_idx, &"Master")
		_bell_lpf = AudioEffectLowPassFilter.new()
		_bell_lpf.cutoff_hz = 1200.0
		_bell_lpf.resonance = 0.55
		AudioServer.add_bus_effect(_bell_bus_idx, _bell_lpf)
		var dly := AudioEffectDelay.new()
		dly.dry = 0.88
		dly.tap1_active = true
		dly.tap1_delay_ms = 780.0
		dly.tap1_level_db = -7.0
		dly.tap1_pan = -0.55
		dly.tap2_active = true
		dly.tap2_delay_ms = 1480.0
		dly.tap2_level_db = -10.5
		dly.tap2_pan = 0.55
		dly.feedback_active = true
		dly.feedback_delay_ms = 1150.0
		dly.feedback_level_db = -10.0
		dly.feedback_lowpass = 1650.0
		AudioServer.add_bus_effect(_bell_bus_idx, dly)
		var rev := AudioEffectReverb.new()
		rev.room_size = 1.0
		rev.damping = 0.20
		rev.spread = 1.0
		rev.hipass = 0.0
		rev.dry = 0.72
		rev.wet = 0.80
		rev.predelay_msec = 95.0
		rev.predelay_feedback = 0.35
		AudioServer.add_bus_effect(_bell_bus_idx, rev)
		var comp := AudioEffectCompressor.new()
		comp.threshold = -1.5
		comp.ratio = 4.0
		comp.attack_us = 2500.0
		comp.release_ms = 250.0
		AudioServer.add_bus_effect(_bell_bus_idx, comp)
	else:
		_bell_lpf = AudioServer.get_bus_effect(_bell_bus_idx, 0) as AudioEffectLowPassFilter


func _load_loop(path: String) -> AudioStreamWAV:
	if not ResourceLoader.exists(path):
		push_warning("Missing ambience %s (run tools/gen_audio.gd)" % path)
		return null
	var s: AudioStreamWAV = (load(path) as AudioStreamWAV).duplicate()
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = int(s.get_length() * s.mix_rate)
	return s


func _profile_at_listener() -> String:
	if _listener == null:
		return "city"
	var lp := WorldOrigin.to_logical(_listener.global_position)
	var best := "city"
	var best_vol := INF
	for z: Dictionary in zones:
		var mn: PackedFloat64Array = z.min
		var mx: PackedFloat64Array = z.max
		if lp[0] >= mn[0] and lp[0] <= mx[0] and lp[1] >= mn[1] and lp[1] <= mx[1] and lp[2] >= mn[2] and lp[2] <= mx[2]:
			if float(z.vol) < best_vol:
				best_vol = z.vol
				best = z.profile
	return best


func _apply_profile(name: String, instant := false) -> void:
	current_profile = name
	var p: Dictionary = profiles.get(name, profiles.get("city", {}))
	var layers: Dictionary = p.get("layers", {})
	_target_pitch = float(p.get("pitch", 1.0))
	for layer: String in BED_LAYERS:
		_target_db[layer] = float(layers.get(layer, SILENT_DB))
		if instant:
			var bp := _beds[layer] as AudioStreamPlayer
			bp.volume_db = _target_db[layer]
			bp.pitch_scale = _target_pitch
	var rv: Dictionary = p.get("reverb", {})
	_reverb.room_size = float(rv.get("room", 0.8))
	_reverb.wet = float(rv.get("wet", 0.3))
	_reverb.damping = float(rv.get("damping", 0.5))
	_update_void_bell_zone(name, instant)
	if not instant:
		_maybe_trigger_discovery_music(name)


## Scales The Void Bell's acoustic loudness & low-pass filtering by architectural exposure:
## colossal, echoing, and megalophobic out in the chasm between stacks; deeply muffled indoors.
func _update_void_bell_zone(profile_name: String, instant: bool) -> void:
	match profile_name:
		"gap":
			_bell_target_db = 1.5
			_bell_target_cutoff = 4200.0
		"edge", "shaft", "arrival":
			_bell_target_db = -1.5
			_bell_target_cutoff = 3200.0
		"roof", "crust":
			_bell_target_db = -7.0
			_bell_target_cutoff = 1550.0
		"industrial", "foundry", "preserve":
			_bell_target_db = -13.5
			_bell_target_cutoff = 900.0
		_:
			_bell_target_db = -19.5
			_bell_target_cutoff = 520.0
	if instant and _bell_bus_idx >= 0:
		AudioServer.set_bus_volume_db(_bell_bus_idx, _bell_target_db)
		if _bell_lpf != null:
			_bell_lpf.cutoff_hz = _bell_target_cutoff
	# First time the player steps outside between the stacks, gently prime the first Void Bell toll
	# so they experience the colossal chasm resonance within ~14-22 s, then space subsequent tolls minutes apart.
	if not _bell_first_exterior_primed and (profile_name == "gap" or profile_name == "edge" or profile_name == "shaft"):
		_bell_first_exterior_primed = true
		if _bell_timer > 22.0:
			_bell_timer = _rng.randf_range(13.0, 21.0)


func _maybe_trigger_discovery_music(profile_name: String) -> void:
	if _music_cooldown > 0.0 or _music_player == null or _music_player.playing:
		return
	if _discovered_music.has(profile_name):
		return
	var track := ""
	match profile_name:
		"roof", "shaft":
			track = "music_vista"
		"arrival", "hydroponics", "preserve":
			track = "music_arrival"
		"crust":
			track = "music_crust"
		_:
			return
	if not _music_tracks.has(track):
		return
	_discovered_music[profile_name] = true
	_music_cooldown = 180.0
	_music_player.stream = _music_tracks[track]
	_music_player.play()


func _process(delta: float) -> void:
	if _listener == null:
		return
	if _music_cooldown > 0.0:
		_music_cooldown = maxf(0.0, _music_cooldown - delta)
	_zone_timer -= delta
	if _zone_timer <= 0.0:
		_zone_timer = 0.3
		var prof := _profile_at_listener()
		if prof != current_profile:
			_apply_profile(prof)
	# Crossfade in the linear domain for smooth transitions.
	var k := clampf(delta / FADE_TIME, 0.0, 1.0)
	for layer: String in BED_LAYERS:
		var p: AudioStreamPlayer = _beds[layer]
		var cur := db_to_linear(p.volume_db)
		var tgt := db_to_linear(_target_db[layer])
		p.volume_db = linear_to_db(maxf(lerpf(cur, tgt, k * 2.0) if absf(cur - tgt) > 0.0005 else tgt, 0.00001))
		if absf(p.pitch_scale - _target_pitch) > 0.001:
			p.pitch_scale = lerpf(p.pitch_scale, _target_pitch, k)
	_oneshot_timer -= delta
	if _oneshot_timer <= 0.0:
		var p: Dictionary = profiles.get(current_profile, {})
		var pace := float(p.get("oneshot_interval", 1.0))
		_oneshot_timer = _rng.randf_range(10.0, 28.0) * pace
		_distant_oneshot()
	_tick_void_bell(delta)


func _tick_void_bell(delta: float) -> void:
	if _bell_bus_idx >= 0:
		var k := clampf(delta * 1.4, 0.0, 1.0)
		var cur_db := AudioServer.get_bus_volume_db(_bell_bus_idx)
		AudioServer.set_bus_volume_db(_bell_bus_idx, lerpf(cur_db, _bell_target_db, k))
		if _bell_lpf != null:
			_bell_lpf.cutoff_hz = lerpf(_bell_lpf.cutoff_hz, _bell_target_cutoff, k)
	if _bell_stream == null:
		return
	if _bell_sub_pending >= 0.0:
		_bell_sub_pending -= delta
		if _bell_sub_pending <= 0.0:
			_bell_sub_pending = -1.0
			_play_void_bell_sub_layer(_bell_sub_pitch)
	_bell_timer -= delta
	if _bell_timer <= 0.0:
		var is_chasm := current_profile == "gap" or current_profile == "edge" or current_profile == "shaft" or current_profile == "arrival"
		# Extremely rare & sacred pacing: ~2.7-5.0 minutes outside in the chasm, ~5.5-9.0 minutes indoors.
		_bell_timer = _rng.randf_range(165.0, 300.0) if is_chasm else _rng.randf_range(330.0, 540.0)
		trigger_void_bell()


## Strikes The Void Bell deep within the megastructure:
## 1) Pitched-down colossal metallic gong in 3D space across the chasm (longer tail + immense scale)
## 2) Delayed octave-lower structural sub-resonance so the entire megastructure quietly vibrates.
## 3) Triggers the physical 19 m spherical clapper swing & golden shockwave inside BELFRY-0414.
func trigger_void_bell() -> void:
	if _bell_stream == null or _listener == null:
		return
	var base_pitch := _rng.randf_range(0.79, 0.87)
	var lp := WorldOrigin.to_logical(_listener.global_position)
	var s := AudioStreamPlayer3D.new()
	s.stream = _bell_stream
	s.bus = &"VoidBell"
	s.unit_size = 950.0
	s.max_distance = 14000.0
	s.volume_db = 2.0 if lp[2] < -14400.0 else 0.0
	s.pitch_scale = base_pitch
	s.attenuation_filter_cutoff_hz = 5000.0
	add_child(s)
	if lp[2] < -14400.0:
		# Inside STK-0414 / BELFRY-0414: sound radiates directly from the suspended 106 m Void Bell!
		s.global_position = WorldOrigin.to_render(5982.2, 41006.0, -14952.0)
	else:
		# Across the chasm: project 1,200 m out toward the distant Great Belfry of STK-0414.
		var az := _rng.randf_range(-0.9, 0.9) + (0.0 if _rng.randf() < 0.5 else PI)
		var dir := Vector3(sin(az), _rng.randf_range(-0.35, 0.15), -cos(az)).normalized()
		s.global_position = _listener.global_position + dir * 1200.0
	s.play()
	s.finished.connect(s.queue_free)
	# Queue the deep octave-lower structural vibration layer 0.38 s after impact.
	_bell_sub_pitch = base_pitch * 0.62
	_bell_sub_pending = 0.38
	if get_tree() != null:
		get_tree().call_group(&"void_bell_sanctum", &"on_bell_struck")


func _play_void_bell_sub_layer(pitch: float) -> void:
	if _bell_stream == null:
		return
	var sub := AudioStreamPlayer.new()
	sub.stream = _bell_stream
	sub.bus = &"VoidBell"
	sub.volume_db = -8.5
	sub.pitch_scale = pitch
	add_child(sub)
	sub.play()
	sub.finished.connect(sub.queue_free)


func _pick_oneshot(profile_name: String) -> String:
	var roll := _rng.randf()
	match profile_name:
		"shaft":
			if roll > 0.62:
				return "cable_groan"
			elif roll > 0.30:
				return "metal_ring_%d" % _rng.randi_range(0, 2)
			return "impact_far"
		"gap", "edge":
			if roll > 0.84:
				return "horn_far"
			elif roll > 0.52:
				return "cable_groan"
			elif roll > 0.25:
				return "creak"
			return "metal_ring_%d" % _rng.randi_range(0, 2)
		"foundry", "industrial", "crust":
			if roll > 0.58:
				return "impact_far"
			elif roll > 0.18:
				return "metal_ring_%d" % _rng.randi_range(0, 2)
			return "creak"
		"market", "residential", "room", "preserve":
			if roll > 0.65:
				return "creak"
			return "metal_ring_%d" % _rng.randi_range(0, 2)
		"barren", "barren_deep":
			# Dead blocks: the structure settling, nothing human.
			if roll > 0.55:
				return "creak"
			elif roll > 0.2:
				return "cable_groan"
			return "impact_far"
		"unbuilt", "brink":
			# Nothing works out here: only the one long groan, slowed with the bed.
			return "cable_groan"
		"frozen":
			return "cable_groan" if roll > 0.4 else "creak"
		_:
			if roll > 0.93:
				return "horn_far"
			elif roll > 0.70:
				return "impact_far"
			elif roll > 0.55:
				return "creak"
			return "metal_ring_%d" % _rng.randi_range(0, 2)


## A sound somewhere in the structure: felt more than heard.
func _distant_oneshot() -> void:
	if _oneshots.is_empty():
		return
	var p: Dictionary = profiles.get(current_profile, {})
	if p.get("oneshots", true) == false:
		return
	var name := _pick_oneshot(current_profile)
	if not _oneshots.has(name):
		return
	var dir := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.2, 0.5), _rng.randf_range(-1, 1)).normalized()
	var is_close := name == "creak" or name == "cable_groan"
	var dist := _rng.randf_range(55.0, 240.0) if is_close else _rng.randf_range(160.0, 720.0)
	var s := AudioStreamPlayer3D.new()
	s.stream = _oneshots[name]
	s.bus = &"World"
	s.unit_size = 55.0 if is_close else 120.0
	s.max_distance = 3000.0
	var gain_bias := float(p.get("oneshot_db", 0.0))
	s.volume_db = (-2.0 if name == "horn_far" else -5.0) + gain_bias
	s.pitch_scale = _rng.randf_range(0.85, 1.1) * _target_pitch
	s.attenuation_filter_cutoff_hz = 2500.0
	add_child(s)
	s.global_position = _listener.global_position + dir * dist
	s.play()
	s.finished.connect(s.queue_free)


func footstep(surface: String) -> void:
	var list: Array = _steps.get(surface, _steps.stone)
	if list.is_empty():
		return
	_step_player.stream = list[_rng.randi() % list.size()]
	_step_player.pitch_scale = _rng.randf_range(0.9, 1.08)
	_step_player.play()
