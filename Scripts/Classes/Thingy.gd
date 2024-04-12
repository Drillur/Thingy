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
var inhand: Inhand
var persist := Persist.new()

var index: int
var just_born := true
var details = Details.new()
var timer := LoudTimer.new(1.0, 1.0)
var next_job_haste_divider := LoudFloat.new(1.0)



func _init(_index: int) -> void:
	index = _index
	persist.failed_persist_check.connect(reset)
	kill_me.connect(th.thingy_wants_to_fucking_die)
	details.set_color(color.get_value())
	xp.current.current.change_base(0.0)
	xp.current.reset()
	xp.full.became_true.connect(xp_filled)
	xp.total.book.add_multiplier(xp_modifier)
	xp.total.book.add_multiplier(th.xp_multiplier)
	level.changed.connect(level_changed)
	crit_multiplier.became_not_1.connect(crit_success.set_true)
	crit_multiplier.renewed.connect(crit_success.set_false)
	juice_input_modifier.changed.connect(juice_input_modifier_changed)
	juice_input_modifier_changed()
	juiced.became_true.connect(juiced_became_true)
	timer.timeout.connect(timer_timeout)
	Settings.rate_mode.changed.connect(rate_mode_changed)
	rate_mode_changed()
	timer.started.connect(log_rates)
	timer.wait_time_range.current.book.add_multiplier(th.duration_range.current)
	timer.wait_time_range.current.book.add_multiplier(duration_modifier)
	timer.wait_time_range.total.book.add_multiplier(duration_modifier)
	timer.wait_time_range.total.book.add_multiplier(th.duration_range.total)
	
	if gv.root_ready.is_false():
		SaveManager.loading.became_false.connect(first_start)
		if not SaveManager.can_load_game():
			gv.root_ready.became_true.connect(first_start)
	else:
		start_timer()


func first_start() -> void:
	await th.get_tree().physics_frame
	await th.get_tree().physics_frame
	start_timer()



#region Signals


func reset() -> void:
	timer.stop()
	remove_rates()
	kill_me.emit(index)


func timer_timeout() -> void:
	inhand.add_currencies()
	if inhand.output_has(Currency.Type.XP):
		xp.add(inhand.output[Currency.Type.XP])
	inhand.clear()
	inhand = null
	if th.crits_apply_to_next_job_duration.is_true():
		if next_job_haste_divider.greater(1.0):
			next_job_haste_divider.reset()
			timer.wait_time_range.current.remove_divided(next_job_haste_divider)
			timer.wait_time_range.total.remove_divided(next_job_haste_divider)
		if crit_success.is_true():
			next_job_haste_divider.set_to(crit_multiplier.get_value())
	crit_multiplier.reset()
	if th.crits_apply_to_duration.is_true():
		timer.wait_time_range.current.remove_divided(crit_multiplier)
		timer.wait_time_range.total.remove_divided(crit_multiplier)
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


func juiced_became_true() -> void:
	juiced_multiplier.set_to(
		th.juice_multiplier_range.get_random_point() * (
			crit_multiplier.get_value() if crit_success.is_true() else 1.0
		)
	)
	timer.divide_wait_time(juiced_multiplier, juiced_multiplier.get_value())


func juice_input_modifier_changed() -> void:
	th.max_juice_use.edit_added(self, get_maximum_juice_input() * 2)


func rate_mode_changed() -> void:
	remove_rates()
	log_rates()


#endregion


# - Internal


func start_timer() -> void:
	output_currency.set_to(get_output_currency())
	juiced.set_to(should_juice())
	set_inhands()
	timer.start()


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
		if th.crits_add_to_all_output.is_true():
			th.all_output.add(0.01)
		if th.crits_apply_to_duration.is_true():
			timer.wait_time_range.current.edit_divided(crit_multiplier, crit_multiplier.get_value())
			timer.wait_time_range.total.edit_divided(crit_multiplier, crit_multiplier.get_value())
	if next_job_haste_divider.greater(1.0):
		timer.wait_time_range.current.edit_divided(next_job_haste_divider, next_job_haste_divider.get_value())
		timer.wait_time_range.total.edit_divided(next_job_haste_divider, next_job_haste_divider.get_value())
	inhand = Inhand.new()
	set_inhand_xp()
	set_coin_inhand()
	match output_currency.get_value():
		Currency.Type.WILL:
			set_inhand_will()
		Currency.Type.JUICE:
			set_inhand_juice()
	inhand.edit_pending()


func set_inhand_will() -> void:
	inhand.add_output({Currency.Type.WILL:
		get_random_output().m(
			crit_multiplier.get_value() if crit_success.is_true() else 1.0
		).m(
			juiced_multiplier.get_value() if juiced.is_true() else 1.0
		)
	})


func set_inhand_juice() -> void:
	inhand.add_output({Currency.Type.JUICE:
		get_random_output().m(
			crit_multiplier.get_value() if crit_success.is_true() else 1.0
		).m(
			juiced_multiplier.get_value() if juiced.is_true() else 1.0
		)
	})


func set_inhand_xp() -> void:
	if not wa.is_unlocked(Currency.Type.XP):
		return
	var new_inhand = th.xp_output_range.get_random_point()
	if juiced.is_true():
		new_inhand *= juiced_multiplier.get_value()
	if crit_success.is_true() and th.crits_apply_to_xp.is_true():
		new_inhand *= crit_multiplier.get_value()
	if th.duration_affects_xp_output.is_true():
		new_inhand *= max(1, timer.wait_time)
	inhand.add_output({Currency.Type.XP: new_inhand})


func set_coin_inhand() -> void:
	if crit_success.is_false():
		return
	var new_inhand := th.crit_coin_output.get_random_point()
	if juiced.is_true():
		new_inhand *= juiced_multiplier.get_value()
	if th.crits_apply_to_coin.is_true():
		new_inhand *= crit_multiplier.get_value()
	if th.crits_apply_to_coin_twice.is_true():
		new_inhand *= crit_multiplier.get_value()
	inhand.add_output({Currency.Type.COIN: Big.new(new_inhand)})


func log_rates() -> void:
	match Settings.rate_mode.get_value():
		wa.RateMode.LIVE:
			if Currency.Type.WILL in inhand.output.keys():
				wa.get_currency(Currency.Type.WILL).gain_rate.edit_added(
					self, Big.new(inhand.output[Currency.Type.WILL]).d(timer.wait_time)
				)
			elif Currency.Type.JUICE in inhand.output.keys():
				wa.get_currency(Currency.Type.JUICE).gain_rate.edit_added(
					self, Big.new(inhand.output[Currency.Type.JUICE]).d(timer.wait_time)
				)
			if wa.is_unlocked(Currency.Type.XP):
				wa.get_currency(Currency.Type.XP).gain_rate.edit_added(
					self,
					Big.new(inhand.output[Currency.Type.XP]).d(timer.wait_time)
				)
			if crit_success.is_true():
				wa.get_currency(Currency.Type.COIN).gain_rate.edit_added(
					self,
					Big.new(inhand.output[Currency.Type.COIN]).d(timer.wait_time)
				)
		wa.RateMode.MINIMUM:
			wa.get_currency(Currency.Type.WILL).gain_rate.edit_added(
				self, get_minimum_output().d(get_minimum_duration())
			)
			if wa.is_unlocked(Currency.Type.XP):
				wa.get_currency(Currency.Type.XP).gain_rate.edit_added(
					self, get_minimum_xp_output() / get_minimum_duration()
				)
			if wa.is_unlocked(Currency.Type.JUICE):
				wa.get_currency(Currency.Type.JUICE).gain_rate.edit_added(
					self, get_minimum_juice_output() / get_minimum_duration()
				)
			var coin_rate = (
				get_minimum_coin_output() * get_crit_chance_divider()
			) / get_minimum_duration()
			wa.get_currency(Currency.Type.COIN).gain_rate.edit_added(
				self, coin_rate
			)


func remove_rates() -> void:
	wa.get_currency(Currency.Type.WILL).gain_rate.remove_added(self)
	wa.get_currency(Currency.Type.XP).gain_rate.remove_added(self)
	wa.get_currency(Currency.Type.JUICE).gain_rate.remove_added(self)
	wa.get_currency(Currency.Type.COIN).gain_rate.remove_added(self)


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
