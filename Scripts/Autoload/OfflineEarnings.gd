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
