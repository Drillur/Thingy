class_name ResetMenu
extends MarginContainer



@onready var info = %info
@onready var info_icon = %"info icon"
@onready var soul_label = %"Soul Label"
@onready var soul_flair = %"Soul Flair"
@onready var free_button = %"Free Button"



func _ready() -> void:
	info.text = "[i]Free the souls of your [img=<15>]res://Art/Icons/Hud/activeBuffs.png[/img] Thingies which you have lovingly cultivated. This will also obliterate all of your [img=<15>]res://Art/Icons/Hud/upgrades.png[/img] Upgrades and currencies (except %s)." % (
		wa.get_details("SOUL").get_icon_and_name()
	)
	free_button.color = wa.get_color("SOUL")
	info_icon.modulate = wa.get_color("SOUL")
	soul_flair.text = "[i]" + wa.get_details("SOUL").get_icon_and_name()
	wa.get_pending_amount("SOUL").changed.connect(soul_changed)
	soul_changed()


#region Signals


func soul_changed() -> void:
	soul_label.text = "[i]" + (
		wa.get_details("SOUL").get_color_text() % (
			"+" + wa.get_pending_amount("SOUL").text
		)
	)


func _on_free_button_pressed():
	gv.root.current_tab.reset()
	gv.reset_now(1)


#endregion

