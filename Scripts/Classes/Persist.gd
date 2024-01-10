class_name Persist
extends Resource



signal failed_persist_check

var persist_through_tier1 := LoudBool.new(false)
var persist_through_tier2 := LoudBool.new(false)
var persist_through_tier3 := LoudBool.new(false)
var persist_through_tier4 := LoudBool.new(false)



func _init() -> void:
	gv.reset.connect(check_if_can_persist_through_tier)



#region Signals


func check_if_can_persist_through_tier(_tier: int) -> void:
	if should_fail_at_tier(_tier):
		failed_persist_check.emit()
	


#endregion


#region Action


func through_tier(_tier: int) -> void:
	if _tier >= 1:
		persist_through_tier1.set_default_value(true)
		persist_through_tier1.reset()
	if _tier >= 2:
		persist_through_tier2.set_default_value(true)
		persist_through_tier2.reset()
	if _tier >= 3:
		persist_through_tier3.set_default_value(true)
		persist_through_tier3.reset()
	if _tier >= 4:
		persist_through_tier4.set_default_value(true)
		persist_through_tier4.reset()


#endregion



#region Get


func get_highest_tier_can_persist_through() -> int:
	if persist_through_tier4.is_true():
		return 4
	if persist_through_tier3.is_true():
		return 3
	if persist_through_tier2.is_true():
		return 2
	if persist_through_tier1.is_true():
		return 1
	return 0


func should_fail_at_tier(_tier: int) -> bool:
	return get_highest_tier_can_persist_through() < _tier


#endregion
