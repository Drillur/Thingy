class_name FlyingText
extends Resource



enum Type { CURRENCY, JUST_TEXT, ROLL_TEXT, }
enum CurrencyKeys { collide, cur, text, }

static var global_flying_texts_parent: Control



var type: Type
var vicos := []
var rect: Rect2
var parent_node: Node
var duration: float
var layer: Array
var timer := Timer.new()
var velocity_range: Array



func _init(
	_type: Type,
	_base_node: Node,
	_parent_node: Node,
	_layer: Array,
	_velocity_range: Array = [
		randf_range(-1, 1),
		randf_range(-1, -1.8)
	]
):
	type = _type
	rect = _base_node.get_global_rect()
	parent_node = _parent_node
	layer = _layer
	velocity_range = _velocity_range
	match type:
		Type.CURRENCY:
			duration = 0.6
		Type.JUST_TEXT, Type.ROLL_TEXT:
			duration = 1.5
	timer.wait_time = 0.08
	timer.one_shot = false
	timer.timeout.connect(throw_text)
	gv.add_child(timer)
	
	gv.flying_texts.append(self)


func add(data: Dictionary) -> void:
	var vico = bag.get_resource("flying_text").instantiate() as FlyingTextVico
	vicos.append(vico)
	vico.setup(layer[0], layer[1])
	parent_node.add_child(vico)
	vico.global_position = Vector2(
		rect.position.x + randf_range(0, rect.size.x),
		rect.position.y + randf_range(0, rect.size.y)
	)
	vico.hide()
	
	match type:
		Type.CURRENCY:
			vico.setup_currency(data)
		Type.ROLL_TEXT:
			vico.setup_roll_text(data)
		Type.JUST_TEXT:
			vico.setup_text(data)



func go(_custom_duration := duration):
	duration = _custom_duration
	timer.start()
	throw_text()


func throw_text() -> void:
	var vico = vicos.pop_front() as FlyingTextVico
	vico.go(duration, velocity_range)
	if vicos.size() == 0:
		timer.stop()
		gv.flying_texts.erase(self)
