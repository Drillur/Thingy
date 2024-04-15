class_name Inhand
extends Resource



@export var output := {}
@export var input := {}

var thingy: Thingy



func _init(_thingy: Thingy) -> void:
	thingy = _thingy



#region Action


func add_output(_output: Dictionary) -> void:
	for currency_type in _output:
		output[currency_type] = _output[currency_type]


func edit_pending() -> void:
	for currency_type in output.keys():
		var currency := wa.get_currency(currency_type)
		currency.edit_pending(self, output[currency_type])


func clear_pending() -> void:
	for x in output.keys():
		var currency := wa.get_currency(x)
		currency.remove_pending(self)


func add_currencies() -> void:
	for x in output.keys():
		wa.add(x, output[x])


func log_rates() -> void:
	var minimum_duration := thingy.get_minimum_duration()
	for currency_type in Currency.Type.values():
		if Currency.is_invalid(currency_type):
			continue
		var gain_rate: Value = wa.get_currency(currency_type).gain_rate
		if not currency_type in output.keys():
			gain_rate.remove_added(thingy)
			continue
		match Settings.rate_mode.get_value():
			wa.RateMode.LIVE:
				gain_rate.edit_added(
					thingy,
					Big.new(output[currency_type]).d(thingy.timer.wait_time.get_value())
				)
			wa.RateMode.MINIMUM:
				match currency_type:
					Currency.Type.WILL:
						gain_rate.edit_added(
							thingy,
							thingy.get_minimum_output().d(minimum_duration)
						)
					Currency.Type.XP:
						gain_rate.edit_added(
							self,
							thingy.get_minimum_xp_output() / minimum_duration
						)
					Currency.Type.JUICE:
						gain_rate.edit_added(
							self,
							thingy.get_minimum_juice_output() / minimum_duration
						)
					Currency.Type.COIN:
						gain_rate.edit_added(
							self,
							thingy.get_minimum_coin_output() * 
							thingy.get_crit_chance_divider() / minimum_duration
						)


func refund() -> void:
	refund_input()
	clear_pending()
	clear()


func refund_input() -> void:
	for currency_type in input.keys():
		wa.add(currency_type, input[currency_type])


func clear() -> void:
	clear_pending()
	input.clear()
	output.clear()


#endregion


#region Get


func has_input() -> bool:
	return input.size() > 0


func output_has(_currency_type: Currency.Type) -> bool:
	return output.has(_currency_type)


#endregion


#region Dev


func report() -> void:
	print_debug("Report for Inhand ", self, ":")
	#print_debug(" - Output: ", output.get_text())
	#print_debug(" - Output Currency: ", Currency.Type.keys()[output_currency_type])


#endregion
