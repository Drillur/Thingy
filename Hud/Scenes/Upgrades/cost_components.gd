class_name CostComponents
extends VBoxContainer



@onready var content_parent = %"Content Parent"
@onready var check = %Check
@onready var check_bg = %"title bg"
@onready var bar = %Bar as Bar
@onready var pending_bar = %PendingBar

var content := {}

var color: Color:
	set(val):
		color = val
		check.self_modulate = color
		check_bg.self_modulate = color
		bar.color = color
		bar.color.a = 0.25
		pending_bar.color = color
		pending_bar.color.a = 0.2

var price: Price:
	set(val):
		price = val
		for key in price.currency_keys:
			var label = ResourceBag.get_resource("RichLabel").instantiate() as RichLabel
			label.theme = ResourceBag.get_resource("ShadowText")
			label.disable_autowrap()
			content[key] = label
			if price.get_price(key).equal(0):
				label.hide()
			label.attach_price(key, price)
			content_parent.add_child(label)
		bar.attach_price(price, false)
		pending_bar.attach_price(price, true)
		price.owner_purchased.became_true.connect(disconnect_calls)
		price.owner_purchased.became_false.connect(connect_calls)
		connect_calls()


func connect_calls() -> void:
	if SaveManager.loading.became_false.is_connected(set_eta_text):
		return
	SaveManager.loading.became_false.connect(set_eta_text)
	for currency_type in price.currency_keys:
		var currency = wa.get_currency(currency_type) as Currency
		currency.amount.changed.connect(set_eta_text)
		currency.net_rate.changed.connect(set_eta_text)
	price.all_affordable.changed.connect(affordable_changed)
	price.all_affordable.became_true.connect(flash_became_affordable)
	price.changed.connect(set_eta_text)
	affordable_changed()
	set_eta_text()


func disconnect_calls() -> void:
	if not SaveManager.loading.became_false.is_connected(set_eta_text):
		return
	SaveManager.loading.became_false.disconnect(set_eta_text)
	for currency_type in price.currency_keys:
		var currency = wa.get_currency(currency_type) as Currency
		currency.amount.changed.disconnect(set_eta_text)
		currency.net_rate.changed.disconnect(set_eta_text)
	price.all_affordable.changed.disconnect(affordable_changed)
	price.all_affordable.became_true.disconnect(flash_became_affordable)
	price.changed.disconnect(set_eta_text)


func affordable_changed() -> void:
	check.button_pressed = price.can_afford()


func set_eta_text() -> void:
	var _eta = price.get_eta()
	if _eta.equal(0):
		check.text = ""
		return
	check.text = tp.full_parse_big(_eta)


func flash_became_affordable() -> void:
	gv.flash(check, Color(0, 1, 0))


func flash_missing_currencies() -> void:
	for cur in price.get_missing_currencies():
		gv.flash(content[cur], Color.RED)
