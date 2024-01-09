extends Node



signal initialized
signal container_loaded
signal thingy_created

@export var thingies := {}
@export var cost: Cost

var container: ThingyContainer:
	set(val):
		container = val
		container_loaded.emit()

var next_thingy_color := Color(1, 0.243, 0.208)

var xp_output_range := FloatPair.new(1.0, 1.0)
var xp_increase_range := FloatPair.new(1.15, 1.15)
var xp_multiplier := LoudFloat.new(1.0)
var duration_applies_to_xp_output := LoudBool.new(false)

var output_range := FloatPair.new(1.0, 1.0)
var output_increase_range := FloatPair.new(1.15, 1.15)

var crit_chance := LoudFloat.new(0.0)
var crit_range := FloatPair.new(1.5, 1.5)
var crit_crit_chance := LoudFloat.new(0.0)
var crit_coin_output := FloatPair.new(0.0, 0.0)
var crits_apply_to_xp := LoudBool.new(false)
var crits_apply_to_coin := LoudBool.new(false)
var crits_apply_to_duration := LoudBool.new(false)

var duration_range := FloatPair.new(5.0, 5.0)
var duration_increase_range := FloatPair.new(1.1, 1.1)

var juice_output_range := FloatPair.new(1.0, 1.0)
var juice_input_range := FloatPair.new(1.0, 1.0)
var juice_output_increase_range := FloatPair.new(1.1, 1.1)
var juice_input_increase_range := FloatPair.new(1.1, 1.1)
var juice_multiplier_range := FloatPair.new(2.0, 2.0)
var max_juice_use := Value.new(0.0)
var smart_juice := LoudBool.new(false)



func _ready():
	cost = Cost.new({Currency.Type.WILL: Value.new(1)})
	cost.increase_multiplier = 3.0
	initialized.emit()
	gv.reset.connect(reset)



#region Signals


func thingy_wants_to_fucking_die(_index: int) -> void:
	#print("erasing ", _index)
	thingies.erase(_index)


func reset(_tier: int) -> void:
	cost.reset_now()


#endregion

#region Action


func purchase_thingy() -> void:
	cost.purchase()
	new_thingy()


func new_thingy() -> void:
	var new_index = thingies.size()
	thingies[new_index] = Thingy.new(new_index)
	next_thingy_color = gv.get_random_nondark_color()
	thingy_created.emit()


#endregion



#region Get


func get_thingy(index: int) -> Thingy:
	return thingies[index]


func get_latest_thingy() -> Thingy:
	return get_thingy(get_count() - 1)


func get_top_index() -> int:
	return get_count() - 1


func get_next_index() -> int:
	if has_thingy(get_selected_index() + 1):
		return get_selected_index() + 1
	return get_selected_index()


func get_selected_index() -> int:
	return container.selected_index.get_value()


func get_previous_index() -> int:
	if has_thingy(get_selected_index() - 1):
		return get_selected_index() - 1
	return get_selected_index()


func get_bottom_index() -> int:
	return 0 # incredible


func has_thingy(index: int) -> bool:
	return index in thingies.keys()


func get_count() -> int:
	return thingies.size()


func can_afford_thingy() -> bool:
	return cost.affordable.is_true()


func get_color(index: int) -> Color:
	return get_thingy(index).details.color


func get_latest_color() -> Color:
	return get_latest_thingy().details.color


#endregion
