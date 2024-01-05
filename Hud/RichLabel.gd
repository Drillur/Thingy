extends RichTextLabel



@export var autowrap := true

var currency: Currency
var cost_value: Value



func _ready() -> void:
	if not autowrap:
		disable_autowrap()



func watch_cost(_cur: Currency.Type, _cost: Cost) -> void:
	currency = wa.get_currency(_cur) as Currency
	currency.amount.changed.connect(update_text_cost)
	cost_value = _cost.amount[_cur]
	cost_value.changed.connect(update_text_cost)
	update_text_cost()



func update_text_cost() -> void:
	text = "[center]%s%s %s" % [
		currency.details.color_text % (currency.amount.get_text() + "/"),
		currency.details.color_text % cost_value.get_text(),
		currency.details.icon_and_name
	]


func disable_autowrap() -> void:
	autowrap_mode = TextServer.AUTOWRAP_OFF
