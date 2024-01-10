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
var setup_done := false



func _ready() -> void:
	Settings.joypad.right.changed.connect(update_focus)
	upgrade = up.get_upgrade(upgrade_type)
	upgrade.vico = self
	upgrade.unlocked.changed.connect(unlocked_changed)
	upgrade.unlocked.changed.connect(update_focus)
	upgrade.purchased.changed.connect(upgrade_purchased_changed)
	upgrade.purchased.changed.connect(update_focus)
	update_focus()
	pb.color = upgrade.details.color
	pb.setup(upgrade.cost)
	if upgrade.unlocked.is_true():
		setup()
	else:
		pb.lock()
	await up.container_loaded
	set_tab()


func set_tab() -> void:
	var tab = get_parent_until_scroll_container(get_parent())
	match tab:
		1, 2:
			upgrade.persist.through_tier(1)
		3, 4:
			upgrade.persist.through_tier(2)
		5, 6:
			upgrade.persist.through_tier(3)
		7, 8:
			upgrade.persist.through_tier(4)


func get_parent_until_scroll_container(node) -> int:
	if node is ScrollContainer:
		return node.get_index()
	if not node.get_parent():
		return -1
	return get_parent_until_scroll_container(node.get_parent())


func setup() -> void:
	pb.title_components.show()
	pb.title.show()
	if upgrade.details.description != "":
		pb.description.show()
	else:
		pb.description.hide()
	if upgrade.get_purchase_limit() > 1:
		pb.times_purchased.show()
	set_cost_visibility()
	if setup_done:
		return
	setup_done = true
	pb.title.text = upgrade.details.name
	pb.texture_rect.texture = upgrade.details.icon
	if upgrade.details.description != "":
		upgrade.times_purchased.changed.connect(set_description_text)
		set_description_text()
	if upgrade.get_purchase_limit() > 1:
		pb.times_purchased.show()
		upgrade.times_purchased.changed.connect(times_purchased_changed)
		times_purchased_changed()


func _on_purchase_button_pressed():
	if upgrade.can_purchase():
		upgrade.purchase()
	elif upgrade.unlocked.is_false():
		up.flash_vico(upgrade.required_upgrade)


func upgrade_purchased_changed() -> void:
	set_cost_visibility()
	if upgrade.purchased.is_true():
		pb.disconnect_calls()
	else:
		pb.connect_calls()
	if upgrade.purchased.is_true():
		pb.button.mouse_default_cursor_shape = CURSOR_ARROW
	else:
		pb.button.mouse_default_cursor_shape = CURSOR_POINTING_HAND


func set_cost_visibility() -> void:
	pb.cost_components.visible = upgrade.unlocked.is_true() and upgrade.purchased.is_false()
	if pb.cost_components.visible:
		pb.update()


func _on_purchase_button_right_clicked():
	if gv.dev_mode and upgrade.purchased.is_true():
		#upgrade.reset()
		pass


func times_purchased_changed() -> void:
	pb.times_purchased.text = "%s/%s" % [
		upgrade.times_purchased.get_text(),
		str(upgrade.get_purchase_limit())
	]


func set_description_text() -> void:
	pb.description.text = "[center]" + upgrade.get_description()


func unlocked_changed() -> void:
	if upgrade.unlocked.is_true():
		setup()
	else:
		pb.lock()


func update_focus() -> void:
	if gv.root_ready.is_false():
		return
	if Settings.joypad.are_true():
		if upgrade.unlocked.is_false() or upgrade.purchased.is_true():
			focus_mode = FOCUS_NONE
			pb.focus_mode = FOCUS_NONE
			pb.button.focus_mode = FOCUS_NONE
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
