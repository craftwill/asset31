// Asset 31 outer Mantle steel shell as seen from orbital space (refs 075s, 625s).
// Bare dark warm-charcoal matte megastructure steel in vacuum: soft angled solar
// terminator, subtle macro panel/tonal mottling, pitch-black night side occluding
// background stars, zero blue atmosphere halo, zero glossy specular.
shader_type spatial;
render_mode unshaded, fog_disabled;

uniform vec3 sun_dir = vec3(0.95, 0.20, 0.22);
uniform vec3 lit_color : source_color = vec3(0.248, 0.236, 0.218);
uniform vec3 dark_color : source_color = vec3(0.002, 0.002, 0.003);
uniform float light_energy = 1.0;

varying vec3 v_world_n;
varying vec3 v_local_p;

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));
	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);
	float nxy0 = mix(nx00, nx10, f.y);
	float nxy1 = mix(nx01, nx11, f.y);
	return mix(nxy0, nxy1, f.z);
}

void vertex() {
	v_world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_local_p = normalize(VERTEX);
}

void fragment() {
	vec3 n = normalize(v_world_n);
	vec3 l = normalize(sun_dir);
	float ndl = dot(n, l);

	// Soft, matte planetary steel diffuse falloff (Oren-Nayar-like flat-topped response
	// matching the broad warm-charcoal lit face and soft diagonal terminator in 075s/625s).
	float term = smoothstep(-0.09, 0.14, ndl);
	float shade = pow(max(ndl + 0.06, 0.0) / 1.06, 0.68) * term;

	// Very subtle macro megastructure hull mottling & faint structural plating variation.
	float m1 = vnoise3(v_local_p * 6.5);
	float m2 = vnoise3(v_local_p * 19.0);
	float mottle = 0.92 + 0.11 * m1 + 0.05 * m2;

	// Faint grazing limb darkening so the lit right edge reads as a solid curved steel sphere.
	vec3 v = normalize(VIEW);
	vec3 n_view = normalize(NORMAL);
	float ndv = clamp(dot(n_view, v), 0.0, 1.0);
	float limb = mix(0.86, 1.0, smoothstep(0.0, 0.28, ndv));

	vec3 col = mix(dark_color, lit_color * mottle * limb * light_energy, shade);
	ALBEDO = col;
}
