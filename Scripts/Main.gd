extends CanvasLayer



@onready var gold_label = %"Gold Label"
@onready var gold_flair = %"Gold Flair"
@onready var gold_rate = %"Gold Rate"
@onready var tab_container = %TabContainer
@onready var top_panel = %TopPanel

#region Dev
@onready var fps = %FPS
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
	gold_flair.text = "[i]" + wa.get_details(Currency.Type.GOLD).icon_and_name_text
	gold_rate.modulate = wa.get_color(Currency.Type.GOLD)
	wa.get_currency(Currency.Type.GOLD).amount.changed.connect(gold_changed)
	wa.get_currency(Currency.Type.GOLD).net_rate.changed.connect(gold_rate_changed)
	gold_changed()
	gold_rate_changed()
	top_panel.hide()
	th.thingy_created.connect(thingy_created)
	
	th.container = %ThingyContainer
	up.container = %UpgradeContainer
	
	gv.root_ready.set_to(true)
	
	# when loading game, display top_panel



func gold_changed() -> void:
	gold_label.text = "[font_size=18][i]" + (
		wa.get_details(Currency.Type.GOLD).color_text % wa.get_amount_text(Currency.Type.GOLD)
	)


func gold_rate_changed() -> void:
	gold_rate.text = "[i](%s/s)" % wa.get_net_rate(Currency.Type.GOLD).get_text()


func fps_timer_timeout() -> void:
	fps.text = "FPS: " + str(Engine.get_frames_per_second())


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


