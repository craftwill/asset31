class_name InputSetup
extends RefCounted
## Default key bindings, registered at startup so project.godot stays readable.


static func ensure() -> void:
	_key(&"move_forward", KEY_W)
	_key(&"move_back", KEY_S)
	_key(&"move_left", KEY_A)
	_key(&"move_right", KEY_D)
	_key(&"sprint", KEY_SHIFT)
	_key(&"crouch", KEY_CTRL)
	_key(&"jump", KEY_SPACE)
	_key(&"interact", KEY_E)
	_key(&"inventory", KEY_TAB)
	_key(&"inventory", KEY_I)
	_key(&"rotate_item", KEY_R)
	_key(&"toggle_map", KEY_M)
	_key(&"toggle_journal", KEY_J)
	_key(&"toggle_planet_view", KEY_P)
	_key(&"toggle_lamp", KEY_F)
	_key(&"release_mouse", KEY_ESCAPE)
	_key(&"toggle_debug", KEY_F3)
	_key(&"quick_save", KEY_F5)
	_key(&"cycle_retro", KEY_F6)
	_key(&"toggle_post", KEY_F7)
	_key(&"quick_load", KEY_F9)


static func _key(action: StringName, code: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	InputMap.action_add_event(action, ev)
