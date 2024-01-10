@tool
class_name _MenuButton
extends MarginContainer



signal pressed

@onready var icon_container = %IconContainer
@onready var texture_rect = %Icon
@onready var button = $Button
@onready var label = %Label
@onready var h_box = %HBox

@export var icon: Texture2D
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
		if val == Color.BLACK:
			label.modulate = val

@export var center_content := false

@export var display_node: Node
@export var drop_down: Node



func _ready():
	color = color
	Settings.joypad.right.changed.connect(joypad_allowed_changed)
	joypad_allowed_changed()
	set_icon(icon)
	if drop_down != null:
		button.disconnect("button_down", _on_button_button_down)
		button.disconnect("button_up", _on_button_button_up)
		drop_down.visibility_changed.connect(drop_down_visibility_changed)
		drop_down.hide()
		drop_down_visibility_changed()
	if text == "":
		label.hide()
	else:
		label.show()
	
	if center_content:
		h_box.alignment = HBoxContainer.ALIGNMENT_CENTER



func _on_button_pressed():
	if drop_down != null:
		drop_down.visible = not drop_down.visible
	elif display_node != null:
		display_node.visible = not display_node.visible
	
	pressed.emit()


func _on_button_gui_input(event):
	gui_input.emit(event)



func drop_down_visibility_changed() -> void:
	if drop_down.visible:
		texture_rect.rotation_degrees = 0
		texture_rect.position.y = 0
	else:
		texture_rect.rotation_degrees = -90
		texture_rect.position = Vector2(0, 24)


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


func _on_focus_entered():
	button.grab_focus()


func _on_focus_exited():
	texture_rect.position.y = 0


func joypad_allowed_changed() -> void:
	if Settings.joypad.are_true():
		focus_mode = Control.FOCUS_ALL
		button.focus_mode = Control.FOCUS_ALL
	else:
		focus_mode = Control.FOCUS_NONE
		button.focus_mode = Control.FOCUS_NONE
