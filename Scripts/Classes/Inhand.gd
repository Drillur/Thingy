class_name Inhand
extends Resource



@export var output := {}
@export var input := {}

var thingy: Thingy



func _init(_thingy: Thingy) -> void:
	thingy = _thingy



#region Action


func add_output(_output: Dictionary) -> void:
	for key in _output:
		output[key] = _output[key]


func edit_pending() -> void:
	for key in output.keys():
		var currency := wa.get_currency(key)
		currency.edit_pending(self, output[key])


func clear_pending() -> void:
	for x in output.keys():
		var currency := wa.get_currency(x)
		currency.remove_pending(self)


func add_currencies() -> void:
	for x in output.keys():
		wa.add(x, output[x])


func log_rates() -> void:
	var minimum_duration := thingy.get_minimum_duration()
	for key in Currency.data.keys():
		var gain_rate: Value = wa.get_currency(key).gain_rate
		if not key in output.keys():
			gain_rate.remove_added(thingy)
			continue
		match Settings.rate_mode.get_value():
			wa.RateMode.LIVE:
				gain_rate.edit_added(
					thingy,
					Big.new(output[key]).d(thingy.timer.wait_time.get_value())
				)
			wa.RateMode.MINIMUM:
				match key:
					"WILL":
						gain_rate.edit_added(
							thingy,
							thingy.get_minimum_output().d(minimum_duration)
						)
					"XP":
						gain_rate.edit_added(
							thingy,
							thingy.get_minimum_xp_output() / minimum_duration
						)
					"JUICE":
						gain_rate.edit_added(
							thingy,
							thingy.get_minimum_juice_output() / minimum_duration
						)
					"COIN":
						gain_rate.edit_added(
							thingy,
							thingy.get_minimum_coin_output() * 
							thingy.get_crit_chance_divider() / minimum_duration
						)


func refund() -> void:
	refund_input()
	clear_pending()
	clear()


func refund_input() -> void:
	for key in input.keys():
		wa.add(key, input[key])


func clear() -> void:
	clear_pending()
	input.clear()
	output.clear()


#endregion


#region Get


func has_input() -> bool:
	return input.size() > 0


#endregion


#region Dev


func report() -> void:
	print_debug("Report for Inhand ", self, ":")
	#print_debug(" - Output: ", output.get_text())
	#print_debug(" - Output Currency: ", keys()[output_key])


#endregion
