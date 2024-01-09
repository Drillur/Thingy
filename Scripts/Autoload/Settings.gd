extends Node



var color := Color(0, 1, 0.812)

@export var fullscreen := LoudBool.new(false)
@export var joypad_allowed := LoudBool.new(true)



func _ready() -> void:
	for variable in gv.get_script_variables(get_script()):
		if has_method(variable + "_changed"):
			get(variable).changed.connect(get(variable + "_changed"))



func _input(_event) -> void:
	if Input.is_action_just_pressed("fullscreen_toggle"):
		fullscreen.invert()



func joypad_allowed_changed() -> void:
	get_viewport().gui_release_focus()


func fullscreen_changed() -> void:
	if gv.root_ready.is_false():
		await gv.root_ready.became_true
	if fullscreen.is_true():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
