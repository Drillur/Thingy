extends CanvasLayer



@onready var tab_container = %TabContainer

#region Dev
@onready var fps = %FPS
func fps_timer_timeout() -> void:
	fps.text = "FPS: " + str(Engine.get_frames_per_second())
#endregion

enum Tab {
	THINGY,
	UPGRADE,
}

var current_tab := LoudInt.new(0)


func _ready() -> void:
	randomize()
	if gv.dev_mode:
		fps.get_node("Timer").timeout.connect(fps_timer_timeout)
	else:
		fps.queue_free()
	current_tab.changed.connect(current_tab_changed)
	setup_sidebar()
	setup_top_panel()
	th.thingy_created.connect(thingy_created)
	
	th.container = %ThingyContainer
	up.container = %UpgradeContainer
	
	gv.root_ready.set_to(true)
	
	# when loading game, display top_panel

#region Top Panel


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


func setup_top_panel() -> void:
	will_flair.text = "[i]" + wa.get_details(Currency.Type.WILL).icon_and_name_text
	will_rate.modulate = wa.get_color(Currency.Type.WILL)
	wa.get_currency(Currency.Type.WILL).amount.changed.connect(will_changed)
	wa.get_currency(Currency.Type.WILL).net_rate.changed.connect(will_rate_changed)
	will_changed()
	will_rate_changed()
	coin_flair.text = "[i]" + wa.get_details(Currency.Type.COIN).icon_and_name_text
	coin_rate.modulate = wa.get_color(Currency.Type.COIN)
	wa.get_currency(Currency.Type.COIN).amount.changed.connect(coin_changed)
	wa.get_currency(Currency.Type.COIN).net_rate.changed.connect(coin_rate_changed)
	coin_changed()
	coin_rate_changed()
	xp_flair.text = "[i]" + wa.get_details(Currency.Type.XP).icon_and_name_text
	xp_rate.modulate = wa.get_color(Currency.Type.XP)
	wa.get_currency(Currency.Type.XP).amount.changed.connect(xp_changed)
	wa.get_currency(Currency.Type.XP).net_rate.changed.connect(xp_rate_changed)
	xp_changed()
	xp_rate_changed()
	top_panel.hide()


func coin_changed() -> void:
	coin_label.text = "[i]" + (
		wa.get_details(Currency.Type.COIN).color_text % wa.get_amount_text(Currency.Type.COIN)
	)


func coin_rate_changed() -> void:
	coin_rate.text = "[i](%s/s)" % wa.get_net_rate(Currency.Type.COIN).get_text()


func will_changed() -> void:
	will_label.text = "[i]" + (
		wa.get_details(Currency.Type.WILL).color_text % (
			wa.get_amount_text(Currency.Type.WILL)
		)
	)


func will_rate_changed() -> void:
	will_rate.text = "[i](%s/s)" % wa.get_net_rate(Currency.Type.WILL).get_text()


func xp_changed() -> void:
	xp_label.text = "[i]" + (
		wa.get_details(Currency.Type.XP).color_text % (
			wa.get_amount_text(Currency.Type.XP)
		)
	)


func xp_rate_changed() -> void:
	xp_rate.text = "[i](%s/s)" % wa.get_net_rate(Currency.Type.XP).get_text()


#endregion



func thingy_created() -> void:
	top_panel.show()
	th.thingy_created.disconnect(thingy_created)


func current_tab_changed() -> void:
	tab_container.current_tab = current_tab.get_value()

#region Sidebar


@onready var sidebar = %Sidebar
@onready var tab_thingy = %"Tab Thingy"
@onready var tab_upgrade = %"Tab Upgrade"
@onready var sidebar_button = %SidebarButton
@onready var sidebar_header = %SidebarHeader
@onready var unlock_upgrades_button = %UnlockUpgradesButton

var sidebar_open := LoudBool.new(true)


func setup_sidebar() -> void:
	up.get_upgrade(
		Upgrade.Type.UNLOCK_UPGRADES
	).purchased.changed.connect(update_sidebar_visibility)
	update_sidebar_visibility()
	th.thingy_created.connect(update_unlock_upgrades_button_visibility)
	update_unlock_upgrades_button_visibility()
	sidebar_open.became_true.connect(tab_thingy.show_text)
	sidebar_open.became_true.connect(tab_upgrade.show_text)
	sidebar_open.became_false.connect(tab_thingy.hide_text)
	sidebar_open.became_false.connect(tab_upgrade.hide_text)
	sidebar_open.set_to(false)
	
	th.thingy_created.connect(update_tab_thingy_color)
	update_tab_thingy_color()
	await th.container_loaded
	th.container.selected_index.changed.connect(update_sidebar_button_color)
	sidebar_header.color = tab_thingy.color


func _on_sidebar_button_pressed():
	sidebar_open.invert()


func _on_tab_thingy_pressed():
	current_tab.set_to(Tab.THINGY)


func _on_tab_upgrade_pressed():
	current_tab.set_to(Tab.UPGRADE)


func update_tab_thingy_color() -> void:
	tab_thingy.color = th.next_thingy_color


func update_sidebar_button_color() -> void:
	sidebar_header.color = th.get_color(th.container.selected_index.get_value())


func update_sidebar_visibility() -> void:
	sidebar.visible = up.is_purchased(Upgrade.Type.UNLOCK_UPGRADES)
	unlock_upgrades_button.hide()
	if sidebar.visible:
		gv.flash(sidebar, th.get_latest_color())
	


func update_unlock_upgrades_button_visibility() -> void:
	unlock_upgrades_button.visible = th.get_count() >= 3 and not sidebar.visible
	if unlock_upgrades_button.visible:
		gv.flash(unlock_upgrades_button, unlock_upgrades_button.upgrade.details.color)


#endregion


