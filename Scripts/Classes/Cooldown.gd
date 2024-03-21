class_name Cooldown
extends RefCounted



signal cooldown_ended

var sig: Signal
var queued := false
var timer: LoudTimer
var on_cooldown := LoudBool.new(false)



func _init(cd_duration: float, _sig := Signal()) -> void:
	if _sig != Signal():
		sig = _sig
	if gv.root_ready.is_false():
		gv.root_ready.became_true.connect(emit_if_queued)
	timer = LoudTimer.new(cd_duration)
	on_cooldown.became_true.connect(timer.start)
	timer.timeout.connect(on_cooldown.set_false)
	timer.timeout.connect(emit_if_queued)
	on_cooldown.became_false.connect(func(): cooldown_ended.emit())


func emit_if_queued() -> void:
	if queued:
		queued = false
		start()


func start() -> void:
	if queued:
		return
	if gv.root_ready.is_false():
		queued = true
		return
	if is_on_cooldown():
		queued = true
		return
	on_cooldown.set_true()
	if is_signal_valid():
		sig.emit()


func is_on_cooldown() -> bool:
	return on_cooldown.get_value()


func is_signal_valid() -> bool:
	return sig != null
