extends MarginContainer



#region Nodes

@onready var joypad_allowed = %JoypadAllowed
@onready var joypad_allowed_details = %JoypadAllowedDetails
@onready var joypad_detected = %JoypadDetected
@onready var fullscreen = %Fullscreen

#endregion



func _ready() -> void:
	Settings.joypad_allowed.changed.connect(joypad_allowed_changed)
	Settings.fullscreen.changed.connect(fullscreen_changed)
	gv.joypad_detected.changed.connect(joypad_detected_changed)
	gv.joypad_detected.changed.connect(update_focus_modes)
	joypad_allowed_changed()
	joypad_detected_changed()
	update_focus_modes()
	
	fullscreen.pressed.connect(Settings.fullscreen.invert)
	joypad_allowed.pressed.connect(Settings.joypad_allowed.invert)


func fullscreen_changed() -> void:
	fullscreen.button_pressed = Settings.fullscreen.get_value()


func joypad_allowed_changed() -> void:
	joypad_allowed.button_pressed = Settings.joypad_allowed.get_value()
	joypad_allowed_details.visible = joypad_allowed.button_pressed


func joypad_detected_changed() -> void:
	joypad_detected.button_pressed = gv.joypad_detected.get_value()


func update_focus_modes() -> void:
	var i: int
	if gv.joypad_detected.is_false():
		i = Control.FOCUS_NONE
	else:
		i = Control.FOCUS_ALL
	fullscreen.focus_mode = i
	joypad_allowed.focus_mode = i
