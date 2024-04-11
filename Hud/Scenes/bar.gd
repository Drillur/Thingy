class_name Bar
extends MarginContainer



@onready var progress_bar = %"Progress Bar"
@onready var edge = %Edge

@export var kill_background := false

var color: Color:
	set(val):
		color = val
		progress_bar.modulate = color

var progress: float = -1:
	set(val):
		if progress != val:
			progress = val
			bar_size.set_to(min(progress * size.x, size.x))

var bar_size := LoudInt.new(-1)
var display_pending := false
var resize_queued := false

var queue := await Queueable.new(self)

var timer: LoudTimer
var value: Resource
var price: Price



func _ready() -> void:
	if kill_background:
		$bg.theme = bag.get_resource("Invis")
	call_deferred("_on_resized")
	set_process(false)
	bar_size.changed.connect(bar_size_changed)
	if resize_queued:
		bar_size_changed()



func _on_resized():
	if not is_node_ready():
		resize_queued = true
		return
	bar_size.set_to(min(progress * size.x, size.x))
	progress_bar.size.y = size.y


func bar_size_changed() -> void:
	progress_bar.size = Vector2(bar_size.get_value(), size.y)



# - Action


func stop() -> void:
	set_process(false)
	progress = 0.0


func hide_edge() -> void:
	edge.hide()


func show_edge() -> void:
	edge.show()


func attach_value_pair(_value_pair: ValuePair, _pending_value := false) -> void:
	display_pending = _pending_value
	remove_value()
	value = _value_pair
	queue.method = update_progress
	if display_pending:
		value.current.pending_changed.connect(queue.call_method)
	value.changed.connect(queue.call_method)
	value.full.became_true.connect(queue.call_method)
	queue.call_method()


func attach_float_pair(_float_pair: LoudFloatPair) -> void:
	remove_value()
	value = _float_pair
	queue.method = update_progress
	value.changed.connect(queue.call_method)
	value.full.became_true.connect(queue.call_method)
	queue.call_method()


func remove_value() -> void:
	if value != null:
		value.changed.disconnect(queue.call_method)
		value.full.became_true.disconnect(queue.call_method)
		if value is ValuePair and display_pending:# and value.current.pending_changed.is_connected(queue.call_method):
			value.current.pending_changed.disconnect(queue.call_method)
		value = null


func update_progress() -> void:
	# value_pair only
	if value:
		if display_pending:
			set_deferred("progress", value.get_pending_percent())
		else:
			set_deferred("progress", value.get_current_percent())


func attach_price(_price: Price, _pending_price := false) -> void:
	price = _price
	display_pending = _pending_price
	if not is_node_ready():
		await ready
	progress = 0
	price.owner_purchased.became_false.connect(connect_calls_price)
	price.owner_purchased.became_true.connect(disconnect_calls_price)
	if price.owner_purchased.is_false():
		connect_calls_price()


func connect_calls_price() -> void:
	#price.changed.connect(update_by_price)
	queue.method = update_by_price
	for x in price.price.keys():
		var currency = wa.get_currency(x)
		if display_pending:
			currency.amount.pending_changed.connect(queue.call_method)
		currency.amount.changed.connect(queue.call_method)
	await get_tree().physics_frame
	queue.call_method()


func disconnect_calls_price() -> void:
	#price.changed.disconnect(update_by_price)
	for x in price.price.keys():
		var currency = wa.get_currency(x)
		if display_pending:
			currency.amount.pending_changed.disconnect(queue.call_method)
		currency.amount.changed.disconnect(queue.call_method)


func update_by_price() -> void:
	set_progress_by_price()
	update_edge_by_price()


func update_edge_by_price() -> void:
	if display_pending:
		edge.set_deferred("visible", not is_equal_approx(price.get_pending_progress_percent(), 1.0))
	else:
		edge.set_deferred("visible", not is_equal_approx(price.get_progress_percent(), 1.0))


func set_progress_by_price() -> void:
	if display_pending:
		set_deferred("progress", price.get_pending_progress_percent())
	else:
		set_deferred("progress", price.get_progress_percent())



# - Timer based


func _process(_delta) -> void:
	set_deferred("progress", timer.get_percent())


func attach_timer(_timer: LoudTimer) -> void:
	if timer != null:
		timer = null
	timer = _timer
	set_process(true)


func remove_timer() -> void:
	timer = null
	set_process(false)
