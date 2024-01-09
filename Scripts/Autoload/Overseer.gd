extends Node


const dev_mode := false

var root: CanvasLayer
var root_ready := LoudBool.new(false)
var joypad_detected := LoudBool.new(false)
var game_has_focus := LoudBool.new(true)



func _ready() -> void:
	SaveManager.color.set_to(get_random_nondark_color())
	Settings.joypad_allowed.changed.connect(joypad_allowed_changed)
	game_has_focus.became_false.connect(game_lost_focus)
	game_has_focus.became_true.connect(game_gained_focus)
	session_tracker()
	setup_reset()
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
	if _event is InputEventJoypadButton:
		joypad_detected.set_to(true)
	if joypad_detected.is_true():
		set_process_input(false)


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
		if property.usage in [
			PROPERTY_USAGE_SCRIPT_VARIABLE,
			4102
		]:
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


#region Clock

signal one_second

var last_clock: float
var current_clock: float = Time.get_unix_time_from_system()
var session_duration := LoudInt.new(0)
var total_duration_played: int
var run_duration := LoudInt.new(0)


func game_lost_focus() -> void:
	last_clock = Time.get_unix_time_from_system()


func game_gained_focus() -> void:
	var time := Time.get_unix_time_from_system()
	if time - current_clock > 1:
		var time_delta := time - last_clock
		if time_delta > 1:
			pass#get_offline_earnings(last_clock)


func session_tracker() -> void:
	await root_ready.became_true
	var t = Timer.new()
	t.one_shot = false
	t.wait_time = 1
	add_child(t)
	t.timeout.connect(second_passed)
	t.start()


func second_passed() -> void:
	current_clock = Time.get_unix_time_from_system()
	session_duration.add(1)
	total_duration_played += 1
	run_duration.add(1)
	if SaveManager.get_time_since_last_save() >= 30:
		SaveManager.save_game()
	one_second.emit()


#endregion



#region Reset Prestige


signal reset(tier)


func setup_reset() -> void:
	pass


func reset_now(tier: int) -> void:
	wa.collect_reset_currency(tier)
	reset.emit(tier)


#endregion
