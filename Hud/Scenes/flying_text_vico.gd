@icon("res://Art/Currency/liq.png.png")
class_name FlyingTextVico
extends RigidBody2D



@onready var label = %Label
@onready var collision = %CollisionShape2D
@onready var margin_container = $MarginContainer
@onready var background = %Background
@onready var timer = %Timer
@onready var icon = %Icon

var initial_direction := Vector2(
	randf_range(-25, 25), 
	randf_range(-85,-75)
)
var crit: bool



func _ready():
	set_process(false)
	label.finished.connect(fix_body)
	timer.timeout.connect(queue_free)


func _physics_process(_delta):
#	if use_move_slide:
#		velocity.x *= (1 - (0.1 * delta))
#		velocity.y += gravity * delta
#		var collision = move_and_collide(velocity)
#		if collision:
#			velocity = velocity.bounce(collision.get_normal())
	
	if not timer.is_stopped():
		if timer.time_left <= 0.15:
			margin_container.modulate = Color(1, 1, 1, margin_container.modulate.a * 0.95)



func fix_body() -> void:
	collision.shape.height = margin_container.size.x - 8
	label.finished.disconnect(fix_body)



func setup(layer: int, mask: int) -> void:
	if layer > 0:
		set_collision_layer_value(layer, true)
	if mask > 0:
		set_collision_mask_value(layer, true)


func setup_currency(data: Dictionary) -> void:
	crit = data.crit
	var currency = wa.get_currency(data.cur) as Currency
	icon.texture = currency.details.get_icon()
	background.modulate = currency.details.get_color()
	var _text = "[i]" + data.text + "[/i]"
	var text = currency.details.get_color_text() % _text
	#var img_text = currency.details.icon_text + " "
	if crit:
		text = "[font_size=14]" + text
	label.text = text


func setup_text(data: Dictionary) -> void:
	icon.queue_free()
	label.text = data.text
	label.modulate = data.color


func setup_roll_text(_data: Dictionary) -> void:
	icon.queue_free()
	var quality: RollLog.RollQuality = _data.get("quality")
	var percent_text: String = " (%s%%)" % str(100 - _data.get("percent") * 100).pad_decimals(3)
	var quality_text: String = RollLog.RollQuality.keys()[quality].capitalize() + " Roll!"
	match quality:
		RollLog.RollQuality.UNBELIEVABLY_BAD:
			label.text = "[b][i][rainbow freq=0.5][wave freq=2.5]" + quality_text + percent_text
			modulate = Color(1, 0, 0)
		RollLog.RollQuality.PITIFUL:
			label.text = "[b][i]" + quality_text + percent_text
			modulate = Color(0.969, 0.384, 0)
		RollLog.RollQuality.BAD:
			label.text = "[i]" + quality_text + percent_text
			modulate = Color(1, 1, 0)
		RollLog.RollQuality.GOOD:
			label.text = "[i]" + quality_text + percent_text
			modulate = Color(0.412, 1, 0.082)
		RollLog.RollQuality.AMAZING:
			label.text = "[b][i]" + quality_text + percent_text
			modulate = Color(0.027, 0.722, 0.933)
		RollLog.RollQuality.GODLIKE:
			label.text = "[b][i][rainbow freq=0.5][wave freq=2.5]" + quality_text + percent_text



func go(_duration: float, _velocity_range: Array) -> void:
	show()
	if _duration > 0:
		timer.start(_duration)
	apply_impulse(initial_direction)
	
	animate() if not crit else animate_crit()
	set_process(true)


func animate() -> void:
	pass


func animate_crit() -> void:
	pass

