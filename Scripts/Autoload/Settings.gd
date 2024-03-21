extends Node



var color := Color(0, 1, 0.812)

@export var fullscreen := LoudBool.new(false)
@export var joypad_allowed := LoudBool.new(true)
@export var joypad_detected := LoudBool.new(false)
var joypad := LoudBoolArray.new([joypad_allowed, joypad_detected])
@export var rate_mode := LoudInt.new(wa.RateMode.MINIMUM)


func _ready() -> void:
	for variable in gv.get_script_variables(get_script()):
		if has_method(variable + "_changed"):
			get(variable).changed.connect(get(variable + "_changed"))



func _input(_event) -> void:
	if Input.is_action_just_pressed("fullscreen_toggle"):
		fullscreen.invert()
	if joypad_allowed.is_true() and joypad_detected.is_false():
		if _event is InputEventJoypadButton:
			joypad_detected.set_to(true)



func joypad_allowed_changed() -> void:
	if joypad_allowed.is_false():
		joypad.set_to(false)
		get_viewport().gui_release_focus()


func fullscreen_changed() -> void:
	if gv.root_ready.is_false():
		await gv.root_ready.became_true
	if fullscreen.is_true():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
