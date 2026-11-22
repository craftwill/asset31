// Shared retro helpers. Global uniforms live in project.godot [shader_globals]
// and are driven at runtime by main.gd (F6 cycles modes).

global uniform vec2 retro_snap_resolution;
global uniform float retro_snap_strength;
global uniform vec3 world_origin;

// Screen-space vertex snapping (the "shaky" late-90s look). Vertices are
// quantised to a virtual pixel grid in NDC. Depth is untouched, so it does not
// introduce z-fighting. Vertices behind the camera are left alone.
vec4 retro_snap(vec4 clip) {
	if (retro_snap_strength <= 0.0 || clip.w <= 0.0001) {
		return clip;
	}
	vec2 grid = retro_snap_resolution * 0.5;
	vec2 ndc = clip.xy / clip.w;
	vec2 snapped = round(ndc * grid) / grid;
	clip.xy = mix(ndc, snapped, retro_snap_strength) * clip.w;
	return clip;
}

// Comfort-tuned vertex snapping: giant megastructure quads (walls, slabs,
// long rails/girders) are never snapped so planes do not swim, and in subtle
// mode snapping fades out in the distance so tiny city silhouettes stay steady.
vec4 retro_snap_stable(vec4 clip, vec3 obj_scale) {
	if (retro_snap_strength <= 0.0 || clip.w <= 0.0001) {
		return clip;
	}
	float max_dim = max(obj_scale.x, max(obj_scale.y, obj_scale.z));
	if (max_dim > 80.0) {
		return clip;
	}
	float dist_k = (retro_snap_resolution.x > 500.0) ? (1.0 - smoothstep(80.0, 220.0, clip.w)) : 1.0;
	float s = retro_snap_strength * dist_k;
	if (s <= 0.001) {
		return clip;
	}
	vec2 grid = retro_snap_resolution * 0.5;
	vec2 ndc = clip.xy / clip.w;
	vec2 snapped = round(ndc * grid) / grid;
	clip.xy = mix(ndc, snapped, s) * clip.w;
	return clip;
}

const float RETRO_BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

// 4x4 ordered Bayer threshold in (0, 1) for retro dithered LOD fades.
float retro_bayer(vec2 fragcoord) {
	ivec2 p = ivec2(fragcoord) % 4;
	return (RETRO_BAYER[p.y * 4 + p.x] + 0.5) / 16.0;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// Object-space position in metres. MultiMesh instances carry their size in
// INSTANCE_CUSTOM.yzw (robust regardless of how the instance basis is applied);
// plain MeshInstance3D nodes use the scale of MODEL_MATRIX.
vec3 retro_object_scale(mat4 model, vec4 custom) {
	if (custom.y > 0.0) {
		return custom.yzw;
	}
	return vec3(length(model[0].xyz), length(model[1].xyz), length(model[2].xyz));
}

// Picks a planar projection for an axis-aligned box face. Returns facade-style
// coordinates: x along the face, y up (or the other horizontal axis on
// horizontal faces). `n` is the face normal in the same space as `p`.
vec2 retro_box_uv(vec3 p, vec3 n) {
	vec3 a = abs(n);
	if (a.y > a.x && a.y > a.z) {
		return p.xz;
	}
	if (a.x > a.z) {
		return vec2(p.z * sign(n.x), p.y);
	}
	return vec2(-p.x * sign(n.z), p.y);
}
