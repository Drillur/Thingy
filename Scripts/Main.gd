extends CanvasLayer



#region Dev
@onready var fps = %FPS
func fps_timer_timeout() -> void:
	fps.text = "FPS: " + str(Engine.get_frames_per_second())
#endregion


func _ready() -> void:
	randomize()
	if gv.dev_mode:
		fps.get_node("Timer").timeout.connect(fps_timer_timeout)
	else:
		fps.queue_free()
	setup_sidebar()
	setup_navigation_panel()
	setup_top_panel()
	th.thingy_created.connect(thingy_created)
	
	th.container = %ThingyContainer
	up.container = %UpgradeContainer
	
	gv.root_ready.set_to(true)
	
	# when loading game, display top_panel


#region Signals


func thingy_created() -> void:
	top_panel.show()
	th.thingy_created.disconnect(thingy_created)


func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		current_tab.reset()
	if Input.is_action_just_pressed("Normal Upgrades"):
		if up.is_purchased(Upgrade.Type.UNLOCK_UPGRADES):
			current_tab.set_to(Tab.UPGRADE)
	if not gv.node_has_point(sidebar, sidebar.get_global_mouse_position()):
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN):
			if th.has_thingy(th.get_selected_index() - 1):
				th.container.snap_to_index(th.get_selected_index() - 1)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP):
			if th.has_thingy(th.get_selected_index() + 1):
				th.container.snap_to_index(th.get_selected_index() + 1)


#endregion


#region Currency Panel


@onready var top_panel = %TopPanel
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


func setup_top_panel() -> void:
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
	
	top_panel.hide()


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


#endregion


#region Navigation Panel


@onready var navigation_panel = %"Navigation Panel"
@onready var tab_upgrade = %"Tab Upgrade"
@onready var unlock_upgrades_button = %UnlockUpgradesButton
@onready var purchase_thingy = %"Purchase Thingy"

var navigation_panel_open := LoudBool.new(true)


func setup_navigation_panel() -> void:
	up.get_upgrade(
		Upgrade.Type.UNLOCK_UPGRADES
	).purchased.changed.connect(update_navigation_panel_visibility)
	update_navigation_panel_visibility()
	th.thingy_created.connect(update_unlock_upgrades_button_visibility)
	update_unlock_upgrades_button_visibility()
	navigation_panel_open.became_true.connect(tab_upgrade.show_text)
	navigation_panel_open.became_false.connect(tab_upgrade.hide_text)
	navigation_panel_open.set_to(false)
	
	purchase_thingy.setup(th.cost)
	purchase_thingy.color = th.next_thingy_color


func _on_navigation_panel_button_pressed():
	navigation_panel_open.invert()


func _on_tab_upgrade_pressed():
	if current_tab.equal(Tab.UPGRADE):
		current_tab.reset()
	else:
		current_tab.set_to(Tab.UPGRADE)


func _on_purchase_thingy_pressed():
	th.purchase_thingy()
	purchase_thingy.color = th.next_thingy_color


func update_navigation_panel_visibility() -> void:
	navigation_panel.visible = up.is_purchased(Upgrade.Type.UNLOCK_UPGRADES)
	unlock_upgrades_button.hide()
	if navigation_panel.visible:
		gv.flash(navigation_panel, th.get_latest_color())
	


func update_unlock_upgrades_button_visibility() -> void:
	unlock_upgrades_button.visible = th.get_count() >= 3 and not navigation_panel.visible
	if unlock_upgrades_button.visible:
		gv.flash(unlock_upgrades_button, unlock_upgrades_button.upgrade.details.color)


#endregion


#region Sidebar


@onready var sidebar = %Sidebar
@onready var tab_container = %TabContainer
@onready var upgrade_container = %UpgradeContainer as UpgradeContainer
@onready var sidebar_header = %"Sidebar Header"


enum Tab {
	UPGRADE,
}

var current_tab := LoudInt.new(-1)



func setup_sidebar() -> void:
	sidebar.hide()
	current_tab.changed.connect(current_tab_changed)
	upgrade_container.tab_container.tab_changed.connect(upgrade_container_tab_changed)
	upgrade_container_tab_changed(1)



func current_tab_changed() -> void:
	if current_tab.less(0):
		sidebar.hide()
	else:
		tab_container.current_tab = current_tab.get_value()
		sidebar.show()


func upgrade_container_tab_changed(index: int) -> void:
	var tree: up.UpgradeTree = up.get_upgrade_tree(index + 1)
	sidebar_header.color = tree.details.color
	sidebar_header.text = tree.details.name
	sidebar_header.icon = tree.details.icon
	tab_upgrade.color = tree.details.color
	upgrade_container.color_tab(tree.details.color)


#endregion
