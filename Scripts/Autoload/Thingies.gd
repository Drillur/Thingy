extends Node



signal initialized
signal container_loaded
signal thingy_created

@export var thingies: Array#[Thingy]
@export var price: Price
@export var next_thingy_color := LoudColor.new(1, 0.243, 0.208)
@export var autobuyer_unlocked := LoudBool.new(false)
@export var autobuyer_enabled := LoudBool.new(true)

var container: ThingyContainer:
	set(val):
		container = val
		container_loaded.emit()

var autobuyer := LoudBoolArray.new([autobuyer_unlocked, autobuyer_enabled])
var all_output := LoudFloat.new(1.0)
var will_output := LoudFloat.new(1.0)

var xp_output_range := LoudFloatPair.new(1.0, 1.0)
var xp_increase_range := LoudFloatPair.new(1.15, 1.15)
var xp_multiplier := LoudFloat.new(1.0)
var duration_affects_xp_output := LoudBool.new(false)

var output_range := LoudFloatPair.new(1.0, 1.0)
var output_increase_range := LoudFloatPair.new(1.15, 1.15)

var crit_chance := LoudFloat.new(0.0)
var crit_range := LoudFloatPair.new(1.5, 1.5)
var crit_crit_chance := LoudFloat.new(0.0)
var crit_coin_output := LoudFloatPair.new(0.0, 0.0)
var coin_increase := LoudFloatPair.new(1.0, 1.0) # reset tier: 1
var crits_apply_to_xp := LoudBool.new(false)
var crits_apply_to_coin := LoudBool.new(false)
var crits_apply_to_coin_twice := LoudBool.new(false)
var crits_apply_to_duration := LoudBool.new(false)
var crits_apply_to_next_job_duration := LoudBool.new(false)
var crit_rolls := LoudInt.new(1)

var duration_range := LoudFloatPair.new(5.0, 5.0)
var duration_increase_range := LoudFloatPair.new(1.1, 1.1)

var juice_output_range := LoudFloatPair.new(1.0, 1.0)
var juice_input_range := LoudFloatPair.new(1.0, 1.0)
var juice_output_increase_range := LoudFloatPair.new(1.1, 1.1)
var juice_input_increase_range := LoudFloatPair.new(1.1, 1.1)
var juice_multiplier_range := LoudFloatPair.new(2.0, 2.0)
var crit_rolls_from_duration := LoudBool.new(false)
var crit_rolls_from_duration_count := LoudInt.new(10)
var max_juice_use := Value.new(0.0)
var smart_juice := LoudBool.new(false)



func _ready():
	xp_output_range.current.book.add_multiplier(all_output)
	xp_output_range.total.book.add_multiplier(all_output)
	output_range.current.book.add_multiplier(all_output)
	output_range.total.book.add_multiplier(all_output)
	output_range.current.book.add_multiplier(will_output)
	output_range.total.book.add_multiplier(will_output)
	crit_coin_output.current.book.add_multiplier(all_output)
	crit_coin_output.total.book.add_multiplier(all_output)
	juice_output_range.current.book.add_multiplier(all_output)
	juice_output_range.total.book.add_multiplier(all_output)
	
	price = Price.new({"WILL": 1})
	price.increase_modifier.set_to(3.0)
	initialized.emit()
	gv.reset.connect(reset)
	SaveManager.loading.became_false.connect(load_finished)


func load_finished() -> void:
	if thingies.size() == 0:
		return
	thingies.sort_custom(
		func(a: Thingy, b: Thingy) -> bool:
			return a.index < b.index
	)
	await get_tree().physics_frame
	thingy_created.emit()



#region Signals


func reset(_tier: int) -> void:
	price.reset()
	max_juice_use.reset()
	if _tier >= 1:
		coin_increase.current.reset()
		coin_increase.total.reset()


#endregion

#region Action


func purchase_thingy() -> void:
	price.purchase()
	new_thingy()


func new_thingy() -> void:
	var new_index = thingies.size()
	thingies.append(Thingy.new(new_index))
	next_thingy_color.set_to(gv.get_random_nondark_color())
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
	return index < thingies.size() and index >= 0


func get_count() -> int:
	return thingies.size()


func can_afford_thingy() -> bool:
	return price.can_afford()


func get_color(index: int) -> Color:
	return get_thingy(index).details.get_color()


func get_latest_color() -> Color:
	return get_latest_thingy().details.get_color()


#endregion
