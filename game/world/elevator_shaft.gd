class_name ElevatorShaft
extends WorldAnchor
## Elevator shafts rising through the gaps between stacks: the Mantle's links
## down to the mining surface (canon). Lattice columns, strings of lamps that
## vanish into the depth (frames 175s, 225s) and slowly travelling cars.
## Local y 0 = the logical altitude given in data.

var def: Dictionary
var _cars: Array = []    # { node, phase, speed }
var _bottom := 0.0
var _top := 0.0


static func build(sdef: Dictionary) -> ElevatorShaft:
	var e := ElevatorShaft.new()
	e.def = sdef
	e.name = sdef.id
	var p: Array = sdef.position
	e.lx = float(p[0])
	e.ly = float(p[1])
	e.lz = float(p[2])
	e._build()
	return e


func _build() -> void:
	var s := float(def.size)
	var hs := s * 0.5
	_bottom = -float(def.depth)
	_top = float(def.height)
	var h := _top - _bottom
	var cy := (_top + _bottom) * 0.5
	var col := 3.0
	for c in [Vector2(-hs, -hs), Vector2(hs, -hs), Vector2(-hs, hs), Vector2(hs, hs)]:
		SliceMaterials.add_box(self, null, Vector3(c.x, cy, c.y), Vector3(col, h, col), &"structure", false)
	# Horizontal bracing every 40 m on all four faces.
	var beams: Array = []
	var y := _bottom + 20.0
	while y < _top:
		beams.append({ "c": Vector3(0, y, -hs), "s": Vector3(s - col, 1.2, 1.2) })
		beams.append({ "c": Vector3(0, y, hs), "s": Vector3(s - col, 1.2, 1.2) })
		beams.append({ "c": Vector3(-hs, y, 0), "s": Vector3(1.2, 1.2, s - col) })
		beams.append({ "c": Vector3(hs, y, 0), "s": Vector3(1.2, 1.2, s - col) })
		y += 40.0
	SliceMaterials.add_multimesh(self, beams, &"structure")
	# Lamp strings down two corners: small heads every 12 m with slight
	# irregularity in brightness (some dead, some dim) so depth reads naturally.
	var heads: Array = []
	var glows: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(def.id))
	for c in [Vector2(-hs - 2.2, -hs), Vector2(hs + 2.2, hs)]:
		y = _bottom + 6.0
		while y < _top:
			if rng.randf() > 0.08:
				var p := Vector3(c.x, y, c.y)
				heads.append({ "c": p, "s": Vector3(1.4, 1.4, 1.4) })
				glows.append(p)
			y += 12.0
	SliceMaterials.add_multimesh(self, heads, &"lamp")
	SliceMaterials.add_coronas(self, glows, 11.0, &"corona_soft")
	# Cars travelling the shaft.
	for i in int(def.get("cars", 2)):
		var car := Node3D.new()
		add_child(car)
		SliceMaterials.add_box(car, null, Vector3.ZERO, Vector3(s - 8.0, 10.5, s - 8.0), &"building", false)
		SliceMaterials.add_box(car, null, Vector3(0, -5.6, 0), Vector3(s - 6.0, 0.7, s - 6.0), &"structure", false)
		SliceMaterials.add_box(car, null, Vector3(0, -6.1, 0), Vector3(2.0, 0.3, 2.0), &"lamp", false)
		SliceMaterials.add_coronas(car, [Vector3(0, -6.4, 0)], 10.0, &"corona_soft")
		_cars.append({ "node": car, "phase": rng.randf(), "speed": rng.randf_range(4.0, 9.0) })
	_update_cars()


func _process(_delta: float) -> void:
	_update_cars()


func _update_cars() -> void:
	var span := (_top - 20.0) - (_bottom + 20.0)
	var t := Time.get_ticks_msec() / 1000.0
	for c: Dictionary in _cars:
		# Triangle wave: up, then down, at constant speed.
		var u := fposmod(float(c.phase) + t * float(c.speed) / (2.0 * span), 1.0)
		var k := u * 2.0 if u < 0.5 else 2.0 - u * 2.0
		(c.node as Node3D).position.y = _bottom + 20.0 + k * span
