@tool
class_name PurchaseButton
extends MarginContainer



@export var icon: Texture2D
@export var text: String
@export var remove_cost_components := false
@export var remove_title_components := false

@onready var cost_components = %CostComponents as CostComponents
@onready var texture_rect = %"Texture Rect"
@onready var title = %Title
@onready var button = %Button
@onready var title_components = %TitleComponents
@onready var description = %Description
@onready var autobuyer_anim = %AutobuyerAnim
@onready var times_purchased = %"times purchased"

signal pressed
signal right_clicked


var locked: bool
var loud_color: LoudColor
var price: Price
var color: Color:
	set(val):
		if color == val:
			return
		color = val
		button.modulate = color
		texture_rect.modulate = color
		if not remove_cost_components:
			cost_components.color = color



func _ready() -> void:
	times_purchased.hide()
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



func setup_price(_price: Price) -> void:
	price = _price
	if not is_node_ready():
		await ready
	cost_components.price = price
	cost_components.custom_minimum_size.x = 170
	price.all_affordable.became_true.connect(
		func():
			if not locked:
				gv.flash(self, color)
	)


func assign_loud_color(_loud_color: LoudColor) -> void:
	loud_color = _loud_color
	loud_color.changed.connect(loud_color_changed)
	loud_color_changed()



# - Signals


func loud_color_changed() -> void:
	color = loud_color.get_value()


func _on_button_pressed():
	pressed.emit()


func _on_button_gui_input(event: InputEvent):
	if (
		event is InputEventMouseButton
		and event.button_mask == MOUSE_BUTTON_MASK_RIGHT
		and event.is_pressed()
	):
		right_click()


func right_click() -> void:
	right_clicked.emit()


func _on_button_button_down():
	texture_rect.position.y = 1


func _on_button_button_up():
	texture_rect.position.y = 0


func _on_focus_entered():
	if Settings.joypad.is_true():
		button.grab_focus()


func _on_button_mouse_entered():
	if button.focus_mode == Control.FOCUS_ALL:
		button.grab_focus()



# - Action


func unlock() -> void:
	locked = false
	title_components.show()
	title.show()


func lock() -> void:
	locked = true
	texture_rect.texture = bag.get_resource("Locked")
	cost_components.hide()
	title.hide()
	description.hide()
	times_purchased.hide()
