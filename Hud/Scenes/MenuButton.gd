@tool
class_name _MenuButton
extends MarginContainer



signal pressed

@export var icon: Texture2D:
	set(val):
		icon = val
		if not is_node_ready():
			await ready
		set_icon(val)
@export var text: String:
	set(val):
		text = val
		if not is_node_ready():
			await ready
		label.text = text
		if text == "":
			label.hide()
		else:
			label.show()
@export var color := Color.WHITE:
	set(val):
		color = val
		if not is_node_ready():
			await ready
		button.modulate = val
		texture_rect.modulate = val
		if background:
			background.modulate = val
		if val == Color.BLACK:
			label.modulate = val
@export var icon_size := 24:
	set(val):
		icon_size = val
		if not is_node_ready():
			await ready
		icon_container.custom_minimum_size = Vector2(val, val)
		texture_rect.custom_minimum_size = Vector2(val, val)
@export var center_content := false
@export var drop_down: Node
@export var display_background := false:
	set(val):
		display_background = val
		if not is_node_ready():
			await ready
		if display_background:
			background.show()
		else:
			background.hide()

@onready var icon_container = %IconContainer
@onready var texture_rect = %Icon
@onready var button = $Button
@onready var label = %Label
@onready var h_box = %HBox
@onready var background = %Background

var disabled := LoudBool.new(false)



func _ready():
	color = color
	set_icon(icon)
	if drop_down != null:
		button.disconnect("button_down", _on_button_button_down)
		button.disconnect("button_up", _on_button_button_up)
		drop_down.hide()
	if text == "":
		label.hide()
	else:
		label.show()
	if display_background:
		background.show()
	else:
		background.hide()
	
	if center_content:
		h_box.alignment = HBoxContainer.ALIGNMENT_CENTER
	else:
		h_box.alignment = HBoxContainer.ALIGNMENT_BEGIN
	disabled.became_true.connect(disable)
	disabled.became_false.connect(enable)



func _on_button_pressed():
	if drop_down != null:
		drop_down.visible = not drop_down.visible
	
	pressed.emit()


func _on_button_mouse_exited():
	mouse_exited.emit()


func _on_button_mouse_entered():
	mouse_entered.emit()


func _on_button_button_down():
	texture_rect.position.y = 1


func _on_button_button_up():
	texture_rect.position.y = 0





func set_icon(_icon: Texture) -> void:
	if _icon == null:
		icon_container.hide()
	else:
		texture_rect.texture = _icon
		icon_container.show()



func set_text_visibility(val: bool) -> void:
	label.visible = val


func show_text() -> void:
	set_text_visibility(true)


func hide_text() -> void:
	set_text_visibility(false)


func set_color(val: Color) -> void:
	color = val


func enable() -> void:
	color = Color.WHITE
	button.disabled = false
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func disable() -> void:
	color = Color.BLACK
	button.disabled = true
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW
