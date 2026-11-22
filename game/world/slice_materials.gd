class_name SliceMaterials
extends RefCounted
## The slice's material family and instancing helpers. Few shaders, small
## pixel textures (TextureFactory), parameter variants cached by id.

const FACADE := preload("res://shaders/facade.gdshader")
const GROUND := preload("res://shaders/ground.gdshader")
const SURFACE := preload("res://shaders/surface.gdshader")
const DECAL := preload("res://shaders/decal.gdshader")
const EMISSIVE := preload("res://shaders/emissive.gdshader")
const CORONA := preload("res://shaders/corona.gdshader")
const TUBE := preload("res://shaders/tube_light.gdshader")
const MOLTEN := preload("res://shaders/molten.gdshader")
const GLASS := preload("res://shaders/glass.gdshader")
const FIGURE := preload("res://shaders/figure.gdshader")

const WARM := Color(1.0, 0.62, 0.32)
const COOL := Color(0.78, 0.88, 1.0)

static var _cache: Dictionary = {}
static var _unit_box: BoxMesh
static var _quad: QuadMesh
static var _cyl: Dictionary = {}


static func unit_box() -> BoxMesh:
	if _unit_box == null:
		_unit_box = BoxMesh.new()
		_unit_box.size = Vector3.ONE
	return _unit_box


static func unit_quad() -> QuadMesh:
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = Vector2.ONE
	return _quad


## Unit cylinder (radius 0.5, height 1, axis Y) with few sides (retro).
static func unit_cylinder(sides := 8) -> CylinderMesh:
	if not _cyl.has(sides):
		var c := CylinderMesh.new()
		c.top_radius = 0.5
		c.bottom_radius = 0.5
		c.height = 1.0
		c.radial_segments = sides
		c.rings = 1
		_cyl[sides] = c
	return _cyl[sides]


static func tex(id: StringName) -> Texture2D:
	return TextureFactory.get_tex(id)


static func _facade(extra: Dictionary) -> Dictionary:
	var p := {
		"brick_tex": tex(&"brick"),
		"concrete_tex": tex(&"concrete"),
		"panel_tex": tex(&"panel"),
		"goods_tex": tex(&"goods"),
	}
	p.merge(extra, true)
	return p


static func _surface(texture_id: StringName, size: float, extra := {}) -> Dictionary:
	var p := { "albedo_tex": tex(texture_id), "tex_size": size }
	p.merge(extra, true)
	return p


static func get_mat(id: StringName) -> Material:
	if _cache.has(id):
		return _cache[id]
	var m: ShaderMaterial
	match id:
		# --- facades
		&"building":
			m = _make(FACADE, _facade({ "base_sink": 1.0 }))
		&"building_small":
			m = _make(FACADE, _facade({ "base_sink": 1.0, "fade_start": 3200.0, "fade_end": 4000.0 }))
		&"building_cool":
			m = _make(FACADE, _facade({ "base_sink": 1.0, "window_color": Color(0.72, 0.8, 0.95),
				"window_color_alt": Color(1.0, 0.7, 0.4), "alt_fraction": 0.04, "tint": Color(0.8, 0.85, 0.95) }))
		&"building_small_cool":
			m = _make(FACADE, _facade({ "base_sink": 1.0, "window_color": Color(0.72, 0.8, 0.95),
				"window_color_alt": Color(1.0, 0.7, 0.4), "alt_fraction": 0.04, "tint": Color(0.8, 0.85, 0.95),
				"fade_start": 3200.0, "fade_end": 4000.0 }))
		&"shopfront":
			m = _make(FACADE, _facade({ "base_sink": 1.0, "shopfront": 1.0, "lit_fraction": 0.3 }))
		&"authored_facade":
			m = _make(FACADE, _facade({ "use_world": 1.0, "style_override": 0.0, "lit_fraction": 0.12 }))
		&"authored_concrete":
			m = _make(FACADE, _facade({ "use_world": 1.0, "style_override": 1.0, "lit_fraction": 0.08 }))
		&"stack_wall":
			m = _make(FACADE, _facade({ "lit_fraction": 0.11, "style_override": 2.0, "tex_sizes": Vector3(2.5, 8.0, 8.0),
				"no_snap": 1.0, "floor_bands": 1.0, "interior_enabled": 0.0 }))
		&"stack_wall_cool":
			m = _make(FACADE, _facade({ "lit_fraction": 0.11, "style_override": 1.0, "tex_sizes": Vector3(2.5, 8.0, 8.0),
				"window_color": Color(0.85, 0.9, 1.0), "tint": Color(0.8, 0.85, 0.95),
				"no_snap": 1.0, "floor_bands": 1.0, "interior_enabled": 0.0 }))
		&"ceiling":
			m = _make(FACADE, _facade({ "windows_enabled": 0.0, "ceiling_lights": 1.0, "roof_color": Color(0.09, 0.07, 0.06),
				"no_snap": 1.0, "interior_enabled": 0.0 }))
		&"industrial_wall":
			m = _make(FACADE, _facade({ "use_world": 1.0, "style_override": 2.0, "windows_enabled": 0.0, "tint": Color(0.75, 0.7, 0.65),
				"no_snap": 1.0, "interior_enabled": 0.0 }))
		# --- ground
		&"ground":
			m = _make(GROUND, { "albedo_tex": tex(&"pavers"), "side_tex": tex(&"concrete"), "grime_tex": tex(&"grime") })
		&"concrete_floor":
			m = _make(GROUND, { "albedo_tex": tex(&"concrete"), "side_tex": tex(&"concrete"), "grime_tex": tex(&"grime"),
				"tex_size": 8.0, "use_world": 1.0, "wet_amount": 0.3, "tint": Color(0.8, 0.75, 0.7) })
		&"bridge_deck":
			m = _make(GROUND, { "albedo_tex": tex(&"grating"), "side_tex": tex(&"metal_dark"), "grime_tex": tex(&"grime"),
				"tex_size": 1.0, "wet_amount": 0.2 })
		&"grass_floor":
			m = _make(GROUND, { "albedo_tex": tex(&"fabric"), "side_tex": tex(&"concrete"), "grime_tex": tex(&"grime"),
				"tex_size": 2.4, "use_world": 1.0, "wet_amount": 0.05, "tint": Color(0.28, 0.62, 0.18) })
		&"crust_rock":
			m = _make(GROUND, { "albedo_tex": tex(&"concrete"), "side_tex": tex(&"concrete"), "grime_tex": tex(&"grime"),
				"tex_size": 7.0, "use_world": 1.0, "wet_amount": 0.12, "tint": Color(0.34, 0.26, 0.22) })
		# --- textured surfaces
		&"structure":
			m = _make(SURFACE, _surface(&"metal_dark", 3.0, { "grime": 0.3 }))
		&"structure_fade_near":
			m = _make(SURFACE, _surface(&"metal_dark", 3.0, { "grime": 0.3, "fade_start": 700.0, "fade_end": 900.0 }))
		&"structure_fade_mid":
			m = _make(SURFACE, _surface(&"metal_dark", 3.0, { "grime": 0.3, "fade_start": 1000.0, "fade_end": 1350.0 }))
		&"structure_fade_far":
			m = _make(SURFACE, _surface(&"metal_dark", 3.0, { "grime": 0.3, "fade_start": 1400.0, "fade_end": 1800.0 }))
		&"structure_world":
			m = _make(SURFACE, _surface(&"metal_dark", 3.0, { "use_world": 1.0 }))
		&"awning_rust":
			m = _make(SURFACE, _surface(&"fabric", 1.2, { "tint": Color(0.65, 0.32, 0.22), "roughness_val": 0.95 }))
		&"awning_dark":
			m = _make(SURFACE, _surface(&"fabric", 1.2, { "tint": Color(0.36, 0.34, 0.30), "roughness_val": 0.95 }))
		&"crop_green":
			m = _make(SURFACE, _surface(&"fabric", 1.2, { "tint": Color(0.34, 0.96, 0.24), "roughness_val": 0.90, "specular_val": 0.08 }))
		&"crop_dark":
			m = _make(SURFACE, _surface(&"fabric", 1.2, { "tint": Color(0.20, 0.68, 0.16), "roughness_val": 0.94, "specular_val": 0.06 }))
		&"preserve_wall":
			m = _make(SURFACE, _surface(&"panel", 6.0, { "use_world": 1.0, "tint": Color(0.92, 0.88, 0.78), "roughness_val": 0.90, "specular_val": 0.08, "no_snap": 1.0 }))
		&"tree_trunk":
			m = _make(SURFACE, _surface(&"wood", 1.2, { "tint": Color(0.32, 0.22, 0.14), "roughness_val": 0.95 }))
		&"deer_coat":
			m = _make(SURFACE, _surface(&"fabric", 1.0, { "tint": Color(0.76, 0.50, 0.32), "roughness_val": 0.92 }))
		&"plate":
			m = _make(SURFACE, _surface(&"plate", 0.9, { "use_world": 1.0, "roughness_val": 0.7, "specular_val": 0.25, "tint": Color(0.8, 0.78, 0.76) }))
		&"wood":
			m = _make(SURFACE, _surface(&"wood", 1.2))
		&"wood_dark":
			m = _make(SURFACE, _surface(&"wood", 1.2, { "tint": Color(0.55, 0.5, 0.45), "use_world": 1.0 }))
		&"fabric":
			m = _make(SURFACE, _surface(&"fabric", 1.0))
		&"fabric_dark":
			m = _make(SURFACE, _surface(&"fabric", 1.0, { "tint": Color(0.55, 0.45, 0.38) }))
		&"metal_light":
			m = _make(SURFACE, _surface(&"metal_dark", 1.0, { "tint": Color(2.6, 2.4, 2.2), "roughness_val": 0.5, "specular_val": 0.5 }))
		&"copper":
			m = _make(SURFACE, _surface(&"metal_dark", 1.0, { "tint": Color(3.0, 1.8, 1.0), "roughness_val": 0.5, "specular_val": 0.5 }))
		&"ceramic":
			m = _make(SURFACE, _surface(&"fabric", 1.0, { "tint": Color(1.7, 1.65, 1.5), "roughness_val": 0.4 }))
		&"concrete":
			m = _make(SURFACE, _surface(&"concrete", 4.0, { "use_world": 1.0 }))
		&"hazard":
			m = _make(GROUND, { "albedo_tex": tex(&"hazard"), "side_tex": tex(&"hazard"), "grime_tex": tex(&"grime"), "tex_size": 1.2, "use_world": 1.0, "wet_amount": 0.2 })
		&"rail_steel":
			m = _make(GROUND, { "albedo_tex": tex(&"metal_dark"), "side_tex": tex(&"metal_dark"), "grime_tex": tex(&"grime"), "tex_size": 1.0, "wet_amount": 0.0, "tint": Color(1.6, 1.5, 1.4) })
		&"floor_wood":
			m = _make(GROUND, { "albedo_tex": tex(&"wood"), "side_tex": tex(&"wood"), "grime_tex": tex(&"grime"), "tex_size": 1.2, "use_world": 1.0, "wet_amount": 0.0, "tint": Color(0.6, 0.55, 0.5) })
		&"poster_tree":
			m = _make(SURFACE, _surface(&"poster_tree", 1.0, { "stretch": 1.0, "roughness_val": 0.95, "specular_val": 0.1 }))
		&"note":
			m = _make(SURFACE, _surface(&"note", 1.0, { "stretch": 1.0, "roughness_val": 0.95, "specular_val": 0.1 }))
		&"cloth_red":
			m = _make(SURFACE, _surface(&"fabric", 1.0, { "tint": Color(1.4, 0.45, 0.35) }))
		&"cloth_teal":
			m = _make(SURFACE, _surface(&"fabric", 1.0, { "tint": Color(0.45, 1.1, 1.0) }))
		&"cloth_beige":
			m = _make(SURFACE, _surface(&"fabric", 1.0, { "tint": Color(1.3, 1.15, 0.9) }))
		&"cloth_magenta":
			m = _make(SURFACE, _surface(&"fabric", 1.0, { "tint": Color(1.3, 0.5, 1.1) }))
		&"tally":
			m = _make(DECAL, { "albedo_tex": tex(&"tally") })
		# --- light sources
		&"lamp":
			m = _make(EMISSIVE, { "color": WARM, "energy": 4.0 })
		&"lamp_cool":
			m = _make(EMISSIVE, { "color": COOL, "energy": 4.0 })
		&"bulb":
			m = _make(EMISSIVE, { "color": Color(1.0, 0.8, 0.5), "energy": 6.0 })
		&"rail_glow":
			m = _make(EMISSIVE, { "color": Color(1.0, 0.72, 0.25), "energy": 1.7, "no_snap": 1.0, "min_px_y": 1.15 })
		&"window_glow":
			m = _make(EMISSIVE, { "color": Color(1.0, 0.7, 0.38), "energy": 2.2 })
		&"sign_green":
			m = _make(EMISSIVE, { "color": Color(0.3, 1.0, 0.75), "energy": 2.4 })
		&"sign_magenta":
			m = _make(EMISSIVE, { "color": Color(1.0, 0.35, 0.85), "energy": 2.4 })
		&"sign_cyan":
			m = _make(EMISSIVE, { "color": Color(0.45, 0.8, 1.0), "energy": 2.4 })
		&"sign_yellow":
			m = _make(EMISSIVE, { "color": Color(1.0, 0.85, 0.4), "energy": 2.4 })
		&"beacon_red":
			m = _make(EMISSIVE, { "color": Color(1.0, 0.15, 0.1), "energy": 5.0 })
		&"grow_magenta":
			m = _make(EMISSIVE, { "color": Color(1.0, 0.44, 0.92), "energy": 3.4, "no_snap": 1.0 })
		&"tram_headlamp":
			m = _make(EMISSIVE, { "color": Color(1.0, 0.82, 0.48), "energy": 4.8 })
		&"sky_panel":
			m = _make(EMISSIVE, { "color": Color(1.0, 0.95, 0.82), "energy": 3.0, "no_snap": 1.0 })
		&"water_beam":
			m = _make(EMISSIVE, { "color": Color(0.74, 0.92, 1.0), "energy": 2.4, "no_snap": 1.0 })
		&"drill_glow":
			m = _make(EMISSIVE, { "color": Color(1.0, 0.48, 0.14), "energy": 4.5 })
		&"container_rust":
			m = _make(SURFACE, _surface(&"panel", 4.0, { "tint": Color(1.6, 0.9, 0.65) }))
		&"container_teal":
			m = _make(SURFACE, _surface(&"panel", 4.0, { "tint": Color(0.7, 1.1, 1.05) }))
		&"container_grey":
			m = _make(SURFACE, _surface(&"panel", 4.0, { "tint": Color(1.1, 1.1, 1.15) }))
		&"corona":
			m = _make(CORONA, { "color": WARM, "energy": 0.9 })
		&"corona_soft":
			m = _make(CORONA, { "color": WARM, "energy": 0.45, "fade_start": 400.0, "fade_end": 3500.0 })
		&"corona_cool":
			m = _make(CORONA, { "color": COOL, "energy": 0.8 })
		&"corona_molten":
			m = _make(CORONA, { "color": Color(1.0, 0.45, 0.1), "energy": 1.4, "fade_start": 300.0, "fade_end": 1500.0 })
		&"corona_magenta":
			m = _make(CORONA, { "color": Color(1.0, 0.42, 0.90), "energy": 0.55, "fade_start": 180.0, "fade_end": 900.0 })
		&"tube":
			m = _make(TUBE, {})
		&"molten":
			m = _make(MOLTEN, {})
		&"molten_slow":
			m = _make(MOLTEN, { "flow": 0.3, "energy": 2.2 })
		&"glass":
			m = _make(GLASS, {})
		&"figure":
			m = _make(FIGURE, {})
		_:
			push_error("Unknown material id %s" % id)
			m = _make(SURFACE, _surface(&"metal_dark", 2.0))
	_cache[id] = m
	return m


static func _make(shader: Shader, params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	for k: String in params:
		m.set_shader_parameter(k, params[k])
	return m


## Adds a scaled unit-cube MeshInstance3D (and optional collision box).
static func add_box(parent: Node3D, body: StaticBody3D, center: Vector3, size: Vector3, mat_id: StringName, collide := true, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = unit_box()
	mi.position = center
	mi.rotation = rot
	mi.scale = size
	mi.material_override = get_mat(mat_id)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	if collide and body != null:
		add_collision_box(body, center, size, rot)
	return mi


static func add_collision_box(body: StaticBody3D, center: Vector3, size: Vector3, rot := Vector3.ZERO) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = center
	cs.rotation = rot
	body.add_child(cs)


## Cylinder from point a to point b (any direction).
static func add_cylinder(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat_id: StringName, sides := 8) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = unit_cylinder(sides)
	mi.material_override = get_mat(mat_id)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var axis := b - a
	var length := axis.length()
	var y := axis / length
	var x := y.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y).normalized()
	mi.transform = Transform3D(Basis(x * radius * 2.0, y * length, z * radius * 2.0), (a + b) * 0.5)
	parent.add_child(mi)
	return mi


## items: Array of { "c": Vector3, "s": Vector3, "seed": float, optional "r": Vector3 euler }.
static func add_multimesh(parent: Node3D, items: Array, mat_id: StringName, vis_end := 0.0, mesh: Mesh = null) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh if mesh != null else unit_box()
	mm.instance_count = items.size()
	for i in items.size():
		var b: Dictionary = items[i]
		var s: Vector3 = b.s
		var basis := Basis.from_euler(b.get("r", Vector3.ZERO)) * Basis.from_scale(s)
		mm.set_instance_transform(i, Transform3D(basis, b.c))
		mm.set_instance_custom_data(i, Color(float(b.get("seed", 0.0)), s.x, s.y, s.z))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = get_mat(mat_id)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if vis_end > 0.0:
		mmi.visibility_range_end = vis_end
		mmi.visibility_range_end_margin = 250.0
	parent.add_child(mmi)
	return mmi


## Camera-facing glows at the given positions (size = diameter in metres).
static func add_coronas(parent: Node3D, positions: Array, size: float, mat_id := &"corona") -> MultiMeshInstance3D:
	var items: Array = []
	for p: Vector3 in positions:
		items.append({ "c": p, "s": Vector3(size, size, size) })
	var mmi := add_multimesh(parent, items, mat_id, 0.0, unit_quad())
	mmi.extra_cull_margin = size
	return mmi


static func make_lamp_light(color := WARM, energy := 2.2, light_range := 16.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = light_range
	l.omni_attenuation = 1.2
	l.shadow_enabled = false
	l.light_volumetric_fog_energy = 1.5
	l.distance_fade_enabled = true
	l.distance_fade_begin = 280.0
	l.distance_fade_length = 90.0
	return l


static func add_sign(parent: Node3D, pos: Vector3, text: String, pixel_size := 0.05, color := Color(1.0, 0.85, 0.55), rot_y := 0.0) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.rotation.y = rot_y
	l.pixel_size = pixel_size
	l.font_size = 32
	l.outline_size = 0
	l.modulate = color
	l.shaded = false
	l.double_sided = false
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l


## Releases cached resources (called on exit so nothing leaks at shutdown).
static func clear_caches() -> void:
	_cache.clear()
	_cyl.clear()
	_unit_box = null
	_quad = null
	TextureFactory._cache.clear()
	ItemDB.clear_caches()
	Crowd._mesh = null
