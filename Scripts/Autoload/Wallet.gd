extends Node



var currencies := {}



func _ready() -> void:
	for cur in Currency.Type.values():
		currencies[cur] = Currency.new(cur)



# - Action


func add(cur: Currency.Type, amount: Big) -> void:
	get_currency(cur).add(amount)


func subtract(cur: Currency.Type, amount: Big) -> void:
	get_currency(cur).subtract(amount)



# - Get


func get_currency(cur: Currency.Type) -> Currency:
	return currencies[cur]


func get_amount(cur: Currency.Type) -> Big:
	return get_currency(cur).amount


func get_net_rate(cur: Currency.Type) -> Big:
	return get_currency(cur).net_rate


func get_details(cur: Currency.Type) -> Details:
	return get_currency(cur).details


func get_amount_text(cur: Currency.Type) -> String:
	return get_currency(cur).amount.text


func get_color(cur: Currency.Type) -> Color:
	return get_details(cur).color
