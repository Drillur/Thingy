class_name FlyingText
extends MarginContainer



static var global_flying_texts_parent: Control

@onready var background = %Background
@onready var icon = %Icon
@onready var label = %Label

var tween: Tween



func _ready() -> void:
	hide()



func set_text(_text: String) -> void:
	label.text = _text


func set_icon(_icon) -> void:
	if _icon is Texture2D:
		icon.texture = _icon
	elif _icon is String:
		icon.texture = ResourceBag.get_icon(_icon)


func set_position_by_spawn_node(_spawn_node: Node) -> void:
	var node_rect: Rect2 = _spawn_node.get_global_rect()
	var node_half_width = node_rect.size.x / 2
	var node_fourth_height = node_rect.size.y / 4
	var x_offset = randi_range(-node_rect.size.x / 4, node_rect.size.x / 4)
	
	var my_half_width = size.x / 2
	var my_half_height = size.y / 2
	position = Vector2(
		node_rect.position.x + node_half_width - my_half_width + x_offset,
		node_rect.position.y + node_fourth_height - my_half_height
	)


func go(_spawn_node: Node) -> void:
	await get_tree().physics_frame
	set_position_by_spawn_node(_spawn_node)
	show()
	animate_normally()


func animate_normally() -> void:
	tween = get_tree().create_tween()
	var new_pos := Vector2(position.x, position.y - randf_range(20, 25))
	tween.tween_property(self, "position", new_pos, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(tween.kill)
	tween.finished.connect(queue_free)



#region Static



static func new_text_with_icon(_spawn_node: Node, _text: String, _icon: Texture2D, color := Color.WHITE) -> void:
	if not FlyingText.can_throw(_spawn_node):
		return
	var prefab: FlyingText = ResourceBag.get_resource("FlyingText").instantiate()
	FlyingText.global_flying_texts_parent.add_child(prefab)
	prefab.set_icon(_icon)
	prefab.set_text(_text)
	prefab.label.modulate = color
	prefab.icon.modulate = color
	prefab.go(_spawn_node)


static func new_text(_spawn_node: Node, _text: String) -> void:
	if not FlyingText.can_throw(_spawn_node):
		return
	var prefab: FlyingText = ResourceBag.get_resource("FlyingText").instantiate()
	FlyingText.global_flying_texts_parent.add_child(prefab)
	prefab.icon.queue_free()
	prefab.set_text(_text)
	prefab.go(_spawn_node)


static func got_currency(_spawn_node: Node, currency_key: String, _amount: Big) -> void:
	if not FlyingText.can_throw(_spawn_node):
		return
	var text: String = "+%s %s" % [
		_amount.get_text(),
		wa.get_details(currency_key).get_colored_name()
	]
	var _icon: Texture2D = wa.get_icon(currency_key)
	FlyingText.new_text_with_icon(_spawn_node, text, _icon)


static func got_crit(_spawn_node: Node, crit_text: String, color: Color) -> void:
	if not FlyingText.can_throw(_spawn_node):
		return
	var text: String = "[b]Crit![/b] [i]%s[/i]" % crit_text
	var _icon: Texture2D = ResourceBag.get_icon("Dice")
	FlyingText.new_text_with_icon(_spawn_node, text, _icon, color)


static func can_throw(spawn_node: Node) -> bool:
	return spawn_node.is_visible_in_tree()


#endregion
