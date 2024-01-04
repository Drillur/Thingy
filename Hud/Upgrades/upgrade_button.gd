extends MarginContainer



@export var upgrade_type: Upgrade.Type

@onready var pb = $"Purchase Button" as PurchaseButton

var upgrade: Upgrade



func _ready() -> void:
	upgrade = up.get_upgrade(upgrade_type)
	upgrade.unlocked.changed.connect(unlocked_changed)
	pb.color = upgrade.details.color
	if upgrade.unlocked.is_true():
		setup()
	else:
		pb.lock()

func setup() -> void:
	if upgrade.details.name != "":
		pb.title_components.show()
		pb.title.text = upgrade.details.name
		pb.title.show()
		pb.texture_rect.texture = upgrade.details.icon
	else:
		pb.title_components.hide()
	if upgrade.details.description != "":
		upgrade.times_purchased.changed.connect(set_description_text)
		set_description_text()
		pb.description.show()
	else:
		pb.description.hide()
	upgrade.purchased.changed.connect(upgrade_purchased_changed)
	pb.cost_components.show()
	pb.setup(upgrade.cost)
	if upgrade.purchase_limit > 1:
		pb.times_purchased.show()
		upgrade.times_purchased.changed.connect(times_purchased_changed)
		times_purchased_changed()


func _on_purchase_button_pressed():
	if upgrade.can_purchase():
		upgrade.purchase()


func upgrade_purchased_changed() -> void:
	pb.cost_components.visible = not upgrade.purchased.get_value()
	if upgrade.purchased.is_true():
		pb.disconnect_calls()
	else:
		pb.connect_calls()
	if upgrade.purchased.is_true():
		pb.button.mouse_default_cursor_shape = CURSOR_ARROW
	else:
		pb.button.mouse_default_cursor_shape = CURSOR_POINTING_HAND


func _on_purchase_button_right_clicked():
	if gv.dev_mode and upgrade.purchased.is_true():
		upgrade.reset()


func times_purchased_changed() -> void:
	pb.times_purchased.text = "%s/%s" % [
		upgrade.times_purchased.get_text(),
		str(upgrade.purchase_limit)
	]


func set_description_text() -> void:
	pb.description.text = "[center]" + upgrade.get_description()


func unlocked_changed() -> void:
	if upgrade.unlocked.is_true():
		setup()
	else:
		pb.lock()
