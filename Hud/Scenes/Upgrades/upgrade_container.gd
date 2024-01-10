class_name UpgradeContainer
extends MarginContainer



@onready var tab_container = $TabContainer as TabContainer
@onready var joypad_controls = %JoypadControls
@onready var lb = %LB
@onready var rb = %RB

const SCROLL_SPEED := 25

var focus: UpgradeButton
var current_scroll_container: ScrollContainer
var focus_set := false



func _ready() -> void:
	for node in tab_container.get_children():
		tab_container.set_tab_hidden(node.get_index(), true)
		node.get_v_scroll_bar().self_modulate = up.get_upgrade_tree(
			node.get_index() + 1
		).details.color
	get_viewport().gui_focus_changed.connect(focus_changed)
	Settings.joypad.right.changed.connect(joypad_detected_changed)
	joypad_detected_changed()
	up.get_upgrade_tree(up.UpgradeTree.Type.VOYAGER).unlocked.changed.connect(voyager_unlocked_changed)
	_on_tab_container_tab_changed(0)
	SaveManager.loading.became_false.connect(_on_tab_container_tab_changed)
	gv.reset.connect(reset)



#region Signals


func _input(_event):
	if Input.is_action_just_pressed("upgrades0"):
		tab_container.current_tab = 0
	elif Input.is_action_just_pressed("upgrades1"):
		if up.is_upgrade_tree_unlocked(up.UpgradeTree.Type.VOYAGER):
			tab_container.current_tab = 1


func _physics_process(_delta):
	if not is_visible_in_tree():
		return
	if Settings.joypad.right.is_true():
		if Input.is_action_pressed("joy_scroll_down"):
			current_scroll_container.scroll_vertical += int(Input.get_action_strength("joy_scroll_down") * SCROLL_SPEED)
		elif Input.is_action_pressed("joy_scroll_up"):
			current_scroll_container.scroll_vertical -= int(Input.get_action_strength("joy_scroll_up") * SCROLL_SPEED)
		if Input.is_action_pressed("joy_next_upgrade_tree"):
			tab_container.current_tab += 1
		elif Input.is_action_pressed("joy_prev_upgrade_tree"):
			tab_container.current_tab -= 1


func _on_visibility_changed():
	if is_visible_in_tree():
		if focus and focus.focus_mode == Control.FOCUS_ALL:
			focus.grab_focus()
		else:
			determine_focus()


func joypad_detected_changed() -> void:
	joypad_controls.visible = Settings.joypad.get_right()


func focus_changed(node: Node) -> void:
	if node and node is UpgradeButton:
		focus = node
	elif not node:
		determine_focus()


func _on_tab_container_tab_changed(tab = tab_container.current_tab):
	current_scroll_container = tab_container.get_child(tab)
	
	tab += 1
	if up.tree_exists_and_is_unlocked(tab + 1):
		var next_tree = up.get_upgrade_tree(tab + 1)
		rb.modulate = next_tree.details.color
		return
	if up.tree_exists_and_is_unlocked(tab - 1):
		var prev_tree = up.get_upgrade_tree(tab - 1)
		lb.modulate = prev_tree.details.color
		return
	var cur_tree = up.get_upgrade_tree(tab)
	rb.modulate = cur_tree.details.color
	lb.modulate = cur_tree.details.color


func voyager_unlocked_changed() -> void:
	tab_container.tabs_visible = up.is_upgrade_tree_unlocked(up.UpgradeTree.Type.VOYAGER)


func reset(_tier: int) -> void:
	for scroll_container in tab_container.get_children():
		if up.get_upgrade_tree(scroll_container.get_index() + 1).persist.should_fail_at_tier(_tier):
			scroll_container.scroll_vertical = 0


#endregion


#region Action


func determine_focus() -> void:
	var current_tab_vbox: VBoxContainer = tab_container.get_child(tab_container.current_tab).get_child(0).get_child(0)
	get_focus_in_children(current_tab_vbox)
	focus_set = false
	if focus:
		if focus.focus_mode == Control.FOCUS_ALL:
			focus.grab_focus()


func get_focus_in_children(parent: Node) -> void:
	for node in parent.get_children():
		if focus_set:
			return
		if node is UpgradeButton:
			if node.upgrade.purchased.is_false():
				focus_set = true
				focus = node
				return
		else:
			get_focus_in_children(node)


func color_tab(val: Color) -> void:
	tab_container.add_theme_color_override("font_selected_color", val)


#endregion

