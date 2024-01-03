class_name Currency
extends Resource



enum Type {
	WILL,
	GOLD,
	XP,
}

var type: Type
var key: String
var details := Details.new()

var amount: Big

var net_rate := Big.new(0, true)
var gain_rate := Value.new(0)
var loss_rate := Value.new(0)



func _init(_type: Type) -> void:
	type = _type
	key = Type.keys()[type]
	gain_rate.changed.connect(sync_rate)
	loss_rate.changed.connect(sync_rate)
	details.name = key.capitalize()
	set_starting_amount()
	match type:
		Type.WILL:
			details.color = Color(1, 0.114, 0.278)
			details.icon = bag.get_resource("Heart")
		Type.GOLD:
			details.name = "Coin"
			details.color = Color(1, 0.867, 0)
			details.icon = bag.get_resource("Coin")
		Type.XP:
			details.name = "Experience"
			details.color = Color(0.894, 0.51, 1)
			details.icon = bag.get_resource("Star")




func set_starting_amount() -> void:
	match type:
		Type.GOLD:
			amount = Big.new(1, true)
		_:
			amount = Big.new(0, true)





# - Action


func add(_amount) -> void:
	amount.a(_amount)


func subtract(_amount) -> void:
	amount.s(_amount)


func sync_rate() -> void:
	var gain = gain_rate.get_value()
	var loss = loss_rate.get_value()
	if gain.greater_equal(loss):
		net_rate.positive.set_to(true)
		net_rate.set_to(Big.new(gain).s(loss))
	else:
		net_rate.positive.set_to(false)
		net_rate.set_to(Big.new(loss).s(gain))



func add_pending(amount: Big) -> void:
	amount.add_pending(amount)


func subtract_pending(amount: Big) -> void:
	amount.subtract_pending(amount)



# - Get


func get_eta(threshold: Big) -> Big:
	if (
		amount.greater_equal(threshold)
		or net_rate.equal(0)
		or net_rate.positive.is_false()
	):
		return Big.new(0)
	
	var deficit = Big.new(threshold).s(amount)
	return deficit.d(net_rate)
