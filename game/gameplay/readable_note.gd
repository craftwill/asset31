class_name ReadableNote
extends StaticBody3D
## Small interactable in-world note, plaque, or log that displays restrained
## diegetic text when inspected with [E].

var note_id := ""
var title := ""
var body_text := ""


static func create(id: String, p_title: String, p_body: String, pos: Vector3, rot_y: float, style := "plaque") -> ReadableNote:
	var n := ReadableNote.new()
	n.name = id
	n.note_id = id
	n.title = p_title
	n.body_text = p_body
	n.position = pos
	n.rotation.y = rot_y
	n.add_to_group(&"readable_notes")
	match style:
		"invisible":
			# Sits over an already-authored wall note mesh (e.g. home room note).
			SliceMaterials.add_collision_box(n, Vector3.ZERO, Vector3(0.48, 0.36, 0.14))
		"paper":
			SliceMaterials.add_box(n, n, Vector3.ZERO, Vector3(0.32, 0.02, 0.24), &"note")
		_:
			# Industrial steel plaque with dim amber strip.
			SliceMaterials.add_box(n, n, Vector3.ZERO, Vector3(0.68, 0.44, 0.06), &"structure")
			SliceMaterials.add_box(n, null, Vector3(0, 0, 0.035), Vector3(0.58, 0.34, 0.015), &"plate", false)
			SliceMaterials.add_box(n, null, Vector3(0, 0.19, 0.04), Vector3(0.46, 0.025, 0.015), &"rail_glow", false)
	return n


func prompt_text() -> String:
	return "[E] Read %s" % title
