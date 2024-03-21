class_name ValuePair
extends Resource



@export var current: Value
@export var saved_total: Big

var cap_current := true
var total: Value

var full := LoudBool.new(false)
var empty := LoudBool.new(false)



func _init(base_value = 1.0, base_total = base_value) -> void:
	current = Value.new(base_value)
	total = Value.new(base_total)
	
	current.changed.connect(emit_changed)
	current.changed.connect(check_if_full)
	current.decreased.connect(check_if_empty)
	total.changed.connect(emit_changed)
	total.changed.connect(check_if_full)
	total.changed.connect(check_if_empty)
	
	check_if_full()
	check_if_empty()
	SaveManager.loading.became_false.connect(load_finished)



#region Signals


func load_finished() -> void:
	if saved_total:
		total.set_to(saved_total)
	if cap_current:
		check_if_full()


func check_if_full() -> void:
	if get_current().greater(get_total()):
		if cap_current:
			fill()
		full.set_true()
	elif get_current().equal(get_total()):
		full.set_true()
	else:
		full.set_false()


func check_if_empty() -> void:
	empty.set_to(current.equal(0))


#endregion



# - Actions

func reset():
	current.reset()
	total.reset()


func change_base(new_base_value: float) -> void:
	current.change_base(new_base_value)


func do_not_cap_current() -> ValuePair:
	cap_current = false
	return self



func add(amount) -> void:
	amount = set_amount_to_deficit_if_necessary(amount)
	current.add(amount)


func add_one() -> void:
	add(1)


func subtract(amount) -> void:
	if not amount is Big:
		amount = Big.new(amount)
	current.subtract(amount)


func add_percent(percent: float) -> void:
	var amount = Big.new(percent).m(get_total())
	add(amount)


func set_amount_to_deficit_if_necessary(amount) -> Big:
	if not amount is Big:
		amount = Big.new(amount)
	if not cap_current:
		return amount
	var deficit = get_deficit()
	if deficit.less(amount):
		return deficit
	if not amount is Big:
		amount = Big.new(amount)
	return amount



func increase_added(amount) -> void:
	total.increase_added(amount)


func decrease_added(amount) -> void:
	total.decrease_added(amount)


func increase_subtracted(amount) -> void:
	total.increase_subtracted(amount)


func decrease_subtracted(amount) -> void:
	total.decrease_subtracted(amount)


func increase_multiplied(amount) -> void:
	total.increase_multiplied(amount)


func decrease_multiplied(amount) -> void:
	total.decrease_multiplied(amount)


func increase_divided(amount) -> void:
	total.increase_divided(amount)


func decrease_divided(amount) -> void:
	total.decrease_divided(amount)


func set_from_level(amount) -> void:
	if not amount is Big:
		amount = Big.new(amount)
	total.set_from_level(amount)


func set_d_from_lored(amount) -> void:
	if not amount is Big:
		amount = Big.new(amount)
	total.set_d_from_lored(amount)


func set_m_from_lored(amount) -> void:
	if not amount is Big:
		amount = Big.new(amount)
	total.set_m_from_lored(amount)


func set_to(amount) -> void:
	if not amount is Big:
		amount = Big.new(amount)
	current.set_to(amount)
	if full.is_true() and cap_current:
		current.set_to(get_total())


func set_to_percent(percent: float, with_random_range := false) -> void:
	var multiplier := randf_range(0.8, 1.2) if with_random_range else 1.0
	multiplier *= percent
	set_to(Big.new(get_total()).m(multiplier))


func fill() -> void:
	if full.is_false():
		set_to(get_total())


func save_total() -> void:
	saved_total = get_total()



# - Get


func get_current() -> Big:
	return current.current


func get_value() -> Big:
	return get_current()


func get_current_percent() -> float:
	return current.current.percent(get_total())


func get_pending() -> Big:
	return current.get_pending()


func get_pending_percent() -> float:
	return current.get_effective_amount().percent(get_total())


func get_x_percent(float_between_0_and_1: float) -> Big:
	return Big.new(get_total()).m(float_between_0_and_1)


func get_x_percent_text(percent: float) -> String:
	return get_x_percent(percent).text


func get_randomized_total(min_range := 0.8, max_range := 1.2) -> Big:
	return Big.new(get_total()).m(randf_range(min_range, max_range))


func get_midpoint() -> Big:
	if full.is_true():
		return get_total()
	return Big.new(get_current()).a(get_total()).d(2)


func get_random_point() -> Big:
	if full.is_true():
		return get_total()
	return Big.new(randf_range(get_current().toFloat(), get_total().toFloat()))


func get_total() -> Big:
	return total.current


func get_total_text() -> String:
	return total.get_text()


func get_as_float() -> float:
	return total.get_as_float()


func get_as_int() -> int:
	return total.get_as_int()


func get_current_text() -> String:
	return current.get_text()


func get_deficit() -> Big:
	return Big.new(total.current).s(current.current)


func get_surplus() -> Big:
	if current.current.greater_equal(total.current):
		return Big.new(current.current).s(total.current)
	return Big.new(0)


func get_base() -> Big:
	return total.base


func get_deficit_text() -> String:
	return get_deficit().text


func get_deficit_text_plus_one() -> String:
	return get_deficit().a(1).text


func get_text() -> String:
	return get_current_text() + "/" + get_total_text()


func is_empty() -> bool:
	return get_current().equal(0)


func is_full() -> bool:
	return get_current().greater_equal(get_total())


func is_not_full() -> bool:
	return not is_full()




#region Dev


func report() -> void:
	printt("Report for ValuePair ", self, " - Current/Total:")
	current.report()
	total.report()
	printt("- - -")
#endregion
