class_name UpgradeButton
extends MarginContainer



@export var upgrade_type: Upgrade.Type
@export var wrap_description := false:
	set(val):
		wrap_description = val
		if not is_node_ready():
			await ready
		if val:
			pb.description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			pb.description.autowrap_mode = TextServer.AUTOWRAP_OFF

@onready var pb = $"Purchase Button" as PurchaseButton

var upgrade: Upgrade



func _ready() -> void:
	Settings.joypad_allowed.changed.connect(update_focus)
	gv.joypad_detected.changed.connect(update_focus)
	upgrade = up.get_upgrade(upgrade_type)
	upgrade.unlocked.changed.connect(unlocked_changed)
	upgrade.purchased.changed.connect(upgrade_purchased_changed)
	update_focus()
	pb.color = upgrade.details.color
	pb.setup(upgrade.cost)
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
	pb.cost_components.show()
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
		update_focus()
	else:
		pb.button.mouse_default_cursor_shape = CURSOR_POINTING_HAND


func _on_purchase_button_right_clicked():
	if gv.dev_mode and upgrade.purchased.is_true():
		#upgrade.reset()
		pass


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
		update_focus()
	else:
		pb.lock()


func update_focus() -> void:
	if Settings.joypad_allowed.is_true() and gv.joypad_detected.is_true():
		if upgrade.unlocked.is_false() or upgrade.purchased.is_true():
			focus_mode = FOCUS_NONE
			pb.focus_mode = FOCUS_NONE
			pb.button.focus_mode = FOCUS_NONE
			get_viewport().gui_focus_changed.emit(null)
			await get_tree().physics_frame
			gv.find_nearest_focus(self)
		elif upgrade.unlocked.is_true() and upgrade.purchased.is_false():
			focus_mode = FOCUS_ALL
			pb.focus_mode = FOCUS_ALL
			pb.button.focus_mode = FOCUS_ALL
	else:
		focus_mode = FOCUS_NONE


func _on_focus_entered():
	if focus_mode == FOCUS_ALL:
		pb.grab_focus()
