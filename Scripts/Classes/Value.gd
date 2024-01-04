class_name Value
extends Resource



var saved_vars := [
	"current",
]

signal increased
signal decreased

var current: Big

var added := Big.new(0, true)
var subtracted := Big.new(0, true)
var multiplied := Big.new(1, true)
var divided := Big.new(1, true)



func _init(base_value = 0.0) -> void:
	current = Big.new(base_value, true)
	current.changed.connect(emit_changed)
	current.increased.connect(emit_increase)
	current.decreased.connect(emit_decrease)


func emit_increase() -> void:
	emit_signal("increased")


func emit_decrease() -> void:
	emit_signal("decreased")


func set_to(amount) -> void:
	current.set_to(amount)


func change_base(new_base: float) -> void:
	current.change_base(new_base)


func add(amount) -> void:
	current.a(amount)


func subtract(amount: Big) -> void:
	if amount.greater_equal(current):
		current.set_to(0)
	else:
		current.s(amount)


func add_pending(amount: Big) -> void:
	current.add_pending(amount)


func subtract_pending(amount: Big) -> void:
	current.subtract_pending(amount)



func sync() -> void:
	var new_cur = Big.new(current.base)
	new_cur.m(multiplied)
	new_cur.d(divided)
	new_cur.a(added)
	new_cur.s(subtracted)
	current.set_to(new_cur)


func get_text() -> String:
	return current.text


func get_value() -> Big:
	return current



func increase_added(amount) -> void:
	added.a(amount)
	sync()


func decrease_added(amount) -> void:
	added.s(amount)
	sync()


func increase_subtracted(amount) -> void:
	subtracted.a(amount)
	sync()


func decrease_subtracted(amount) -> void:
	subtracted.s(amount)
	sync()


func increase_multiplied(amount) -> void:
	multiplied.m(amount)
	sync()


func decrease_multiplied(amount) -> void:
	multiplied.d(amount)
	sync()


func increase_divided(amount) -> void:
	divided.m(amount)
	sync()


func decrease_divided(amount) -> void:
	divided.d(amount)
	sync()


var log := {
	"added": {},
	"subtracted": {},
	"multiplied": {},
	"divided": {},
}


func add_change(category: String, source, amount) -> void:
	if log[category].has(source):
		if gv.dev_mode:
			print_debug("This source already logged a change for this Value! Fix your code.")
		return
	log[category][source] = Big.new(amount)
	match category:
		"added":
			increase_added(amount)
		"subtracted":
			increase_subtracted(amount)
		"multiplied":
			increase_multiplied(amount)
		"divided":
			increase_divided(amount)


func edit_change(category: String, source, amount) -> void:
	if log[category].has(source):
		remove_change(category, source, false)
	add_change(category, source, amount)


func remove_change(category: String, source, sync_afterwards := true) -> void:
	if not source in log[category].keys():
		return
	var amount: Big = log[category][source]
	match category:
		"added":
			added.s(amount)
		"subtracted":
			subtracted.s(amount)
		"multiplied":
			multiplied.d(amount)
		"divided":
			divided.d(amount)
	log[category].erase(source)
	if sync_afterwards:
		sync()



func reset():
	added.reset()
	subtracted.reset()
	multiplied.reset()
	divided.reset()
	current.reset()



# - Get


func get_as_float() -> float:
	return current.toFloat()


func get_as_int() -> int:
	return current.toInt()


func greater(value) -> bool:
	return current.greater(value)


func greater_equal(value) -> bool:
	return current.greater_equal(value)


func less(value) -> bool:
	return current.less(value)


func less_equal(value) -> bool:
	return current.less_equal(value)


func equal(value) -> bool:
	return current.equal(value)



# - Dev


func report() -> void:
	print("Report for ", self)
	print("    Base: ", Big.new(current.base).text)
	print("    Added: ", added.text)
	print("    Subtracted: ", subtracted.text)
	print("    Multiplied: ", multiplied.text)
	print("    Divided: ", divided.text)
	print("    == Result: ", get_text())
