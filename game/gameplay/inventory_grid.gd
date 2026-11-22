class_name InventoryGrid
extends RefCounted
## Tarkov-inspired 2D grid inventory model: items occupy (w x h) cells, can be
## rotated 90 degrees, stacked up to max_stack, and transferred between grids.

signal changed

var cols: int
var rows: int
var entries: Array[Dictionary] = [] # { uid, item_id, x, y, w, h, rotated, count }
var _next_uid := 1


func _init(p_cols := 6, p_rows := 5) -> void:
	cols = p_cols
	rows = p_rows


func clear() -> void:
	entries.clear()
	changed.emit()


func get_entry(uid: int) -> Dictionary:
	for e in entries:
		if int(e.uid) == uid:
			return e
	return {}


func get_entry_at(gx: int, gy: int) -> Dictionary:
	for e in entries:
		var ex := int(e.x)
		var ey := int(e.y)
		if gx >= ex and gx < ex + int(e.w) and gy >= ey and gy < ey + int(e.h):
			return e
	return {}


func item_dims(item_id: String, rotated: bool) -> Vector2i:
	var d := ItemDB.get_item(item_id)
	var sz: Array = d.get("size", [1, 1])
	var w := int(sz[0])
	var h := int(sz[1])
	return Vector2i(h, w) if rotated else Vector2i(w, h)


func can_place(gx: int, gy: int, w: int, h: int, ignore_uid := -1) -> bool:
	if gx < 0 or gy < 0 or gx + w > cols or gy + h > rows:
		return false
	for e in entries:
		if int(e.uid) == ignore_uid:
			continue
		var ex := int(e.x)
		var ey := int(e.y)
		var ew := int(e.w)
		var eh := int(e.h)
		if gx < ex + ew and gx + w > ex and gy < ey + eh and gy + h > ey:
			return false
	return true


func place_item(item_id: String, gx: int, gy: int, rotated := false, count := 1) -> int:
	if not ItemDB.has_item(item_id) or count <= 0:
		return -1
	var dims := item_dims(item_id, rotated)
	if not can_place(gx, gy, dims.x, dims.y):
		return -1
	var max_s := int(ItemDB.get_item(item_id).get("max_stack", 1))
	var uid := _next_uid
	_next_uid += 1
	entries.append({
		"uid": uid,
		"item_id": item_id,
		"x": gx,
		"y": gy,
		"w": dims.x,
		"h": dims.y,
		"rotated": rotated,
		"count": mini(count, max_s),
	})
	changed.emit()
	return uid


## Adds `count` of `item_id` by topping up existing stacks first, then placing
## remaining stacks in the first free slot (trying normal then rotated).
## Returns the number of items that could NOT fit (0 = all added).
func auto_add(item_id: String, count := 1) -> int:
	if not ItemDB.has_item(item_id) or count <= 0:
		return count
	var d := ItemDB.get_item(item_id)
	var max_s := int(d.get("max_stack", 1))
	var rem := count
	var touched := false
	for e in entries:
		if rem <= 0:
			break
		if String(e.item_id) == item_id and int(e.count) < max_s:
			var add := mini(rem, max_s - int(e.count))
			e.count = int(e.count) + add
			rem -= add
			touched = true
	while rem > 0:
		var chunk := mini(rem, max_s)
		var placed := false
		for rot in [false, true]:
			var dims := item_dims(item_id, rot)
			for gy in range(rows - dims.y + 1):
				for gx in range(cols - dims.x + 1):
					if can_place(gx, gy, dims.x, dims.y):
						var uid := _next_uid
						_next_uid += 1
						entries.append({
							"uid": uid,
							"item_id": item_id,
							"x": gx,
							"y": gy,
							"w": dims.x,
							"h": dims.y,
							"rotated": rot,
							"count": chunk,
						})
						rem -= chunk
						placed = true
						touched = true
						break
				if placed:
					break
			if placed:
				break
		if not placed:
			break
	if touched:
		changed.emit()
	return rem


func remove_entry(uid: int) -> Dictionary:
	for i in entries.size():
		if int(entries[i].uid) == uid:
			var e := entries[i]
			entries.remove_at(i)
			changed.emit()
			return e
	return {}


func consume_one(uid: int) -> String:
	for i in entries.size():
		if int(entries[i].uid) == uid:
			var id := String(entries[i].item_id)
			var c := int(entries[i].count) - 1
			if c <= 0:
				entries.remove_at(i)
			else:
				entries[i].count = c
			changed.emit()
			return id
	return ""


func consume_item_id(item_id: String) -> bool:
	for e in entries:
		if String(e.item_id) == item_id:
			return consume_one(int(e.uid)) != ""
	return false


## Moves/transfers entry `uid` from `src` to `dst` at `(tx, ty)` with `rotated`.
## If dropping onto a single matching stack in `dst`, merges stacks cleanly.
static func transfer_to_cell(src: InventoryGrid, uid: int, dst: InventoryGrid, tx: int, ty: int, rotated: bool) -> bool:
	var e := src.get_entry(uid)
	if e.is_empty():
		return false
	var item_id := String(e.item_id)
	var dims := dst.item_dims(item_id, rotated)
	var max_s := int(ItemDB.get_item(item_id).get("max_stack", 1))
	# Check if target cell hits a stackable entry of the same item type.
	var target := dst.get_entry_at(tx, ty)
	if not target.is_empty() and (src != dst or int(target.uid) != uid) and String(target.item_id) == item_id and int(target.count) < max_s:
		var space := max_s - int(target.count)
		var move_n := mini(space, int(e.count))
		target.count = int(target.count) + move_n
		if move_n >= int(e.count):
			src.remove_entry(uid)
		else:
			e.count = int(e.count) - move_n
			src.changed.emit()
		dst.changed.emit()
		return true
	var ignore := uid if src == dst else -1
	if not dst.can_place(tx, ty, dims.x, dims.y, ignore):
		return false
	if src == dst:
		e.x = tx
		e.y = ty
		e.w = dims.x
		e.h = dims.y
		e.rotated = rotated
		dst.changed.emit()
		return true
	var removed := src.remove_entry(uid)
	dst.place_item(String(removed.item_id), tx, ty, rotated, int(removed.count))
	return true


func total_item_count() -> int:
	var n := 0
	for e in entries:
		n += int(e.count)
	return n


func serialize() -> Array:
	var out: Array = []
	for e in entries:
		out.append({
			"item_id": String(e.item_id),
			"x": int(e.x),
			"y": int(e.y),
			"rotated": bool(e.rotated),
			"count": int(e.count),
		})
	return out


func deserialize(arr: Array) -> void:
	entries.clear()
	_next_uid = 1
	for d: Dictionary in arr:
		place_item(String(d.get("item_id", "")), int(d.get("x", 0)), int(d.get("y", 0)), bool(d.get("rotated", false)), int(d.get("count", 1)))
	changed.emit()
