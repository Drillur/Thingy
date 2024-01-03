@tool
extends MarginContainer



@onready var background = %Background
@onready var label = %Label
@onready var texture_rect = %"Texture Rect"

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

@export var icon: Texture2D:
	set(val):
		icon = val
		if not is_node_ready():
			await ready
		print(texture_rect == null)
		texture_rect.texture = icon



func _ready() -> void:
	if icon == null:
		texture_rect.queue_free()
	label.text = text
