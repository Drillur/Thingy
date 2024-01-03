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

var timer: Timer
var value: Resource



func _ready() -> void:
	if kill_background:
		$bg.theme = bag.get_resource("Invis")
	resized.connect(_on_resized)
	call_deferred("_on_resized")
	set_process(false)
	bar_size.changed.connect(bar_size_changed)
#	if animate:
#		animate = false
#		set_deferred("animate", true)



func _process(_delta) -> void:
	progress = 1 - (timer.time_left / timer.wait_time)




func _on_resized():
	progress_bar.size.y = size.y


func bar_size_changed() -> void:
	progress_bar.size.x = bar_size.get_value()



# - Action


func stop() -> void:
	set_process(false)
	progress = 0.0


func hide_edge() -> void:
	edge.hide()


func show_edge() -> void:
	edge.show()


func attach_attribute(_attribute: ValuePair) -> void:
	remove_value()
	value = _attribute
	value.changed.connect(update_progress)
	value.filled.connect(update_progress)
	update_progress.call_deferred()


func attach_float_pair(_float_pair: FloatPair) -> void:
	remove_value()
	value = _float_pair
	value.changed.connect(update_progress)
	value.filled.connect(update_progress)
	update_progress.call_deferred()


func remove_value() -> void:
	if value != null:
		value.changed.disconnect(update_progress)
		value.filled.disconnect(update_progress)
		value = null


func update_progress() -> void:
	# value_pair only
	progress = value.get_current_percent()



# - Timer based


func attach_timer(_timer: Timer) -> void:
	if timer != null:
		timer = null
	timer = _timer
	set_process(true)


func remove_timer() -> void:
	timer = null
	set_process(false)
