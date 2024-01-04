extends Node



signal initialized
signal container_loaded
signal thingy_created

var thingies := {}
var container: ThingyContainer:
	set(val):
		container = val
		container_loaded.emit()
var cost: Cost

var next_thingy_color := Color(1, 0.243, 0.208)

var xp := Value.new(10)
var xp_range := FloatPair.new(1.0, 1.0)
var xp_increase := LoudFloat.new(1.1)
var xp_unlocked := LoudBool.new(false)

var output_range := FloatPair.new(1.0, 1.0)
var output_increase := Big.new(1.15, true)

var crit_chance := LoudFloat.new(0.0)
var crit_range := FloatPair.new(1.5, 1.5)
var crit_crit_chance := LoudFloat.new(0.0)

var crit_coin_output := FloatPair.new(0.0, 0.0)

var duration_range := FloatPair.new(5.0, 5.0)
var duration_increase := LoudFloat.new(1.1)


func _ready():
	cost = Cost.new({Currency.Type.WILL: Value.new(1)})
	cost.increase_multiplier = 3.0
	initialized.emit()
	return
	xp_unlocked.set_to(true)
	crit_chance.set_to(5)
	crit_range.total.set_to(2.5)
	output_range.total.set_to(2)
	duration_range.current.set_to(0.9)
	duration_range.total.set_to(1.1)
	xp.set_to(1)
	



 # - Action


func purchase_thingy() -> void:
	cost.spend()
	cost.increase()
	new_thingy()


func new_thingy() -> void:
	var new_index = thingies.size()
	thingies[new_index] = Thingy.new(new_index)
	next_thingy_color = gv.get_random_nondark_color()
	thingy_created.emit()




# - Get


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
