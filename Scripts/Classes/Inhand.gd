class_name Inhand
extends Resource



var output := {}
var input := {}



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
