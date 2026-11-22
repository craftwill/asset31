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


func _ready() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.085, 0.055, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.22, 0.15)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(0.17, 0.105, 0.06)
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
	env.glow_intensity = 0.35
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.3
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
	m.albedo_color = Color(1.0, 0.82, 0.58, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	q.material = m
	_dust.draw_pass_1 = q
	add_child(_dust)
	WorldOrigin.origin_shifted.connect(func(_d: Vector3) -> void: _dust.restart())


func follow(target: Node3D) -> void:
	_target = target


func _process(_delta: float) -> void:
	if _target == null:
		return
	var p := _target.global_position
	_dust.global_position = p + Vector3(0, 2.0, 0)
	# Mist sits on the floor slab of the current level, around the player.
	var floor_y := WorldOrigin.to_render(0.0, floor_logical_y, 0.0).y
	_mist.global_position = Vector3(p.x, floor_y + 2.5, p.z)
	_mist.visible = absf(p.y - floor_y) < 30.0
