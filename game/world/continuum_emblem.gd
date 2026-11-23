class_name ContinuumEmblem
extends Node3D
## Sacred Symbol of The Continuum: one continuous vertical spine passing through
## three connected rings (Matter, Life, Memory). Built purely from industrial
## materials (oxidized copper / dark structural steel) with offset Z planes so
## ZFightLint reports zero coplanar overlaps.


static func create(scale_m := 1.0, ring_mat := &"copper", spine_mat := &"structure", with_votive := false) -> ContinuumEmblem:
	var e := ContinuumEmblem.new()
	e.name = "ContinuumEmblem"
	e._build(scale_m, ring_mat, spine_mat, with_votive)
	return e


func _build(s: float, ring_mat: StringName, spine_mat: StringName, with_votive: bool) -> void:
	# Continuous vertical spine (continuity through time & the vertical Mantle structure),
	# seated cleanly in front of the three rings (z = +0.06 * s) so zero faces are coplanar.
	SliceMaterials.add_box(self, null, Vector3(0.0, 0.0, 0.06 * s), Vector3(0.085 * s, 3.10 * s, 0.055 * s), spine_mat, false)

	# Three connected rings (Matter, Life, Memory) threaded along the vertical axis.
	# Each ring is a 12-segment industrial octagon/dodecagon at z = 0.0.
	var segs: Array = []
	var ring_r := 0.44 * s
	var seg_n := 12
	var chord := 2.0 * ring_r * tan(PI / float(seg_n)) * 0.94
	var bar_t := 0.065 * s
	var bar_d := 0.05 * s
	for cy: float in [-0.84 * s, 0.0, 0.84 * s]:
		for i in seg_n:
			var ang := (float(i) + 0.5) * TAU / float(seg_n)
			var px := cos(ang) * ring_r
			var py := cy + sin(ang) * ring_r
			segs.append({
				"c": Vector3(px, py, 0.0),
				"s": Vector3(bar_t, chord, bar_d),
				"r": Vector3(0.0, 0.0, ang),
			})
	SliceMaterials.add_multimesh(self, segs, ring_mat)

	if with_votive:
		# Subtle weathered steel votive shelf + twin warm tungsten votive bulbs below the emblem.
		SliceMaterials.add_box(self, null, Vector3(0.0, -1.68 * s, 0.14 * s), Vector3(1.10 * s, 0.08 * s, 0.36 * s), &"structure", false)
		for vx: float in [-0.30 * s, 0.30 * s]:
			SliceMaterials.add_box(self, null, Vector3(vx, -1.58 * s, 0.18 * s), Vector3(0.08 * s, 0.12 * s, 0.08 * s), &"bulb", false)
		SliceMaterials.add_coronas(self, [Vector3(-0.30 * s, -1.54 * s, 0.20 * s), Vector3(0.30 * s, -1.54 * s, 0.20 * s)], 0.55 * s, &"corona_soft")
		var vl := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 0.75, 5.5)
		vl.position = Vector3(0.0, -1.35 * s, 0.45 * s)
		add_child(vl)
