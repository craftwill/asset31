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
