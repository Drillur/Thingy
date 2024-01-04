@tool
class_name PurchaseButton
extends MarginContainer



@onready var content_parent = %"Content Parent"
@onready var check = %Check
@onready var check_bg = %"title bg"
@onready var bar = %Bar as Bar
@onready var cost_components = %CostComponents
@onready var texture_rect = %"Texture Rect"
@onready var title = %Title
@onready var button = %Button
@onready var title_components = %TitleComponents
@onready var description = %Description
@onready var times_purchased = %TimesPurchased

@export var icon: Texture2D
@export var text: String
@export var remove_cost_components := false
@export var remove_title_components := false

signal pressed
signal right_clicked

var content := {}

var color: Color:
	set(val):
		if color == val:
			return
		color = val
		texture_rect.modulate = color
		button.modulate = color
		if not remove_cost_components:
			check.self_modulate = color
			check_bg.self_modulate = color
			bar.color = color
			bar.color.a = 0.25

var cost: Cost



func _ready() -> void:
	if remove_cost_components:
		cost_components.queue_free()
	if remove_title_components:
		title_components.queue_free()
	title.text = text
	if text == "":
		title.hide()
	else:
		title.show()
	if icon:
		texture_rect.texture = icon



func setup(_cost: Cost) -> void:
	cost = _cost
	if not is_node_ready():
		await ready
	custom_minimum_size.x = 170
	for cur in cost.amount:
		var label = bag.get_resource("RichLabel").instantiate()
		label.disable_autowrap()
		content[cur] = label
		label.watch_cost(cur, cost)
		content_parent.add_child(label)
	
	cost.affordable.connect_and_call("changed", affordable_changed)
	
	if cost.affordable.is_true():
		update_progress_bar()
		bar.hide_edge()
	else:
		connect_calls()


func connect_calls() -> void:
	for cur in cost.amount:
		var currency = wa.get_currency(cur) as Currency
		if currency.amount.changed.is_connected(set_eta_text):
			return
		currency.amount.changed.connect(set_eta_text)
		currency.net_rate.changed.connect(set_eta_text)
		currency.amount.changed.connect(update_progress_bar)


func disconnect_calls() -> void:
	check.text = ""
	for cur in cost.amount:
		var currency = wa.get_currency(cur) as Currency
		if not currency.amount.changed.is_connected(set_eta_text):
			return
		currency.amount.changed.disconnect(set_eta_text)
		currency.net_rate.changed.disconnect(set_eta_text)
		currency.amount.changed.disconnect(update_progress_bar)



# - Signals


func _on_button_pressed():
	if cost:
		if cost.affordable.is_true() or gv.dev_mode:
			pressed.emit()
			set_eta_text()
		else:
			for cur in cost.amount:
				if wa.get_amount(cur).less(cost.get_amount_value(cur)):
					gv.flash(content[cur], Color.RED)
	else:
		pressed.emit()


func _on_button_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
				right_click()


func right_click() -> void:
	right_clicked.emit() 


func update_progress_bar() -> void:
	bar.set_deferred("progress", cost.get_progress_percent())


func set_eta_text() -> void:
	var _eta = cost.get_eta()
	if _eta.equal(0):
		check.text = ""
		return
	check.text = tp.full_parse_big(_eta)


func flash(): # manual flash
	if cost.affordable.is_true():
		flash_became_affordable()
	else:
		for cur in cost.get_insufficient_currency_types():
			content[cur].flash()


func flash_became_affordable() -> void:
	gv.flash(check, Color(0, 1, 0))


func affordable_changed() -> void:
	var val = cost.affordable.get_value()
	check.button_pressed = val
	if val:
		bar.hide_edge()
		disconnect_calls()
		flash_became_affordable()
	else:
		bar.show_edge()
		connect_calls()
		set_eta_text()
		update_progress_bar()


func _on_button_button_down():
	texture_rect.position.y = 1


func _on_button_button_up():
	texture_rect.position.y = 0



# - Action


func lock() -> void:
	texture_rect.texture = bag.get_resource("Locked")
	cost_components.hide()
	title.hide()
	description.hide()
	times_purchased.hide()
