class_name Currency
extends Resource



enum Type {
	WILL,
	COIN,
	XP,
	JUICE,
	SOUL,
}

var type: Type
var key: String
var details := Details.new()

var amount: Value

var unlocked := LoudBool.new(false)

var net_rate := Big.new(0)
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
			unlocked = LoudBool.new(true)
		Type.COIN:
			details.color = Color(1, 0.867, 0)
			details.icon = bag.get_resource("Coin")
		Type.XP:
			details.name = "Experience"
			details.color = Color(0.894, 0.51, 1)
			details.icon = bag.get_resource("Star")
		Type.JUICE:
			details.color = Color(0.424, 0.957, 0.125)
			details.icon = bag.get_resource("Juice")
		Type.SOUL:
			details.color = Color(0.918, 0.2, 0.553)
			details.icon = bag.get_resource("Ghost")




func set_starting_amount() -> void:
	match type:
		Type.WILL:
			amount = Value.new(1)
		_:
			amount = Value.new(0)





# - Action


func add(_amount) -> void:
	amount.add(_amount)


func subtract(_amount) -> void:
	amount.subtract(_amount)


func sync_rate() -> void:
	var gain = gain_rate.get_value()
	var loss = loss_rate.get_value()
	if gain.greater_equal(loss):
		net_rate.positive.set_to(true)
		net_rate.set_to(Big.new(gain).s(loss))
	else:
		net_rate.positive.set_to(false)
		net_rate.set_to(Big.new(loss).s(gain))



#region Get


func get_eta(threshold: Big) -> Big:
	if (
		get_amount().greater_equal(threshold)
		or net_rate.equal(0)
		or net_rate.positive.is_false()
	):
		return Big.new(0)
	
	var deficit = Big.new(threshold).s(get_amount())
	return deficit.d(net_rate)


func get_amount() -> Big:
	return amount.get_value()


#endregion
