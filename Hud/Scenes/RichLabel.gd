class_name RichLabel
extends RichTextLabel



@export var autowrap := true
@export var hide_icon := false
@export var italics := false

var currency: Currency
var big: Big
var price_big: Big
var loud_string: LoudString
var int_pair: LoudIntPair
var parent_visible_in_tree := false
var queued := false
var queued_method: Callable



func _ready() -> void:
	if not autowrap:
		disable_autowrap()
	if not get_parent().is_node_ready():
		await get_parent().ready
	get_parent().visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func _on_visibility_changed():
	parent_visible_in_tree = get_parent().is_visible_in_tree()
	if parent_visible_in_tree and queued:
		queued = false
		queued_method.call()



func watch_price(_cur: Currency.Type, _price: Price) -> void:
	currency = wa.get_currency(_cur) as Currency
	price_big = _price.get_price(_cur)
	queued_method = update_text_price
	currency.amount.changed.connect(queued_method)
	price_big.changed.connect(queued_method)
	queued_method.call()


func update_text_price() -> void:
	if queued:
		return
	if not parent_visible_in_tree:
		queued = true
		return
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



func watch_currency(_cur: Currency.Type) -> void:
	currency = wa.get_currency(_cur)
	queued_method = currency_changed
	currency.amount.changed.connect(queued_method)
	queued_method.call()


func currency_changed() -> void:
	if queued:
		return
	if not parent_visible_in_tree:
		queued = true
		return
	var new_text: String
	if not hide_icon:
		new_text = currency.details.get_icon_text() + " "
	new_text += "[b]%s[/b]" % (
		currency.details.get_color_text() % (
			currency.amount.get_text()
		)
	)
	set_deferred("text", new_text)


func watch_currency_rate(_cur: Currency.Type) -> void:
	currency = wa.get_currency(_cur)
	currency.net_rate.changed.connect(currency_rate_changed)
	currency_rate_changed()
	queued_method = currency_rate_changed


func currency_rate_changed() -> void:
	if queued:
		return
	if not parent_visible_in_tree:
		queued = true
		return
	var new_text: String
	if not hide_icon:
		new_text = currency.details.get_icon_text() + " "
	if italics:
		new_text += "[i]"
	new_text += currency.details.get_color_text() % (currency.net_rate.get_text() + "/s")
	set_deferred("text", new_text)


func watch_string(_str: LoudString) -> void:
	loud_string = _str
	loud_string.changed.connect(string_changed)
	string_changed()
	queued_method = string_changed


func string_changed() -> void:
	if queued:
		return
	if not parent_visible_in_tree:
		queued = true
		return
	if loud_string.get_value() == "":
		hide()
	else:
		show()
		set_deferred("text", ("[i]" if italics else "") + loud_string.get_value())


func watch_pending_currency(_cur: Currency.Type) -> void:
	currency = wa.get_currency(_cur) as Currency
	currency.amount.pending_changed.connect(currency_pending_changed)
	currency_pending_changed()
	queued_method = currency_pending_changed


func currency_pending_changed() -> void:
	if queued:
		return
	if not parent_visible_in_tree:
		queued = true
		return
	var new_text: String
	if not hide_icon:
		new_text = currency.details.get_icon_text() + " "
	new_text += "[b]%s[/b]" % (
		currency.details.get_color_text() % (
			"+" + currency.amount.get_pending_text()
		)
	)
	set_deferred("text", new_text)


func watch_big(_big: Big, color: Color) -> void:
	modulate = color
	big = _big
	queued_method = big_changed
	big.changed.connect(queued_method)
	queued_method.call()


func big_changed() -> void:
	if queued:
		return
	if not parent_visible_in_tree:
		queued = true
		return
	var new_text: String
	new_text = "[b]%s[/b]" % (
		"+" + big.get_text()
	)
	set_deferred("text", new_text)


func watch_int_pair(_int_pair: LoudIntPair, color := Color.WHITE) -> void:
	if int_pair:
		if int_pair == _int_pair:
			return
		queued = false
		int_pair.changed.disconnect(queued_method)
	modulate = color
	int_pair = _int_pair
	queued_method = int_pair_changed
	int_pair.changed.connect(queued_method)
	queued_method.call()


func int_pair_changed() -> void:
	if queued:
		return
	if not parent_visible_in_tree:
		queued = true
		return
	var new_text: String
	new_text = "[i]%s[/i]" % (
		int_pair.get_text()
	)
	set_deferred("text", new_text)
