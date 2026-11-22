class_name ItemDB
extends RefCounted
## Data-driven item catalog loaded from res://data/items/items.json, paired
## with deterministic low-res retro pixel icons matching TextureFactory's style.

const ITEMS_PATH := "res://data/items/items.json"

static var _items: Dictionary = {}   # id -> Dictionary
static var _icons: Dictionary = {}   # id -> ImageTexture
static var _loaded := false


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(ITEMS_PATH):
		push_error("ItemDB: missing %s" % ITEMS_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ITEMS_PATH))
	if parsed is Dictionary:
		for item: Dictionary in parsed.get("items", []):
			_items[String(item.id)] = item


static func get_item(id: String) -> Dictionary:
	ensure_loaded()
	return _items.get(id, {})


static func has_item(id: String) -> bool:
	ensure_loaded()
	return _items.has(id)


static func is_consumable(id: String) -> bool:
	var d := get_item(id)
	if d.is_empty():
		return false
	return int(d.get("hunger", 0)) > 0 or int(d.get("thirst", 0)) > 0 or int(d.get("health", 0)) > 0


static func category_color(cat: String) -> Color:
	match cat:
		"food": return Color(0.68, 0.45, 0.22)
		"water": return Color(0.32, 0.54, 0.66)
		"medical": return Color(0.72, 0.30, 0.25)
		"tool": return Color(0.72, 0.60, 0.28)
		"scrap": return Color(0.55, 0.44, 0.34)
		_: return Color(0.45, 0.40, 0.35)


static func get_icon(id: String) -> ImageTexture:
	ensure_loaded()
	if _icons.has(id):
		return _icons[id]
	var d := get_item(id)
	var sz: Array = d.get("size", [1, 1])
	var w := int(sz[0]) * 24
	var h := int(sz[1]) * 24
	var img := _draw_icon(id, w, h)
	var tex := ImageTexture.create_from_image(img)
	_icons[id] = tex
	return tex


static func clear_caches() -> void:
	_icons.clear()
	_items.clear()
	_loaded = false


static func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, col: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(maxi(0, y0), mini(h, y1)):
		for x in range(maxi(0, x0), mini(w, x1)):
			img.set_pixel(x, y, col)


static func _draw_icon(id: String, w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var outline := Color(0.08, 0.06, 0.05, 1.0)
	match id:
		"ration_tin":
			_rect(img, 4, 5, 20, 19, outline)
			_rect(img, 5, 6, 19, 18, Color(0.56, 0.42, 0.26))
			_rect(img, 5, 6, 19, 9, Color(0.72, 0.58, 0.38))
			_rect(img, 6, 11, 18, 15, Color(0.76, 0.56, 0.22))
			_rect(img, 8, 12, 16, 14, Color(0.24, 0.16, 0.10))
		"dried_strip":
			_rect(img, 4, 6, 44, 18, outline)
			_rect(img, 5, 7, 43, 17, Color(0.54, 0.36, 0.20))
			_rect(img, 9, 8, 39, 16, Color(0.72, 0.52, 0.30))
			for bx in [14, 24, 34]:
				_rect(img, bx, 7, bx + 2, 17, Color(0.32, 0.20, 0.12))
		"condensate_can":
			_rect(img, 6, 3, 18, 21, outline)
			_rect(img, 7, 4, 17, 20, Color(0.42, 0.52, 0.58))
			_rect(img, 8, 5, 16, 7, Color(0.72, 0.78, 0.82))
			_rect(img, 7, 10, 17, 15, Color(0.24, 0.44, 0.56))
			_rect(img, 10, 11, 14, 14, Color(0.70, 0.86, 0.94))
		"water_flask":
			_rect(img, 8, 3, 16, 9, outline)
			_rect(img, 9, 4, 15, 8, Color(0.45, 0.42, 0.38))
			_rect(img, 4, 9, 20, 44, outline)
			_rect(img, 5, 10, 19, 43, Color(0.36, 0.48, 0.56))
			_rect(img, 6, 11, 10, 42, Color(0.50, 0.64, 0.72))
			_rect(img, 5, 22, 19, 26, Color(0.22, 0.20, 0.18))
			_rect(img, 5, 34, 19, 37, Color(0.22, 0.20, 0.18))
		"bandage_roll":
			_rect(img, 4, 4, 20, 20, outline)
			_rect(img, 5, 5, 19, 19, Color(0.78, 0.74, 0.64))
			_rect(img, 10, 7, 14, 17, Color(0.76, 0.24, 0.18))
			_rect(img, 7, 10, 17, 14, Color(0.76, 0.24, 0.18))
		"fuse_cell":
			_rect(img, 6, 4, 18, 44, outline)
			_rect(img, 7, 5, 17, 11, Color(0.76, 0.60, 0.28))
			_rect(img, 7, 37, 17, 43, Color(0.76, 0.60, 0.28))
			_rect(img, 7, 11, 17, 37, Color(0.46, 0.42, 0.38))
			_rect(img, 9, 15, 15, 33, Color(0.92, 0.72, 0.32))
			_rect(img, 11, 17, 13, 31, Color(1.0, 0.90, 0.58))
		"brass_coil":
			_rect(img, 4, 5, 44, 19, outline)
			_rect(img, 5, 6, 9, 18, Color(0.36, 0.32, 0.28))
			_rect(img, 39, 6, 43, 18, Color(0.36, 0.32, 0.28))
			for sx in range(9, 39, 3):
				_rect(img, sx, 7, sx + 2, 17, Color(0.80, 0.48, 0.22))
				_rect(img, sx + 2, 7, sx + 3, 17, Color(0.46, 0.24, 0.12))
		"salvaged_relay":
			_rect(img, 4, 4, 44, 44, outline)
			_rect(img, 5, 5, 43, 43, Color(0.28, 0.30, 0.28))
			_rect(img, 8, 8, 40, 40, Color(0.18, 0.20, 0.19))
			_rect(img, 11, 11, 24, 24, Color(0.72, 0.46, 0.20))
			_rect(img, 27, 11, 37, 21, Color(0.45, 0.66, 0.54))
			_rect(img, 11, 28, 37, 36, Color(0.52, 0.46, 0.36))
			for px in [14, 20, 26, 32]:
				_rect(img, px, 30, px + 3, 34, Color(0.92, 0.74, 0.36))
		_:
			_rect(img, 3, 3, w - 3, h - 3, Color(0.5, 0.45, 0.4))
	return img
