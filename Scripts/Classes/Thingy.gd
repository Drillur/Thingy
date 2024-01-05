class_name Thingy
extends Resource



const saved_vars := [
	"output_multiplier",
]

enum Attribute {
	NONE,
	DURATION_RANGE,
	DURATION_RANGE_CURRENT,
	DURATION_RANGE_TOTAL,
	DURATION_INCREASE_RANGE,
	DURATION_INCREASE_RANGE_CURRENT,
	DURATION_INCREASE_RANGE_TOTAL,
	OUTPUT_RANGE,
	OUTPUT_RANGE_TOTAL,
	OUTPUT_RANGE_CURRENT,
	OUTPUT_INCREASE_RANGE,
	OUTPUT_INCREASE_RANGE_CURRENT,
	OUTPUT_INCREASE_RANGE_TOTAL,
	COST,
	CRIT,
	CRIT_RANGE,
	CRIT_RANGE_CURRENT,
	CRIT_RANGE_TOTAL,
	CRIT_COIN_OUTPUT,
	CRIT_COIN_OUTPUT_CURRENT,
	CRIT_COIN_OUTPUT_TOTAL,
	CURRENT_XP_INCREASE_RANGE,
	XP_OUTPUT_TOTAL,
	XP_OUTPUT_CURRENT,
	XP_OUTPUT,
	XP,
}

signal timer_started

var index: int
var just_born := true
var level := LoudInt.new(1)
var timer := Timer.new()
var output_multiplier := Big.new(1.0, true)
var xp := ValuePair.new(10.0).do_not_cap_current()
var xp_modifier := LoudFloat.new(1.0)
var duration_modifier := LoudFloat.new(1.0)
var inhand := Big.new(0, true)
var inhand_coin := Big.new(0, true)
var inhand_xp := Big.new(0, true)
var crit_success := LoudBool.new(false)
var crit_multiplier := LoudFloat.new(1.0)
var inhand_currency: Currency.Type

var details = Details.new()

#region References
var will: Currency = wa.get_currency(Currency.Type.WILL)
#endregion



func _init(_index: int) -> void:
	index = _index
	details.color = th.next_thingy_color
	xp.current.current.change_base(0.0)
	xp.current.reset()
	xp.filled.connect(xp_filled)
	xp_modifier.changed.connect(xp_modifier_changed)
	level.changed.connect(level_changed)
	th.xp_multiplier.changed.connect(global_xp_multiplier_changed)
	global_xp_multiplier_changed()
	crit_multiplier.changed.connect(crit_success.set_true)
	crit_multiplier.renewed.connect(crit_success.set_false)
	timer.timeout.connect(timer_timeout)
	gv.add_child(timer)
	timer.one_shot = true
	start_timer()
	
	log_rates()




# - Signals


func timer_timeout() -> void:
	will.amount.subtract_pending(inhand)
	will.add(inhand)
	if th.xp_unlocked.is_true():
		xp.add(inhand_xp)
		wa.add(Currency.Type.XP, inhand_xp)
		inhand_xp.reset()
	if crit_success.is_true():
		wa.get_currency(Currency.Type.COIN).amount.subtract_pending(inhand_coin)
		wa.add(Currency.Type.COIN, inhand_coin)
		if th.crit_chance.less(100):
			wa.get_currency(Currency.Type.COIN).gain_rate.remove_change("added", self)
		inhand_coin.reset()
	crit_multiplier.reset()
	start_timer()


func xp_filled() -> void:
	xp.subtract(xp.get_total())
	level.add(1)


func level_changed() -> void:
	output_multiplier.m(th.output_increase_range.get_random_point())
	xp_modifier.multiply(th.xp_increase_range.get_random_point())
	duration_modifier.multiply(th.duration_increase_range.get_random_point())


func xp_modifier_changed() -> void:
	xp.total.edit_change("multiplied", self, xp_modifier.get_value())


func global_xp_multiplier_changed() -> void:
	xp.total.edit_change(
		"multiplied",
		th.xp_multiplier,
		th.xp_multiplier.get_value()
	)



# - Internal


func log_rates() -> void:
	wa.get_currency(
		Currency.Type.XP
	).gain_rate.edit_change(
		"added", self, Big.new(inhand_xp).d(timer.wait_time)
	)
	will.gain_rate.edit_change("added", self, get_output_rate())
	if crit_success.is_true():
		wa.get_currency(
			Currency.Type.COIN
		).gain_rate.edit_change(
			"added", self, Big.new(inhand_coin).d(timer.wait_time)
		)


func start_timer() -> void:
	set_inhand()
	timer.start(get_random_duration())
	timer_started.emit()
	log_rates()
	inhand_currency = Currency.Type.WILL


func set_inhand() -> void:
	var new_inhand := get_random_output()
	var new_inhand_xp = th.xp_output_range.get_random_point()
	
	if randf_range(0, 100) < th.crit_chance.get_value():
		crit_multiplier.multiply(th.crit_range.get_random_point())
		inhand_coin.set_to(th.crit_coin_output.get_random_point())
		wa.get_currency(Currency.Type.COIN).amount.add_pending(inhand_coin)
		while randf_range(0, 100) < th.crit_crit_chance.get_value():
			crit_multiplier.multiply(th.crit_range.get_random_point())
		new_inhand.m(crit_multiplier.get_value())
		if th.crits_apply_to_xp.is_true():
			new_inhand_xp *= crit_multiplier.get_value()
		if th.crits_apply_to_coin.is_true():
			inhand_coin.m(crit_multiplier.get_value())
	
	inhand.set_to(new_inhand)
	inhand_xp.set_to(new_inhand_xp)
	wa.get_currency(Currency.Type.XP).amount.add_pending(inhand_xp)
	will.amount.add_pending(inhand)


#region Action


func reset() -> void:
	timer.stop()
	level.reset()
	output_multiplier.reset()
	xp_modifier.reset()
	xp.reset()
	inhand.reset()
	inhand_coin.reset()
	inhand_xp.reset()
	crit_multiplier.reset()


#endregion



#region Get


func get_minimum_output() -> Big:
	return Big.new(output_multiplier).m(th.output_range.get_current())


func get_maximum_output() -> Big:
	return Big.new(output_multiplier).m(th.output_range.get_total())


func get_random_output() -> Big:
	return Big.new(output_multiplier).m(th.output_range.get_random_point())


func get_random_duration() -> float:
	return duration_modifier.get_value() * th.duration_range.get_random_point()


func get_minimum_duration() -> float:
	return duration_modifier.get_value() * th.duration_range.get_current()


func get_maximum_duration() -> float:
	return duration_modifier.get_value() * th.duration_range.get_total()


func get_output_rate() -> Big:
	var rate := Big.new(inhand).d(timer.time_left)
	return rate


#endregion
