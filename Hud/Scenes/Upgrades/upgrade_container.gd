class_name UpgradeContainer
extends MarginContainer



@onready var tab_container = $TabContainer as TabContainer

const SCROLL_SPEED := 2

var focus: UpgradeButton
var current_scroll_container: ScrollContainer
var focus_set := false



func _ready() -> void:
	for node in tab_container.get_children():
		tab_container.set_tab_hidden(node.get_index(), true)
		node.get_v_scroll_bar().self_modulate = up.get_upgrade_tree(
			node.get_index() + 1
		).details.color
	_on_tab_container_tab_changed(0)
	get_viewport().gui_focus_changed.connect(focus_changed)



#region Signals


func _process(delta):
	if is_visible_in_tree():
		if gv.input_is_action_pressed("joy_scroll_down"):
			current_scroll_container.scroll_vertical += Input.get_action_strength("joy_scroll_down") * SCROLL_SPEED
		elif gv.input_is_action_pressed("joy_scroll_up"):
			current_scroll_container.scroll_vertical -= Input.get_action_strength("joy_scroll_up") * SCROLL_SPEED


func _on_visibility_changed():
	if is_visible_in_tree():
		if focus:
			focus.grab_focus()
		else:
			determine_focus()


func focus_changed(node: Node) -> void:
	if node and node is UpgradeButton:
		focus = node
	elif not node:
		determine_focus()


func _on_tab_container_tab_changed(tab):
	current_scroll_container = tab_container.get_child(tab)


#endregion


#region Action


func determine_focus() -> void:
	var current_tab_vbox: VBoxContainer = tab_container.get_child(tab_container.current_tab).get_child(0).get_child(0)
	get_focus_in_children(current_tab_vbox)
	focus_set = false
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

