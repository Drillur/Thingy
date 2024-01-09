extends CanvasLayer



@onready var save_notification = %"Save Notification"
@onready var save_notification_icon = %"Save notification icon"
@onready var save_notification_background = %"Save notification Background"
@onready var save_notification_label = %"Save Notification Label"



func _ready() -> void:
	randomize()
	setup_dev()
	setup_sidebar()
	setup_navigation_panel()
	setup_currency_panel()
	th.thingy_created.connect(thingy_created)
	th.container = %ThingyContainer
	up.container = %UpgradeContainer
	
	SaveManager.color.changed.connect(save_color_changed)
	SaveManager.saving.became_false.connect(save_notification_now)
	gv.one_second.connect(save_notification_soon)
	save_notification.hide()
	save_color_changed()
	
	if SaveManager.can_load_game():
		SaveManager.load_game()
	
	gv.root = self
	gv.root_ready.set_to(true)



#region Signals


func thingy_created() -> void:
	th.thingy_created.disconnect(thingy_created)


func _input(event):
	if event is InputEventJoypadButton:
		if gv.joypad_detected.is_false() or gv.game_has_focus.is_false():
			return
	
	if Input.is_action_just_pressed("ui_cancel"):
		if event is InputEventJoypadButton:
			current_tab.reset()
		else:
			open_or_close_tab(Tab.MENU)
	elif Input.is_action_just_pressed("ui_menu"):
		open_or_close_tab(Tab.MENU)
	elif Input.is_action_just_pressed("open_upgrades"):
		open_or_close_tab(Tab.UPGRADE)
	elif Input.is_action_just_pressed("open_reset_menu"):
		open_or_close_tab(Tab.RESET_MENU)
	elif Input.is_action_just_pressed("open_settings_menu"):
		open_or_close_tab(Tab.SETTINGS)
	elif (
		Input.is_action_just_pressed("upgrades0")
		or Input.is_action_just_pressed("upgrades1")
	):
		hotkey_upgrades_tab()
	elif Input.is_action_just_pressed("ui_up"):
		scroll_thingies_up()
	elif Input.is_action_just_pressed("ui_down"):
		scroll_thingies_down()
	elif Input.is_action_just_pressed("joy_to_top"):
		th.container.snap_to_index(th.get_top_index())
	elif Input.is_action_just_pressed("joy_to_bot"):
		th.container.snap_to_index(th.get_bottom_index())
	elif Input.is_action_just_pressed("ui_accept") and not event is InputEventJoypadButton:
		purchase_thingy._on_button_pressed()
	elif Input.is_action_just_pressed("save"):
		SaveManager.save_game()
	elif event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if sidebar.visible:
				if (
					not gv.node_has_point(sidebar, event.position)
					and not gv.node_has_point(purchase_thingy, event.position)
					and not gv.node_has_point(tab_upgrade, event.position)
					and not gv.node_has_point(tab_settings, event.position)
					and not gv.node_has_point(tab_menu, event.position)
					and not gv.node_has_point(reset_button, event.position)
				):
					current_tab.set_to(-1)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN):
			if not gv.node_has_point(sidebar, sidebar.get_global_mouse_position()):
				scroll_thingies_down()
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP):
			if not gv.node_has_point(sidebar, sidebar.get_global_mouse_position()):
				scroll_thingies_up()


func open_or_close_tab(tab: Tab) -> void:
	if current_tab.equal(tab):
		current_tab.reset()
		return
	if up.is_purchased(Upgrade.Type.UNLOCK_UPGRADES) or tab == Tab.MENU:
		current_tab.set_to(tab)


func hotkey_upgrades_tab() -> void:
	if up.is_purchased(Upgrade.Type.UNLOCK_UPGRADES):
		current_tab.set_to(Tab.UPGRADE)


func scroll_thingies_up() -> void:
	if current_tab.less(0):
		if th.has_thingy(th.get_selected_index() + 1):
			th.container.snap_to_index(th.get_selected_index() + 1)


func save_notification_soon() -> void:
	if 30 - SaveManager.get_time_since_last_save() <= 3:
		save_notification.show()
		save_notification_label.text = "Saving in %s..." % str(ceil(30 - SaveManager.get_time_since_last_save()))


func save_notification_now() -> void:
	save_notification.show()
	save_notification_label.text = "Game saved!"
	gv.flash(save_notification, SaveManager.color.get_value())
	await get_tree().create_timer(2).timeout
	save_notification.hide()


func scroll_thingies_down() -> void:
	if current_tab.less(0):
		if th.has_thingy(th.get_selected_index() - 1):
			th.container.snap_to_index(th.get_selected_index() - 1)


func save_color_changed() -> void:
	save_notification_icon.modulate = SaveManager.color.get_value()
	save_notification_background.modulate = SaveManager.color.get_value()


#endregion


#region Currency Panel


@onready var currency_panel = %CurrencyPanel
@onready var coin_components = %CoinComponents
@onready var coin_label = %"Coin Label"
@onready var coin_flair = %"Coin Flair"
@onready var coin_rate = %"Coin Rate"
@onready var will_label = %"Will Label"
@onready var will_flair = %"Will Flair"
@onready var will_rate = %"Will Rate"
@onready var xp_components = %XPComponents
@onready var xp_label = %"XP Label"
@onready var xp_flair = %"XP Flair"
@onready var xp_rate = %"XP Rate"
@onready var juice_components = %JuiceComponents
@onready var juice_label = %"Juice Label"
@onready var juice_rate = %"Juice Rate"
@onready var juice_flair = %"Juice Flair"
@onready var will_components = %WillComponents
@onready var soul_components = %SoulComponents
@onready var soul_label = %"Soul Label"
@onready var soul_flair = %"Soul Flair"

@onready var dev = %DEV


func setup_currency_panel() -> void:
	will_flair.text = "[i]" + wa.get_details(Currency.Type.WILL).icon_and_name
	will_rate.modulate = wa.get_color(Currency.Type.WILL)
	wa.get_currency(Currency.Type.WILL).amount.pending_changed.connect(will_changed)
	wa.get_currency(Currency.Type.WILL).net_rate.changed.connect(will_rate_changed)
	will_changed()
	will_rate_changed()
	
	coin_flair.text = "[i]" + wa.get_details(Currency.Type.COIN).icon_and_name
	coin_rate.modulate = wa.get_color(Currency.Type.COIN)
	wa.get_currency(Currency.Type.COIN).amount.pending_changed.connect(coin_changed)
	wa.get_currency(Currency.Type.COIN).net_rate.changed.connect(coin_rate_changed)
	wa.get_currency(Currency.Type.COIN).unlocked.changed.connect(coin_unlocked_changed)
	coin_changed()
	coin_rate_changed()
	coin_unlocked_changed()
	
	xp_flair.text = "[i]" + wa.get_details(Currency.Type.XP).icon_and_name
	xp_rate.modulate = wa.get_color(Currency.Type.XP)
	wa.get_currency(Currency.Type.XP).amount.pending_changed.connect(xp_changed)
	wa.get_currency(Currency.Type.XP).net_rate.changed.connect(xp_rate_changed)
	wa.get_currency(Currency.Type.XP).unlocked.changed.connect(xp_unlocked_changed)
	xp_changed()
	xp_rate_changed()
	xp_unlocked_changed()
	
	juice_flair.text = "[i]" + wa.get_details(Currency.Type.JUICE).icon_and_name
	juice_rate.modulate = wa.get_color(Currency.Type.JUICE)
	wa.get_currency(Currency.Type.JUICE).amount.changed.connect(juice_changed)
	wa.get_currency(Currency.Type.JUICE).amount.pending_changed.connect(juice_changed)
	th.max_juice_use.changed.connect(juice_rate_changed)
	wa.get_currency(Currency.Type.JUICE).unlocked.changed.connect(juice_unlocked_changed)
	juice_changed()
	juice_rate_changed()
	juice_unlocked_changed()
	
	soul_flair.text = "[i]" + wa.get_details(Currency.Type.SOUL).icon_and_name
	wa.soul_gain.changed.connect(soul_changed)
	soul_changed()
	wa.get_currency(Currency.Type.SOUL).unlocked.changed.connect(soul_unlocked_changed)
	soul_unlocked_changed()
	
	currency_panel.hide()


func coin_unlocked_changed() -> void:
	coin_components.visible = wa.is_unlocked(Currency.Type.COIN)


func coin_changed() -> void:
	coin_label.text = "[i]" + (
		wa.get_details(Currency.Type.COIN).color_text % (
			"+" + wa.get_currency(Currency.Type.COIN).amount.get_pending_text()
		)
	)


func coin_rate_changed() -> void:
	coin_rate.text = "[i](%s/s)" % wa.get_net_rate(Currency.Type.COIN).get_text()


func will_changed() -> void:
	will_label.text = "[i]" + (
		wa.get_details(Currency.Type.WILL).color_text % (
			"+" + wa.get_currency(Currency.Type.WILL).amount.get_pending_text()
		)
	)


func will_rate_changed() -> void:
	will_rate.text = "[i](%s/s)" % wa.get_net_rate(Currency.Type.WILL).get_text()


func xp_unlocked_changed() -> void:
	xp_components.visible = wa.is_unlocked(Currency.Type.XP)


func xp_changed() -> void:
	xp_label.text = "[i]" + (
		wa.get_details(Currency.Type.XP).color_text % (
			"+" + wa.get_currency(Currency.Type.XP).amount.get_pending_text()
		)
	)


func xp_rate_changed() -> void:
	xp_rate.text = "[i](%s/s)" % wa.get_net_rate(Currency.Type.XP).get_text()


func juice_unlocked_changed() -> void:
	juice_components.visible = wa.is_unlocked(Currency.Type.JUICE)


func juice_changed() -> void:
	juice_label.text = "[i]" + (
		wa.get_details(Currency.Type.JUICE).color_text % (
			wa.get_amount_text(Currency.Type.JUICE) + "+" +
			wa.get_pending_amount(Currency.Type.JUICE).text
		)
	)


func juice_rate_changed() -> void:
	juice_rate.text = "[i](%s)" % th.max_juice_use.get_text()


func soul_unlocked_changed() -> void:
	soul_components.visible = wa.is_unlocked(Currency.Type.SOUL)
	reset_button.visible = soul_components.visible


func soul_changed() -> void:
	soul_label.text = "[i]" + (
		wa.get_details(Currency.Type.SOUL).color_text % (
			"+" + wa.soul_gain.text
		)
	)


func _on_coin_components_resized():
	if is_node_ready():
		if coin_components.size.x > coin_components.custom_minimum_size.x:
			coin_components.custom_minimum_size.x = coin_components.size.x


func _on_will_components_resized():
	if is_node_ready():
		if will_components.size.x > will_components.custom_minimum_size.x:
			will_components.custom_minimum_size.x = will_components.size.x


func _on_xp_components_resized():
	if is_node_ready():
		if xp_components.size.x > xp_components.custom_minimum_size.x:
			xp_components.custom_minimum_size.x = xp_components.size.x


func _on_juice_components_resized():
	if is_node_ready():
		if juice_components.size.x > juice_components.custom_minimum_size.x:
			juice_components.custom_minimum_size.x = juice_components.size.x


func _on_soul_components_resized():
	if is_node_ready():
		if soul_components.size.x > soul_components.custom_minimum_size.x:
			soul_components.custom_minimum_size.x = soul_components.size.x


#endregion


#region Navigation Panel


@onready var navigation_panel = %"Navigation Panel"
@onready var unlock_upgrades_button = %UnlockUpgradesButton
@onready var purchase_thingy = %"Purchase Thingy"
@onready var navigation_buttons = %"Navigation Buttons"
@onready var tab_upgrade = %"Tab Upgrade"
@onready var tab_settings = %"Tab Settings"
@onready var tab_menu = %"Tab Menu"
@onready var reset_button = %"Reset Button"


func setup_navigation_panel() -> void:
	up.get_upgrade(
		Upgrade.Type.UNLOCK_UPGRADES
	).purchased.changed.connect(update_navigation_panel_visibility)
	update_navigation_panel_visibility()
	th.thingy_created.connect(update_unlock_upgrades_button_visibility)
	update_unlock_upgrades_button_visibility()
	tab_settings.color = Settings.color
	tab_menu.color = SaveManager.color.get_value()
	Settings.joypad_allowed.changed.connect(update_navigation_button_focus_modes)
	gv.joypad_detected.changed.connect(update_navigation_button_focus_modes)
	update_navigation_button_focus_modes()
	reset_button.color = wa.get_color(Currency.Type.SOUL)
	
	
	purchase_thingy.setup(th.cost)
	purchase_thingy.color = th.next_thingy_color


func update_navigation_button_focus_modes() -> void:
	if Settings.joypad_allowed.is_true() and gv.joypad_detected.is_true():
		for node in navigation_buttons.get_children():
			node.focus_mode = Control.FOCUS_ALL
			node.button.focus_mode = Control.FOCUS_ALL
	else:
		for node in navigation_buttons.get_children():
			node.focus_mode = Control.FOCUS_NONE
			node.button.focus_mode = Control.FOCUS_NONE


func _on_tab_upgrade_pressed():
	if current_tab.equal(Tab.UPGRADE):
		current_tab.reset()
	else:
		current_tab.set_to(Tab.UPGRADE)


func _on_tab_settings_pressed():
	if current_tab.equal(Tab.SETTINGS):
		current_tab.reset()
	else:
		current_tab.set_to(Tab.SETTINGS)


func _on_tab_menu_pressed():
	if current_tab.equal(Tab.MENU):
		current_tab.reset()
	else:
		current_tab.set_to(Tab.MENU)


func _on_reset_button_pressed():
	if current_tab.equal(Tab.RESET_MENU):
		current_tab.reset()
	else:
		current_tab.set_to(Tab.RESET_MENU)


func _on_purchase_thingy_pressed():
	th.purchase_thingy()
	purchase_thingy.color = th.next_thingy_color


func update_navigation_panel_visibility() -> void:
	navigation_panel.visible = up.is_purchased(Upgrade.Type.UNLOCK_UPGRADES)
	currency_panel.visible = navigation_panel.visible
	unlock_upgrades_button.hide()
	if navigation_panel.visible:
		gv.flash(navigation_panel, up.get_upgrade_tree(up.UpgradeTree.Type.FIRESTARTER).details.color)


func update_unlock_upgrades_button_visibility() -> void:
	unlock_upgrades_button.visible = th.get_count() >= 3 and not navigation_panel.visible
	if unlock_upgrades_button.visible:
		gv.flash(unlock_upgrades_button, unlock_upgrades_button.upgrade.details.color)


#endregion


#region Sidebar


@onready var sidebar = %Sidebar
@onready var upgrade_container = %UpgradeContainer as UpgradeContainer
@onready var sidebar_header = %"Sidebar Header"
@onready var tab_container = %TabContainer
@onready var reset_menu = %ResetMenu as ResetMenu


enum Tab {
	MENU,
	SETTINGS,
	UPGRADE,
	RESET_MENU,
}

var current_tab := LoudInt.new(-1)



func setup_sidebar() -> void:
	sidebar.hide()
	current_tab.changed.connect(current_tab_changed)
	upgrade_container.tab_container.tab_changed.connect(upgrade_tab_changed)
	upgrade_tab_changed()



func current_tab_changed() -> void:
	if current_tab.less(0):
		if purchase_thingy.focus_mode == Control.FOCUS_ALL:
			purchase_thingy.grab_focus()
		sidebar.hide()
	else:
		tab_container.current_tab = current_tab.get_value()
		sidebar.show()
		match current_tab.get_value():
			Tab.MENU:
				sidebar_header.color = SaveManager.color.get_value()
				sidebar_header.text = "Thingy\n1.0.0"
				sidebar_header.icon = bag.get_icon("activeBuffs")
			Tab.SETTINGS:
				sidebar_header.color = Settings.color
				sidebar_header.text = "Settings"
				sidebar_header.icon = bag.get_icon("Settings")
			Tab.UPGRADE:
				upgrade_tab_changed()
			Tab.RESET_MENU:
				sidebar_header.color = wa.get_color(Currency.Type.SOUL)
				sidebar_header.text = "Free"
				sidebar_header.icon = bag.get_icon("Skull")
				await get_tree().physics_frame
				reset_menu.free_button.grab_focus()


func upgrade_tab_changed(index: int = upgrade_container.tab_container.current_tab) -> void:
	var tree: up.UpgradeTree = up.get_upgrade_tree(index + 1)
	sidebar_header.color = tree.details.color
	sidebar_header.text = tree.details.name
	sidebar_header.icon = tree.details.icon
	tab_upgrade.color = tree.details.color
	upgrade_container.color_tab(tree.details.color)


#endregion


#region Dev


@onready var fps = %FPS
@onready var dev_button = %DevButton
@onready var dev_button_2 = %DevButton2


func setup_dev() -> void:
	if gv.dev_mode:
		fps.get_node("Timer").timeout.connect(fps_timer_timeout)
		wa.get_currency(Currency.Type.WILL).amount.changed.connect(dev_text)
	else:
		fps.queue_free()
		dev.queue_free()
		dev_button.queue_free()
		dev_button_2.queue_free()


func fps_timer_timeout() -> void:
	fps.text = "FPS: " + str(Engine.get_frames_per_second())


func _on_dev_button_pressed():
	wa.get_amount(Currency.Type.WILL).m(1.1)
	#dev.text = mynum.text + " = " + Big.new(mynum).power(0.12).text


func _on_dev_button_2_pressed():
	wa.get_amount(Currency.Type.WILL).d(2)


func dev_text() -> void:
	pass


#endregion
