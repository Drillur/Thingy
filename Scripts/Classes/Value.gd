class_name Value
extends Resource



signal increased
signal decreased
signal pending_changed

@export var _class_name := "Value"
@export var current: Big
@export var pending := Big.new(0.0)

var added := Big.new(0)
var subtracted := Big.new(0)
var multiplied := Big.new(1)
var divided := Big.new(1)

var add_pending_to_current_on_game_load := true


func _init(base_value = 0.0) -> void:
	current = Big.new(base_value)
	current.changed.connect(emit_changed)
	current.increased.connect(emit_increase)
	current.decreased.connect(emit_decrease)
	pending.changed.connect(emit_pending_changed)
	if gv.save_manager_ready.is_false():
		gv.save_manager_ready.became_true.connect(connect_game_loaded)
	else:
		connect_game_loaded()


func connect_game_loaded() -> void:
	SaveManager.loading.became_false.connect(game_loaded)


func game_loaded() -> void:
	if add_pending_to_current_on_game_load:
		current.a(pending)
	pending.reset()


func emit_increase() -> void:
	increased.emit()


func emit_decrease() -> void:
	decreased.emit()


func emit_pending_changed() -> void:
	pending_changed.emit()


func set_to(amount) -> void:
	current.set_to(amount)


func change_base(new_base: float) -> void:
	current.change_base(new_base)


func add(amount) -> void:
	current.a(amount)


func subtract(amount) -> void:
	if not amount is Big:
		amount = Big.new(amount)
	if amount.greater_equal(current):
		current.set_to(0)
	else:
		current.s(amount)



func sync() -> void:
	var new_cur = Big.new(current.base)
	new_cur.a(added)
	new_cur.s(subtracted)
	new_cur.m(multiplied)
	new_cur.d(divided)
	current.set_to(new_cur)


func get_value() -> Big:
	return current


func get_pending_value() -> Big:
	return pending



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


var book := {
	"added": {},
	"subtracted": {},
	"multiplied": {},
	"divided": {},
	"pending": {},
}


func add_change(category: String, source, amount) -> void:
	if book[category].has(source):
		if gv.dev_mode:
			print_debug("This source already logged a change for this Value! Fix your code.")
		return
	book[category][source] = Big.new(amount)
	match category:
		"added":
			increase_added(amount)
		"subtracted":
			increase_subtracted(amount)
		"multiplied":
			increase_multiplied(amount)
		"divided":
			increase_divided(amount)
		"pending":
			pending.a(amount)


func edit_change(category: String, source, amount) -> void:
	if book[category].has(source):
		remove_change(category, source, false)
	if not amount is Big:
		amount = Big.new(amount)
		if amount.equal(0):
			return
	add_change(category, source, amount)


func remove_change(category: String, source, sync_afterwards := true) -> void:
	if not source in book[category].keys():
		return
	var amount: Big = book[category][source]
	match category:
		"added":
			added.s(amount)
		"subtracted":
			subtracted.s(amount)
		"multiplied":
			multiplied.d(amount)
		"divided":
			divided.d(amount)
		"pending":
			pending.s(amount)
	book[category].erase(source)
	if sync_afterwards:
		sync()



func reset():
	book.clear()
	added.reset()
	subtracted.reset()
	multiplied.reset()
	divided.reset()
	pending.reset()
	current.reset()



#region Get


func get_text() -> String:
	return current.text


func get_pending_text() -> String:
	return pending.text


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


#endregion


# - Dev


func report() -> void:
	print("Report for ", self)
	print("    Base: ", Big.new(current.base).text)
	print("    Added: ", added.text)
	print("    Subtracted: ", subtracted.text)
	print("    Multiplied: ", multiplied.text)
	print("    Divided: ", divided.text)
	print("    == Result: ", get_text())
