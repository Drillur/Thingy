class_name ThingyContainer
extends MarginContainer



@onready var th0 = %th0 as ThingyVico
@onready var th1 = %th1 as ThingyVico
@onready var th2 = %th2 as ThingyVico
@onready var th3 = %th3 as ThingyVico
@onready var th4 = %th4 as ThingyVico
@onready var th5 = %th5 as ThingyVico
@onready var th6 = %th6 as ThingyVico
@onready var purchase_thingy = %"Purchase Thingy"

@onready var _up = %Up
@onready var to_top = %ToTop
@onready var down = %Down
@onready var to_bot = %ToBot

var selected_index := LoudInt.new(-1)



func _ready():
	selected_index.changed.connect(selected_index_changed)
	hide_all_thingies()
	purchase_thingy.setup(th.cost)
	purchase_thingy.color = th.next_thingy_color
	th.thingy_created.connect(thingy_created)
	thingy_created()


func _input(_event) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN):
		if th.has_thingy(selected_index.get_value() - 1):
			snap_to_index(selected_index.get_value() - 1)
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP):
		if th.has_thingy(selected_index.get_value() + 1):
			snap_to_index(selected_index.get_value() + 1)



# - Signal


func selected_index_changed() -> void:
	update_navigator_colors()



func _on_purchase_thingy_pressed():
	th.purchase_thingy()
	purchase_thingy.color = th.next_thingy_color


func _on_up_pressed():
	snap_to_index(th.get_next_index())


func _on_to_top_pressed():
	snap_to_index(th.get_top_index())


func _on_down_pressed():
	snap_to_index(th.get_previous_index())


func _on_to_bot_pressed():
	snap_to_index(th.get_bottom_index())


func thingy_created() -> void:
	match th.get_count():
		0, 1:
			snap_to_index(0)
			_up.hide()
			to_top.hide()
			down.hide()
			to_bot.hide()
		2:
			_up.show()
			to_top.hide()
			down.show()
			to_bot.hide()
		3:
			_up.show()
			to_top.show()
			down.show()
			to_bot.show()



# - Action


func snap_to_index(index: int) -> void:
	if th.has_thingy(index):
		selected_index.set_to(index)


func hide_all_thingies() -> void:
	th0.hide()
	th1.hide()
	th2.hide()
	th3.hide()
	th4.hide()
	th5.hide()
	th6.hide()


func update_navigator_colors() -> void:
	_up.color = th.get_color(th.get_next_index())
	to_top.color = th.get_color(th.get_top_index())
	down.color = th.get_color(th.get_previous_index())
	to_bot.color = th.get_color(th.get_bottom_index())
