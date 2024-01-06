class_name ThingyWidget
extends MarginContainer



@onready var header = %Header
@onready var level = %Level
@onready var xp_components = %"XP Components"
@onready var xp_label = %"XP Label"
@onready var xp_output_range = %"XP Output Range"
@onready var xp_bar = %"XP Bar"
@onready var will_output = %"Will Output"
@onready var crit_components = %"Crit Components"
@onready var crit_chance = %"Crit Chance"
@onready var crit_crit_chance = %"Crit Crit Chance"
@onready var crit_multiplier = %"Crit Multiplier"
@onready var crit_coin = %"Crit Coin"
@onready var duration = %Duration
@onready var xp_increase_range = %"XP Increase Range"
@onready var output_increase_range = %"Output Increase Range"
@onready var duration_increase = %"Duration Increase"

var thingy: Thingy



func _ready() -> void:
	hide()
	wa.get_unlocked(Currency.Type.XP).changed.connect(xp_unlocked)
	await th.container_loaded
	th.container.selected_index.changed.connect(selected_index_changed)



func selected_index_changed() -> void:
	show()
	if thingy:
		disconnect_calls()
		thingy = null
	thingy = th.get_thingy(th.get_selected_index()) as Thingy
	
	connect_calls()
	
	header.color = thingy.details.color
	header.text = "Thingy %s" % str(thingy.index + 1)



func connect_calls() -> void:
	xp_bar.attach_attribute(thingy.xp)
	thingy.level.changed.connect(level_changed)
	thingy.xp.changed.connect(xp_changed)
	th.xp_output_range.changed.connect(xp_output_range_changed)
	th.xp_increase_range.changed.connect(xp_increase_range_changed)
	th.output_increase_range.changed.connect(output_changed)
	th.output_range.changed.connect(output_changed)
	th.output_increase_range.changed.connect(output_increase_range_changed)
	thingy.level.changed.connect(output_changed)
	th.crit_chance.changed.connect(crit_chance_changed)
	th.crit_crit_chance.changed.connect(crit_crit_chance_changed)
	th.crit_range.changed.connect(crit_range_changed)
	th.crit_coin_output.changed.connect(crit_coin_output_changed)
	th.duration_increase_range.changed.connect(duration_changed)
	th.duration_range.changed.connect(duration_changed)
	thingy.level.changed.connect(duration_changed)
	th.duration_increase_range.changed.connect(duration_increase_changed)
	level_changed()
	xp_changed()
	xp_output_range_changed()
	xp_increase_range_changed()
	xp_unlocked()
	output_changed()
	output_increase_range_changed()
	crit_chance_changed()
	crit_crit_chance_changed()
	crit_range_changed()
	crit_coin_output_changed()
	duration_changed()
	duration_increase_changed()


func disconnect_calls() -> void:
	thingy.level.changed.disconnect(level_changed)
	thingy.xp.changed.disconnect(xp_changed)
	th.xp_output_range.changed.disconnect(xp_output_range_changed)
	th.xp_increase_range.changed.disconnect(xp_increase_range_changed)
	th.output_increase_range.changed.disconnect(output_changed)
	th.output_range.changed.disconnect(output_changed)
	th.output_increase_range.changed.disconnect(output_increase_range_changed)
	th.crit_chance.changed.disconnect(crit_chance_changed)
	th.crit_crit_chance.changed.disconnect(crit_crit_chance_changed)
	th.crit_range.changed.disconnect(crit_range_changed)
	th.crit_coin_output.changed.disconnect(crit_coin_output_changed)
	th.duration_increase_range.changed.disconnect(duration_changed)
	th.duration_range.changed.disconnect(duration_changed)
	thingy.level.changed.disconnect(duration_changed)
	th.duration_increase_range.changed.disconnect(duration_increase_changed)



#region Signals


func xp_unlocked() -> void:
	xp_components.visible = wa.is_unlocked(Currency.Type.XP)
	xp_output_range.visible = xp_components.visible
	xp_increase_range.visible = xp_components.visible
	output_increase_range.visible = xp_components.visible
	duration_increase.visible = xp_components.visible


func level_changed() -> void:
	level.text = "Level [b]" + thingy.level.get_text()


func xp_changed() -> void:
	xp_label.text = wa.get_details(Currency.Type.XP).color_text % (
		"%s/%s" % [
			thingy.xp.get_current_text(),
			thingy.xp.get_total_text()
		]
	)


func xp_output_range_changed() -> void:
	var text = wa.get_details(Currency.Type.XP).icon_and_name + ": [b]"
	text += wa.get_details(Currency.Type.XP).color_text
	if th.xp_output_range.is_full():
		text = text % th.xp_output_range.get_total_text()
	else:
		text = text % (
			"%s-%s" % [
				th.xp_output_range.get_current_text(),
				th.xp_output_range.get_total_text()
			]
		)
	xp_output_range.text = text


func xp_increase_range_changed() -> void:
	var xp_color_text = wa.get_details(Currency.Type.XP).color.to_html()
	var text = "[img=<15> color=#%s]%s[/img] [b]x" % [
		xp_color_text,
		bag.get_resource("Arrow Up Fill").get_path()
	]
	if th.xp_increase_range.is_full():
		text += th.xp_increase_range.get_total_text()
	else:
		text += "%s-%s" % [
			th.xp_increase_range.get_current_text(),
			th.xp_increase_range.get_total_text()
		]
	xp_increase_range.text = text


func output_changed() -> void:
	var text = wa.get_details(Currency.Type.WILL).icon_and_name + ": [b]"
	text += wa.get_details(Currency.Type.WILL).color_text
	if th.output_range.is_full():
		text = text % thingy.get_maximum_output().get_text()
	else:
		text = text % (
			"%s-%s" % [
				thingy.get_minimum_output().get_text(),
				thingy.get_maximum_output().get_text(),
			]
		)
	will_output.text = text


func output_increase_range_changed() -> void:
	var text = "[img=<15> color=#%s]%s[/img] [b]x" % [
		wa.get_details(Currency.Type.XP).color.to_html(),
		bag.get_resource("Arrow Up Fill").get_path()
	]
	if th.output_increase_range.is_full():
		text += th.output_increase_range.get_total_text()
	else:
		text += "%s-%s" % [
			th.output_increase_range.get_current_text(),
			th.output_increase_range.get_total_text()
		]
	output_increase_range.text = text


func crit_chance_changed() -> void:
	crit_components.visible = th.crit_chance.greater(0)
	crit_chance.text = "Chance: [b]%s%%" % th.crit_chance.get_text()


func crit_crit_chance_changed() -> void:
	crit_crit_chance.visible = th.crit_crit_chance.greater(0)
	crit_crit_chance.text = "Lucky Chance: [b]%s%%" % th.crit_crit_chance.get_text()


func crit_range_changed() -> void:
	var crit_mult_text = "Multiplier: [b]x%s[/b]"
	if th.crit_range.is_full():
		crit_mult_text = crit_mult_text % th.crit_range.get_total_text()
	else:
		crit_mult_text = crit_mult_text % (
			th.crit_range.get_current_text() + "-" + th.crit_range.get_total_text()
		)
	crit_multiplier.text = crit_mult_text


func crit_coin_output_changed() -> void:
	crit_coin.visible = th.crit_coin_output.total.greater(0)
	var text = wa.get_details(Currency.Type.COIN).icon_and_name + ": [b]"
	text += wa.get_details(Currency.Type.COIN).color_text
	if th.crit_coin_output.is_full():
		text = text % th.crit_coin_output.get_total_text()
	else:
		text = text % "%s-%s" % [
			th.crit_coin_output.get_current_text(),
			th.crit_coin_output.get_total_text()
		]
	crit_coin.text = text


func duration_changed() -> void:
	if th.duration_range.is_full():
		duration.text = "[b]" + tp.quick_parse(thingy.get_maximum_duration(), false)
	else:
		duration.text = "[b]%s-%s" % [
			str(thingy.get_minimum_duration()).pad_decimals(1),
			tp.quick_parse(thingy.get_maximum_duration(), false)
		]


func duration_increase_changed() -> void:
	var text = "[img=<15> color=#%s]%s[/img] [b]x" % [
		wa.get_details(Currency.Type.XP).color.to_html(),
		bag.get_resource("Arrow Up Fill").get_path()
	]
	if th.duration_increase_range.is_full():
		text += th.duration_increase_range.get_total_text()
	else:
		text += "%s-%s" % [
			th.duration_increase_range.get_current_text(),
			th.duration_increase_range.get_total_text()
		]
	duration_increase.text = text


#endregion
