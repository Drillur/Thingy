class_name Cost
extends RefCounted



var amount := {}
var affordable := LoudBool.new(false)
var times_purchased := LoudInt.new(0)
var increase_multiplier: float
var longest_eta_currency_type := -1



func _init(_amount: Dictionary) -> void:
	amount = _amount
	check()
	for cur in amount:
		wa.get_currency(cur).amount.increased.connect(currency_amount_increased)
		wa.get_currency(cur).amount.decreased.connect(currency_amount_decreased)




# - Signal


func currency_amount_increased() -> void:
	if affordable.is_true():
		return
	if can_afford():
		affordable.set_to(true)


func currency_amount_decreased() -> void:
	if affordable.is_false():
		return
	if not can_afford():
		affordable.set_to(false)



# - Internal


func check() -> void:
	if can_afford():
		affordable.set_to(true)
	else:
		affordable.set_to(false)


func can_afford() -> bool:
	for cur in amount:
		if wa.get_amount(cur).less(get_amount_value(cur)):
			return false
	return true




# - Action


func spend() -> void:
	for cur in amount:
		wa.subtract(cur, get_amount_value(cur))


func increase() -> void:
	for cur in amount:
		amount[cur].increase_multiplied(increase_multiplier)
	check()



# - Get


func get_amount_value(cur: Currency.Type) -> Big:
	return amount[cur].get_value()


func get_eta() -> Big:
	longest_eta_currency_type = amount.keys()[0]
	
	var eta: Big = wa.get_currency(longest_eta_currency_type).get_eta(amount.values()[0].get_value())
	for i in amount.size():
		var cur = wa.get_currency(amount.keys()[i]) as Currency
		
		if cur.net_rate.positive.is_false():
			longest_eta_currency_type = -1
			return Big.new(0)
		
		var i_eta = cur.get_eta(amount.values()[i].get_value())
		if i_eta.greater(eta):
			eta = i_eta
			longest_eta_currency_type = cur.type
	
	return Big.new(eta)


func get_progress_percent() -> float:
	#if (
		#currencies_are_unlocked
		#and not lv.any_loreds_in_list_are_inactive(produced_by)
		#and not longest_eta_currency_type == -1
	#):
		#var count = wa.get_count(longest_eta_currency_type)
		#var _amount = amount[longest_eta_currency_type].get_value()
		#return count.percent(_amount)
	
	var total_percent = amount.size()
	var percent := 0.0
	for cur in amount:
		var currency = wa.get_currency(cur)
		var _amount = amount[cur].get_value()
		percent += currency.get_amount().percent(_amount)
	return percent / total_percent
