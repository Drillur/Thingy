class_name Thingy
extends Resource



signal died

#static var total_levels := LoudInt.new(0)

@export var _class_name := "Thingy"
@export var index: int
@export var color := LoudColor.new(th.next_thingy_color.get_value())

@export var level := LoudInt.new(1)
@export var xp := ValuePair.new(10.0).do_not_cap_current()

@export var output_multiplier := Big.new(1.0)
@export var xp_multiplier := LoudFloat.new(1.0)
@export var crit_multiplier := LoudFloat.new(1.0)
@export var juiced_multiplier := LoudFloat.new(1.0)
@export var duration_multiplier := LoudFloat.new(1.0)
@export var coin_output_multiplier := LoudFloat.new(1.0)
@export var juice_input_multiplier := LoudFloat.new(1.0)
@export var juice_output_multiplier := Big.new(1.0)

@export var inhand := Inhand.new(self)
@export var juiced := LoudBool.new(false)
@export var output_currency := LoudString.new("")
@export var crit_success := LoudBool.new(false)

@export var timer := LoudTimer.new(1.0, 1.0)
@export var next_job_haste_divider := LoudFloat.new(1.0)
var just_born := true
var details = Details.new()
var persist := Persist.new()
var crit_rolls := LoudInt.new(0)



func _init(_index: int) -> void:
	index = _index
	#Thingy.total_levels.book.add_adder(level)
	persist.failed_persist_check.connect(reset)
	details.set_color(color.get_value())
	xp.current.current.change_base(0.0)
	xp.current.reset()
	xp.full.became_true.connect(xp_filled)
	xp.total.book.add_multiplier(xp_multiplier)
	xp.total.book.add_multiplier(th.xp_multiplier)
	level.increased.connect(level_increased)
	crit_multiplier.changed_to_not_equal_to_one.connect(crit_success.set_true)
	crit_multiplier.reset_to_base.connect(crit_success.set_false)
	juice_input_multiplier.changed.connect(juice_input_multiplier_changed)
	juice_input_multiplier_changed()
	juiced.changed.connect(juiced_changed)
	timer.timeout.connect(timer_timeout)
	Settings.rate_mode.changed.connect(rate_mode_changed)
	rate_mode_changed()
	timer.started.connect(log_rates)
	timer.wait_time_range.total.book.add_multiplier(th.duration_range.total)
	timer.wait_time_range.current.book.add_multiplier(th.duration_range.current)
	timer.wait_time_range.total.book.add_multiplier(duration_multiplier)
	timer.wait_time_range.current.book.add_multiplier(duration_multiplier)
	timer.wait_time_range.total.book.add_divider(juiced_multiplier)
	timer.wait_time_range.current.book.add_divider(juiced_multiplier)
	
	th.crit_rolls.changed.connect(update_crit_rolls)
	th.duration_range.changed.connect(update_crit_rolls)
	duration_multiplier.changed.connect(update_crit_rolls)
	th.crit_rolls_from_duration.changed.connect(update_crit_rolls)
	th.crit_rolls_from_duration_count.changed.connect(update_crit_rolls)
	
	if gv.root_ready.is_false():
		SaveManager.loading.became_false.connect(first_start)
		if not SaveManager.can_load_game():
			gv.root_ready.became_true.connect(first_start)
	else:
		start_timer()


func first_start() -> void:
	await th.get_tree().physics_frame
	await th.get_tree().physics_frame
	if should_resume_task_from_previous_game():
		inhand.edit_pending()
		timer.resume_from_load()
	else:
		start_timer()



#region Signals


func reset() -> void:
	timer.stop()
	remove_rates()
	th.thingies.erase(self)
	died.emit()


func timer_timeout() -> void:
	inhand.add_currencies()
	if inhand.output.has("XP"):
		xp.add(inhand.output["XP"])
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
	while xp.current.greater_equal(xp.get_total()):
		xp.subtract(xp.get_total())
		level.add(1)


func level_increased() -> void:
	output_multiplier.m(th.output_increase_range.get_random_point())
	xp_multiplier.multiply(th.xp_increase_range.get_random_point())
	duration_multiplier.multiply(th.duration_increase_range.get_random_point())
	juice_input_multiplier.multiply(th.juice_input_increase_range.get_random_point())
	juice_output_multiplier.m(th.juice_output_increase_range.get_random_point())
	coin_output_multiplier.multiply(th.coin_increase.get_random_point())


func juiced_changed() -> void:
	if juiced.is_true():
		juiced_multiplier.set_to(
			th.juice_multiplier_range.get_random_point() * (
				crit_multiplier.get_value() if crit_success.is_true() else 1.0
			)
		)
	elif juiced.is_false():
		juiced_multiplier.reset()


func juice_input_multiplier_changed() -> void:
	th.max_juice_use.edit_added(self, get_maximum_juice_input() * 2)


func rate_mode_changed() -> void:
	remove_rates()
	log_rates()


func update_crit_rolls() -> void:
	crit_rolls.set_to(th.crit_rolls.get_value() + get_crit_rolls_from_duration())


#endregion


# - Internal


func start_timer() -> void:
	output_currency.set_to(get_output_currency())
	juiced.set_to(should_juice())
	set_inhands()
	timer.start()


func get_output_currency() -> String:
	if (
		wa.is_unlocked("JUICE")
		and (
			(
				th.smart_juice.is_true()
				and wa.get_effective_amount("JUICE").less(
					th.max_juice_use.get_value()
				)
			)
			or (
				th.smart_juice.is_false()
				and wa.get_amount("JUICE").less(get_maximum_juice_input()
				)
			)
		)
	):
		return "JUICE"
	return "WILL"


func set_inhands() -> void:
	# Crit rolls
	roll_for_crits()
	if crit_success.is_true():
		roll_for_lucky_crits()
		if th.crits_apply_to_duration.is_true():
			timer.wait_time_range.current.edit_divided(crit_multiplier, crit_multiplier.get_value())
			timer.wait_time_range.total.edit_divided(crit_multiplier, crit_multiplier.get_value())
	
	if next_job_haste_divider.greater(1.0):
		timer.wait_time_range.current.edit_divided(next_job_haste_divider, next_job_haste_divider.get_value())
		timer.wait_time_range.total.edit_divided(next_job_haste_divider, next_job_haste_divider.get_value())
	inhand = Inhand.new(self)
	set_inhand_xp()
	set_coin_inhand()
	match output_currency.get_value():
		"WILL":
			set_inhand_will()
		"JUICE":
			set_inhand_juice()
	inhand.edit_pending()


func set_inhand_will() -> void:
	inhand.add_output(
		{
			"WILL": (
				get_random_output().m(
					crit_multiplier.get_value() if crit_success.is_true() else 1.0
				).m(
					juiced_multiplier.get_value() if juiced.is_true() else 1.0
				)
			)
		}
	)


func set_inhand_juice() -> void:
	inhand.add_output({"JUICE":
		Big.new(get_random_juice_output()).m(
			crit_multiplier.get_value() if crit_success.is_true() else 1.0
		).m(
			juiced_multiplier.get_value() if juiced.is_true() else 1.0
		)
	})


func set_inhand_xp() -> void:
	if not wa.is_unlocked("XP"):
		return
	var new_inhand = th.xp_output_range.get_random_point()
	if juiced.is_true():
		new_inhand *= juiced_multiplier.get_value()
	if crit_success.is_true() and th.crits_apply_to_xp.is_true():
		new_inhand *= crit_multiplier.get_value()
	if th.duration_affects_xp_output.is_true():
		new_inhand *= max(1, timer.get_wait_time())
	inhand.add_output({"XP": new_inhand})


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
	inhand.add_output({"COIN": Big.new(new_inhand)})


func log_rates() -> void:
	inhand.log_rates()


func remove_rates() -> void:
	for key in Currency.data.keys():
		wa.get_currency(key).gain_rate.remove_added(self)


func should_juice() -> bool:
	var amount_juice_drank = get_random_juice_input()
	if wa.can_afford("JUICE", amount_juice_drank):
		wa.subtract("JUICE", amount_juice_drank)
		return true
	return false


#region Action


func roll_for_crits() -> void:
	var roll: float
	for x in crit_rolls.get_value():
		roll = randf()
		if roll < get_crit_chance() / 100:
			crit_multiplier.multiply(th.crit_range.get_random_point())


func roll_for_lucky_crits() -> void:
	while randf_range(0, 100) < get_lucky_crit_chance():
		crit_multiplier.multiply(th.crit_range.get_random_point())


#endregion



#region Get


func is_working() -> bool:
	return timer.is_running()


func should_resume_task_from_previous_game() -> bool:
	if timer.running.is_false():
		return false
	if inhand == null:
		return false
	return true


func get_crit_chance() -> float:
	return th.crit_chance.get_value()


func get_lucky_crit_chance() -> float:
	return th.crit_crit_chance.get_value()


func get_crit_chance_divider() -> float:
	return th.crit_chance.get_value() / 100


func get_crit_rolls_from_duration() -> int:
	if th.crit_rolls_from_duration.is_false():
		return 0
	return floori(get_maximum_duration() / th.crit_rolls_from_duration_count.get_value())


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
	return duration_multiplier.get_value() * th.duration_range.get_random_point()


func get_minimum_duration() -> float:
	return duration_multiplier.get_value() * th.duration_range.get_current()


func get_maximum_duration() -> float:
	return duration_multiplier.get_value() * th.duration_range.get_total()


func get_minimum_juice_input() -> float:
	return juice_input_multiplier.get_value() * th.juice_input_range.get_current()


func get_random_juice_input() -> float:
	return juice_input_multiplier.get_value() * th.juice_input_range.get_random_point()


func get_maximum_juice_input() -> float:
	return juice_input_multiplier.get_value() * th.juice_input_range.get_total()


func get_minimum_juice_output() -> Big:
	return Big.new(juice_output_multiplier.get_value()).m(th.juice_output_range.get_current())


func get_random_juice_output() -> Big:
	return Big.new(juice_output_multiplier.get_value()).m(th.juice_output_range.get_random_point())


func get_maximum_juice_output() -> Big:
	return Big.new(juice_output_multiplier.get_value()).m(th.juice_output_range.get_total())


#endregion
