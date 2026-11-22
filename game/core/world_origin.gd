extends Node
## Autoload "WorldOrigin": floating-origin / large-world coordinate service.
##
## Logical world coordinates are metres held in float64 (GDScript `float`).
## Everything in the SceneTree lives in *render space*:
##     render = logical - origin
## `origin` is always a whole number of sectors, so it is exact even in float32.
## When the tracked body drifts more than REBASE_DISTANCE from the render origin,
## the origin jumps by whole sectors, every WorldAnchor re-places itself, and the
## tracked body moves back by the same amount. Velocities are unaffected.
##
## Rule: anything that must stay put in the world is either a WorldAnchor or a
## descendant of one. Free-moving render-space objects listen to `origin_shifted`.

signal origin_shifted(delta: Vector3)

const SECTOR_SIZE := 1024.0
const REBASE_DISTANCE := 1536.0
const ANCHOR_GROUP := &"world_anchors"

var origin_sector := Vector3i.ZERO
var tracked: Node3D
var rebase_count := 0


func origin_metres() -> Vector3:
	return Vector3(origin_sector) * SECTOR_SIZE


func to_render(lx: float, ly: float, lz: float) -> Vector3:
	return Vector3(
		lx - origin_sector.x * SECTOR_SIZE,
		ly - origin_sector.y * SECTOR_SIZE,
		lz - origin_sector.z * SECTOR_SIZE)


func to_render_arr(p: Array) -> Vector3:
	return to_render(float(p[0]), float(p[1]), float(p[2]))


## Returns [x, y, z] logical metres (float64).
func to_logical(render: Vector3) -> PackedFloat64Array:
	return PackedFloat64Array([
		render.x + origin_sector.x * SECTOR_SIZE,
		render.y + origin_sector.y * SECTOR_SIZE,
		render.z + origin_sector.z * SECTOR_SIZE])


## Puts the render origin at the sector nearest to a logical position.
func recenter_on_logical(lx: float, ly: float, lz: float) -> Vector3:
	return _set_origin(Vector3i(roundi(lx / SECTOR_SIZE), roundi(ly / SECTOR_SIZE), roundi(lz / SECTOR_SIZE)))


func _set_origin(new_sector: Vector3i) -> Vector3:
	var delta := Vector3(new_sector - origin_sector) * SECTOR_SIZE
	origin_sector = new_sector
	RenderingServer.global_shader_parameter_set(&"world_origin", origin_metres())
	get_tree().call_group(ANCHOR_GROUP, &"apply_origin")
	if delta != Vector3.ZERO:
		rebase_count += 1
		origin_shifted.emit(delta)
	return delta


func _physics_process(_delta: float) -> void:
	if tracked == null or not is_instance_valid(tracked):
		return
	var p := tracked.position
	if absf(p.x) > REBASE_DISTANCE or absf(p.y) > REBASE_DISTANCE or absf(p.z) > REBASE_DISTANCE:
		var shift := Vector3i(roundi(p.x / SECTOR_SIZE), roundi(p.y / SECTOR_SIZE), roundi(p.z / SECTOR_SIZE))
		var delta := _set_origin(origin_sector + shift)
		tracked.position -= delta
