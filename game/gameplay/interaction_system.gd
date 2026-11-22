class_name InteractionSystem
extends Node
## Short-range first-person raycast for world interactions (loot containers and readable notes).

signal prompt_changed(prompt: String)
signal container_activated(container: LootContainer)
signal note_activated(note: ReadableNote)
signal tram_console_activated(console: TramConsole)
signal relay_console_activated(console: RelayConsole)

const REACH := 3.0

var camera: Camera3D
var current_target: Node
var enabled := true


func setup(p_camera: Camera3D) -> void:
	camera = p_camera


func _physics_process(_delta: float) -> void:
	if not enabled or camera == null:
		if current_target != null:
			current_target = null
			prompt_changed.emit("")
		return
	var space := camera.get_world_3d().direct_space_state
	var origin := camera.global_position
	var end := origin - camera.global_basis.z * REACH
	var q := PhysicsRayQueryParameters3D.create(origin, end)
	q.collide_with_areas = false
	q.collide_with_bodies = true
	var hit := space.intersect_ray(q)
	var found: Node = null
	if not hit.is_empty():
		var col: Object = hit.collider
		if col is LootContainer or col is ReadableNote or col is TramConsole or col is RelayConsole:
			found = col as Node
	if found != current_target:
		current_target = found
		if found is LootContainer:
			prompt_changed.emit((found as LootContainer).prompt_text())
		elif found is ReadableNote:
			prompt_changed.emit((found as ReadableNote).prompt_text())
		elif found is TramConsole:
			prompt_changed.emit((found as TramConsole).prompt_text())
		elif found is RelayConsole:
			prompt_changed.emit((found as RelayConsole).prompt_text())
		else:
			prompt_changed.emit("")
	elif found is TramConsole:
		prompt_changed.emit((found as TramConsole).prompt_text())
	elif found is RelayConsole:
		prompt_changed.emit((found as RelayConsole).prompt_text())


func try_interact() -> bool:
	if current_target == null or not is_instance_valid(current_target):
		return false
	if current_target is LootContainer:
		var c := current_target as LootContainer
		c.mark_opened()
		container_activated.emit(c)
		return true
	if current_target is ReadableNote:
		note_activated.emit(current_target as ReadableNote)
		return true
	if current_target is TramConsole:
		tram_console_activated.emit(current_target as TramConsole)
		return true
	if current_target is RelayConsole:
		relay_console_activated.emit(current_target as RelayConsole)
		return true
	return false
