class_name Price
extends Resource



signal purchase_requested

@export var times_purchased := LoudInt.new(0)

var owner_purchased := LoudBool.new(false)
var owner_unlocked := LoudBool.new(true)
var purchase_requested_cd := PhysicsCooldown.new(purchase_requested)
var currency_types: Array[Currency.Type]
var increase_modifier := LoudFloat.new(1.0)

var all_affordable := LoudBoolArray.new()

var price := {}
var affordable := {}



func _init(data: Dictionary) -> void:
	for currency_type in data.keys():
		add_price(currency_type, data[currency_type])


func add_price(_currency_type: Currency.Type, base_value) -> void:
	price[_currency_type] = Value.new(base_value)
	price[_currency_type].book.add_powerer(increase_modifier, times_purchased, 0)
	price[_currency_type].changed.connect(emit_changed)
	currency_types.append(_currency_type)
	var x = LoudBool.new(false)
	all_affordable.add_bool(x)
	
	# Check currency
	var check_currency = func():
		x.set_to(wa.can_afford(_currency_type, get_price(_currency_type)))
	times_purchased.renewed.connect(check_currency)
	owner_purchased.became_false.connect(check_currency)
	owner_unlocked.became_true.connect(check_currency)
	price[_currency_type].changed.connect(check_currency)
	check_currency.call()
	
	# Currency increased or decreased
	var currency_increased = func() -> void:
		if x.is_false():
			check_currency.call()
		emit_changed()
	var currency_decreased = func() -> void:
		if x.is_true():
			check_currency.call()
		emit_changed()
	
	# Update signal connections
	var currency_amount: Value = wa.get_currency(_currency_type).amount
	var update_calls = func():
		if owner_purchased.is_true() or owner_unlocked.is_false():
			if currency_amount.increased.is_connected(currency_increased):
				currency_amount.increased.disconnect(currency_increased)
			if currency_amount.decreased.is_connected(currency_decreased):
				currency_amount.decreased.disconnect(currency_decreased)
		else:
			if not currency_amount.increased.is_connected(currency_increased):
				currency_amount.increased.connect(currency_increased)
			if not currency_amount.decreased.is_connected(currency_decreased):
				currency_amount.decreased.connect(currency_decreased)
	owner_purchased.changed.connect(update_calls)
	owner_unlocked.changed.connect(update_calls)
	update_calls.call()



#region Signals




#endregion


#region Internal



#endregion


#region Action


func reset() -> void:
	times_purchased.reset()
	emit_changed()


func purchase() -> void:
	spend()
	if not times_purchased.copycat_var:
		times_purchased.add(1)


func spend() -> void:
	for currency_type in currency_types:
		wa.subtract(currency_type, get_price(currency_type))
	#check_all()
	emit_changed()


func refund() -> void:
	for currency_type in currency_types:
		wa.add(currency_type, get_price(currency_type))


func edit_change(currency_type: Currency.Type, source, amount) -> void:
	price[currency_type].edit_multiplied(source, amount)


func request_purchase(manual: bool, override_safe := false) -> void:
	if (
		gv.dev_mode and (
			manual
		)
		or (
			can_afford() and (
				manual
				or override_safe
			)
		)
	):
		purchase_requested_cd.emit()


func set_unlocked(_unlocked: LoudBool) -> void:
	owner_unlocked.copycat(_unlocked)


#endregion



#region Get


func can_afford() -> bool:
	return all_affordable.is_true()


func get_price(currency_type: Currency.Type) -> Big:
	return price[currency_type].get_value()


func get_price_dict() -> Dictionary:
	var dict := {}
	for currency_type in currency_types:
		dict[currency_type] = Big.new(get_price(currency_type))
	return dict


func get_missing_currencies() -> Array[Currency.Type]:
	var arr: Array[Currency.Type]
	for currency_type in currency_types:
		if affordable[currency_type].is_false():
			arr.append(currency_type)
	return arr


func get_eta() -> Big:
	for currency_type in currency_types:
		var currency = wa.get_currency(currency_type)
		if not currency.is_net_rate_positive():
			return Big.new(0)
	
	var longest_eta_currency_type = currency_types[0]
	var eta: Big = wa.get_currency(longest_eta_currency_type).get_eta(get_price(longest_eta_currency_type))
	if currency_types.size() > 1:
		for i in range(1, currency_types.size()):
			var currency = wa.get_currency(currency_types[i]) as Currency
			
			if currency.net_rate.positive.is_false():
				longest_eta_currency_type = Currency.Type.NONE
				return Big.new(0)
			
			var i_eta = currency.get_eta(get_price(currency_types[i]))
			if i_eta.greater(eta):
				eta = i_eta
				longest_eta_currency_type = currency.type
	
	return Big.new(eta)


func get_progress_percent() -> float:
	var total_percent = currency_types.size()
	var percent := 0.0
	for currency_type in currency_types:
		var currency = wa.get_currency(currency_type)
		var _amount = get_price(currency_type)
		if _amount.equal(0):
			total_percent -= 1.0
			continue
		percent += currency.get_amount().percent(_amount)
	return percent / total_percent


func get_pending_progress_percent() -> float:
	var total_percent = currency_types.size()
	var percent := 0.0
	for currency_type in currency_types:
		var currency = wa.get_currency(currency_type)
		var _amount = get_price(currency_type)
		if _amount.equal(0):
			total_percent -= 1.0
			continue
		percent += currency.get_effective_amount().percent(_amount)
	return percent / total_percent


func can_use_currencies() -> bool:
	for currency_type in currency_types:
		if wa.get_currency(currency_type).can_use.is_false():
			return false
	return true

#endregion


#region Dev


var variable_name: String


func report_on_changed(_variable_name: String):
	variable_name = _variable_name
	changed.connect(report)


func report() -> void:
	print_debug("Report for Price ", str(self) if variable_name == "" else variable_name)
	for currency_type in currency_types:
		var amount = wa.get_amount(currency_type)
		var _price = get_price(currency_type)
		print_debug(" - %s/%s" % [amount.text, _price.text])
		print_debug(" - Pending: ", wa.get_pending(currency_type).text)


#endregion
