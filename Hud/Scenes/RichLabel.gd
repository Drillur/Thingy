class_name RichLabel
extends RichTextLabel



@export var autowrap := true
@export var hide_icon := false
@export var italics := false
@export var bold := false

var currency: Currency
var big: Big
var price_big: Big
var loud_string: LoudString
var value: Resource

var queue := await Queueable.new(self)



func _ready() -> void:
	if not autowrap:
		disable_autowrap()



func attach_price(key: String, _price: Price) -> void:
	currency = wa.get_currency(key) as Currency
	price_big = _price.get_price(key)
	queue.method = update_text_price
	currency.amount.changed.connect(queue.call_method)
	price_big.changed.connect(queue.call_method)
	queue.call_method()


func update_text_price() -> void:
	set_deferred(
		"text",
		"[center]" + currency.details.get_color_text() % (
			"%s/%s " % [
				currency.amount.get_text(),
				price_big.get_text()
			]
		) + currency.details.get_icon_and_name() if not hide_icon else ""
	)


func disable_autowrap() -> void:
	autowrap_mode = TextServer.AUTOWRAP_OFF


func enable_autowrap() -> void:
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART



func attach_currency(key: String) -> void:
	currency = wa.get_currency(key)
	queue.method = currency_changed
	currency.amount.changed.connect(queue.call_method)
	queue.call_method()


func currency_changed() -> void:
	var new_text: String
	if not hide_icon:
		new_text = currency.details.get_icon_text() + " "
	new_text += "[b]%s[/b]" % (
		currency.details.get_color_text() % (
			currency.amount.get_text()
		)
	)
	set_deferred("text", new_text)


func attach_currency_rate(key: String) -> void:
	currency = wa.get_currency(key)
	queue.method = currency_rate_changed
	currency.net_rate.changed.connect(queue.call_method)
	queue.call_method()


func currency_rate_changed() -> void:
	var new_text: String
	if not hide_icon:
		new_text = currency.details.get_icon_text() + " "
	if italics:
		new_text += "[i]"
	new_text += currency.details.get_color_text() % (currency.net_rate.get_text() + "/s")
	set_deferred("text", new_text)


func attach_string(_str: LoudString) -> void:
	loud_string = _str
	queue.method = string_changed
	loud_string.changed.connect(queue.call_method)
	queue.call_method()


func string_changed() -> void:
	if loud_string.get_value() == "":
		hide()
	else:
		show()
		set_deferred("text", ("[i]" if italics else "") + loud_string.get_value())


func attach_pending_currency(key: String) -> void:
	currency = wa.get_currency(key) as Currency
	queue.method = currency_pending_changed
	currency.amount.pending_changed.connect(queue.call_method)
	queue.call_method()


func currency_pending_changed() -> void:
	var new_text: String
	if not hide_icon:
		new_text = currency.details.get_icon_text() + " "
	new_text += "[b]%s[/b]" % (
		currency.details.get_color_text() % (
			"+" + currency.amount.get_pending_text()
		)
	)
	set_deferred("text", new_text)


func attach_big(_big: Big, color: Color) -> void:
	modulate = color
	big = _big
	queue.method = big_changed
	big.changed.connect(queue.call_method)
	queue.call_method()


func big_changed() -> void:
	var new_text: String
	new_text = "[b]%s[/b]" % (
		"+" + big.get_text()
	)
	set_deferred("text", new_text)


func attach_float_pair(_value: LoudFloatPair) -> void:
	if are_values_equal(_value):
		return
	value = _value
	setup_value()


func attach_float(_value: LoudFloat) -> void:
	if are_values_equal(_value):
		return
	value = _value
	setup_value()


func attach_int_pair(_value: LoudIntPair) -> void:
	if are_values_equal(_value):
		return
	value = _value
	setup_value()


func attach_int(_value: LoudInt) -> void:
	if are_values_equal(_value):
		return
	value = _value
	setup_value()


func setup_value() -> void:
	queue.method = value_changed
	value.changed.connect(queue.call_method)
	queue.call_method()


func value_changed() -> void:
	if value == null:
		return
	var _text: String = ""
	_text += "[i]" if italics else ""
	_text += "[b]" if bold else ""
	_text += value.get_text()
	set_deferred("text", _text)


func clear_value() -> void:
	value.changed.disconnect(queue.call_method)
	value = null


func are_values_equal(x: Resource) -> bool:
	return value and value == x
