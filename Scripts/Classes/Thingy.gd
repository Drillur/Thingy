class_name Thingy
extends Resource



signal kill_me

@export var _class_name := "Thingy"

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
	CRIT_CRIT,
	JUICE_OUTPUT_RANGE,
	JUICE_OUTPUT_RANGE_CURRENT,
	JUICE_OUTPUT_RANGE_TOTAL,
	JUICE_INPUT_RANGE,
	JUICE_INPUT_RANGE_CURRENT,
	JUICE_INPUT_RANGE_TOTAL,
	JUICE_OUTPUT_INCREASE_RANGE,
	JUICE_OUTPUT_INCREASE_RANGE_CURRENT,
	JUICE_OUTPUT_INCREASE_RANGE_TOTAL,
	JUICE_INPUT_INCREASE_RANGE,
	JUICE_INPUT_INCREASE_RANGE_CURRENT,
	JUICE_INPUT_INCREASE_RANGE_TOTAL,
	JUICE_MULTIPLIER_RANGE,
	JUICE_MULTIPLIER_RANGE_CURRENT,
	JUICE_MULTIPLIER_RANGE_TOTAL,
}

signal timer_started

@export var level := LoudInt.new(1)
@export var output_multiplier := Big.new(1.0)
@export var xp := ValuePair.new(10.0).do_not_cap_current()
@export var xp_modifier := LoudFloat.new(1.0)
@export var duration_modifier := LoudFloat.new(1.0)
@export var juice_output_modifier := LoudFloat.new(1.0)
@export var juice_input_modifier := LoudFloat.new(1.0)
@export var crit_multiplier := LoudFloat.new(1.0)
@export var juiced_multiplier := LoudFloat.new(1.0)
@export var output_currency := LoudInt.new(Currency.Type.WILL)
@export var color := LoudColor.new(th.next_thingy_color.get_value())

var juiced := LoudBool.new(false)
var crit_success := LoudBool.new(false)
var inhand_will := Big.new(0)
var inhand_coin := Big.new(0)
var inhand_xp := Big.new(0)
var inhand_juice := Big.new(0)
var persist := Persist.new()


var index: int
var just_born := true
var details = Details.new()
var timer := Timer.new()



func _init(_index: int) -> void:
	index = _index
	persist.failed_persist_check.connect(reset)
	kill_me.connect(th.thingy_wants_to_fucking_die)
	details.color = color.get_value()
	xp.current.current.change_base(0.0)
	xp.current.reset()
	xp.filled.connect(xp_filled)
	xp_modifier.changed.connect(xp_modifier_changed)
	level.changed.connect(level_changed)
	th.xp_multiplier.changed.connect(global_xp_multiplier_changed)
	global_xp_multiplier_changed()
	crit_multiplier.changed.connect(crit_success.set_true)
	crit_multiplier.renewed.connect(crit_success.set_false)
	output_currency.changed.connect(output_currency_changed)
	inhand_will.changed.connect(inhand_will_changed)
	inhand_xp.changed.connect(inhand_xp_changed)
	inhand_coin.changed.connect(inhand_coin_changed)
	inhand_juice.changed.connect(inhand_juice_changed)
	juice_input_modifier.changed.connect(juice_input_modifier_changed)
	juiced.became_true.connect(juiced_became_true)
	juice_input_modifier_changed()
	timer.timeout.connect(timer_timeout)
	Settings.rate_mode.changed.connect(rate_mode_changed)
	rate_mode_changed()
	
	gv.add_child(timer)
	timer.one_shot = true
	if gv.root_ready.is_false():
		gv.root_ready.became_true.connect(start_timer)
	else:
		start_timer()



#region Signals


func reset() -> void:
	timer.stop()
	remove_rates()
	kill_me.emit(index)


func timer_timeout() -> void:
	wa.add(Currency.Type.WILL, inhand_will)
	wa.add(Currency.Type.JUICE, inhand_juice)
	wa.add(Currency.Type.XP, inhand_xp)
	xp.add(inhand_xp)
	if crit_success.is_true():
		wa.add(Currency.Type.COIN, inhand_coin)
		if get_crit_chance() < 100:
			wa.get_currency(Currency.Type.COIN).gain_rate.remove_change("added", self)
			inhand_coin.reset()
	crit_multiplier.reset()
	juiced.reset()
	start_timer()


func xp_filled() -> void:
	xp.subtract(xp.get_total())
	level.add(1)


func level_changed() -> void:
	output_multiplier.m(th.output_increase_range.get_random_point())
	xp_modifier.multiply(th.xp_increase_range.get_random_point())
	duration_modifier.multiply(th.duration_increase_range.get_random_point())
	juice_input_modifier.multiply(th.juice_input_increase_range.get_random_point())
	juice_output_modifier.multiply(th.juice_output_increase_range.get_random_point())


func xp_modifier_changed() -> void:
	xp.total.edit_change("multiplied", self, xp_modifier.get_value())


func global_xp_multiplier_changed() -> void:
	xp.total.edit_change(
		"multiplied",
		th.xp_multiplier,
		th.xp_multiplier.get_value()
	)


func output_currency_changed() -> void:
	match output_currency.get_value():
		Currency.Type.WILL:
			if inhand_juice.greater(0):
				inhand_juice.reset()
		Currency.Type.JUICE:
			if inhand_will.greater(0):
				inhand_will.reset()


func inhand_will_changed() -> void:
	wa.get_currency(Currency.Type.WILL).amount.edit_change("pending", self, inhand_will)


func inhand_xp_changed() -> void:
	wa.get_currency(Currency.Type.XP).amount.edit_change("pending", self, inhand_xp)


func inhand_coin_changed() -> void:
	wa.get_currency(Currency.Type.COIN).amount.edit_change("pending", self, inhand_coin)


func inhand_juice_changed() -> void:
	wa.get_currency(Currency.Type.JUICE).amount.edit_change("pending", self, inhand_juice)


func juiced_became_true() -> void:
	juiced_multiplier.set_to(
		th.juice_multiplier_range.get_random_point() * (
			crit_multiplier.get_value() if crit_success.is_true() else 1.0
		)
	)
	timer.wait_time /= juiced_multiplier.get_value()


func juice_input_modifier_changed() -> void:
	th.max_juice_use.edit_change("added", self, get_maximum_juice_input() * 2)


func rate_mode_changed() -> void:
	if Settings.rate_mode.get_value() == wa.RateMode.MINIMUM:
		if not th.output_range.changed.is_connected(log_rates):
			th.output_range.changed.connect(log_rates)
			th.duration_range.changed.connect(log_rates)
			th.xp_output_range.changed.connect(log_rates)
			th.juice_output_range.changed.connect(log_rates)
			th.crit_coin_output.changed.connect(log_rates)
			th.crit_chance.changed.connect(log_rates)
			th.crits_apply_to_coin.became_true.connect(log_rates)
			th.crits_apply_to_coin_twice.became_true.connect(log_rates)
			output_multiplier.changed.connect(log_rates)
			duration_modifier.changed.connect(log_rates)
			juice_output_modifier.changed.connect(log_rates)
			crit_multiplier.changed.connect(log_rates)
	if Settings.rate_mode.get_value() != wa.RateMode.MINIMUM:
		if th.output_range.changed.is_connected(log_rates):
			th.output_range.changed.disconnect(log_rates)
			th.duration_range.changed.disconnect(log_rates)
			th.xp_output_range.changed.disconnect(log_rates)
			th.juice_output_range.changed.disconnect(log_rates)
			th.crit_coin_output.changed.disconnect(log_rates)
			th.crit_chance.changed.disconnect(log_rates)
			th.crits_apply_to_coin.became_true.disconnect(log_rates)
			th.crits_apply_to_coin_twice.became_true.disconnect(log_rates)
			output_multiplier.changed.disconnect(log_rates)
			duration_modifier.changed.disconnect(log_rates)
			juice_output_modifier.changed.disconnect(log_rates)
			crit_multiplier.changed.disconnect(log_rates)
	if Settings.rate_mode.get_value() == wa.RateMode.LIVE:
		if not timer_started.is_connected(log_rates):
			timer_started.connect(log_rates)
	if Settings.rate_mode.get_value() != wa.RateMode.LIVE:
		if timer_started.is_connected(log_rates):
			timer_started.disconnect(log_rates)
	remove_rates()
	log_rates()


#endregion


# - Internal


func start_timer() -> void:
	timer.wait_time = get_random_duration()
	output_currency.set_to(get_output_currency())
	juiced.set_to(should_juice())
	set_inhands()
	timer.wait_time = maxf(timer.wait_time, 0.05)
	timer.start()
	timer_started.emit()


func get_output_currency() -> Currency.Type:
	if (
		wa.is_unlocked(Currency.Type.JUICE)
		and (
			(
				th.smart_juice.is_true()
				and wa.get_effective_amount(Currency.Type.JUICE).less(
					th.max_juice_use.get_value()
				)
			)
			or (
				th.smart_juice.is_false()
				and wa.get_amount(Currency.Type.JUICE).less(
					get_maximum_juice_input()
				)
			)
		)
	):
		return Currency.Type.JUICE
	return Currency.Type.WILL


func set_inhands() -> void:
	if successful_crit_roll():
		roll_for_lucky_crits()
		if th.crits_apply_to_duration.is_true():
			timer.wait_time /= crit_multiplier.get_value()
	set_inhand_xp()
	set_coin_inhand()
	match output_currency.get_value():
		Currency.Type.WILL:
			set_inhand_will()
		Currency.Type.JUICE:
			set_inhand_juice()


func set_inhand_will() -> void:
	inhand_will.set_to(
		get_random_output().m(
			crit_multiplier.get_value() if crit_success.is_true() else 1.0
		).m(
			juiced_multiplier.get_value() if juiced.is_true() else 1.0
		)
	)


func set_inhand_juice() -> void:
	inhand_juice.set_to(
		get_random_juice_output() * (
			crit_multiplier.get_value() if crit_success.is_true() else 1.0
		) * (
			juiced_multiplier.get_value() if juiced.is_true() else 1.0
		)
	)


func set_inhand_xp() -> void:
	if not wa.is_unlocked(Currency.Type.XP):
		return
	var new_inhand = th.xp_output_range.get_random_point()
	if juiced.is_true():
		new_inhand *= juiced_multiplier.get_value()
	if crit_success.is_true() and th.crits_apply_to_xp.is_true():
		new_inhand *= crit_multiplier.get_value()
	if th.duration_applies_to_xp_output.is_true():
		new_inhand *= max(1, timer.wait_time)
	inhand_xp.set_to(new_inhand)


func set_coin_inhand() -> void:
	if crit_success.is_false():
		return
	var new_inhand = th.crit_coin_output.get_random_point()
	if juiced.is_true():
		new_inhand *= juiced_multiplier.get_value()
	if th.crits_apply_to_coin.is_true():
		new_inhand *= crit_multiplier.get_value()
	if th.crits_apply_to_coin_twice.is_true():
		new_inhand *= crit_multiplier.get_value()
	inhand_coin.set_to(new_inhand)


func log_rates() -> void:
	match Settings.rate_mode.get_value():
		wa.RateMode.LIVE:
			wa.get_currency(Currency.Type.WILL).gain_rate.edit_change(
				"added", self, Big.new(inhand_will).d(timer.wait_time)
			)
			wa.get_currency(Currency.Type.XP).gain_rate.edit_change(
				"added", self, Big.new(inhand_xp).d(timer.wait_time)
			)
			wa.get_currency(Currency.Type.JUICE).gain_rate.edit_change(
				"added", self, Big.new(inhand_juice).d(timer.wait_time)
			)
			if crit_success.is_true():
				wa.get_currency(Currency.Type.COIN).gain_rate.edit_change(
					"added", self, Big.new(inhand_coin).d(timer.wait_time)
				)
		wa.RateMode.MINIMUM:
			wa.get_currency(Currency.Type.WILL).gain_rate.edit_change(
				"added", self, get_minimum_output().d(get_minimum_duration())
			)
			wa.get_currency(Currency.Type.XP).gain_rate.edit_change(
				"added", self, get_minimum_xp_output() / get_minimum_duration()
			)
			wa.get_currency(Currency.Type.JUICE).gain_rate.edit_change(
				"added", self, get_minimum_juice_output() / get_minimum_duration()
			)
			var coin_rate = (
				get_minimum_coin_output() * get_crit_chance_divider()
			) / get_minimum_duration()
			wa.get_currency(Currency.Type.COIN).gain_rate.edit_change(
				"added", self, coin_rate
			)


func remove_rates() -> void:
	wa.get_currency(Currency.Type.WILL).gain_rate.remove_change("added", self)
	wa.get_currency(Currency.Type.XP).gain_rate.remove_change("added", self)
	wa.get_currency(Currency.Type.JUICE).gain_rate.remove_change("added", self)
	wa.get_currency(Currency.Type.COIN).gain_rate.remove_change("added", self)


func should_juice() -> bool:
	var juice_drank = get_random_juice_input()
	if wa.get_amount(Currency.Type.JUICE).greater_equal(juice_drank):
		wa.subtract(Currency.Type.JUICE, juice_drank)
		return true
	return false


#region Action


func successful_crit_roll() -> bool:
	if randf_range(0, 100) < get_crit_chance():
		crit_multiplier.multiply(th.crit_range.get_random_point())
		return true
	return false


func roll_for_lucky_crits() -> void:
	while randf_range(0, 100) < th.crit_crit_chance.get_value():
		crit_multiplier.multiply(th.crit_range.get_random_point())


#endregion



#region Get


func get_crit_chance() -> float:
	return th.crit_chance.get_value()


func get_crit_chance_divider() -> float:
	return th.crit_chance.get_value() / 100


func get_minimum_output() -> Big:
	return Big.new(output_multiplier).m(th.output_range.get_current())


func get_maximum_output() -> Big:
	return Big.new(output_multiplier).m(th.output_range.get_total())


func get_random_output() -> Big:
	return Big.new(output_multiplier).m(th.output_range.get_random_point())


func get_minimum_xp_output() -> float:
	return th.xp_output_range.get_current()


func get_minimum_coin_output() -> float:
	return th.crit_coin_output.get_current() * (
		th.crit_range.get_current() if th.crits_apply_to_coin.is_true() else 1.0 *
		th.crit_range.get_current() if th.crits_apply_to_coin_twice.is_true() else 1.0
	)


func get_random_duration() -> float:
	return duration_modifier.get_value() * th.duration_range.get_random_point()


func get_minimum_duration() -> float:
	return duration_modifier.get_value() * th.duration_range.get_current()


func get_maximum_duration() -> float:
	return duration_modifier.get_value() * th.duration_range.get_total()


func get_minimum_juice_input() -> float:
	return juice_input_modifier.get_value() * th.juice_input_range.get_current()


func get_random_juice_input() -> float:
	return juice_input_modifier.get_value() * th.juice_input_range.get_random_point()


func get_maximum_juice_input() -> float:
	return juice_input_modifier.get_value() * th.juice_input_range.get_total()


func get_minimum_juice_output() -> float:
	return juice_output_modifier.get_value() * th.juice_output_range.get_current()


func get_random_juice_output() -> float:
	return juice_output_modifier.get_value() * th.juice_output_range.get_random_point()


func get_maximum_juice_output() -> float:
	return juice_output_modifier.get_value() * th.juice_output_range.get_total()


#endregion
