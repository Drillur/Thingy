class_name UpgradeButton
extends MarginContainer



@export var wrap_description := false:
	set(val):
		wrap_description = val
		if not is_node_ready():
			await ready
		update_wrap_mode()

@onready var pb = $"Purchase Button" as PurchaseButton
@onready var enabled_border = %"Enabled Border"

var description_queue := await Queueable.new(self)

var upgrade: Upgrade


func _ready() -> void:
	if not Upgrade.data.has(name):
		print_debug("Upgrade ", name, " does not exist!")
		return
	upgrade = up.get_upgrade(name) as Upgrade
	upgrade.vico = self
	update_wrap_mode()
	
	description_queue.method = set_description_text
	upgrade.applied.changed.connect(applied_changed)
	upgrade.unlocked.changed.connect(unlocked_changed)
	upgrade.purchased.changed.connect(upgrade_purchased_changed)
	pb.button.mouse_entered.connect(tooltip_time)
	pb.autobuyer_anim.modulate = upgrade.details.get_color()
	pb.autobuyer_anim.speed_scale = 3.0
	upgrade.times_purchased.changed.connect(description_queue.call_method)
	upgrade.applied.changed.connect(description_queue.call_method)
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
	Settings.joypad.changed.connect(update_focus)
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


func update_wrap_mode():
	if wrap_description:
		pb.description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		pb.description.autowrap_mode = TextServer.AUTOWRAP_OFF


#region Signals


func applied_changed() -> void:
	enabled_border.visible = upgrade.purchased.is_true() and upgrade.applied.is_false()


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
	pb.unlock()
	pb.title.text = upgrade.details.get_name()
	description_queue.call_method()
	if upgrade.times_purchased.get_total() > 1:
		pb.times_purchased_current.get_parent().modulate = upgrade.details.get_color()
		pb.times_purchased_current.get_parent().show()
		pb.times_purchased_current.attach_int(upgrade.times_purchased.current)
		pb.times_purchased_total.attach_int(upgrade.times_purchased.total)
	set_cost_visibility()
	pb.texture_rect.texture = upgrade.details.get_icon()


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
		elif upgrade.can_purchase():
			upgrade.purchase()


func _on_purchase_button_right_clicked():
	if upgrade.times_purchased.current.equal(0):
		return
	if upgrade.applied.is_true():
		upgrade.remove()
	else:
		upgrade.apply()


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
	pb.description.visible = upgrade.unlocked.is_true() or upgrade.purchased.is_false()
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
	set_cost_visibility()
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


func lock() -> void:
	pb.lock()
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func unlock() -> void:
	pb.unlock()
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
