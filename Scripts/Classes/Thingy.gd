class_name Thingy
extends Resource



enum Attribute {
	NONE,
	DURATION,
	OUTPUT,
	COST,
}

signal timer_started

var index: int
var just_born := true
var level := LoudInt.new(1)
var timer := Timer.new()
var xp := ValuePair.new(1.0).do_not_cap_current()
var pending_amount := Big.new(0)

var details = Details.new()

#region References
var gold: Currency = wa.get_currency(Currency.Type.GOLD)
#endregion



func _init(_index: int) -> void:
	index = _index
	details.color = th.next_thingy_color
	th.duration.changed.connect(duration_changed)
	th.duration_increase.changed.connect(duration_changed)
	th.duration_range.changed.connect(duration_changed)
	th.output.changed.connect(output_changed)
	th.output_increase.changed.connect(output_changed)
	th.output_range.changed.connect(output_changed)
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
	gold.add(get_random_output())
	if th.xp_unlocked.is_true():
		xp.add(th.xp_gain.get_value())
	start_timer()


func duration_changed() -> void:
	log_output_rate()
	#print("time left at point of duration change: ", timer.time_left, " - new duration: ", get_duration())


func output_changed() -> void:
	log_output_rate()
	update_pending_amount()


func xp_filled() -> void:
	xp.subtract(xp.get_total())
	level.add(1)


func level_changed() -> void:
	sync_xp()
	log_output_rate()
	update_pending_amount()



# - Internal


func sync_xp() -> void:
	xp.total.set_to(
		Big.new(th.xp_increase.get_value()).power(level.get_value() - 1).m(th.xp.get_value())
	)


func log_output_rate() -> void:
	var rate: Big = get_output_rate()
	gold.gain_rate.edit_change("added", self, rate)


func start_timer() -> void:
	timer.start(get_random_duration())
	timer_started.emit()
	update_pending_amount()


func update_pending_amount() -> void:
	if pending_amount.greater(0):
		gold.amount.subtract_pending(pending_amount)
	pending_amount.set_to(get_average_output())
	gold.amount.add_pending(pending_amount)



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
	var rate := get_average_output().d(get_average_duration())
	return rate
