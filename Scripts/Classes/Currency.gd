class_name Currency
extends Resource



enum Type {
	NONE,
	WILL,
	COIN,
	XP,
	JUICE,
	SOUL,
}

const NONE := Type.NONE

signal sync_requested
signal increased__type(_type)
signal decreased__type(_type)
signal increased__amount(_amount)

var type: Type
var key: String

@export var amount := Value.new(0)
@export var unlocked := LoudBool.new(false)
@export var share := LoudBool.new(true)

var sync_cd := PhysicsCooldown.new(sync_requested)

var weight := 1
#var stage: Stage
var details := Details.new()
var persist := Persist.new()
#var safe := LoudBool.new(true)
#var can_use := LoudBoolArray.new([safe, share])

var net_rate := Big.new(0)
var gain_rate := Value.new(0)
var loss_rate := Value.new(0)

var highest_gain_rate := Big.new(0)

var offline_production: Big
var positive_offline_rate: bool



#region Init


func _init(_type: Type) -> void:
	type = _type
	key = Type.keys()[type]
	gain_rate.changed.connect(sync_cd.emit)
	loss_rate.changed.connect(sync_cd.emit)
	sync_requested.connect(sync_rate)
	persist.disconnect_calls()

	amount = Value.new(0)
	amount.increased.connect(emit_increased)
	amount.decreased.connect(emit_decreased)
	details.set_name(key.capitalize())
	match type:
		Type.WILL:
			amount.change_base(1)
			details.set_icon(bag.get_resource("Heart"), false)
			details.set_color(Color(1, 0.114, 0.278))
			unlocked = LoudBool.new(true)
		Type.COIN:
			details.set_color(Color(1, 0.867, 0))
			details.set_icon(bag.get_resource("Coin"), false)
		Type.XP:
			details.set_name("Experience")
			details.set_color(Color(0.894, 0.51, 1))
			details.set_icon(bag.get_resource("Star"), false)
		Type.JUICE:
			details.set_color(Color(0.424, 0.957, 0.125))
			details.set_icon(bag.get_resource("Juice"), false)
		Type.SOUL:
			details.set_color(Color(0.918, 0.2, 0.553))
			details.set_icon(bag.get_resource("Ghost"), false)
			persist.through_tier(1)
			amount.add_pending_to_current_on_game_load = false


#endregion


#region Internal


func emit_increased() -> void:
	increased__type.emit(type)


func emit_decreased() -> void:
	decreased__type.emit(type)


#endregion


#region Signals


func reset(tier: int) -> void:
	if persist.get_highest_tier_can_persist_through() >= tier:
		return
	amount.reset()
	highest_gain_rate.reset()
	sync_rate()


#endregion




# - Action


func add(_amount) -> void:
	amount.add(_amount)
	if not _amount is Big:
		_amount = Big.new(_amount)
	increased__amount.emit(_amount)


func add_pending(_amount) -> void:
	get_pending().add(_amount)


func subtract(_amount) -> void:
	amount.subtract(_amount)


func edit_pending(source, _amount) -> void:
	amount.edit_change(Book.Category.PENDING, source, _amount)


func remove_pending(source) -> void:
	amount.remove_change(Book.Category.PENDING, source)


func reset_pending() -> void:
	amount.reset_pending()


func convert_pending() -> void:
	add(get_pending())
	amount.reset_pending()


func sync_rate() -> void:
	var gain = gain_rate.get_value()
	var loss = loss_rate.get_value()
	if gain.greater_equal(loss):
		net_rate.set_to(Big.new(gain).s(loss))
		net_rate.positive.set_to(true)
	else:
		gain.text
		loss.text
		net_rate.set_to(Big.new(loss).s(gain))
		net_rate.positive.set_to(false)
	if gain_rate.greater(highest_gain_rate):
		highest_gain_rate.set_to(gain_rate.get_value())



#region Get


func get_eta(threshold: Big) -> Big:
	if (
		get_amount().greater_equal(threshold)
		#or get_effective_amount().greater_equal(threshold)
		or not is_net_rate_positive()
	):
		return Big.new(0)
	
	var deficit = Big.new(threshold).s(get_amount())
	return deficit.d(net_rate)


func is_net_rate_positive() -> bool:
	return (
		net_rate.greater(0)
		and net_rate.positive.is_true()
	)


func get_amount() -> Big:
	return amount.get_value()


func get_pending() -> Big:
	return amount.get_pending()


func get_effective_amount() -> Big:
	return amount.get_effective_amount()


#endregion


#region Dev


func report() -> void:
	printt("Report for Currency", key)
	printt("-", "Amount: " + amount.get_text())
	printt("-", "Net Rate: " + net_rate.get_text(), "(Positive: %s)" % str(net_rate.positive.get_value()))
	printt("-", "-", "Gain Rate: " + gain_rate.get_text())
	printt("-", "-", "Loss Rate: " + loss_rate.get_text())
	#printt("-", "-", "-")
