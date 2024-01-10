@tool
class_name PurchaseButton
extends MarginContainer



@onready var content_parent = %"Content Parent"
@onready var check = %Check
@onready var check_bg = %"title bg"
@onready var bar = %Bar as Bar
@onready var pending_bar = %PendingBar
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
@export var allow_focus := true

signal pressed
signal right_clicked

var content := {}

var loud_color: LoudColor

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
			pending_bar.color = color
			pending_bar.color.a = 0.2
			

var cost: Cost



func _ready() -> void:
	Settings.joypad.right.changed.connect(joypad_allowed_changed)
	joypad_allowed_changed()
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
	if not allow_focus:
		button.focus_mode = FOCUS_NONE
	button.focus_exited.connect(_on_button_button_up)
	pressed.connect(pressed_emitted)



func setup(_cost: Cost) -> void:
	cost = _cost
	if not is_node_ready():
		await ready
	cost_components.custom_minimum_size.x = 170
	for cur in cost.amount:
		var label = bag.get_resource("RichLabel").instantiate()
		#label.theme = bag.get_resource("ShadowText")
		label.disable_autowrap()
		content[cur] = label
		label.watch_cost(cur, cost)
		content_parent.add_child(label)
	
	cost.affordable.connect_and_call("changed", affordable_changed)
	cost.reset.connect(update)
	SaveManager.loading.became_false.connect(update)
	
	if cost.affordable.is_true():
		update()
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
		currency.amount.changed.connect(update_pending_progress_bar)
		currency.amount.pending_changed.connect(update_pending_progress_bar)


func disconnect_calls() -> void:
	check.text = ""
	for cur in cost.amount:
		var currency = wa.get_currency(cur) as Currency
		if not currency.amount.changed.is_connected(set_eta_text):
			return
		currency.amount.changed.disconnect(set_eta_text)
		currency.net_rate.changed.disconnect(set_eta_text)
		currency.amount.changed.disconnect(update_progress_bar)
		currency.amount.changed.disconnect(update_pending_progress_bar)
		currency.amount.pending_changed.disconnect(update_pending_progress_bar)


func assign_loud_color(_loud_color: LoudColor) -> void:
	loud_color = _loud_color
	loud_color.changed.connect(loud_color_changed)
	loud_color_changed()



# - Signals


func loud_color_changed() -> void:
	color = loud_color.get_value()


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


func pressed_emitted() -> void:
	gv.flash(self, color)
	update()


func joypad_allowed_changed() -> void:
	if Settings.joypad.are_true():
		focus_mode = Control.FOCUS_ALL
		button.focus_mode = Control.FOCUS_ALL
	else:
		focus_mode = Control.FOCUS_NONE
		button.focus_mode = Control.FOCUS_NONE


func _on_button_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
				right_click()


func right_click() -> void:
	right_clicked.emit()


func update() -> void:
	update_progress_bar()
	update_pending_progress_bar()
	set_eta_text()


func update_progress_bar() -> void:
	if cost:
		bar.set_deferred("progress", cost.get_progress_percent())


func update_pending_progress_bar() -> void:
	if cost:
		var pending_progress_percent = cost.get_pending_progress_percent()
		pending_bar.set_deferred("progress", pending_progress_percent)
		if is_equal_approx(pending_progress_percent, 1.0):
			pending_bar.hide_edge()
		else:
			pending_bar.show_edge()


func set_eta_text() -> void:
	if cost:
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
		update()


func _on_button_button_down():
	texture_rect.position.y = 1


func _on_button_button_up():
	texture_rect.position.y = 0


func _on_focus_entered():
	if Settings.joypad.get_left():
		button.grab_focus()


func _on_button_mouse_entered():
	if button.focus_mode == Control.FOCUS_ALL:
		button.grab_focus()



# - Action


func lock() -> void:
	texture_rect.texture = bag.get_resource("Locked")
	cost_components.hide()
	title.hide()
	description.hide()
	times_purchased.hide()
