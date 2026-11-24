class_name Atmosphere
extends Node3D
## Environment, distance haze, low ground mist (frame 575s) and drifting dust
## motes (575s, 275s). Restrained on purpose: the reference look, stable, with
## no global volumetric haze and gentle glow.

var env: Environment
var floor_logical_y := 41000.0
var _mist: FogVolume
var _dust: GPUParticles3D
var _target: Node3D
var _last_mood := ""
var _rate := 2.2


func _ready() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.095, 0.058, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.22, 0.15)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(0.20, 0.118, 0.062)
	env.fog_light_energy = 1.0
	env.fog_density = 0.00022
	env.fog_sky_affect = 1.0
	# Volumetric fog only inside explicit FogVolumes (the ground mist).
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.0
	env.volumetric_fog_albedo = Color(0.85, 0.72, 0.58)
	env.volumetric_fog_length = 90.0
	env.volumetric_fog_ambient_inject = 0.6
	env.volumetric_fog_temporal_reprojection_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.28
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.4
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 0.95
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-62.0, 35.0, 0.0)
	fill.light_color = Color(1.0, 0.78, 0.6)
	fill.light_energy = 0.1
	fill.shadow_enabled = false
	add_child(fill)

	_mist = FogVolume.new()
	_mist.size = Vector3(220.0, 6.0, 220.0)
	_mist.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	var fm := FogMaterial.new()
	fm.density = 0.035
	fm.albedo = Color(0.8, 0.68, 0.55)
	fm.height_falloff = 0.9
	fm.edge_fade = 0.6
	_mist.material = fm
	add_child(_mist)

	_dust = GPUParticles3D.new()
	_dust.amount = 420
	_dust.lifetime = 16.0
	_dust.preprocess = 16.0
	_dust.local_coords = false
	_dust.visibility_aabb = AABB(Vector3(-40, -20, -40), Vector3(80, 40, 80))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(28, 12, 28)
	pm.direction = Vector3(0.3, -1.0, 0.1)
	pm.spread = 60.0
	pm.initial_velocity_min = 0.03
	pm.initial_velocity_max = 0.15
	pm.gravity = Vector3(0, -0.01, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	_dust.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = Color(1.0, 0.82, 0.58, 0.45)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	m.distance_fade_min_distance = 1.6
	m.distance_fade_max_distance = 3.8
	q.material = m
	_dust.draw_pass_1 = q
	add_child(_dust)
	WorldOrigin.origin_shifted.connect(func(_d: Vector3) -> void: _dust.restart())


func follow(target: Node3D) -> void:
	_target = target


## Smoothly adapts atmospheric tint & floor mist datum between the dark Mantle
## megastructure ("default"), the luminous Ecological Preserve 413-B ("preserve"),
## and Asset 31's excavated planetary mining floor ("crust").
func set_mood(mood: String, delta: float, instant := false) -> void:
	if env == null:
		return
	var tgt_bg := Color(0.095, 0.058, 0.035)
	var tgt_fog := Color(0.20, 0.118, 0.062)
	var tgt_amb := Color(0.32, 0.22, 0.15)
	var tgt_amb_e := 0.75
	var tgt_fog_d := 0.00022
	var tgt_mist := Color(0.8, 0.68, 0.55)
	var rate := 2.2
	var dust := 0   # 0 warm dust motes, 1 cold flecks, 2 snow
	if mood == "preserve":
		tgt_bg = Color(0.76, 0.74, 0.64)
		tgt_fog = Color(0.78, 0.76, 0.66)
		tgt_amb = Color(0.84, 0.84, 0.76)
		tgt_amb_e = 1.20
		tgt_fog_d = 0.00052
		floor_logical_y = 59100.0
	elif mood == "hydroponics":
		tgt_bg = Color(0.22, 0.11, 0.19)
		tgt_fog = Color(0.32, 0.16, 0.27)
		tgt_amb = Color(0.48, 0.30, 0.42)
		tgt_amb_e = 0.95
		tgt_fog_d = 0.0022
		floor_logical_y = 59100.0
	elif mood == "glass_terrace":
		tgt_bg = Color(0.54, 0.56, 0.53)
		tgt_fog = Color(0.62, 0.64, 0.60)
		tgt_amb = Color(0.68, 0.70, 0.66)
		tgt_amb_e = 1.05
		tgt_fog_d = 0.00055
		floor_logical_y = 41000.0
	elif mood == "belfry":
		tgt_bg = Color(0.24, 0.155, 0.088)
		tgt_fog = Color(0.40, 0.26, 0.14)
		tgt_amb = Color(0.48, 0.35, 0.22)
		tgt_amb_e = 0.92
		tgt_fog_d = 0.0026
		floor_logical_y = 41000.0
	elif mood == "gap":
		tgt_bg = Color(0.092, 0.056, 0.034)
		tgt_fog = Color(0.195, 0.115, 0.060)
		tgt_amb = Color(0.32, 0.22, 0.15)
		tgt_amb_e = 0.75
		tgt_fog_d = 0.000135
		floor_logical_y = 41000.0
	elif mood == "crust":
		tgt_bg = Color(0.065, 0.038, 0.025)
		tgt_fog = Color(0.18, 0.095, 0.048)
		tgt_amb = Color(0.28, 0.18, 0.12)
		tgt_amb_e = 0.65
		tgt_fog_d = 0.0011
		floor_logical_y = 0.0
	elif mood == "barren":
		# Abandoned blocks (577s): the same brown, thicker and dimmer.
		tgt_bg = Color(0.062, 0.043, 0.030)
		tgt_fog = Color(0.185, 0.130, 0.085)
		tgt_amb = Color(0.34, 0.25, 0.175)
		tgt_amb_e = 1.15
		tgt_fog_d = 0.0019
		floor_logical_y = 41000.0
		rate = 0.35
	elif mood == "unbuilt":
		# Never-built extremity (581s-597s): cold navy murk you cannot see across.
		tgt_bg = Color(0.012, 0.022, 0.046)
		tgt_fog = Color(0.030, 0.056, 0.110)
		tgt_amb = Color(0.20, 0.28, 0.46)
		tgt_amb_e = 1.25
		tgt_fog_d = 0.0046
		tgt_mist = Color(0.34, 0.46, 0.7)
		dust = 1
		floor_logical_y = 41000.0
		rate = 0.35
	elif mood == "plain":
		# The empty plates between the dead blocks and the first steel: the same cold
		# blue, already thick enough to swallow the stack walls; a little thinner than
		# among the frames, so the dead city behind fades out rather than vanishing at once.
		tgt_bg = Color(0.014, 0.024, 0.048)
		tgt_fog = Color(0.030, 0.054, 0.105)
		tgt_amb = Color(0.19, 0.27, 0.45)
		tgt_amb_e = 1.15
		tgt_fog_d = 0.0034
		tgt_mist = Color(0.34, 0.46, 0.7)
		dust = 1
		floor_logical_y = 41000.0
		rate = 0.35
	elif mood == "brink":
		# The unclosed edge and the lift up its face: the murk thins, the horizon opens.
		tgt_bg = Color(0.014, 0.024, 0.048)
		tgt_fog = Color(0.03, 0.052, 0.10)
		tgt_amb = Color(0.18, 0.25, 0.42)
		tgt_amb_e = 1.0
		tgt_fog_d = 0.00011
		tgt_mist = Color(0.34, 0.46, 0.7)
		dust = 1
		floor_logical_y = 41000.0
		rate = 0.5
	elif mood == "frozen":
		# Unheated top floor: a bright white-out.
		tgt_bg = Color(0.50, 0.58, 0.68)
		tgt_fog = Color(0.56, 0.64, 0.74)
		tgt_amb = Color(0.62, 0.72, 0.88)
		tgt_amb_e = 1.15
		tgt_fog_d = 0.0042
		tgt_mist = Color(0.92, 0.96, 1.0)
		dust = 2
		floor_logical_y = 59100.0
		rate = 0.5
	else:
		floor_logical_y = 41000.0
	if mood != _last_mood:
		_set_dust(dust)
		# Leaving the slow zones is slow too, so the colour never snaps at a line.
		if _last_mood == "barren" or _last_mood == "unbuilt" or _last_mood == "plain":
			_rate = 0.35
		else:
			_rate = rate
		_last_mood = mood
	var k := 1.0 if instant else clampf(delta * _rate, 0.0, 1.0)
	var fm := _mist.material as FogMaterial
	if fm != null:
		fm.albedo = fm.albedo.lerp(tgt_mist, k)
	env.background_color = env.background_color.lerp(tgt_bg, k)
	env.fog_light_color = env.fog_light_color.lerp(tgt_fog, k)
	env.ambient_light_color = env.ambient_light_color.lerp(tgt_amb, k)
	env.ambient_light_energy = lerpf(env.ambient_light_energy, tgt_amb_e, k)
	env.fog_density = lerpf(env.fog_density, tgt_fog_d, k)


## Airborne particles to suit the place: warm dust in the lit Mantle, sparse cold
## flecks drifting sideways through the never-built murk, driven snow on the top floor.
func _set_dust(kind: int) -> void:
	var pm := _dust.process_material as ParticleProcessMaterial
	var mat := (_dust.draw_pass_1 as QuadMesh).material as StandardMaterial3D
	match kind:
		1:
			mat.albedo_color = Color(0.55, 0.7, 1.0, 0.2)
			(_dust.draw_pass_1 as QuadMesh).size = Vector2(0.035, 0.035)
			pm.direction = Vector3(1.0, -0.12, 0.25)
			pm.spread = 14.0
			pm.initial_velocity_min = 0.25
			pm.initial_velocity_max = 0.6
			pm.gravity = Vector3(0, -0.004, 0)
			_dust.amount_ratio = 0.4
		2:
			mat.albedo_color = Color(1.0, 1.0, 1.0, 0.7)
			(_dust.draw_pass_1 as QuadMesh).size = Vector2(0.045, 0.045)
			pm.direction = Vector3(1.0, -0.45, 0.2)
			pm.spread = 18.0
			pm.initial_velocity_min = 1.6
			pm.initial_velocity_max = 3.4
			pm.gravity = Vector3(0.6, -0.5, 0)
			_dust.amount_ratio = 1.0
		_:
			mat.albedo_color = Color(1.0, 0.82, 0.58, 0.45)
			(_dust.draw_pass_1 as QuadMesh).size = Vector2(0.05, 0.05)
			pm.direction = Vector3(0.3, -1.0, 0.1)
			pm.spread = 60.0
			pm.initial_velocity_min = 0.03
			pm.initial_velocity_max = 0.15
			pm.gravity = Vector3(0, -0.01, 0)
			_dust.amount_ratio = 1.0
	_dust.restart()


func _process(_delta: float) -> void:
	if _target == null:
		return
	var p := _target.global_position
	_dust.global_position = p + Vector3(0, 2.0, 0)
	# Mist sits on the floor slab of the current level, around the player.
	var floor_y := WorldOrigin.to_render(0.0, floor_logical_y, 0.0).y
	_mist.global_position = Vector3(p.x, floor_y + 2.5, p.z)
	_mist.visible = absf(p.y - floor_y) < 30.0
