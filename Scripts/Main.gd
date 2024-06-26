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
	th.container = %ThingyContainer
	up.container = %UpgradeContainer
	Settings.joypad.changed.connect(joypad_changed)
	joypad_changed()
	SaveManager.color.changed.connect(save_color_changed)
	SaveManager.saving.became_false.connect(save_notification_now)
	gv.one_second.connect(save_notification_soon)
	save_notification.hide()
	save_color_changed()
	
	if SaveManager.can_load_game():
		SaveManager.load_game()
		Settings.joypad_detected.set_false()
	else:
		SaveManager.color.set_to(gv.get_random_nondark_color())
	
	FlyingText.global_flying_texts_parent = $Control
	
	gv.root = self
	gv.root_ready.set_to(true)



#region Signals


func joypad_changed() -> void:
	if Settings.joypad.is_true():
		purchase_thingy.focus_mode = Control.FOCUS_ALL
		purchase_thingy.button.focus_mode = Control.FOCUS_ALL
	else:
		purchase_thingy.focus_mode = Control.FOCUS_NONE
		purchase_thingy.button.focus_mode = Control.FOCUS_NONE


func _input(event):
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if Settings.joypad.is_false() or gv.game_has_focus.is_false():
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
		scroll_thingies_up(event is InputEventJoypadButton)
	elif Input.is_action_just_pressed("ui_down"):
		scroll_thingies_down(event is InputEventJoypadButton)
	elif Input.is_action_just_pressed("joy_to_top"):
		th.container.snap_to_index(th.get_top_index())
	elif Input.is_action_just_pressed("joy_to_bot"):
		th.container.snap_to_index(th.get_bottom_index())
	elif Input.is_action_just_pressed("ui_accept") and not event is InputEventJoypadButton:
		purchase_thingy._on_button_pressed()
	elif Input.is_action_just_pressed("save"):
		SaveManager.save_game()
	elif event is InputEventMouseButton:
		if Settings.joypad_detected.is_true():
			Settings.joypad_detected.set_false()
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
				scroll_thingies_down(false)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP):
			if not gv.node_has_point(sidebar, sidebar.get_global_mouse_position()):
				scroll_thingies_up(false)


func open_or_close_tab(tab: Tab) -> void:
	if current_tab.equal(tab):
		current_tab.reset()
		return
	if up.is_purchased("UNLOCK_UPGRADES") or tab == Tab.MENU:
		current_tab.set_to(tab)


func hotkey_upgrades_tab() -> void:
	if up.is_purchased("UNLOCK_UPGRADES"):
		current_tab.set_to(Tab.UPGRADE)


func scroll_thingies_up(_joypad: bool) -> void:
	if current_tab.greater_equal(0) and _joypad:
		return
	if th.has_thingy(th.get_selected_index() + 1):
		th.container.snap_to_index(th.get_selected_index() + 1)


func scroll_thingies_down(_joypad: bool) -> void:
	if current_tab.greater_equal(0) and _joypad:
		return
	if th.has_thingy(th.get_selected_index() - 1):
		th.container.snap_to_index(th.get_selected_index() - 1)


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
@onready var juice_flair = %"Juice Flair"
@onready var will_components = %WillComponents
@onready var soul_components = %SoulComponents
@onready var soul_label = %"Soul Label"
@onready var soul_flair = %"Soul Flair"
@onready var soul_rate = %"Soul Rate"

@onready var dev = %DEV


func setup_currency_panel() -> void:
	will_flair.text = "[i]" + wa.get_details("WILL").get_icon_and_name()
	will_rate.modulate = wa.get_color("WILL")
	wa.get_currency("WILL").amount.changed.connect(will_changed)
	wa.get_currency("WILL").net_rate.changed.connect(will_rate_changed)
	will_changed()
	will_rate_changed()
	
	coin_flair.text = "[i]" + wa.get_details("COIN").get_icon_and_name()
	coin_rate.modulate = wa.get_color("COIN")
	wa.get_currency("COIN").amount.changed.connect(coin_changed)
	wa.get_currency("COIN").net_rate.changed.connect(coin_rate_changed)
	wa.get_currency("COIN").unlocked.changed.connect(coin_unlocked_changed)
	coin_changed()
	coin_rate_changed()
	coin_unlocked_changed()
	
	xp_flair.text = "[i]" + wa.get_details("XP").get_icon_and_name()
	xp_rate.modulate = wa.get_color("XP")
	wa.get_currency("XP").amount.changed.connect(xp_changed)
	wa.get_currency("XP").net_rate.changed.connect(xp_rate_changed)
	wa.get_currency("XP").unlocked.changed.connect(xp_unlocked_changed)
	xp_changed()
	xp_rate_changed()
	xp_unlocked_changed()
	
	juice_flair.text = "[i]" + wa.get_details("JUICE").get_icon_and_name()
	wa.get_currency("JUICE").amount.changed.connect(juice_changed)
	th.max_juice_use.changed.connect(juice_changed)
	wa.get_currency("JUICE").unlocked.changed.connect(juice_unlocked_changed)
	juice_changed()
	juice_unlocked_changed()
	
	soul_flair.text = "[i]" + wa.get_details("SOUL").get_icon_and_name()
	soul_rate.modulate = wa.get_color("SOUL")
	wa.get_currency("SOUL").amount.changed.connect(soul_changed)
	wa.get_currency("SOUL").amount.pending_changed.connect(soul_changed)
	wa.get_currency("SOUL").net_rate.changed.connect(soul_rate_changed)
	wa.get_currency("SOUL").unlocked.changed.connect(soul_unlocked_changed)
	soul_changed()
	soul_rate_changed()
	soul_unlocked_changed()
	
	currency_panel.hide()


func coin_unlocked_changed() -> void:
	coin_components.visible = wa.is_unlocked("COIN")


func coin_changed() -> void:
	coin_label.text = "[i]" + (
		wa.get_details("COIN").get_color_text() % (
			wa.get_currency("COIN").amount.get_text()
		)
	)


func coin_rate_changed() -> void:
	coin_rate.text = "[i](%s/s)" % wa.get_net_rate("COIN").get_text()


func will_changed() -> void:
	will_label.text = "[i]" + (
		wa.get_details("WILL").get_color_text() % (
			wa.get_currency("WILL").amount.get_text()
		)
	)


func will_rate_changed() -> void:
	will_rate.text = "[i](%s/s)" % wa.get_net_rate("WILL").get_text()


func xp_unlocked_changed() -> void:
	xp_components.visible = wa.is_unlocked("XP")


func xp_changed() -> void:
	xp_label.text = "[i]" + (
		wa.get_details("XP").get_color_text() % (
			wa.get_currency("XP").amount.get_text()
		)
	)


func xp_rate_changed() -> void:
	xp_rate.text = "[i](%s/s)" % wa.get_net_rate("XP").get_text()


func juice_unlocked_changed() -> void:
	juice_components.visible = wa.is_unlocked("JUICE")


func juice_changed() -> void:
	if up.is_purchased("SMART_JUICE"):
		juice_label.text = wa.get_details("JUICE").get_color_text() % (
			"[i]%s (Goal: %s)[/i]" % [
				wa.get_amount_text("JUICE"),
				th.max_juice_use.get_text(),
			]
		)
	else:
		juice_label.text = wa.get_details("JUICE").get_color_text() % (
			"[i]%s[/i]" % wa.get_amount_text("JUICE")
		)


func soul_unlocked_changed() -> void:
	soul_components.visible = wa.is_unlocked("SOUL")
	reset_button.visible = soul_components.visible


func soul_changed() -> void:
	soul_label.text = "[i]" + (
		wa.get_details("SOUL").get_color_text() % (
			"%s+%s" % [
				wa.get_amount_text("SOUL"),
				wa.get_pending_amount("SOUL").text
			]
		)
	)


func soul_rate_changed() -> void:
	soul_rate.text = "[i](%s/s)" % wa.get_net_rate("SOUL").get_text()


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
@onready var unlock_upgrades_button = %UNLOCK_UPGRADES
@onready var purchase_thingy = %"Purchase Thingy"
@onready var navigation_buttons = %"Navigation Buttons"
@onready var tab_upgrade = %"Tab Upgrade"
@onready var tab_settings = %"Tab Settings"
@onready var tab_menu = %"Tab Menu"
@onready var reset_button = %"Reset Button"


func setup_navigation_panel() -> void:
	up.get_upgrade("UNLOCK_UPGRADES").purchased.changed.connect(update_navigation_panel_visibility)
	update_navigation_panel_visibility()
	th.thingy_created.connect(update_unlock_upgrades_button_visibility)
	update_unlock_upgrades_button_visibility()
	tab_settings.color = Settings.color
	tab_menu.color = SaveManager.color.get_value()
	Settings.joypad_detected.changed.connect(update_navigation_button_focus_modes)
	update_navigation_button_focus_modes()
	reset_button.color = wa.get_color("SOUL")
	purchase_thingy.assign_loud_color(th.next_thingy_color)
	purchase_thingy.setup_price(th.price)


func update_navigation_button_focus_modes() -> void:
	if Settings.joypad.is_true():
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
	if th.can_afford_thingy() or gv.dev_mode:
		th.purchase_thingy()
	else:
		purchase_thingy.cost_components.flash_missing_currencies()


func update_navigation_panel_visibility() -> void:
	navigation_panel.visible = up.is_purchased("UNLOCK_UPGRADES")
	currency_panel.visible = navigation_panel.visible
	unlock_upgrades_button.hide()
	if navigation_panel.visible:
		gv.flash(navigation_panel, up.get_upgrade_tree(UpgradeTree.Type.FIRESTARTER).details.get_color())


func update_unlock_upgrades_button_visibility() -> void:
	unlock_upgrades_button.visible = th.get_count() >= 3 and not navigation_panel.visible
	if unlock_upgrades_button.visible:
		gv.flash(unlock_upgrades_button, unlock_upgrades_button.upgrade.details.get_color())


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
				sidebar_header.text = "Thingy\n" + ProjectSettings.get_setting("application/config/version")
				sidebar_header.icon = ResourceBag.get_icon("activeBuffs")
			Tab.SETTINGS:
				sidebar_header.color = Settings.color
				sidebar_header.text = "Settings"
				sidebar_header.icon = ResourceBag.get_icon("Settings")
			Tab.UPGRADE:
				upgrade_tab_changed()
			Tab.RESET_MENU:
				sidebar_header.color = wa.get_color("SOUL")
				sidebar_header.text = "Free"
				sidebar_header.icon = ResourceBag.get_icon("Skull")
				await get_tree().physics_frame
				reset_menu.free_button.grab_focus()


func upgrade_tab_changed(index: int = upgrade_container.tab_container.current_tab) -> void:
	var tree: UpgradeTree = up.get_upgrade_tree(index + 1)
	sidebar_header.color = tree.details.get_color()
	sidebar_header.text = tree.details.get_name()
	sidebar_header.icon = tree.details.get_icon()
	tab_upgrade.color = tree.details.get_color()
	upgrade_container.color_tab(tree.details.get_color())


#endregion


#region Dev


@onready var fps = %FPS
@onready var dev_button = %DevButton
@onready var dev_button_2 = %DevButton2


func setup_dev() -> void:
	fps.get_node("Timer").timeout.connect(fps_timer_timeout)
	fps_timer_timeout()
	if gv.dev_mode:
		wa.get_currency("WILL").amount.changed.connect(dev_text)
	else:
		#fps.queue_free()
		dev.queue_free()
		dev_button.queue_free()
		dev_button_2.queue_free()


func fps_timer_timeout() -> void:
	fps.text = "[b]" + str(Engine.get_frames_per_second()).pad_zeros(3) + (
		"[/b] [img=<15>]%s[/img] [i]fps" % ResourceBag.get_resource("Speed").get_path()
	)

func _on_dev_button_pressed():
	wa.get_amount("WILL").m(1.1)
	#dev.text = mynum.text + " = " + Big.new(mynum).power(0.12).text


func _on_dev_button_2_pressed():
	wa.get_amount("WILL").d(2)


func dev_text() -> void:
	pass


#endregion
