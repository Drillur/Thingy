class_name Value
extends Resource



signal increased
signal decreased
signal pending_changed

@export var _class_name := "Value"
@export var current: Big
@export var pending: Big

var book := Book.new(Book.Type.BIG)
var copycat_var: Resource
var add_pending_to_current_on_game_load := true
var minimum := Big.new(0.0)


func _init(base_value = 0.0) -> void:
	pending = book.book[Book.Category.PENDING].sum
	current = Big.new(base_value)
	minimum.changed.connect(minimum_check)
	current.changed.connect(emit_changed)
	current.increased.connect(
		func():
			increased.emit())
	current.decreased.connect(
		func():
			minimum_check()
			decreased.emit())
	book.pending_changed.connect(func(): pending_changed.emit())
	book.changed.connect(sync)
	SaveManager.loading.became_false.connect(game_loaded)


func game_loaded() -> void:
	if add_pending_to_current_on_game_load:
		if book.get_pending().greater(0):
			current.a(pending)
			book.book[Book.Category.PENDING].reset()


func minimum_check() -> void:
	if less(minimum):
		set_to(minimum)


func set_to(amount) -> void:
	current.set_to(amount)


func change_base(new_base: float) -> void:
	current.change_base(new_base)


func set_minimum(_minimum) -> Value:
	minimum.set_to(_minimum)
	return self


func add(amount) -> void:
	current.a(amount)


func subtract(amount) -> void:
	if not amount is Big:
		amount = Big.new(amount)
	if amount.greater_equal(current):
		current.set_to(0)
	else:
		current.s(amount)


func multiply(amount) -> void:
	current.m(amount)


func divide(amount) -> void:
	current.d(amount)



func sync() -> void:
	current.set_to(book.sync.call(current.base))


func copycat(value: Resource) -> void:
	change_base(0.0)
	copycat_var = value
	copycat_var.changed.connect(copycat_changed)
	copycat_changed()


func copycat_changed() -> void:
	edit_added(copycat_var, copycat_var.get_value())


func clear_copycat() -> void:
	copycat_var.changed.disconnect(copycat_changed)
	copycat_var = null


func edit_change(category: Book.Category, source, amount) -> void:
	book.edit_change(category, source, amount)


func edit_pending(source, amount) -> void:
	edit_change(Book.Category.PENDING, source, amount)


func edit_multiplied(source, amount) -> void:
	edit_change(Book.Category.MULTIPLIED, source, amount)


func edit_added(source, amount) -> void:
	edit_change(Book.Category.ADDED, source, amount)


func edit_subtracted(source, amount) -> void:
	edit_change(Book.Category.SUBTRACTED, source, amount)


func remove_change(category: Book.Category, source) -> void:
	book.remove_change(category, source)


func remove_pending(source) -> void:
	remove_change(Book.Category.PENDING, source)


func remove_multiplied(source) -> void:
	remove_change(Book.Category.MULTIPLIED, source)


func remove_added(source) -> void:
	remove_change(Book.Category.ADDED, source)


func remove_subtracted(source) -> void:
	remove_change(Book.Category.SUBTRACTED, source)


func reset():
	current.reset()
	book.reset()


func reset_pending() -> void:
	book.reset_pending()



#region Get


func get_value() -> Big:
	return current


func get_pending() -> Big:
	return book.get_pending()


func get_effective_amount() -> Big:
	return Big.new(get_value()).a(get_pending())


func get_text() -> String:
	return current.text


func get_pending_text() -> String:
	return get_pending().text


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


func get_base() -> Dictionary:
	return current.base


#endregion


#region Dev


var variable_name: String


func report_on_changed(_variable_name: String):
	variable_name = _variable_name
	changed.connect(simple_report)


func simple_report() -> void:
	printt(variable_name, "Value changed to:", get_text())


func report() -> void:
	printt("Report for Value ", str(self) if variable_name == "" else variable_name, ":")
	printt(" - Base: ", Big.new(current.base).text)
	book.report()


#endregion


