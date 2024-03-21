class_name Inhand
extends Resource



var xp: LoudFloat
var coin: Big
var output := {}
var input := {}



#region Action


func add_output(_output: Dictionary) -> void:
	output[_output.keys()[0]] = _output.values()[0]


func set_xp(_xp: LoudFloat) -> void:
	xp = _xp
	var currency := wa.get_currency(Currency.Type.XP)
	currency.edit_pending(self, xp.get_value())
	add_output({Currency.Type.XP: xp.get_value()})


func set_coin(_coin: Big) -> void:
	coin = _coin
	var currency := wa.get_currency(Currency.Type.COIN)
	currency.edit_pending(self, coin)


func edit_pending() -> void:
	for x in output.keys():
		var currency := wa.get_currency(x)
		currency.edit_pending(self, output[x])
	


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


#endregion


#region Dev


func report() -> void:
	print_debug("Report for Inhand ", self, ":")
	#print_debug(" - Output: ", output.get_text())
	#print_debug(" - Output Currency: ", Currency.Type.keys()[output_currency_type])


#endregion
