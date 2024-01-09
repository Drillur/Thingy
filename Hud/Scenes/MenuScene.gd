extends MarginContainer


@onready var save = %Save
@onready var load_button = %Load
@onready var export = %Export
@onready var new_game = %"New Game"
@onready var hard_reset = %"Hard Reset"
@onready var set_color = %"Set Color"
@onready var rename = %Rename
@onready var duplicate_button = %Duplicate
@onready var delete_save = %"Delete Save"





func _on_save_pressed():
	SaveManager.save_game()
