@tool
class_name IconButton
extends MarginContainer



signal pressed
signal right_mouse_pressed

@export var icon: Texture2D
@export var center_content := false:
	set(val):
		center_content = val
		if not is_node_ready():
			await ready
		if val:
			$MarginContainer.size_flags_horizontal = SIZE_FILL
		else:
			$MarginContainer.size_flags_horizontal = SIZE_SHRINK_BEGIN
@export var flip_h := false:
	set(val):
		flip_h = val
		if not is_node_ready():
			await ready
		texture_rect.flip_h = val
@export var display_background := false:
	set(val):
		display_background = val
		if not is_node_ready():
			await ready
		if display_background:
			background.show()
		else:
			background.hide()

@onready var texture_rect = %Icon
@onready var button = $Button
@onready var icon_shadow = %"Icon Shadow"
@onready var background = %Background

var color: Color:
	set(val):
		color = val
		texture_rect.self_modulate = val
		button.modulate = val


func _ready():
	if icon != null:
		texture_rect.texture = icon
		icon_shadow.texture = texture_rect.texture


func _on_button_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			right_mouse_pressed.emit()


func _on_button_mouse_exited():
	mouse_exited.emit()


func _on_button_mouse_entered():
	mouse_entered.emit()


func _on_button_button_down():
	texture_rect.position.y = 1


func _on_button_button_up():
	texture_rect.position.y = 0




func set_icon(_icon: Texture) -> void:
	texture_rect.texture = _icon
	icon_shadow.texture = texture_rect.texture


func set_icon_min_size(_size: Vector2) -> void:
	texture_rect.custom_minimum_size = _size


func set_button_color(_color: Color) -> void:
	button.self_modulate = _color



func clear_optionals() -> IconButton:
	icon_shadow.queue_free()
	return self


func clear_icon_shadow():
	icon_shadow.queue_free()
	return self

