extends SceneTree
## Offline sound synthesis for the slice's ambience (run once, re-run to tweak):
##   godot --headless --path game --script res://tools/gen_audio.gd
## Writes res://audio/*.wav (22.05 kHz mono). Loops are crossfaded seamlessly.

const SR := 22050
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://audio"))
	_rng.seed = 31
	_save("rumble", _loop(_rumble(32.0), 3.0))
	_save("vent", _loop(_vent(20.0), 2.0))
	_save("room_tone", _loop(_room_tone(16.0), 2.0))
	_save("wind", _loop(_wind(30.0), 3.0))
	_save("machinery", _loop(_machinery(16.0), 0.5))
	_save("foundry_roar", _loop(_roar(12.0), 1.5))
	_save("market", _loop(_market(24.0), 2.0))
	_save("lift_motor", _loop(_lift_motor(6.0), 0.5))
	_save("lift_clunk", _clunk())
	for i in 3:
		_save("metal_ring_%d" % i, _metal_ring([55.0, 92.0, 160.0][i], 6.0))
	_save("impact_far", _impact())
	_save("horn_far", _horn())
	_save("creak", _creak())
	for i in 4:
		_save("step_stone_%d" % i, _step(false))
		_save("step_metal_%d" % i, _step(true))
	print("[gen_audio] done")
	quit(0)


# ---------------------------------------------------------------- io / util

func _save(name: String, data: PackedFloat32Array) -> void:
	var peak := 0.0
	for v in data:
		peak = maxf(peak, absf(v))
	var g := 0.89 / maxf(peak, 1e-6)
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i] * g, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = bytes
	w.save_to_wav("res://audio/%s.wav" % name)
	print("[gen_audio] %s  %.1fs" % [name, data.size() / float(SR)])


## Makes a buffer loop seamlessly: crossfade the tail into the head.
func _loop(d: PackedFloat32Array, fade_s: float) -> PackedFloat32Array:
	var f := int(fade_s * SR)
	var n := d.size() - f
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = d[i]
	for i in f:
		var t := float(i) / f
		out[i] = d[i] * sqrt(t) + d[n + i] * sqrt(1.0 - t)
	return out


func _buf(seconds: float) -> PackedFloat32Array:
	var d := PackedFloat32Array()
	d.resize(int(seconds * SR))
	return d


func _noise() -> float:
	return _rng.randf() * 2.0 - 1.0


## One-pole low-pass coefficient for a cutoff in Hz.
func _lp(hz: float) -> float:
	return 1.0 - exp(-TAU * hz / SR)


## Slow random control signal (smoothed noise), values ~0..1.
func _ctrl(seconds: float, rate_hz: float) -> PackedFloat32Array:
	var d := _buf(seconds)
	var target := _rng.randf()
	var v := target
	var a := _lp(rate_hz)
	var hold := 0
	for i in d.size():
		hold -= 1
		if hold <= 0:
			target = _rng.randf()
			hold = int(SR / rate_hz)
		v += a * (target - v)
		d[i] = v
	return d


# ---------------------------------------------------------------- beds

func _rumble(s: float) -> PackedFloat32Array:
	var d := _buf(s)
	var swell := _ctrl(s, 0.08)
	var b := 0.0
	var l1 := 0.0
	var l2 := 0.0
	var a := _lp(55.0)
	for i in d.size():
		b = b * 0.998 + _noise() * 0.02
		l1 += a * (b - l1)
		l2 += a * (l1 - l2)
		var t := float(i) / SR
		var hum := sin(TAU * 31.0 * t) * 0.25 + sin(TAU * 46.5 * t + 1.3) * 0.12
		d[i] = (l2 * 6.0 + hum * 0.4) * (0.55 + 0.6 * swell[i])
	return d


func _vent(s: float) -> PackedFloat32Array:
	var d := _buf(s)
	var mod := _ctrl(s, 0.25)
	var lo := 0.0
	var hi := 0.0
	var a1 := _lp(1400.0)
	var a2 := _lp(280.0)
	for i in d.size():
		var n := _noise()
		lo += a1 * (n - lo)
		hi += a2 * (lo - hi)
		var t := float(i) / SR
		d[i] = (lo - hi) * (0.7 + 0.5 * mod[i]) + sin(TAU * 120.0 * t) * 0.03
	return d


func _room_tone(s: float) -> PackedFloat32Array:
	var d := _buf(s)
	var l := 0.0
	var a := _lp(350.0)
	for i in d.size():
		l += a * (_noise() - l)
		var t := float(i) / SR
		var hum := sin(TAU * 50.0 * t) * 0.08 + sin(TAU * 100.0 * t) * 0.05 + sin(TAU * 150.0 * t) * 0.02
		d[i] = l * 0.5 + hum
	return d


func _wind(s: float) -> PackedFloat32Array:
	var d := _buf(s)
	var gust := _ctrl(s, 0.18)
	var sweep := _ctrl(s, 0.3)
	var low := 0.0
	var band := 0.0
	for i in d.size():
		var n := _noise()
		var fc := 180.0 + 900.0 * sweep[i] * gust[i]
		low += _lp(fc) * (n - low)
		band += _lp(fc * 0.35) * (low - band)
		d[i] = (low - band * 0.6) * (0.25 + 1.1 * gust[i] * gust[i])
	return d


func _machinery(s: float) -> PackedFloat32Array:
	var d := _buf(s)
	var grind_l := 0.0
	var grind_h := 0.0
	var beat := 1.6
	for i in d.size():
		var t := float(i) / SR
		var n := _noise()
		grind_l += _lp(420.0) * (n - grind_l)
		grind_h += _lp(140.0) * (grind_l - grind_h)
		var g := (grind_l - grind_h) * (0.5 + 0.5 * sin(TAU * 7.0 * t)) * 0.4
		var tb := fmod(t, beat)
		var thump := sin(TAU * 52.0 * tb) * exp(-tb * 9.0) * 1.2
		var tc := fmod(t + beat * 0.5, beat * 2.0)
		var clank := 0.0
		for f in [430.0, 1170.0, 1690.0]:
			clank += sin(TAU * f * tc) * exp(-tc * 11.0) * 0.25
		d[i] = g + thump + clank * (1.0 if tc < 0.6 else 0.0)
	return d


func _roar(s: float) -> PackedFloat32Array:
	var d := _buf(s)
	var mod := _ctrl(s, 1.5)
	var l := 0.0
	var l2 := 0.0
	for i in d.size():
		var n := _noise()
		l += _lp(600.0) * (n - l)
		l2 += _lp(120.0) * (l - l2)
		var crackle := 0.0
		if _rng.randf() < 0.0015:
			crackle = _noise() * 3.0
		d[i] = l * 0.6 + l2 * 1.4 * (0.7 + 0.5 * mod[i]) + crackle * 0.4
	return d


## Distant market murmur: many band-passed noise "voices" with syllabic
## envelopes, plus the buzz of the tube light.
func _market(s: float) -> PackedFloat32Array:
	var d := _buf(s)
	var voices := 14
	for v in voices:
		var env := _ctrl(s, _rng.randf_range(3.0, 6.0))
		var presence := _ctrl(s, 0.15)
		var fc := _rng.randf_range(350.0, 900.0)
		var a1 := _lp(fc * 2.2)
		var a2 := _lp(fc * 0.7)
		var lo := 0.0
		var hi := 0.0
		for i in d.size():
			var n := _noise()
			lo += a1 * (n - lo)
			hi += a2 * (lo - hi)
			var e := maxf(0.0, env[i] - 0.45) * 2.0 * smoothstep(0.35, 0.7, presence[i])
			d[i] += (lo - hi) * e * 0.35
	var l := 0.0
	for i in d.size():
		var t := float(i) / SR
		l += _lp(250.0) * (_noise() - l)
		d[i] = d[i] * 0.8 + sin(TAU * 100.0 * t) * 0.02 + l * 0.15
	return d


func _lift_motor(s: float) -> PackedFloat32Array:
	var d := _buf(s)
	for i in d.size():
		var t := float(i) / SR
		var w := 1.0 + 0.01 * sin(TAU * 0.7 * t)
		d[i] = sin(TAU * 110.0 * w * t) * 0.3 + sin(TAU * 220.0 * w * t) * 0.15 + sin(TAU * 333.0 * t) * 0.05 + _noise() * 0.04
	return d


# ---------------------------------------------------------------- one-shots

func _clunk() -> PackedFloat32Array:
	var d := _buf(1.2)
	var l := 0.0
	for i in d.size():
		var t := float(i) / SR
		l += _lp(900.0) * (_noise() - l)
		d[i] = sin(TAU * 70.0 * t) * exp(-t * 10.0) + l * exp(-t * 25.0) * 1.5 + sin(TAU * 820.0 * t) * exp(-t * 14.0) * 0.2
	return d


## Inharmonic struck-metal resonance with a long decay (distant structure).
func _metal_ring(f0: float, s: float) -> PackedFloat32Array:
	var d := _buf(s)
	var partials := [[1.0, 1.0, 0.7], [2.76, 0.5, 1.1], [5.4, 0.3, 1.8], [8.93, 0.18, 2.6], [13.3, 0.1, 3.5]]
	var l := 0.0
	for i in d.size():
		var t := float(i) / SR
		var v := 0.0
		for p: Array in partials:
			v += sin(TAU * f0 * float(p[0]) * t) * float(p[1]) * exp(-t * float(p[2]))
		l += _lp(2000.0) * (_noise() - l)
		d[i] = v + l * exp(-t * 30.0) * 0.6
	return d


func _impact() -> PackedFloat32Array:
	var d := _buf(5.0)
	var l := 0.0
	var l2 := 0.0
	for i in d.size():
		var t := float(i) / SR
		var f := 38.0 + 30.0 * exp(-t * 6.0)
		l += _lp(400.0) * (_noise() - l)
		l2 += _lp(90.0) * (l - l2)
		d[i] = sin(TAU * f * t) * exp(-t * 2.2) + l2 * 3.0 * exp(-t * 1.1) + l * exp(-t * 12.0) * 0.5
	return d


func _horn() -> PackedFloat32Array:
	var d := _buf(8.0)
	var l := 0.0
	for i in d.size():
		var t := float(i) / SR
		var e := smoothstep(0.0, 0.9, t) * (1.0 - smoothstep(4.5, 7.8, t))
		var v := 0.0
		for f in [82.0, 82.6, 123.0, 164.4]:
			v += fmod(f * t, 1.0) * 2.0 - 1.0
		l += _lp(380.0) * (v * 0.25 - l)
		d[i] = l * e
	return d


func _creak() -> PackedFloat32Array:
	var d := _buf(2.2)
	var l := 0.0
	var h := 0.0
	var phase := 0.0
	for i in d.size():
		var t := float(i) / SR
		var rate := 18.0 + 20.0 * sin(t * 2.1)
		phase += rate / SR
		var pulse := exp(-fmod(phase, 1.0) * 14.0)
		var fc := 500.0 + 350.0 * sin(t * 1.3)
		l += _lp(fc * 1.6) * (_noise() - l)
		h += _lp(fc * 0.6) * (l - h)
		var e := smoothstep(0.0, 0.2, t) * (1.0 - smoothstep(1.6, 2.2, t))
		d[i] = (l - h) * pulse * e
	return d


func _step(metal: bool) -> PackedFloat32Array:
	var d := _buf(0.32)
	var l := 0.0
	var cut := _rng.randf_range(900.0, 1600.0)
	var f1 := _rng.randf_range(850.0, 1000.0)
	for i in d.size():
		var t := float(i) / SR
		l += _lp(cut) * (_noise() - l)
		var v := l * exp(-t * 38.0) + sin(TAU * 90.0 * t) * exp(-t * 40.0) * 0.5
		if metal:
			v += (sin(TAU * f1 * t) * 0.3 + sin(TAU * f1 * 1.58 * t) * 0.2 + sin(TAU * f1 * 2.4 * t) * 0.12) * exp(-t * 16.0)
		d[i] = v
	return d
