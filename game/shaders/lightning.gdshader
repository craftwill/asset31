// One lightning stroke in the haze below (reference 617s): a jagged pale-violet bolt
// with a soft glow around it, drawn on an upright quad and flickered by script.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

#include "res://shaders/retro_common.gdshaderinc"

uniform vec3 color : source_color = vec3(0.78, 0.72, 1.0);
uniform float intensity = 0.0;
uniform float seed = 0.0;

float path_x(float yq) {
	// Random walk, stepped: a retro zig-zag rather than a smooth curve.
	float x = 0.5;
	float amp = 0.09;
	for (int i = 0; i < 3; i++) {
		float s = exp2(float(i)) * 6.0;
		float a = hash12(vec2(floor(yq * s), seed + float(i) * 13.0));
		float b = hash12(vec2(floor(yq * s) + 1.0, seed + float(i) * 13.0));
		x += (mix(a, b, fract(yq * s)) - 0.5) * amp;
		amp *= 0.55;
	}
	return x;
}

void fragment() {
	float y = 1.0 - UV.y;                 // 0 at the foot, 1 at the top
	float yq = floor(y * 48.0) / 48.0;
	float d = abs(UV.x - path_x(yq));
	float taper = smoothstep(0.0, 0.08, y) * (1.0 - smoothstep(0.82, 1.0, y));
	float core = (1.0 - smoothstep(0.008, 0.022, d)) * taper;
	// Branch off one side, lower down.
	float bx = path_x(yq) + (y - 0.55) * (hash12(vec2(seed, 3.0)) > 0.5 ? 0.5 : -0.5);
	float branch = (1.0 - smoothstep(0.006, 0.016, abs(UV.x - bx))) * step(0.25, y) * step(y, 0.55) * 0.6;
	vec2 c = UV - vec2(0.5, 0.55);
	// Round glow that reaches zero before the edge of the quad.
	float halo = exp(-dot(c, c) * 14.0) * 0.32 * (1.0 - smoothstep(0.3, 0.48, length(c)));
	ALBEDO = color * (core * 4.0 + branch * 2.5 + halo) * intensity;
}
