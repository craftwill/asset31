class_name WorldAnchor
extends Node3D
## A node pinned to a logical (float64) world position. Its render position is
## recomputed whenever WorldOrigin rebases. Children use small local coordinates.

var lx := 0.0
var ly := 0.0
var lz := 0.0


func set_logical(x: float, y: float, z: float) -> void:
	lx = x
	ly = y
	lz = z
	if is_inside_tree():
		apply_origin()


func _enter_tree() -> void:
	add_to_group(WorldOrigin.ANCHOR_GROUP)
	apply_origin()


func apply_origin() -> void:
	position = WorldOrigin.to_render(lx, ly, lz)


## Converts a logical position into this anchor's local space (ignores rotation).
func logical_to_local(p: PackedFloat64Array) -> Vector3:
	return Vector3(p[0] - lx, p[1] - ly, p[2] - lz)
