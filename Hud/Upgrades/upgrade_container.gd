class_name UpgradeContainer
extends MarginContainer



@onready var tab_container = $TabContainer



func _ready() -> void:
	tab_container.set_tab_hidden(0, true)
	tab_container.set_tab_hidden(2, true)
	tab_container.current_tab = 1
