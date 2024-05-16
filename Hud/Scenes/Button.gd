class_name RichButton
extends Button



signal left_pressed
signal right_pressed

var color: Color:
	set(val):
		if color == val:
			return
		color = val
		modulate = val


func _ready():
	#Settings.joypad.changed.connect(
		#func():
			#focus_mode = Control.FOCUS_ALL if Settings.joypad.is_true() else Control.FOCUS_NONE
	#)
	pass



func enable() -> void:
	disabled = false


func _on_gui_input(event = 0):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_mask == MOUSE_BUTTON_RIGHT:
				right_pressed.emit()
			elif event.button_mask == MOUSE_BUTTON_LEFT:
				left_pressed.emit()

