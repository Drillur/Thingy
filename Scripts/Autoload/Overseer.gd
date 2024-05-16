extends Node


const dev_mode := false

var root: CanvasLayer
var root_ready := LoudBool.new(false)
var save_manager_ready := LoudBool.new(false)
var game_has_focus := LoudBool.new(true)
var flying_texts: Array[FlyingText]



func _ready() -> void:
	game_has_focus.became_false.connect(game_lost_focus)
	game_has_focus.became_true.connect(game_gained_focus)
	setup_clock()
	session_tracker()
	setup_reset()
	setup_discord()
	get_viewport().gui_focus_changed.connect(focus_changed)


func _notification(what):
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			game_has_focus.set_to(false)
		NOTIFICATION_APPLICATION_FOCUS_IN:
			game_has_focus.set_to(true)




func flash(parent: Node, color = Color(1, 0, 0)) -> void:
	if Engine.get_frames_per_second() < 60:
		return
	var _flash = ResourceBag.get_resource("flash").instantiate()
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
	return Color(
		randf_range(0, 1),
		randf_range(0, 1),
		randf_range(0, 1),
		1.0
	)


func get_random_nondark_color() -> Color:
	var color: Color = get_random_color()
	while color.r + color.g + color.b < 1.0:
		color.r *= 1.1
		color.g *= 1.1
		color.b *= 1.1
	return color


func get_list_text_from_array(arr: Array) -> String:
	var text := ""
	var size = arr.size()
	var i = 0
	while size >= 1:
		text += arr[i]
		if size >= 3:
			text += ", "
		elif size >= 2 and arr.size() >= 3:
			text += ", and "
		elif size >= 2:
			text += " and "
		size -= 1
		i += 1
	return text


#endregion



#region Node Focus


func focus_changed(node) -> void:
	if node == null:
		if up.container:
			up.container.focus = null
		return


func find_nearest_focus(node: Control) -> void:
	if root_ready.is_false():
		return
	var nearest_next = get_nearest_next_focus(node.find_next_valid_focus(), 1)
	var nearest_prev = get_nearest_next_focus(node.find_next_valid_focus(), 1)
	if nearest_next[1] == nearest_prev[1] or nearest_next[1] > nearest_prev[1]:
		nearest_next[0].grab_focus()
	else:
		nearest_prev[0].grab_focus()


func get_nearest_next_focus(node: Control, distance: int) -> Array:
	if node is UpgradeButton or node is PurchaseButton:
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
var session_duration: LoudInt
var total_duration_played: int
var run_duration: LoudInt


func setup_clock() -> void:
	session_duration = LoudInt.new(0)
	run_duration = LoudInt.new(0)


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


#region Discord


func setup_discord() -> void:
	
	DiscordSDK.app_id = 1194327849545519205
	
	# this is boolean if everything worked
	#print("Discord working: " + str(DiscordSDK.get_is_discord_working()))
	
	# Set the first custom text row of the activity here
	#DiscordSDK.details = "They're really getting into it..."
	
	# Set the second custom text row of the activity here
	DiscordSDK.state = "Waking their Thingy up"
	
	# Image key for small image from "Art Assets" from the Discord Developer website
	#DiscordSDK.large_image = "Thingy"
	
	# Tooltip text for the large image
	#DiscordSDK.large_image_text = "Buhhhh"
	
	# Image key for large image from "Art Assets" from the Discord Developer website
	#DiscordSDK.small_image = "boss"
	
	# Tooltip text for the small image
	#DiscordSDK.small_image_text = "Fighting the end boss! D:"
	
	# "02:41 elapsed" timestamp for the activity
	DiscordSDK.start_timestamp = int(Time.get_unix_time_from_system())
	
	# "59:59 remaining" timestamp for the activity
	#DiscordSDK.end_timestamp = int(Time.get_unix_time_from_system()) + 3600
	
	# Always refresh after changing the values!
	DiscordSDK.refresh()


func update_discord_details(text: String) -> void:
	DiscordSDK.details = text
	DiscordSDK.refresh()


func update_discord_state(text: String) -> void:
	DiscordSDK.state = text
	DiscordSDK.refresh()


#endregion


#region Dev


func report(object: Object, max_depth := 2) -> void:
	var vars = get_script_variables(object.get_script())
	var _class_name: String
	if "_class_name" in vars:
		_class_name = object.get("_class_name")
	else:
		_class_name = object.get_class()
	printt("Report:", _class_name, object)
	print(get_object_report_text(object, 1, max_depth))


func get_object_report_text(object: Object, depth: int, max_depth: int) -> String:
	if depth > max_depth:
		return str(object)
	if object.get_script() == null:
		return ""
	var vars = get_script_variables(object.get_script())
	var text: String = ""
	for x in vars:
		if x == "_class_name":
			continue
		
		text += "\n"
		for i in depth:
			text += "-\t"
		text += x + ": "
		
		if object.get(x) is LoudBool or object.get(x) is LoudColor:
			text += str(object.get(x).get_value())
		elif object.get(x) is Object:
			if object.get(x).has_method("get_text"):
				text += object.get(x).get_text()
			else:
				text += get_object_report_text(object.get(x), depth + 1, max_depth)
		elif object.get(x) is Dictionary:
			for y in object.get(x):
				text += "\n"
				for i in depth + 1:
					text += "-\t"
				text += str(y) + ": " + str(object.get(x)[y])
		elif typeof(object.get(x)) == TYPE_ARRAY:
			for y in object.get(x):
				text += "\n"
				for i in depth + 1:
					text += "-\t"
				text += str(y)
		else:
			text += str(object.get(x))
	return text


#endregion
