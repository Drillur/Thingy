class_name Price
extends Resource



signal purchase_requested

@export var times_purchased := LoudInt.new(0)

var times_increased := LoudInt.new(0)
var owner_purchased := LoudBool.new(false)
var owner_unlocked := LoudBool.new(true)
var purchase_requested_cd := PhysicsCooldown.new(purchase_requested)
var currency_types: Array[Currency.Type]
var increase_modifier := LoudFloat.new(1.0)

var all_affordable := LoudBool.new(false)

var price := {}
var affordable := {}



func _init(data: Dictionary) -> void:
	if data.size() > 0:
		for currency_type in data.keys():
			add_price(currency_type, data[currency_type])
	owner_purchased.became_false.connect(check_all)
	owner_unlocked.became_true.connect(check_all)
	times_purchased.changed.connect(update_price_based_on_times_purchased)
	increase_modifier.changed.connect(update_price_based_on_times_purchased)
	update_price_based_on_times_purchased()


func add_price(currency_type: Currency.Type, base_value) -> void:
	price[currency_type] = Value.new(base_value)
	affordable[currency_type] = LoudBool.new(false)
	currency_types.append(currency_type)
	affordable[currency_type].changed.connect(affordable_changed)
	check_currency(currency_type)
	var disconnect_calls = func():
		if owner_purchased.is_true() or owner_unlocked.is_false():
			if wa.get_currency(currency_type).increased__type.is_connected(currency_increased):
				wa.get_currency(currency_type).increased__type.disconnect(currency_increased)
			if wa.get_currency(currency_type).decreased__type.is_connected(currency_decreased):
				wa.get_currency(currency_type).decreased__type.disconnect(currency_decreased)
	owner_purchased.became_true.connect(disconnect_calls)
	owner_unlocked.became_false.connect(disconnect_calls)
	disconnect_calls.call()
	price[currency_type].changed.connect(emit_changed)
	price[currency_type].book.add_powerer(increase_modifier, times_increased, -1)



#region Signals


func affordable_changed() -> void:
	all_affordable.set_to(are_all_affordable())


func currency_increased(currency_type: Currency.Type) -> void:
	if affordable[currency_type].is_false():
		check_currency(currency_type)
	emit_changed()


func currency_decreased(currency_type: Currency.Type) -> void:
	if affordable[currency_type].is_true():
		check_currency(currency_type)
	emit_changed()


func update_price_based_on_times_purchased() -> void:
	edit_all(self, Big.new(increase_modifier.get_value()).power(times_purchased.get_value()))


#endregion


#region Internal


func check_all() -> void:
	for currency_type in currency_types:
		check_currency(currency_type)


func check_currency(currency_type: Currency.Type) -> void:
	var amount = wa.get_amount(currency_type)
	affordable[currency_type].set_to(
		amount.greater_equal(get_price(currency_type))
	)
	if affordable[currency_type].is_true():
		if wa.get_currency(currency_type).increased__type.is_connected(currency_increased):
			wa.get_currency(currency_type).increased__type.disconnect(currency_increased)
		if not wa.get_currency(currency_type).decreased__type.is_connected(currency_decreased):
			wa.get_currency(currency_type).decreased__type.connect(currency_decreased)
	else:
		if not wa.get_currency(currency_type).increased__type.is_connected(currency_increased):
			wa.get_currency(currency_type).increased__type.connect(currency_increased)
		if wa.get_currency(currency_type).decreased__type.is_connected(currency_decreased):
			wa.get_currency(currency_type).decreased__type.disconnect(currency_decreased)


#endregion


#region Action


func reset() -> void:
	times_increased.reset()
	times_purchased.reset()
	check_all()
	emit_changed()


func purchase() -> void:
	spend()
	times_purchased.add(1)


func spend() -> void:
	for currency_type in currency_types:
		wa.subtract(currency_type, get_price(currency_type))
	check_all()
	emit_changed()


func refund() -> void:
	for currency_type in currency_types:
		wa.add(currency_type, get_price(currency_type))


func edit_change(currency_type: Currency.Type, source, amount) -> void:
	price[currency_type].edit_multiplied(source, amount)
	check_currency(currency_type)


func edit_all(source, amount) -> void:
	for currency_type in currency_types:
		edit_change(currency_type, source, amount)


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


func are_all_affordable() -> bool:
	for currency_type in currency_types:
		if affordable[currency_type].is_false():
			return false
	return true


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
