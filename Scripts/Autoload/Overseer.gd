extends Node


const dev_mode := true

var root: CanvasLayer
var root_ready := LoudBool.new(false)
var joypad_detected := LoudBool.new(false)
var game_has_focus := LoudBool.new(true)



func _ready() -> void:
	SaveManager.color.set_to(get_random_nondark_color())
	Settings.joypad_allowed.changed.connect(joypad_allowed_changed)
	if Settings.joypad_allowed.is_true():
		get_viewport().gui_focus_changed.connect(focus_changed)


func _notification(what):
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			game_has_focus.set_to(false)
		NOTIFICATION_APPLICATION_FOCUS_IN:
			game_has_focus.set_to(true)


func joypad_allowed_changed() -> void:
	set_process_input(Settings.joypad_allowed.get_value())
	if Settings.joypad_allowed.is_false():
		joypad_detected.set_to(false)


func _input(_event):
	if (
		Input.is_joy_button_pressed(0, JOY_BUTTON_A)
		or Input.is_joy_button_pressed(0, JOY_BUTTON_B)
		or Input.is_joy_button_pressed(0, JOY_BUTTON_X)
		or Input.is_joy_button_pressed(0, JOY_BUTTON_Y)
		or Input.is_joy_button_pressed(0, JOY_BUTTON_START)
		or Input.is_joy_button_pressed(0, JOY_BUTTON_BACK)
		or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN)
		or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP)
		or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT)
		or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT)
	):
		joypad_detected.set_to(true)
	if joypad_detected.is_true():
		set_process_input(false)


func input_is_action_pressed(action: StringName) -> bool:
	if Settings.joypad_allowed.is_true() and joypad_detected.is_true():
		if game_has_focus.is_true():
			return Input.is_action_pressed(action)
	else:
		return Input.is_action_just_pressed(action)
	return false


func input_is_action_just_pressed(action: StringName) -> bool:
	if Settings.joypad_allowed.is_true() and joypad_detected.is_true():
		if game_has_focus.is_true():
			return Input.is_action_just_pressed(action)
	else:
		return Input.is_action_just_pressed(action)
	return false



func flash(parent: Node, color = Color(1, 0, 0)) -> void:
	if Engine.get_frames_per_second() < 60:
		return
	var _flash = bag.get_resource("flash").instantiate()
	parent.add_child(_flash)
	_flash.flash(color)


#region Get


func node_has_point(node: Node, point: Vector2) -> bool:
	if not node.is_visible_in_tree():
		return false
	return node.get_global_rect().has_point(point)


func get_script_variables(script: Script) -> Array:
	var variable_names := []
	for property in script.get_script_property_list():
		if property.usage == PROPERTY_USAGE_SCRIPT_VARIABLE:
			variable_names.append(property.name)
	return variable_names


func get_random_color() -> Color:
	var r = randf_range(0, 1)
	var g = randf_range(0, 1)
	var b = randf_range(0, 1)
	return Color(r, g, b, 1.0)


func get_random_nondark_color() -> Color:
	var r = randf_range(0, 1)
	var g = randf_range(0, 1)
	var b = randf_range(0, 1)
	while r + g + b < 1.0:
		r *= 1.1
		g *= 1.1
		b *= 1.1
	return Color(r, g, b, 1.0)


#endregion



#region Node Focus


func focus_changed(node) -> void:
	if node == null:
		if up.container:
			up.container.focus = null
		return


func find_nearest_focus(node: Control) -> void:
	var nearest_next = get_nearest_next_focus(node.find_next_valid_focus(), 1)
	var nearest_prev = get_nearest_next_focus(node.find_next_valid_focus(), 1)
	if nearest_next[1] == nearest_prev[1] or nearest_next[1] > nearest_prev[1]:
		nearest_next[0].grab_focus()
	else:
		nearest_prev[0].grab_focus()


func get_nearest_next_focus(node: Control, distance: int) -> Array:
	if node is UpgradeButton or PurchaseButton:
		return [node, distance]
	return get_nearest_next_focus(node.find_next_valid_focus(), distance + 1)


func get_prev_focus(node: Control, distance: int) -> Array:
	if node is UpgradeButton or PurchaseButton:
		return [node, distance]
	return get_prev_focus(node.find_prev_valid_focus(), distance + 1)



#endregion
