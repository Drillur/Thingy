extends Node



var currencies := {}
@export var currencies_by_name := {}
var soul_gain := Big.new(0)



func _ready() -> void:
	for cur in Currency.Type.values():
		currencies[cur] = Currency.new(cur)
		currencies_by_name[currencies[cur].key] = currencies[cur]
	get_currency(Currency.Type.WILL).amount.changed.connect(will_changed)



#region Signals


func will_changed() -> void:
	var new_amount = Big.new(
		maxf(
			0,
			pow(get_amount(Currency.Type.WILL).logN(15), 1.5) - 8
		)
	).roundDown()
	soul_gain.set_to(new_amount)


#endregion


# - Action


func collect_reset_currency(_tier: int) -> void:
	match _tier:
		1:
			add(Currency.Type.SOUL, soul_gain)


func add(cur: Currency.Type, amount) -> void:
	get_currency(cur).add(amount)


func subtract(cur: Currency.Type, amount) -> void:
	get_currency(cur).subtract(amount)


func unlock(cur: Currency.Type) -> void:
	get_currency(cur).unlocked.set_to(true)


func lock(cur: Currency.Type) -> void:
	get_currency(cur).unlocked.set_to(false)



# - Get


func get_currency(cur: Currency.Type) -> Currency:
	return currencies[cur]


func get_amount(cur: Currency.Type) -> Big:
	return get_currency(cur).get_amount()


func get_pending_amount(cur: Currency.Type) -> Big:
	return get_currency(cur).amount.pending


func get_effective_amount(cur: Currency.Type) -> Big:
	return Big.new(get_amount(cur)).a(get_pending_amount(cur))


func get_net_rate(cur: Currency.Type) -> Big:
	return get_currency(cur).net_rate


func get_details(cur: Currency.Type) -> Details:
	return get_currency(cur).details


func get_amount_text(cur: Currency.Type) -> String:
	return get_currency(cur).amount.get_text()


func get_currency_name(cur: Currency.Type) -> String:
	return get_details(cur).name


func get_color_text(cur: Currency.Type) -> Color:
	return get_details(cur).color_text


func get_color(cur: Currency.Type) -> Color:
	return get_details(cur).color


func is_unlocked(cur: Currency.Type) -> bool:
	return get_currency(cur).unlocked.get_value()


func get_unlocked(cur: Currency.Type) -> LoudBool:
	return get_currency(cur).unlocked
