class_name XPLevel
extends Resource



@export var hood_xp: ValuePair

var visual_xp: ValuePair
var xp_increase: LoudFloat
var base_xp: float

var cached_xp_required := {}

var level := LoudInt.new(1)
var highest_expected_level: int = 100

var current_xp_text := LoudString.new()
var total_xp_text := LoudString.new()


func _init(_base_xp: float, _xp_increase := 1.15) -> void:
	base_xp = _base_xp
	xp_increase = LoudFloat.new(_xp_increase)
	
	SaveManager.loading.became_false.connect(level_up)
	
	hood_xp = ValuePair.new(0, 1)
	hood_xp.total.set_to(get_required_xp(1))
	hood_xp.set_to(0)
	hood_xp.do_not_cap_current()
	hood_xp.full.became_true.connect(level_up)
	hood_xp.total.changed.connect(update_visual_xp)
	level.changed.connect(
		func():
			hood_xp.total.set_to(get_required_xp(level.get_value()))
	)
	
	visual_xp = ValuePair.new(0, hood_xp.get_total())
	visual_xp.do_not_cap_current()
	xp_increase.changed.connect(cache_xp_required)
	
	visual_xp.changed.connect(update_xp_text)
	update_xp_text()






#region Internal


func update_xp_text() -> void:
	total_xp_text.set_to(visual_xp.get_total_text())
	current_xp_text.set_to(visual_xp.get_current_text())


func calculate_required_xp(_level: int) -> Big:
	var x = Big.new(xp_increase.get_value()).power(_level - 1).m(base_xp)
	#printt("Xp required for level %s: %s" % [str(_level),x.text])
	return x


func get_required_xp(_level: int) -> Big:
	if _level in cached_xp_required.keys():
		return cached_xp_required[_level]
	return calculate_required_xp(_level)


func update_visual_xp() -> void:
	var new_total_visual_xp = Big.new(get_required_xp(level.get_value()))
	var new_current_visual_xp = Big.new(hood_xp.get_current())
	if level.greater(1):
		new_total_visual_xp.s(get_required_xp(level.get_value() - 1))
		new_current_visual_xp.s(get_required_xp(level.get_value() - 1))
	visual_xp.total.set_to(new_total_visual_xp)
	visual_xp.current.set_to(new_current_visual_xp)


func level_up() -> void:
	var left := level.get_value()
	var mid := 0
	var right := highest_expected_level
	while left < right:
		mid = left + (right - left) / 2
		if get_required_xp(mid).less_equal(hood_xp.get_current()):
			left = mid + 1
		else:
			right = mid
	
	var gained_levels = left - level.get_value()
	if gained_levels > 0:
		level.add(gained_levels)


#endregion


#region Action


func reset() -> void:
	hood_xp.reset()
	level.reset()
	update_visual_xp()


func add_xp(amount) -> void:
	visual_xp.add(amount)
	hood_xp.add(amount)


func cache_xp_required(_highest_expected_level: int = highest_expected_level) -> void:
	highest_expected_level = _highest_expected_level
	cached_xp_required.clear()
	var total_xp_so_far = Big.new(0)
	for x in range(1, highest_expected_level + 1):
		total_xp_so_far.a(calculate_required_xp(x))
		cached_xp_required[x] = Big.new(total_xp_so_far)
	hood_xp.total.set_to(get_required_xp(level.get_value()))
	hood_xp.check_if_full()


#endregion


#region Get


func get_level_text() -> String:
	return level.get_text()


func get_xp_text() -> String:
	return visual_xp.get_text()


#endregion


#region Dev





#endregion
