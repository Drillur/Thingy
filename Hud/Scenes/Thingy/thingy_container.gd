class_name ThingyContainer
extends MarginContainer



@onready var th0 = %th0 as ThingyVico
@onready var th1 = %th1 as ThingyVico
@onready var th2 = %th2 as ThingyVico
@onready var th3 = %th3 as ThingyVico
@onready var th4 = %th4 as ThingyVico
@onready var th5 = %th5 as ThingyVico
@onready var th6 = %th6 as ThingyVico

@onready var _up = %Up
@onready var to_top = %ToTop
@onready var down = %Down
@onready var to_bot = %ToBot
@onready var navigation_buttons = %"Navigation Buttons"
@onready var navigation_joypad = %"Navigation Joypad"
@onready var joy_to_top = %JoyToTop
@onready var joy_up = %JoyUp
@onready var joy_down = %JoyDown
@onready var joy_to_bot = %JoyToBot

var selected_index := LoudInt.new(-1)



func _ready():
	selected_index.changed.connect(selected_index_changed)
	Settings.joypad_allowed.changed.connect(joypad_allowed_changed)
	gv.joypad_detected.changed.connect(joypad_allowed_changed)
	joypad_allowed_changed()
	hide_all_thingies()
	th.thingy_created.connect(thingy_created)
	thingy_created()
	display_navigators()



# - Signal


func joypad_allowed_changed() -> void:
	if Settings.joypad_allowed.is_false():
		navigation_buttons.show()
	elif gv.joypad_detected.is_true():
		navigation_buttons.hide()
	navigation_joypad.visible = not navigation_buttons.visible


func selected_index_changed() -> void:
	update_navigator_colors()
	display_navigators()


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
		1:
			snap_to_index(0)
			display_navigators()
		2, 3:
			display_navigators()



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
	
	joy_up.modulate = _up.color
	joy_to_top.modulate = to_top.color
	joy_down.modulate = down.color
	joy_to_bot.modulate = to_bot.color


func display_navigators() -> void:
	to_bot.visible = th.get_count() > 2
	down.visible = th.get_count() > 1
	to_top.visible = th.get_count() > 2
	_up.visible = th.get_count() > 1
	
	joy_up.visible = _up.visible
	joy_to_top.visible = to_top.visible
	joy_down.visible = down.visible
	joy_to_bot.visible = to_bot.visible