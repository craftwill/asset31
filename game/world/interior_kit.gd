class_name InteriorKit
extends RefCounted
## Enterable ground-floor rooms for the procedural city.
##
## A share of city buildings get a "door plan": one street-facing face carries a
## doorway bay plus 1-3 window bays, all on the facade shader's own 4 m bay grid.
## The plan drives three things that must agree exactly:
##   1. facade.gdshader   paints those bays lit from afar and, near the camera,
##                        cuts the doorway and windows out of the facade (per-instance
##                        COLOR, see `instance_color`);
##   2. StackRuntime      streams a real InteriorRoom behind the holes (`LOAD_RADIUS`)
##                        and hollows the building's collision (`shell_collision`);
##   3. InteriorRoom      builds the room shell and one of six furnished templates,
##                        varied per building by the plan's seed.
## Rooms sit physically inside their building, so there is no teleport, no second
## camera and nothing special for saves or the floating origin.
##
## Room-local frame: origin on the facade plane at the centre of the door bay, floor
## level; +X along the facade (the shader's uv.x), +Y up, +Z into the building.

const BAY := 4.0            # facade bay width (facade.gdshader `bay.x`)
const WALL_T := 0.30        # facade plane -> inner face of the street wall
const SHELL_T := 0.25       # side / back wall thickness
const CEIL_Y := 3.2
const CEIL_TALL := 6.7      # double-height halls (two storeys)
const FLOOR_Y := 0.04
const DOOR_HW := 0.70       # must match the doorway cut in facade.gdshader
const DOOR_H := 2.30
const WIN_HW := 1.0         # bay.x * window_frac.x * 0.5
const WIN_Y0 := 0.875       # bay.y * (0.5 - window_frac.y * 0.5)
const WIN_Y1 := 2.625
const LOAD_RADIUS := 78.0   # must stay above facade.gdshader `door_cut_far`
const UNLOAD_RADIUS := 100.0
const DOOR_CHANCE := 0.34
const LIT_CHANCE := 0.62
const LOOT_CHANCE := 0.30
const LOOT_PREFIX := "CONT-INT-"

enum Tpl { DWELLING, BUREAU, WORKSHOP, DEPOT, CANTEEN, SHRINE, BATHHOUSE, LAUNDRY, RATION_HALL }

const FACE_N: Array[Vector3] = [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]

# Template weights per CityLayout.Zone (urban, residential, industrial, abandoned).
# The cool stacks add three communal rooms of their own: bathhouse, laundry, ration hall.
const TPL_WEIGHTS := [
	[2, 3, 1, 1, 3, 1, 0, 0, 0],
	[5, 1, 1, 0, 2, 1, 0, 0, 0],
	[0, 1, 4, 4, 1, 0, 0, 0, 0],
	[5, 1, 1, 1, 2, 1, 0, 0, 0],
]
const TPL_WEIGHTS_COOL := [
	[2, 2, 1, 1, 2, 1, 2, 1, 3],
	[4, 1, 1, 0, 2, 1, 2, 2, 2],
	[0, 1, 4, 4, 1, 0, 0, 1, 1],
	[5, 1, 1, 1, 2, 1, 1, 1, 1],
]

## Loot state of rooms that are currently streamed out: container_id -> serialized dict.
static var loot_state: Dictionary = {}


## Stable 0..1 hash of a building's layout seed; no extra RNG draws, so adding
## doors never reshuffles the city.
static func _h(r: float, i: int) -> float:
	return fposmod(sin(r * 12.9898 + float(i) * 78.233) * 43758.5453, 1.0)


static func face_tangent(face: int) -> Vector3:
	var n := FACE_N[face]
	return Vector3(0, 0, signf(n.x)) if face < 2 else Vector3(-signf(n.z), 0, 0)


## Decides whether ground body `b` ({c, s, seed}) gets an enterable room and, if so,
## stores the plan in `b.door`. `hw`/`hd` are the stack half-extents.
static func plan(b: Dictionary, zone: int, r: float, hw: float, hd: float, chance := DOOR_CHANCE, cool := false) -> void:
	if _h(r, 1) > chance:
		return
	var c: Vector3 = b.c
	var s: Vector3 = b.s
	# Street side of the lot: blocks repeat every BLOCK metres from the stack corner.
	var ux := fposmod(c.x + hw, CityLayout.BLOCK) - CityLayout.BLOCK * 0.5
	var uz := fposmod(c.z + hd, CityLayout.BLOCK) - CityLayout.BLOCK * 0.5
	var face := (1 if ux < 0.0 else 0) if _h(r, 2) < 0.5 else (3 if uz < 0.0 else 2)
	var face_w := s.z if face < 2 else s.x
	var face_d := s.x if face < 2 else s.z
	# Whole bays available on each side of the face centre, clear of the corners.
	var m := int(floor((face_w * 0.5 - SHELL_T - 0.35) / BAY))
	if m < 1:
		return
	var depth := minf(face_d - SHELL_T - 0.35, 6.0 + _h(r, 3) * 4.0)
	if depth < 5.0:
		return
	# Cool stacks run to wider, more open rooms where the building allows it.
	var bays := clampi(2 + int(_h(r, 4) * (5.0 if cool else 3.0)), 2, mini(2 * m, 6 if cool else 4))
	var first := -m + int(_h(r, 5) * float(2 * m - bays + 1))
	var j := int(_h(r, 6) * float(bays))
	var weights: Array = (TPL_WEIGHTS_COOL if cool else TPL_WEIGHTS)[zone]
	var total := 0
	for wgt: int in weights:
		total += wgt
	var pick := int(_h(r, 7) * float(total))
	var tpl := 0
	for i in weights.size():
		pick -= int(weights[i])
		if pick < 0:
			tpl = i
			break
	# Communal halls (and some cool-stack shrines and canteens) take two storeys.
	var tall := tpl == Tpl.BATHHOUSE or tpl == Tpl.RATION_HALL \
		or (cool and (tpl == Tpl.SHRINE or tpl == Tpl.CANTEEN) and _h(r, 10) < 0.45)
	var ruin := zone == CityLayout.Zone.ABANDONED
	b["door"] = {
		"face": face,
		"k": first + j,
		"left": j,
		"right": bays - 1 - j,
		"depth": depth,
		"tpl": tpl,
		"lit": _h(r, 8) < LIT_CHANCE and not ruin,
		"ceil": CEIL_TALL if tall and s.y - 1.0 > CEIL_TALL + 2.0 else CEIL_Y,
		"ruin": ruin,
		"seed": int(_h(r, 9) * 1000000.0),
		"zone": zone,
	}


## Per-instance COLOR read by facade.gdshader (all values are small integers, so
## they survive any float packing exactly).
static func instance_color(b: Dictionary) -> Color:
	if not b.has("door"):
		return Color(0, 0, 0, 1)
	var d: Dictionary = b.door
	return Color(float(d.face) + 1.0, float(d.k), float(int(d.left) + 8 * int(d.right) + (64 if d.lit else 0)), 1.0)


## Room-local -> stack-local transform.
static func xform(b: Dictionary) -> Transform3D:
	var d: Dictionary = b.door
	var c: Vector3 = b.c
	var s: Vector3 = b.s
	var n := FACE_N[d.face]
	var t := face_tangent(d.face)
	var half_n := (s.x if int(d.face) < 2 else s.z) * 0.5
	var origin := Vector3(c.x, 0.0, c.z) + n * half_n + t * ((float(d.k) + 0.5) * BAY)
	return Transform3D(Basis(t, Vector3.UP, -n), origin)


## Clear interior span along the facade: [x0, x1] in room-local metres.
static func span(d: Dictionary) -> Vector2:
	return Vector2(-(float(d.left) * BAY + BAY * 0.5), float(d.right) * BAY + BAY * 0.5)


## Collision for a building with a room, as stack-local [center, size] boxes: the
## solid upper floors, the mass around the room, and the street wall with a doorway.
static func shell_collision(b: Dictionary) -> Array:
	var d: Dictionary = b.door
	var c: Vector3 = b.c
	var s: Vector3 = b.s
	var xf := xform(b)
	var face_w := s.z if int(d.face) < 2 else s.x
	var face_d := s.x if int(d.face) < 2 else s.z
	var u := (float(d.k) + 0.5) * BAY
	var bx0 := -face_w * 0.5 - u
	var bx1 := face_w * 0.5 - u
	var sp := span(d)
	var depth: float = d.depth
	var y0 := c.y - s.y * 0.5
	var y1 := c.y + s.y * 0.5
	var cy: float = d.ceil
	var local: Array = [
		[Vector3(bx0, cy, 0.0), Vector3(bx1, y1, face_d)],
		[Vector3(bx0, y0, 0.0), Vector3(sp.x, cy, face_d)],
		[Vector3(sp.y, y0, 0.0), Vector3(bx1, cy, face_d)],
		[Vector3(sp.x, y0, depth), Vector3(sp.y, cy, face_d)],
		[Vector3(-DOOR_HW, DOOR_H, 0.0), Vector3(DOOR_HW, cy, WALL_T)],
		[Vector3(-BAY * 0.5, y0, 0.0), Vector3(-DOOR_HW, cy, WALL_T)],
		[Vector3(DOOR_HW, y0, 0.0), Vector3(BAY * 0.5, cy, WALL_T)],
	]
	for j in range(-int(d.left), int(d.right) + 1):
		if j != 0:
			var xb := float(j) * BAY
			local.append([Vector3(xb - BAY * 0.5, y0, 0.0), Vector3(xb + BAY * 0.5, cy, WALL_T)])
	var out: Array = []
	for bx: Array in local:
		var a: Vector3 = bx[0]
		var e: Vector3 = bx[1]
		var size := e - a
		if size.x > 0.01 and size.y > 0.01 and size.z > 0.01:
			out.append([xf * ((a + e) * 0.5), (xf.basis * size).abs()])
	return out


## Doorway position in stack-local metres (streaming distance checks).
static func door_point(b: Dictionary) -> Vector3:
	return xform(b).origin
