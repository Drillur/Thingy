class_name OfflineEarnings
extends Node



signal report_ready

var report := {}
var last_clock: float
var time_offline: float
var increase_percent: Big


func _ready() -> void:
	gv.game_has_focus.became_false.connect(game_lost_focus)
	gv.game_has_focus.became_true.connect(game_gained_focus)
	gv.root_ready.became_true.connect(
		func():
			if SaveManager.loaded_data.size() > 0:
				await get_tree().physics_frame
				calculate_offline_earnings(SaveManager.loaded_data["gv"]["current_clock"])
				gv.session_duration.reset()
	)



func game_gained_focus() -> void:
	var time := Time.get_unix_time_from_system()
	if time - gv.current_clock > 1: # current_clock is updated every second (unless game doesnt have focus)
		if time - last_clock > 1: # last_clock is updated when the game loses focus
			calculate_offline_earnings(last_clock)


func game_lost_focus() -> void:
	last_clock = Time.get_unix_time_from_system()


func calculate_offline_earnings(_last_clock: float) -> void:
	if Settings.offline_earnings_allowed.is_false():
		return
	report.clear()
	#
	#var sum_before := Big.new(0)
	#var sum_after := Big.new(0)
	#var blocked_currencies: Array[Currency]
	#for lored_type in lv.unlocked_loreds:
		#var lored = lv.get_lored(lored_type)
		#if lored.awake.is_false():
			#sleeping_loreds.append(lored)
			#lored.awake.set_true()
	#
	#time_offline = Time.get_unix_time_from_system() - _last_clock
	#for currency in wa.currencies.values():
		#if currency.unlocked.is_false():
			#continue
		#if currency.share.is_false():
			#blocked_currencies.append(currency)
			#currency.share.set_true()
		#var gain_rate = Big.new(currency.gain_rate.get_value())
	##	printt(currency.key, gain_rate.text)
		#var delta := Big.new(gain_rate).m(time_offline).m(0.1)
		#if delta.equal(0):
			#continue
		#report[currency] = delta
		#sum_before.a(currency.amount.get_value())
		#sum_after.a(Big.new(currency.amount.get_value()).a(delta))
		#if Currency.is_produced_by_demons(currency.type):
			#currency.edit_pending(currency, delta)
		#else:
			#currency.amount.add(delta)
	#
	#increase_percent = Big.new(sum_after).d(sum_before).m(100).s(100)
	#report_ready.emit()
	#
	#for lored in sleeping_loreds:
		#lored.awake.set_false()
	#for currency in blocked_currencies:
		#currency.share.set_false()

