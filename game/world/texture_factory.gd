class_name TextureFactory
extends RefCounted
## Deterministic low-resolution pixel textures (the retro material family).
## Generated at startup: tiny, editable here, and no import settings to manage.
## All textures tile seamlessly and carry mipmaps (sampled nearest-mipmap).

static var _cache: Dictionary = {}


static func get_tex(id: StringName) -> ImageTexture:
	if _cache.has(id):
		return _cache[id]
	var img: Image
	match id:
		&"brick": img = _brick()
		&"concrete": img = _concrete()
		&"panel": img = _panel()
		&"plate": img = _plate()
		&"pavers": img = _pavers()
		&"metal_dark": img = _metal_dark()
		&"wood": img = _wood()
		&"fabric": img = _fabric()
		&"grating": img = _grating()
		&"goods": img = _goods()
		&"poster_tree": img = _poster_tree()
		&"note": img = _note()
		&"tally": img = _tally()
		&"hazard": img = _hazard()
		&"grime": img = _grime()
		_:
			push_error("Unknown texture %s" % id)
			img = _blank(4, 4, Color.MAGENTA)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[id] = tex
	return tex


# ---------------------------------------------------------------- helpers

static func _blank(w: int, h: int, c: Color) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return img


static func _h(x: int, y: int, s: int) -> float:
	var n: int = x * 374761393 + y * 668265263 + s * 982451653
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xFFFF) / 65535.0


static func _vnoise(x: float, y: float, period: int, s: int) -> float:
	var xi := floori(x)
	var yi := floori(y)
	var fx := x - xi
	var fy := y - yi
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a := _h(posmod(xi, period), posmod(yi, period), s)
	var b := _h(posmod(xi + 1, period), posmod(yi, period), s)
	var c := _h(posmod(xi, period), posmod(yi + 1, period), s)
	var d := _h(posmod(xi + 1, period), posmod(yi + 1, period), s)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


## Tileable fBm over an image of `size` pixels, base cell `cell` pixels.
static func _fbm(px: int, py: int, size: int, cell: int, s: int) -> float:
	var v := 0.0
	var amp := 0.5
	var c := cell
	var total := 0.0
	for o in 3:
		var period := maxi(1, size / c)
		v += amp * _vnoise(float(px) / c, float(py) / c, period, s + o * 17)
		total += amp
		amp *= 0.5
		c = maxi(1, c / 2)
	return v / total


static func _jit(c: Color, amount: float, x: int, y: int, s: int) -> Color:
	var j := (_h(x, y, s) - 0.5) * amount
	return Color(clampf(c.r + j, 0, 1), clampf(c.g + j, 0, 1), clampf(c.b + j, 0, 1), c.a)


# ---------------------------------------------------------------- textures

## 64 px = 2.5 m. Bricks 8x4 px (incl. mortar), running bond, soot streaks.
static func _brick() -> Image:
	var img := _blank(64, 64, Color.BLACK)
	for y in 64:
		for x in 64:
			var row := y / 4
			var off := 4 if row % 2 == 1 else 0
			var bx := (x + off) / 8
			var mortar := y % 4 == 3 or (x + off) % 8 == 7
			var c: Color
			if mortar:
				c = Color(0.17, 0.13, 0.10)
			else:
				var t := _h(posmod(bx, 8), row, 11)
				c = Color(0.42, 0.20, 0.12).lerp(Color(0.30, 0.15, 0.10), t)
				if _h(posmod(bx, 8), row, 12) > 0.9:
					c = Color(0.22, 0.13, 0.09)
			var g := _fbm(x, y, 64, 16, 13)
			c = c * (0.72 + 0.4 * g)
			img.set_pixel(x, y, _jit(c, 0.035, x, y, 14))
	return img


## 64 px = 4 m. Poured concrete panels with seams, tie holes and stains.
static func _concrete() -> Image:
	var img := _blank(64, 64, Color.BLACK)
	for y in 64:
		for x in 64:
			var g := _fbm(x, y, 64, 16, 21)
			var c := Color(0.36, 0.31, 0.26) * (0.75 + 0.4 * g)
			var streak := _vnoise(float(x) / 3.0, float(y) / 24.0, 21, 22)
			c = c * (0.9 + 0.12 * streak)
			if x % 32 == 0 or y % 32 == 0:
				c = c * 0.8
			if (x % 16 == 8) and (y % 16 == 8) and _h(x, y, 24) > 0.5:
				c = c * 0.45
			img.set_pixel(x, y, _jit(c, 0.03, x, y, 23))
	return img


## 64 px = 4 m. Facade metal panels 32x16 with seams and rust.
static func _panel() -> Image:
	var img := _blank(64, 64, Color.BLACK)
	for y in 64:
		for x in 64:
			var pid := (x / 32) + (y / 16) * 2
			var c := Color(0.25, 0.19, 0.15).lerp(Color(0.18, 0.15, 0.13), _h(pid, 0, 31))
			var rust := _fbm(x, y, 64, 8, 32)
			if rust > 0.62:
				c = c.lerp(Color(0.33, 0.17, 0.08), (rust - 0.62) * 2.0)
			if x % 32 == 0 or y % 16 == 0:
				c = c * 0.5
			elif x % 32 == 1 or y % 16 == 1:
				c = c * 1.15
			img.set_pixel(x, y, _jit(c, 0.03, x, y, 33))
	return img


## 64 px = 0.9 m. One riveted interior wall plate (frame 000s).
static func _plate() -> Image:
	var img := _blank(64, 64, Color.BLACK)
	for y in 64:
		for x in 64:
			var g := _fbm(x, y, 64, 16, 41)
			var c := Color(0.30, 0.20, 0.12) * (0.7 + 0.45 * g)
			var rust := _vnoise(float(x) / 4.0, float(y) / 14.0, 16, 42)
			c = c.lerp(Color(0.24, 0.13, 0.07), smoothstep(0.55, 0.9, rust) * 0.6)
			if x <= 1 or y <= 1:
				c = c * 0.45
			elif x >= 62 or y >= 62:
				c = c * 0.6
			elif x == 2 or y == 2:
				c = c * 1.25
			var on_rivet_line := (x >= 4 and x <= 5) or (x >= 58 and x <= 59) or (y >= 4 and y <= 5) or (y >= 58 and y <= 59)
			var on_rivet_slot := ((x - 4) % 9 <= 1) and ((y - 4) % 9 <= 1)
			if on_rivet_line and on_rivet_slot:
				var hi := (x - 4) % 9 == 0 and (y - 4) % 9 == 0
				c = Color(0.48, 0.36, 0.24) if hi else Color(0.14, 0.09, 0.06)
			img.set_pixel(x, y, _jit(c, 0.03, x, y, 43))
	return img


## 64 px = 4 m. Stone pavers 16x8 px (1 x 0.5 m), running bond (frame 575s).
static func _pavers() -> Image:
	var img := _blank(64, 64, Color.BLACK)
	for y in 64:
		for x in 64:
			var row := y / 8
			var off := 8 if row % 2 == 1 else 0
			var bx := posmod(x + off, 64) / 16
			var grout := y % 8 == 7 or (x + off) % 16 == 15
			var c: Color
			if grout:
				c = Color(0.10, 0.08, 0.065)
			else:
				var t := _h(bx, row, 51)
				c = Color(0.34, 0.28, 0.22).lerp(Color(0.25, 0.21, 0.17), t)
				var lx := (x + off) % 16
				var ly := y % 8
				if lx == 0 or ly == 0:
					c = c * 1.12
			var g := _fbm(x, y, 64, 16, 52)
			c = c * (0.7 + 0.45 * g)
			img.set_pixel(x, y, _jit(c, 0.03, x, y, 53))
	return img


## 64 px = 3 m. Dark structural steel.
static func _metal_dark() -> Image:
	var img := _blank(64, 64, Color.BLACK)
	for y in 64:
		for x in 64:
			var g := _fbm(x, y, 64, 16, 61)
			var c := Color(0.15, 0.135, 0.125) * (0.75 + 0.4 * g)
			if _h(x / 6, y, 62) > 0.93:
				c = c * 1.35
			if y % 32 == 0:
				c = c * 0.5
			if y % 32 == 3 and x % 8 == 4:
				c = Color(0.3, 0.27, 0.24)
			img.set_pixel(x, y, _jit(c, 0.025, x, y, 63))
	return img


## 64 px = 1.2 m. Planks with grain.
static func _wood() -> Image:
	var img := _blank(64, 64, Color.BLACK)
	for y in 64:
		for x in 64:
			var plank := y / 8
			var c := Color(0.38, 0.24, 0.13).lerp(Color(0.28, 0.17, 0.09), _h(plank, 0, 71))
			var grain := _vnoise(float(x) / 10.0, float(y) / 1.5 + plank * 3.0, 7, 72)
			c = c * (0.8 + 0.3 * grain)
			if y % 8 == 7:
				c = c * 0.45
			img.set_pixel(x, y, _jit(c, 0.03, x, y, 73))
	return img


## 64 px = 1 m. Worn blanket weave.
static func _fabric() -> Image:
	var img := _blank(64, 64, Color.BLACK)
	for y in 64:
		for x in 64:
			var g := _fbm(x, y, 64, 32, 81)
			var c := Color(0.46, 0.42, 0.35) * (0.7 + 0.45 * g)
			if (x + y) % 2 == 0:
				c = c * 0.94
			if y % 16 == 0:
				c = c * 0.85
			img.set_pixel(x, y, _jit(c, 0.025, x, y, 82))
	return img


## 64 px = 1 m. Floor grating; holes read dark.
static func _grating() -> Image:
	var img := _blank(64, 64, Color.BLACK)
	for y in 64:
		for x in 64:
			var bar := x % 8 < 2 or y % 8 < 2
			var c := Color(0.27, 0.24, 0.21) if bar else Color(0.035, 0.03, 0.028)
			if bar and (x % 8 == 0 or y % 8 == 0):
				c = c * 1.2
			if bar:
				c = c * (0.8 + 0.35 * _fbm(x, y, 64, 16, 91))
			img.set_pixel(x, y, _jit(c, 0.02, x, y, 92))
	return img


## 64 px = 4 m. Shop interior: shelves of goods (emissive in storefronts).
static func _goods() -> Image:
	var img := _blank(64, 64, Color(0.12, 0.09, 0.06))
	var palette := [Color(0.9, 0.25, 0.2), Color(0.95, 0.8, 0.3), Color(0.3, 0.85, 0.8),
		Color(0.4, 0.8, 0.35), Color(0.95, 0.55, 0.2), Color(0.9, 0.88, 0.8), Color(0.85, 0.35, 0.7)]
	for y in 64:
		for x in 64:
			var shelf_y := y % 16
			var c := Color(0.14, 0.10, 0.07)
			if shelf_y == 15:
				c = Color(0.35, 0.26, 0.17)
			elif shelf_y >= 8:
				var slot := x / 3
				var r := _h(slot, y / 16, 101)
				if r > 0.25:
					var top := 8 + int(_h(slot, y / 16, 102) * 5.0)
					if shelf_y >= top and x % 3 != 2:
						c = palette[int(_h(slot, y / 16, 103) * palette.size()) % palette.size()]
						c = c * (0.6 + 0.4 * _h(x, y, 104))
			img.set_pixel(x, y, c)
	return img


## 32x32. Child's drawing of a tree, pinned to the wall (frame 000s).
static func _poster_tree() -> Image:
	var img := _blank(32, 32, Color(0.80, 0.77, 0.63))
	for y in 32:
		for x in 32:
			var c := Color(0.80, 0.77, 0.63) * (0.9 + 0.12 * _h(x, y, 111))
			if x == 0 or y == 0 or x == 31 or y == 31:
				c = Color(0.62, 0.58, 0.46)
			var d := Vector2(x - 15.5, y - 12.0).length()
			if d < 8.5:
				c = Color(0.30, 0.52, 0.24) * (0.85 + 0.3 * _h(x, y, 112))
				if d > 7.5:
					c = Color(0.22, 0.38, 0.17)
			elif x >= 14 and x <= 17 and y >= 19 and y <= 27:
				c = Color(0.40, 0.26, 0.14)
			if y == 27 and x >= 6 and x <= 25:
				c = Color(0.35, 0.42, 0.2)
			img.set_pixel(x, y, c)
	return img


## 32x16. Handwritten note.
static func _note() -> Image:
	var img := _blank(32, 16, Color(0.76, 0.72, 0.58))
	for y in 16:
		for x in 32:
			var c := Color(0.76, 0.72, 0.58) * (0.9 + 0.12 * _h(x, y, 121))
			if (y == 4 or y == 8 or y == 12) and x > 3 and x < 28 - int(_h(y, 0, 122) * 8.0):
				if _h(x, y, 123) > 0.25:
					c = Color(0.25, 0.2, 0.16)
			img.set_pixel(x, y, c)
	return img


## 64x32 RGBA cutout. Tally marks scratched on the wall, counting days.
static func _tally() -> Image:
	var img := _blank(64, 32, Color(0, 0, 0, 0))
	var mark := Color(0.86, 0.82, 0.72, 1.0)
	for row in 3:
		var y0 := 2 + row * 10
		var groups := 3 if row < 2 else 2
		for g in groups:
			var x0 := 3 + g * 20
			for i in 4:
				var x := x0 + i * 3
				for y in range(y0, y0 + 7):
					img.set_pixel(x, y, mark)
			for i in 13:
				img.set_pixel(x0 - 1 + i, y0 + 5 - i * 5 / 13, mark)
	return img


## 32x32. Worn yellow/black hazard stripes.
static func _hazard() -> Image:
	var img := _blank(32, 32, Color.BLACK)
	for y in 32:
		for x in 32:
			var on := ((x + y) / 8) % 2 == 0
			var c := Color(0.72, 0.54, 0.08) if on else Color(0.07, 0.06, 0.05)
			c = c * (0.65 + 0.45 * _fbm(x, y, 32, 8, 131))
			img.set_pixel(x, y, c)
	return img


## 64x64 grayscale tileable noise (wet patches, grime masks).
static func _grime() -> Image:
	var img := _blank(64, 64, Color.BLACK)
	for y in 64:
		for x in 64:
			var v := _fbm(x, y, 64, 32, 141)
			img.set_pixel(x, y, Color(v, v, v))
	return img
