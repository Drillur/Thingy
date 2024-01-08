@tool
extends MarginContainer



@onready var background = %Background
@onready var label = %Label
@onready var texture_rect = %"TextureRect"
@onready var h_box_container = %HBoxContainer

@export var text: String:
	set(val):
		text = val
		if not is_node_ready():
			await ready
		label.text = val

@export var color := Color(1, 1, 1):
	set(val):
		if color != val:
			color = val
			if not is_node_ready():
				await ready
			background.modulate = val

@export var center_content := false:
	set(val):
		center_content = val
		if not is_node_ready():
			await ready
		if val:
			h_box_container.alignment = h_box_container.ALIGNMENT_CENTER
		else:
			h_box_container.alignment = h_box_container.ALIGNMENT_BEGIN

@export var icon: Texture2D:
	set(val):
		icon = val
		if not is_node_ready():
			await ready
		texture_rect.texture = icon
		texture_rect.show()



func _ready() -> void:
	if icon == null:
		texture_rect.hide()
	label.text = text



func set_color(val: Color) -> void:
	color = val
