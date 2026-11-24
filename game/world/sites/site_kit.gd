class_name SiteKit
extends Node3D
## Shared builder for box-built authored sites: batches boxes per material into
## MultiMeshes, adds collision, and offers the few compound shapes sites keep needing
## (ramps, lamp posts, signs). Coordinates are whatever space the site node lives in
## (stack-local for the STK-0413 district sites).

var _items: Dictionary = {}    # material id -> Array of { c, s, r }
var _body: StaticBody3D
var _metal: StaticBody3D
var _glows: Dictionary = {}    # corona material id -> Array[Vector3]


func _init() -> void:
	_body = StaticBody3D.new()
	_body.name = "Collision"
	add_child(_body)
	_metal = StaticBody3D.new()
	_metal.name = "CollisionMetal"
	_metal.set_meta(&"surface", "metal")
	add_child(_metal)


## Box between two corners. `solid` adds collision (`metal` picks the footstep sound).
func box(a: Vector3, b: Vector3, mat: StringName, solid := false, metal := false) -> void:
	var size := (b - a).abs()
	if size.x < 0.002 or size.y < 0.002 or size.z < 0.002:
		return
	_add((a + b) * 0.5, size, Vector3.ZERO, mat, solid, metal)


## Box by centre and size with an euler rotation.
func rbox(c: Vector3, size: Vector3, rot: Vector3, mat: StringName, solid := false, metal := false) -> void:
	_add(c, size, rot, mat, solid, metal)


func _add(c: Vector3, size: Vector3, rot: Vector3, mat: StringName, solid: bool, metal: bool) -> void:
	if not _items.has(mat):
		_items[mat] = []
	_items[mat].append({ "c": c, "s": size, "r": rot })
	if solid:
		SliceMaterials.add_collision_box(_metal if metal else _body, c, size, rot)


## Walkable ramp whose top surface runs from `lo` to `hi` (centre line), `width` wide.
## Runs along X or Z, whichever the two points differ in most.
func ramp(lo: Vector3, hi: Vector3, width: float, mat: StringName, thick := 0.3, metal := false) -> void:
	var dlt := hi - lo
	var along_x := absf(dlt.x) > absf(dlt.z)
	var run := absf(dlt.x) if along_x else absf(dlt.z)
	var length := sqrt(run * run + dlt.y * dlt.y)
	var pitch := atan2(dlt.y, run)
	var rot: Vector3
	var size: Vector3
	if along_x:
		rot = Vector3(0, 0, pitch * signf(dlt.x))
		size = Vector3(length, thick, width)
	else:
		rot = Vector3(-pitch * signf(dlt.z), 0, 0)
		size = Vector3(width, thick, length)
	var c := (lo + hi) * 0.5 - Vector3(0, thick * 0.5 * cos(pitch), 0)
	_add(c, size, rot, mat, true, metal)


## Emissive head + real light. `mat` is the lamp head material.
func light(pos: Vector3, color: Color, energy: float, light_range: float, mat: StringName = &"", head := 0.3) -> OmniLight3D:
	if mat != &"":
		box(pos - Vector3(head, head * 0.4, head) * 0.5, pos + Vector3(head, head * 0.4, head) * 0.5, mat)
	var l := SliceMaterials.make_lamp_light(color, energy, light_range)
	l.position = pos - Vector3(0, 0.35, 0)
	add_child(l)
	return l


## Street lamp: post, arm and a lit head.
func lamp_post(base: Vector3, height: float, color: Color, mat: StringName, energy := 1.8, light_range := 14.0) -> void:
	box(base + Vector3(-0.09, 0, -0.09), base + Vector3(0.09, height, 0.09), &"structure", true)
	light(base + Vector3(0, height + 0.1, 0), color, energy, light_range, mat, 0.5)
	glow(base + Vector3(0, height, 0), &"corona_cool" if color.b > color.r else &"corona")


func glow(pos: Vector3, mat: StringName = &"corona") -> void:
	if not _glows.has(mat):
		_glows[mat] = []
	_glows[mat].append(pos)


## Emits everything batched so far. Call once at the end of the site's build.
func flush() -> void:
	for mat: StringName in _items:
		SliceMaterials.add_multimesh(self, _items[mat], mat)
	for mat: StringName in _glows:
		SliceMaterials.add_coronas(self, _glows[mat], 1.6, mat)
	_items.clear()
	_glows.clear()
