class_name UpgradeContainer
extends MarginContainer



@onready var tab_container = $TabContainer as TabContainer



func _ready() -> void:
	tab_container.set_tab_hidden(0, true)
	tab_container.set_tab_hidden(2, true)
	tab_container.current_tab = 1
	
	for node in tab_container.get_children():
		node.get_v_scroll_bar().self_modulate = up.get_upgrade_tree(
			node.get_index() + 1
		).details.color


func color_tab(val: Color) -> void:
	tab_container.add_theme_color_override("font_selected_color", val)
