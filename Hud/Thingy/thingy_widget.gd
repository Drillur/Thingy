class_name ThingyWidget
extends MarginContainer



@onready var header = %Header
@onready var level = %Level
@onready var xp_components = %"XP Components"
@onready var xp_label = %"XP Label"
@onready var xp_bar = %"XP Bar"
@onready var will_output = %"Will Output"
@onready var crit_components = %"Crit Components"
@onready var crit_chance = %"Crit Chance"
@onready var crit_crit_chance = %"Crit Crit Chance"
@onready var crit_multiplier = %"Crit Multiplier"
@onready var crit_coin = %"Crit Coin"
@onready var duration = %Duration

var thingy: Thingy



func _ready() -> void:
	hide()
	th.xp_unlocked.changed.connect(xp_unlocked)
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
	th.output_increase.changed.connect(output_changed)
	th.output_range.changed.connect(output_changed)
	thingy.level.changed.connect(output_changed)
	th.crit_chance.changed.connect(crit_chance_changed)
	th.crit_crit_chance.changed.connect(crit_crit_chance_changed)
	th.crit_range.changed.connect(crit_range_changed)
	th.crit_coin_output.changed.connect(crit_coin_output_changed)
	th.duration_increase.changed.connect(duration_changed)
	th.duration_range.changed.connect(duration_changed)
	thingy.level.changed.connect(duration_changed)
	level_changed()
	xp_changed()
	xp_unlocked()
	output_changed()
	crit_chance_changed()
	crit_crit_chance_changed()
	crit_range_changed()
	crit_coin_output_changed()
	duration_changed()


func disconnect_calls() -> void:
	thingy.level.changed.disconnect(level_changed)
	thingy.xp.changed.disconnect(xp_changed)
	th.output_increase.changed.disconnect(output_changed)
	th.output_range.changed.disconnect(output_changed)
	th.crit_chance.changed.disconnect(crit_chance_changed)
	th.crit_crit_chance.changed.disconnect(crit_crit_chance_changed)
	th.crit_range.changed.disconnect(crit_range_changed)
	th.crit_coin_output.changed.disconnect(crit_coin_output_changed)
	th.duration_increase.changed.disconnect(duration_changed)
	th.duration_range.changed.disconnect(duration_changed)



#region Signals


func xp_unlocked() -> void:
	xp_components.visible = th.xp_unlocked.get_value()


func level_changed() -> void:
	level.text = "Level " + thingy.level.get_text()


func xp_changed() -> void:
	xp_label.text = wa.get_details(Currency.Type.XP).color_text % (
		"%s/%s " % [
			thingy.xp.get_current_text(),
			thingy.xp.get_total_text()
		]
	) + wa.get_details(Currency.Type.XP).icon_and_name_text


func output_changed() -> void:
	var text = wa.get_details(Currency.Type.WILL).icon_and_name_text + ": "
	text += wa.get_details(Currency.Type.WILL).color_text
	if th.output_range.is_full():
		text = text % thingy.get_average_output().get_text()
	else:
		text = text % (
			"%s-%s" % [
				thingy.get_minimum_output().get_text(),
				thingy.get_maximum_output().get_text(),
			]
		)
	will_output.text = text


func crit_chance_changed() -> void:
	crit_components.visible = th.crit_chance.greater(0)
	crit_chance.text = "Chance: %s%%" % th.crit_chance.get_text()


func crit_crit_chance_changed() -> void:
	crit_crit_chance.visible = th.crit_crit_chance.greater(0)
	crit_crit_chance.text = "Lucky Chance: %s%%" % th.crit_crit_chance.get_text()


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
	var crit_coin_text = wa.get_details(Currency.Type.COIN).icon_and_name_text + ": [b]"
	if th.crit_coin_output.is_full():
		crit_coin_text += th.crit_coin_output.get_total_text()
	else:
		crit_coin_text += "%s-%s" % [
			th.crit_coin_output.get_current_text(),
			th.crit_coin_output.get_total_text()
		]
	crit_coin.text = crit_coin_text


func duration_changed() -> void:
	if th.duration_range.is_full():
		duration.text = tp.quick_parse(thingy.get_average_duration(), false)
	else:
		duration.text = "%s-%s" % [
			Big.get_float_text(thingy.get_minimum_duration()),
			tp.quick_parse(thingy.get_maximum_duration(), false)
		]


#endregion
