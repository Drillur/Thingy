class_name UpgradeButton
extends MarginContainer



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
@onready var enabled_border = %"Enabled Border"

var upgrade: Upgrade
var setup_done := false



func _ready() -> void:
	upgrade = up.get_upgrade(Upgrade.Type[name]) as Upgrade
	upgrade.vico = self
	
	enabled_border.visible = not upgrade.enabled.get_value()
	upgrade.enabled.became_true.connect(enabled_border.hide)
	upgrade.enabled.became_false.connect(enabled_border.show)
	upgrade.unlocked.changed.connect(unlocked_changed)
	upgrade.purchased.changed.connect(upgrade_purchased_changed)
	pb.button.mouse_entered.connect(tooltip_time)
	pb.autobuyer_anim.modulate = upgrade.details.get_color()
	pb.autobuyer_anim.speed_scale = 3.0
	upgrade.times_purchased.changed.connect(set_description_text)
	#upgrade.unlocked_and_not_purchased.changed.connect(update_autobuyer_anim_visibility)
	#upgrade.autobuyer.changed.connect(update_autobuyer_anim_visibility)
	pb.color = upgrade.details.get_color()
	pb.setup_price(upgrade.price)
	if upgrade.unlocked.is_true():
		setup()
	else:
		pb.lock()
	upgrade.unlocked.changed.connect(update_focus)
	upgrade.purchased.changed.connect(update_focus)
	update_focus()
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


#region Signals


#func update_autobuyer_anim_visibility() -> void:
	#pb.autobuyer_anim.visible = upgrade.unlocked_and_not_purchased.get_value() and upgrade.autobuyer.is_true()
	#if pb.autobuyer_anim.visible:
		#pb.autobuyer_anim.play()
	#else:
		#pb.autobuyer_anim.stop()


#endregion


func get_parent_until_scroll_container(node) -> int:
	if node is ScrollContainer:
		return node.get_index()
	if not node.get_parent():
		return -1
	return get_parent_until_scroll_container(node.get_parent())


func setup() -> void:
	pb.title_components.show()
	pb.title.show()
	pb.title.text = upgrade.details.get_name()
	set_description_text()
	if upgrade.times_purchased.get_total() > 1:
		pb.times_purchased.show()
		pb.times_purchased.watch_int_pair(upgrade.times_purchased, upgrade.details.get_color())
	#pb.texture_rect.modulate = Color.WHITE
	set_cost_visibility()
	pb.texture_rect.texture = upgrade.details.get_icon()
	if setup_done:
		return
	setup_done = true


func _on_purchase_button_pressed():
	if gv.dev_mode and upgrade.purchased.is_false():
		if upgrade.unlocked.is_true():
			upgrade.purchase()
			return
	if upgrade.purchased.is_false():
		if upgrade.unlocked.is_false():
			up.flash_vico(upgrade.required_upgrade)
		elif not upgrade.can_afford():
			pb.cost_components.flash_missing_currencies()
		elif upgrade.available_now.is_true():
			upgrade.purchase()
	else:
		upgrade.enabled.invert()


func _on_purchase_button_right_clicked():
	if gv.dev_mode and upgrade.purchased.is_true():
		upgrade.purchased.set_false()
		pass


func upgrade_purchased_changed() -> void:
	set_cost_visibility()
	if upgrade.purchased.is_true():
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pb.button.mouse_default_cursor_shape = CURSOR_ARROW
		gv.flash(self, upgrade.details.get_color())
	else:
		size_flags_vertical = Control.SIZE_FILL
		pb.button.mouse_default_cursor_shape = CURSOR_POINTING_HAND


func set_cost_visibility() -> void:
	pb.cost_components.visible = upgrade.unlocked.is_true() and upgrade.purchased.is_false()
	if pb.cost_components.visible:
		pb.cost_components.connect_calls()
	else:
		pb.cost_components.disconnect_calls()


func set_description_text() -> void:
	if not upgrade.details.is_description_set():
		pb.description.hide()
		return
	pb.description.text = "[center]" + upgrade.get_description()
	var parsed_text = pb.description.get_parsed_text()
	var text_length = parsed_text.length()
	pb.description.custom_minimum_size.x = min(180, 30 + (text_length * 4))
	pb.description.show()


func unlocked_changed() -> void:
	if upgrade.unlocked.is_true():
		setup()
		gv.flash(self, upgrade.details.get_color())
	else:
		pb.lock()


func update_focus() -> void:
	if gv.root_ready.is_false():
		return
	if Settings.joypad.is_true():
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


func tooltip_time() -> void:
	pass#Tooltip.new_tooltip(Tooltip.Type.UPGRADE_TOOLTIP, {"upgrade_type": upgrade.type}, pb.button, self)
