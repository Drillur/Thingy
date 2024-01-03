class_name Thingy
extends Resource



enum Attribute {
	NONE,
	DURATION,
	OUTPUT,
	COST,
	CRIT,
}

signal timer_started

var index: int
var just_born := true
var level := LoudInt.new(1)
var timer := Timer.new()
var xp := ValuePair.new(1.0).do_not_cap_current()
var inhand := Big.new(0, true)
var crit_success := LoudBool.new(false)
var crit_multiplier := LoudFloat.new(1.0)
var inhand_currency: Currency.Type
#var critcrit_success := LoudBool.new(false)

var details = Details.new()

#region References
var will: Currency = wa.get_currency(Currency.Type.WILL)
#endregion



func _init(_index: int) -> void:
	index = _index
	details.color = th.next_thingy_color
	#th.duration.changed.connect(duration_changed)
	#th.duration_increase.changed.connect(duration_changed)
	#th.duration_range.changed.connect(duration_changed)
	#th.output.changed.connect(output_changed)
	#th.output_increase.changed.connect(output_changed)
	#th.output_range.changed.connect(output_changed)
	xp.set_to(0)
	xp.filled.connect(xp_filled)
	level.changed.connect(level_changed)
	
	timer.timeout.connect(timer_timeout)
	gv.add_child(timer)
	timer.one_shot = true
	start_timer()
	
	sync_xp()
	
	log_output_rate()




# - Signals


func timer_timeout() -> void:
	will.amount.subtract_pending(inhand)
	will.add(inhand)
	if th.xp_unlocked.is_true():
		xp.add(th.xp_gain.get_value())
	crit_success.reset()
	crit_multiplier.reset()
	#critcrit_success.reset()
	start_timer()


func duration_changed() -> void:
	pass#log_output_rate()
	#print("time left at point of duration change: ", timer.time_left, " - new duration: ", get_duration())


func output_changed() -> void:
	pass#log_output_rate()


func xp_filled() -> void:
	xp.subtract(xp.get_total())
	level.add(1)


func level_changed() -> void:
	sync_xp()



# - Internal


func sync_xp() -> void:
	xp.total.set_to(
		Big.new(th.xp_increase.get_value()).power(level.get_value() - 1).m(th.xp.get_value())
	)


func log_output_rate() -> void:
	var rate: Big = get_output_rate()
	will.gain_rate.edit_change("added", self, rate)


func start_timer() -> void:
	set_inhand()
	timer.start(get_random_duration())
	timer_started.emit()
	log_output_rate()
	inhand_currency = Currency.Type.WILL


func set_inhand() -> void:
	var new_inhand := get_random_output()
	if randf_range(0, 100) < th.crit_chance.get_value():
		crit_multiplier.multiply(th.crit_range.get_random_point_in_center())
		while randf_range(0, 100) < th.crit_crit_chance.get_value():
			crit_multiplier.multiply(th.crit_range.get_random_point_in_center())
		new_inhand.m(crit_multiplier.get_value())
		crit_success.set_to(true)
	inhand.set_to(new_inhand)
	will.amount.add_pending(inhand)



# - Get


func get_output() -> Big:
	return Big.new(th.output_increase).power(level.get_value() - 1).m(th.output.get_value())


func get_minimum_output() -> Big:
	return get_output().m(th.output_range.get_current())


func get_maximum_output() -> Big:
	return get_output().m(th.output_range.get_total())


func get_random_output() -> Big:
	return get_output().m(th.output_range.get_random_point_in_center())


func get_average_output() -> Big:
	var average_output := get_output().m(th.output_range.get_midpoint())
	return average_output


func get_duration() -> float:
	return pow(th.duration_increase.get_value(), level.get_value() - 1) * th.duration.get_value()


func get_random_duration() -> float:
	return get_duration() * th.duration_range.get_random_point_in_center()


func get_average_duration() -> float:
	var average_duration := get_duration() * th.duration_range.get_midpoint()
	return average_duration


func get_output_rate() -> Big:
	var rate := Big.new(inhand).d(timer.time_left)
	return rate
