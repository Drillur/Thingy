extends MarginContainer



const INDEX_1 := 2

#region Nodes

@onready var joypad_allowed = %JoypadAllowed
@onready var joypad_detected = %JoypadDetected
@onready var fullscreen = %Fullscreen
@onready var eta_mode = %"ETA Mode"

#endregion



func _ready() -> void:
	Settings.fullscreen.changed.connect(fullscreen_changed)
	Settings.rate_mode.changed.connect(rate_mode_changed)
	Settings.joypad_allowed.changed.connect(joypad_allowed_changed)
	Settings.joypad_detected.changed.connect(joypad_detected_changed)
	Settings.joypad_detected.changed.connect(update_focus_modes)
	joypad_allowed_changed()
	joypad_detected_changed()
	update_focus_modes()
	
	fullscreen.pressed.connect(Settings.fullscreen.invert)
	joypad_allowed.pressed.connect(Settings.joypad_allowed.invert)
	eta_mode.item_selected.connect(Settings.rate_mode.set_to)


func fullscreen_changed() -> void:
	fullscreen.button_pressed = Settings.fullscreen.get_value()


func joypad_allowed_changed() -> void:
	joypad_allowed.button_pressed = Settings.joypad_allowed.get_value()
	joypad_detected.visible = joypad_allowed.button_pressed


func joypad_detected_changed() -> void:
	joypad_detected.text = "Detected: %s" % (
		"Yes" if Settings.joypad_detected.get_value() else "No"
	)


func rate_mode_changed() -> void:
	eta_mode.selected = Settings.rate_mode.get_value()


func update_focus_modes() -> void:
	var i: int
	if Settings.joypad.is_true():
		i = Control.FOCUS_ALL
	else:
		i = Control.FOCUS_NONE
	fullscreen.focus_mode = i
	joypad_allowed.focus_mode = i
	eta_mode.focus_mode = i


func _on_scale_item_selected(index):
	match index:
		INDEX_1 - 2:
			ProjectSettings.set_setting("display/window/stretch/scale", 0.9)
		INDEX_1 - 1:
			ProjectSettings.set_setting("display/window/stretch/scale", 0.95)
		INDEX_1 + 0:
			ProjectSettings.set_setting("display/window/stretch/scale", 1.0)
		INDEX_1 + 1:
			ProjectSettings.set_setting("display/window/stretch/scale", 1.05)
		INDEX_1 + 2:
			ProjectSettings.set_setting("display/window/stretch/scale", 1.1)
		INDEX_1 + 3:
			ProjectSettings.set_setting("display/window/stretch/scale", 1.15)
		INDEX_1 + 4:
			ProjectSettings.set_setting("display/window/stretch/scale", 1.2)
		INDEX_1 + 5:
			ProjectSettings.set_setting("display/window/stretch/scale", 1.25)
		INDEX_1 + 6:
			ProjectSettings.set_setting("display/window/stretch/scale", 1.3)
		INDEX_1 + 7:
			ProjectSettings.set_setting("display/window/stretch/scale", 1.35)
		INDEX_1 + 8:
			ProjectSettings.set_setting("display/window/stretch/scale", 1.4)
		INDEX_1 + 9:
			ProjectSettings.set_setting("display/window/stretch/scale", 1.45)
		INDEX_1 + 10:
			ProjectSettings.set_setting("display/window/stretch/scale", 1.5)
