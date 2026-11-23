class_name ZFightLint
extends RefCounted
## Automated coplanar-face (z-fighting) linter for Asset 31's box-built authored sites.
## Scans visible axis-aligned BoxMesh MeshInstance3Ds and MultiMeshInstance3Ds across
## authored sites/structures and flags pairs of boxes that share a same-facing outward
## plane (within FACE_EPS metres) with non-trivial 2D overlap on the perpendicular axes.

const FACE_EPS := 0.015
const MIN_AXIS_OVERLAP := 0.08
const MIN_OVERLAP_AREA := 0.04
const CELL_SIZE := 40.0


static func run(root: Node, max_report := 25) -> Dictionary:
	var boxes: Array = []
	_collect(root, boxes, "")
	# Spatial grid bucket in XZ so pair checks stay O(N).
	var grid: Dictionary = {}
	for i in boxes.size():
		var a: AABB = boxes[i].aabb
		var x0 := int(floor(a.position.x / CELL_SIZE))
		var x1 := int(floor(a.end.x / CELL_SIZE))
		var z0 := int(floor(a.position.z / CELL_SIZE))
		var z1 := int(floor(a.end.z / CELL_SIZE))
		# Clamp huge slabs (>400 m) to a dedicated "big" list so we don't spam grid cells.
		if (x1 - x0) * (z1 - z0) > 64:
			if not grid.has(&"BIG"):
				grid[&"BIG"] = []
			grid[&"BIG"].append(i)
		else:
			for gx in range(x0, x1 + 1):
				for gz in range(z0, z1 + 1):
					var key := Vector2i(gx, gz)
					if not grid.has(key):
						grid[key] = []
					grid[key].append(i)

	var big_list: Array = grid.get(&"BIG", [])
	var seen: Dictionary = {}
	var findings: Array = []

	for key in grid:
		if key is StringName:
			continue
		var cell: Array = grid[key]
		for ii in cell.size():
			var ia: int = cell[ii]
			for jj in range(ii + 1, cell.size()):
				var ib: int = cell[jj]
				_check_pair(boxes, ia, ib, seen, findings)
			for ib: int in big_list:
				if ia != ib:
					_check_pair(boxes, ia, ib, seen, findings)
	for ii in big_list.size():
		for jj in range(ii + 1, big_list.size()):
			_check_pair(boxes, big_list[ii], big_list[jj], seen, findings)

	print("[ZFightLint] Scanned %d authored boxes -> %d coplanar face overlaps" % [boxes.size(), findings.size()])
	var by_site: Dictionary = {}
	for f: Dictionary in findings:
		var s: String = f.site
		if not by_site.has(s):
			by_site[s] = []
		by_site[s].append(f)
	var keys := by_site.keys()
	keys.sort()
	for s: String in keys:
		var arr: Array = by_site[s]
		print("  [%s] %d overlaps:" % [s, arr.size()])
		var lim := mini(arr.size(), max_report)
		for k in lim:
			var f: Dictionary = arr[k]
			print("    plane=%s  overlap=%.2fx%.2fm  at=%s  (%s vs %s)" % [f.plane, f.ow, f.oh, f.pos, f.a_tag, f.b_tag])
	return { "boxes": boxes.size(), "findings": findings }


static func _collect(node: Node, out: Array, site_tag: String) -> void:
	# Skip massive procedural city chunk grids, distant stacks, and non-visible helper geometry.
	if node is DistantStack or node is Crowd:
		return
	var nm := String(node.name)
	if nm.begins_with("Chunk_") or nm.begins_with("Near_") or nm == "PlanetViewLayer" or nm == "City":
		return
	var cur_site := site_tag
	if nm.begins_with("SITE-") or nm.begins_with("BR-") or nm.begins_with("EL-") or nm.begins_with("CRUST-") or nm.begins_with("STA-") or nm.begins_with("VD-") or nm.begins_with("EXP-"):
		cur_site = nm
	if node is Node3D and not (node as Node3D).visible:
		return
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh is BoxMesh and _is_opaque_mat(mi.material_override):
			var xf := mi.global_transform
			if _is_axis_aligned(xf.basis):
				var sz := (mi.mesh as BoxMesh).size
				var ext := Vector3(
					absf(xf.basis.x.x) * sz.x + absf(xf.basis.y.x) * sz.y + absf(xf.basis.z.x) * sz.z,
					absf(xf.basis.x.y) * sz.x + absf(xf.basis.y.y) * sz.y + absf(xf.basis.z.y) * sz.z,
					absf(xf.basis.x.z) * sz.x + absf(xf.basis.y.z) * sz.y + absf(xf.basis.z.z) * sz.z)
				if ext.x >= 0.04 and ext.y >= 0.04 and ext.z >= 0.04:
					out.append({
						"aabb": AABB(xf.origin - ext * 0.5, ext),
						"site": cur_site if cur_site != "" else nm,
						"tag": nm,
						"owner_id": mi.get_instance_id(),
					})
	elif node is MultiMeshInstance3D:
		var mmi := node as MultiMeshInstance3D
		if mmi.has_meta(&"lint_items") and _is_opaque_mat(mmi.material_override):
			var items: Array = mmi.get_meta(&"lint_items")
			var base_xf := mmi.global_transform
			for i in items.size():
				var b: Dictionary = items[i]
				var rot: Vector3 = b.get("r", Vector3.ZERO)
				var s: Vector3 = b.s
				var xf := base_xf * Transform3D(Basis.from_euler(rot) * Basis.from_scale(s), b.c)
				if not _is_axis_aligned(xf.basis):
					continue
				var ext := Vector3(
					absf(xf.basis.x.x) + absf(xf.basis.y.x) + absf(xf.basis.z.x),
					absf(xf.basis.x.y) + absf(xf.basis.y.y) + absf(xf.basis.z.y),
					absf(xf.basis.x.z) + absf(xf.basis.y.z) + absf(xf.basis.z.z))
				if ext.x >= 0.04 and ext.y >= 0.04 and ext.z >= 0.04:
					out.append({
						"aabb": AABB(xf.origin - ext * 0.5, ext),
						"site": cur_site if cur_site != "" else nm,
						"tag": "%s[%d]" % [nm, i],
						"owner_id": mmi.get_instance_id(),
					})
	for ch in node.get_children():
		_collect(ch, out, cur_site)


static func _is_opaque_mat(mat: Material) -> bool:
	if mat == null:
		return true
	if mat is ShaderMaterial:
		var sh := (mat as ShaderMaterial).shader
		if sh != null:
			var p := sh.resource_path
			if p.ends_with("corona.gdshader") or p.ends_with("glass.gdshader") or p.ends_with("curtain_wall.gdshader") or p.ends_with("decal.gdshader"):
				return false
	return true


static func _is_axis_aligned(b: Basis) -> bool:
	for col: Vector3 in [b.x, b.y, b.z]:
		var l := col.length()
		if l < 1e-5:
			return false
		var n := col / l
		var max_c := maxf(absf(n.x), maxf(absf(n.y), absf(n.z)))
		if max_c < 0.999:
			return false
	return true


static func _check_pair(boxes: Array, ia: int, ib: int, seen: Dictionary, findings: Array) -> void:
	var lo := mini(ia, ib)
	var hi := maxi(ia, ib)
	var pk := (lo << 20) | hi
	if seen.has(pk):
		return
	seen[pk] = true
	var ba: Dictionary = boxes[lo]
	var bb: Dictionary = boxes[hi]
	var a: AABB = ba.aabb
	var b: AABB = bb.aabb
	# Quick reject if AABBs don't even come close.
	if a.end.x + FACE_EPS < b.position.x or b.end.x + FACE_EPS < a.position.x:
		return
	if a.end.y + FACE_EPS < b.position.y or b.end.y + FACE_EPS < a.position.y:
		return
	if a.end.z + FACE_EPS < b.position.z or b.end.z + FACE_EPS < a.position.z:
		return

	var ox := minf(a.end.x, b.end.x) - maxf(a.position.x, b.position.x)
	var oy := minf(a.end.y, b.end.y) - maxf(a.position.y, b.position.y)
	var oz := minf(a.end.z, b.end.z) - maxf(a.position.z, b.position.z)

	# Check same-facing outward planes (min vs min, max vs max) on each axis.
	if ox >= MIN_AXIS_OVERLAP and oz >= MIN_AXIS_OVERLAP and ox * oz >= MIN_OVERLAP_AREA:
		if absf(a.end.y - b.end.y) <= FACE_EPS:
			_record(findings, ba, bb, "+Y", ox, oz, Vector3((maxf(a.position.x, b.position.x) + minf(a.end.x, b.end.x)) * 0.5, a.end.y, (maxf(a.position.z, b.position.z) + minf(a.end.z, b.end.z)) * 0.5))
			return
		if absf(a.position.y - b.position.y) <= FACE_EPS:
			_record(findings, ba, bb, "-Y", ox, oz, Vector3((maxf(a.position.x, b.position.x) + minf(a.end.x, b.end.x)) * 0.5, a.position.y, (maxf(a.position.z, b.position.z) + minf(a.end.z, b.end.z)) * 0.5))
			return
	if oy >= MIN_AXIS_OVERLAP and oz >= MIN_AXIS_OVERLAP and oy * oz >= MIN_OVERLAP_AREA:
		if absf(a.end.x - b.end.x) <= FACE_EPS:
			_record(findings, ba, bb, "+X", oy, oz, Vector3(a.end.x, (maxf(a.position.y, b.position.y) + minf(a.end.y, b.end.y)) * 0.5, (maxf(a.position.z, b.position.z) + minf(a.end.z, b.end.z)) * 0.5))
			return
		if absf(a.position.x - b.position.x) <= FACE_EPS:
			_record(findings, ba, bb, "-X", oy, oz, Vector3(a.position.x, (maxf(a.position.y, b.position.y) + minf(a.end.y, b.end.y)) * 0.5, (maxf(a.position.z, b.position.z) + minf(a.end.z, b.end.z)) * 0.5))
			return
	if ox >= MIN_AXIS_OVERLAP and oy >= MIN_AXIS_OVERLAP and ox * oy >= MIN_OVERLAP_AREA:
		if absf(a.end.z - b.end.z) <= FACE_EPS:
			_record(findings, ba, bb, "+Z", ox, oy, Vector3((maxf(a.position.x, b.position.x) + minf(a.end.x, b.end.x)) * 0.5, (maxf(a.position.y, b.position.y) + minf(a.end.y, b.end.y)) * 0.5, a.end.z))
			return
		if absf(a.position.z - b.position.z) <= FACE_EPS:
			_record(findings, ba, bb, "-Z", ox, oy, Vector3((maxf(a.position.x, b.position.x) + minf(a.end.x, b.end.x)) * 0.5, (maxf(a.position.y, b.position.y) + minf(a.end.y, b.end.y)) * 0.5, a.position.z))
			return


static func _record(findings: Array, ba: Dictionary, bb: Dictionary, plane: String, ow: float, oh: float, render_pos: Vector3) -> void:
	var lp := WorldOrigin.to_logical(render_pos)
	findings.append({
		"site": ba.site if ba.site == bb.site else "%s/%s" % [ba.site, bb.site],
		"plane": plane,
		"ow": ow,
		"oh": oh,
		"pos": "(%.1f, %.2f, %.1f)" % [lp[0], lp[1], lp[2]],
		"a_tag": ba.tag,
		"b_tag": bb.tag,
	})
