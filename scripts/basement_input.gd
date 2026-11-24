class_name BasementInput
extends RefCounted

static func configure() -> void:
	# Add controller events to the existing actions, preserving keyboard bindings.
	for pair in [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0],
		["move_forward", JOY_AXIS_LEFT_Y, -1.0], ["move_back", JOY_AXIS_LEFT_Y, 1.0],
		["look_left", JOY_AXIS_RIGHT_X, -1.0], ["look_right", JOY_AXIS_RIGHT_X, 1.0],
		["look_up", JOY_AXIS_RIGHT_Y, -1.0], ["look_down", JOY_AXIS_RIGHT_Y, 1.0],
		["fire", JOY_AXIS_TRIGGER_RIGHT, 1.0]]:
		var motion := InputEventJoypadMotion.new()
		motion.axis = int(pair[1])
		motion.axis_value = float(pair[2])
		_add(str(pair[0]), motion)
	for pair in [["interact", JOY_BUTTON_X], ["jump", JOY_BUTTON_A], ["dodge", JOY_BUTTON_B],
		["cycle_tool", JOY_BUTTON_Y], ["sprint", JOY_BUTTON_LEFT_STICK],
		["melee", JOY_BUTTON_LEFT_SHOULDER], ["pulse", JOY_BUTTON_RIGHT_SHOULDER],
		["pause", JOY_BUTTON_START], ["checklist", JOY_BUTTON_BACK],
		["lantern", JOY_BUTTON_DPAD_UP], ["flashlight", JOY_BUTTON_DPAD_LEFT],
		["drop_item", JOY_BUTTON_DPAD_DOWN], ["craft", JOY_BUTTON_DPAD_RIGHT]]:
		var button := InputEventJoypadButton.new()
		button.button_index = int(pair[1])
		_add(str(pair[0]), button)
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B],
		["ui_up", JOY_BUTTON_DPAD_UP], ["ui_down", JOY_BUTTON_DPAD_DOWN],
		["ui_left", JOY_BUTTON_DPAD_LEFT], ["ui_right", JOY_BUTTON_DPAD_RIGHT]]:
		var button := InputEventJoypadButton.new()
		button.button_index = int(pair[1])
		_add(str(pair[0]), button)
	var drop_key := InputEventKey.new()
	drop_key.physical_keycode = KEY_G
	_add("drop_item", drop_key)


static func _add(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	InputMap.action_set_deadzone(action, 0.2)
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
