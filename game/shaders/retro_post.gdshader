// Full-screen retro output: colour quantisation with 4x4 ordered dithering,
// applied at the internal render resolution (960x540, upscaled nearest).
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float color_levels = 40.0;
uniform float dither_strength : hint_range(0.0, 2.0) = 1.0;
uniform bool enabled = true;

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	if (enabled) {
		ivec2 p = ivec2(FRAGCOORD.xy) % 4;
		float t = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0 - 0.5;
		float lv = color_levels - 1.0;
		c = floor(c * lv + 0.5 + t * dither_strength) / lv;
	}
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
