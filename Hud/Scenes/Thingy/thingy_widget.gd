class_name ThingyWidget
extends MarginContainer



@onready var header = %Header
@onready var level = %Level
@onready var xp_components = %"XP Components"
@onready var xp_label = %"XP Label"
@onready var xp_output_range = %"XP Output Range"
@onready var xp_bar = %"XP Bar" as Bar
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
@onready var juice_output = %"Juice Output"
@onready var juice_output_increase = %"Juice Output Increase"
@onready var input_components = %"Input Components"
@onready var juice_input = %"Juice Input"
@onready var juice_input_increase = %"Juice Input Increase"

var thingy: Thingy:
	set(val):
		thingy = val
		if not wa.get_unlocked(Currency.Type.XP).changed.is_connected(xp_unlocked):
			wa.get_unlocked(Currency.Type.XP).changed.connect(xp_unlocked)
			wa.get_unlocked(Currency.Type.JUICE).changed.connect(juice_unlocked)
			th.xp_output_range.changed.connect(xp_output_range_changed)
			th.duration_applies_to_xp_output.changed.connect(xp_output_range_changed)
			th.xp_increase_range.changed.connect(xp_increase_range_changed)
			th.output_increase_range.changed.connect(output_changed)
			th.output_range.changed.connect(output_changed)
			th.output_increase_range.changed.connect(output_increase_range_changed)
			th.crit_chance.changed.connect(crit_chance_changed)
			th.crit_crit_chance.changed.connect(crit_crit_chance_changed)
			th.crit_range.changed.connect(crit_range_changed)
			th.crits_apply_to_coin.changed.connect(crit_coin_output_changed)
			th.crits_apply_to_coin_twice.changed.connect(crit_coin_output_changed)
			th.crit_coin_output.changed.connect(crit_coin_output_changed)
			th.duration_range.changed.connect(duration_changed)
			th.duration_increase_range.changed.connect(duration_changed)
			th.duration_increase_range.changed.connect(duration_increase_changed)
			th.juice_output_range.changed.connect(juice_output_changed)
			th.juice_input_range.changed.connect(juice_input_changed)
			th.juice_output_increase_range.changed.connect(juice_output_increase_changed)
			th.juice_input_increase_range.changed.connect(juice_input_increase_changed)
			xp_unlocked()
			juice_unlocked()



func _ready() -> void:
	hide()
	await th.container_loaded
	th.container.selected_index.changed.connect(selected_index_changed)



func selected_index_changed() -> void:
	if th.get_selected_index() == -1:
		hide()
		return
	show()
	if thingy:
		disconnect_calls()
		thingy = null
	thingy = th.get_thingy(th.get_selected_index()) as Thingy
	
	connect_calls()
	
	header.color = thingy.details.color
	header.text = "Thingy %s" % str(thingy.index + 1)



func connect_calls() -> void:
	xp_bar.attach_value_pair(thingy.xp)
	thingy.level.changed.connect(level_changed)
	thingy.xp.changed.connect(xp_changed)
	thingy.level.changed.connect(output_changed)
	thingy.duration_modifier.changed.connect(duration_changed)
	thingy.juice_output_modifier.changed.connect(juice_output_changed)
	thingy.juice_input_modifier.changed.connect(juice_input_changed)
	level_changed(false)
	xp_changed()
	xp_output_range_changed(false)
	xp_increase_range_changed(false)
	output_changed(false)
	output_increase_range_changed(false)
	crit_chance_changed(false)
	crit_crit_chance_changed(false)
	crit_range_changed(false)
	crit_coin_output_changed(false)
	duration_changed(false)
	duration_increase_changed(false)
	juice_output_changed(false)
	juice_input_changed(false)
	juice_output_increase_changed(false)
	juice_input_increase_changed(false)


func disconnect_calls() -> void:
	xp_bar.remove_value()
	thingy.level.changed.disconnect(level_changed)
	thingy.xp.changed.disconnect(xp_changed)
	thingy.level.changed.disconnect(output_changed)
	thingy.duration_modifier.changed.disconnect(duration_changed)
	thingy.juice_output_modifier.changed.disconnect(juice_output_changed)
	thingy.juice_input_modifier.changed.disconnect(juice_input_changed)



#region Signals


func xp_unlocked(flash := true) -> void:
	xp_components.visible = wa.is_unlocked(Currency.Type.XP)
	xp_output_range.visible = xp_components.visible
	xp_increase_range.get_parent().visible = xp_components.visible
	output_increase_range.get_parent().visible = xp_components.visible
	duration_increase.get_parent().visible = xp_components.visible
	juice_output_increase.get_parent().visible = xp_components.visible and input_components.visible
	juice_input_increase.get_parent().visible = xp_components.visible and input_components.visible
	if flash:
		gv.flash(level, wa.get_color(Currency.Type.XP))
		gv.flash(xp_label, wa.get_color(Currency.Type.XP))
		gv.flash(xp_increase_range, wa.get_color(Currency.Type.XP))
		gv.flash(xp_bar, wa.get_color(Currency.Type.XP))
		gv.flash(xp_output_range, wa.get_color(Currency.Type.XP))
		gv.flash(output_increase_range, wa.get_color(Currency.Type.XP))
		gv.flash(duration_increase, wa.get_color(Currency.Type.XP))


func juice_unlocked(flash := true) -> void:
	input_components.visible = wa.is_unlocked(Currency.Type.JUICE)
	juice_input.visible = input_components.visible
	juice_output.visible = input_components.visible
	juice_output_increase.get_parent().visible = input_components.visible and xp_components.visible
	juice_input_increase.get_parent().visible = input_components.visible and xp_components.visible
	if flash:
		gv.flash(juice_output, wa.get_color(Currency.Type.JUICE))
		gv.flash(juice_output_increase, wa.get_color(Currency.Type.JUICE))
		gv.flash(juice_input, wa.get_color(Currency.Type.JUICE))
		gv.flash(juice_input_increase, wa.get_color(Currency.Type.JUICE))


func level_changed(flash := true) -> void:
	level.text = "Level [b]" + thingy.level.get_text()
	if flash:
		gv.flash(level, thingy.details.color)


func xp_changed() -> void:
	xp_label.text = wa.get_details(Currency.Type.XP).color_text % (
		"%s/%s" % [
			thingy.xp.get_current_text(),
			thingy.xp.get_total_text()
		]
	)


func xp_output_range_changed(flash := true) -> void:
	var text = wa.get_details(Currency.Type.XP).icon_and_name + ": [b]"
	text += wa.get_details(Currency.Type.XP).color_text
	if th.xp_output_range.is_full():
		if th.duration_applies_to_xp_output.is_true():
			text = text % Big.get_float_text(max(1, thingy.get_minimum_duration()) * th.xp_output_range.get_total())
		else:
			text = text % th.xp_output_range.get_total_text()
	else:
		if th.duration_applies_to_xp_output.is_true():
			text = text % (
				"%s-%s" % [
					Big.get_float_text(max(1, thingy.get_minimum_duration()) * th.xp_output_range.get_current()),
					Big.get_float_text(max(1, thingy.get_maximum_duration()) * th.xp_output_range.get_total()),
				]
			)
		else:
			text = text % (
				"%s-%s" % [
					th.xp_output_range.get_current_text(),
					th.xp_output_range.get_total_text()
				]
			)
	xp_output_range.text = text
	if flash:
		gv.flash(xp_output_range, thingy.details.color)


func xp_increase_range_changed(flash := true) -> void:
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
	if flash:
		gv.flash(xp_increase_range, thingy.details.color)


func output_changed(flash := true) -> void:
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
	if flash:
		gv.flash(will_output, thingy.details.color)


func output_increase_range_changed(flash := true) -> void:
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
	if flash:
		gv.flash(output_increase_range, thingy.details.color)


func juice_output_changed(flash := true) -> void:
	var text = wa.get_details(Currency.Type.JUICE).icon_and_name + ": [b]"
	text += wa.get_details(Currency.Type.JUICE).color_text
	if th.juice_output_range.is_full():
		text = text % Big.get_float_text(thingy.get_minimum_juice_output())
	else:
		text = text % (
			"%s-%s" % [
				Big.get_float_text(thingy.get_minimum_juice_output()),
				Big.get_float_text(thingy.get_maximum_juice_output()),
			]
		)
	juice_output.text = text
	if flash:
		gv.flash(juice_output, thingy.details.color)


func juice_input_changed(flash := true) -> void:
	var text = wa.get_details(Currency.Type.JUICE).icon_and_name + ": [b]"
	text += wa.get_details(Currency.Type.JUICE).color_text
	if th.juice_input_range.is_full():
		text = text % Big.get_float_text(thingy.get_minimum_juice_input())
	else:
		text = text % (
			"%s-%s" % [
				Big.get_float_text(thingy.get_minimum_juice_input()),
				Big.get_float_text(thingy.get_maximum_juice_input()),
			]
		)
	juice_input.text = text
	if flash:
		gv.flash(juice_input, thingy.details.color)


func juice_output_increase_changed(flash := true) -> void:
	var text = "[img=<15> color=#%s]%s[/img] [b]x" % [
		wa.get_details(Currency.Type.XP).color.to_html(),
		bag.get_resource("Arrow Up Fill").get_path()
	]
	if th.juice_output_increase_range.is_full():
		text += th.juice_output_increase_range.get_total_text()
	else:
		text += "%s-%s" % [
			th.juice_output_increase_range.get_current_text(),
			th.juice_output_increase_range.get_total_text()
		]
	juice_output_increase.text = text
	if flash:
		gv.flash(juice_output_increase, thingy.details.color)


func juice_input_increase_changed(flash := true) -> void:
	var text = "[img=<15> color=#%s]%s[/img] [b]x" % [
		wa.get_details(Currency.Type.XP).color.to_html(),
		bag.get_resource("Arrow Up Fill").get_path()
	]
	if th.juice_input_increase_range.is_full():
		text += th.juice_input_increase_range.get_total_text()
	else:
		text += "%s-%s" % [
			th.juice_input_increase_range.get_current_text(),
			th.juice_input_increase_range.get_total_text()
		]
	juice_input_increase.text = text
	if flash:
		gv.flash(juice_input_increase, thingy.details.color)


func crit_chance_changed(flash := true) -> void:
	crit_components.visible = th.crit_chance.greater(0)
	crit_chance.text = "Chance: [b]%s%%" % th.crit_chance.get_text()
	if flash:
		gv.flash(crit_chance, thingy.details.color)


func crit_crit_chance_changed(flash := true) -> void:
	crit_crit_chance.visible = th.crit_crit_chance.greater(0)
	crit_crit_chance.text = "Lucky Chance: [b]%s%%" % th.crit_crit_chance.get_text()
	if flash:
		gv.flash(crit_crit_chance, thingy.details.color)


func crit_range_changed(flash := true) -> void:
	var crit_mult_text = "Multiplier: [b]x%s[/b]"
	if th.crit_range.is_full():
		crit_mult_text = crit_mult_text % th.crit_range.get_total_text()
	else:
		crit_mult_text = crit_mult_text % (
			th.crit_range.get_current_text() + "-" + th.crit_range.get_total_text()
		)
	crit_multiplier.text = crit_mult_text
	if flash:
		gv.flash(crit_multiplier, thingy.details.color)
		if up.is_purchased(Upgrade.Type.CRITS_AFFECT_COIN_GAIN):
			crit_coin_output_changed()


func crit_coin_output_changed(flash := true) -> void:
	crit_coin.visible = th.crit_coin_output.total.greater(0)
	var text = wa.get_details(Currency.Type.COIN).icon_and_name + ": [b]"
	text += wa.get_details(Currency.Type.COIN).color_text
	if th.crit_coin_output.is_full() and th.crits_apply_to_coin.is_false():
		text = text % th.crit_coin_output.get_total_text()
	else:
		#text = text % "%s-%s" % [
			#th.crit_coin_output.get_current_text(),
			#th.crit_coin_output.get_total_text(),
		#]
		text = text % "%s-%s" % [
			Big.get_float_text(th.crit_coin_output.get_current() * (
				(th.crit_range.get_current() if th.crits_apply_to_coin.is_true() else 1.0) *
				(th.crit_range.get_current() if th.crits_apply_to_coin_twice.is_true() else 1.0)
			)),
			Big.get_float_text(th.crit_coin_output.get_total() * (
				(th.crit_range.get_total() if th.crits_apply_to_coin.is_true() else 1.0) *
				(th.crit_range.get_total() if th.crits_apply_to_coin_twice.is_true() else 1.0)
			))
		]
	crit_coin.text = text
	if flash:
		gv.flash(crit_coin, thingy.details.color)


func duration_changed(flash := true) -> void:
	if th.duration_range.is_full():
		duration.text = "[b]" + tp.quick_parse(thingy.get_maximum_duration(), false)
	else:
		duration.text = "[b]%s-%s" % [
			str(thingy.get_minimum_duration()).pad_decimals(1),
			tp.quick_parse(thingy.get_maximum_duration(), false)
		]
	if flash:
		gv.flash(duration, thingy.details.color)
	if th.duration_applies_to_xp_output.is_true():
		xp_output_range_changed(flash)


func duration_increase_changed(flash := true) -> void:
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
	if flash:
		gv.flash(duration_increase, thingy.details.color)


#endregion
