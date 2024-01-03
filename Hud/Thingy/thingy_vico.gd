class_name ThingyVico
extends MarginContainer



@onready var progress_bar = %"Progress Bar"
@onready var max_progress_label = %"Max Progress Label"
@onready var xp_bar = %"Xp Bar" as Bar
@onready var progress_label = %"Progress Label"
@onready var output_label = %"Output Label"
@onready var index_label = %"Index Label"
@onready var xp_label = %"XP Label"
@onready var max_xp_label = %"Max XP Label"
@onready var selected = %Selected
@onready var xp_labels = %"XP Labels"
@onready var border = %Border

var thingy: Thingy

var color: Color:
	set(val):
		color = val
		progress_bar.modulate = val
		index_label.modulate = val
		if get_index() == 3:
			border.modulate = val



func _ready() -> void:
	set_process(false)
	xp_labels.hide()
	xp_bar.hide()
	output_label.modulate = wa.get_color(Currency.Type.GOLD)
	await th.container_loaded
	th.container.selected_index.changed.connect(selected_index_changed)
	th.xp_unlocked.changed.connect(xp_unlocked_changed)
	xp_unlocked_changed()
	
	match get_index():
		3:
			pass
		_:
			selected.queue_free()
	
	if not gv.dev_mode:
		$DEV.queue_free()



func _process(_delta):
	progress_label.text = "[i]" + tp.quick_parse(
		(thingy.timer.wait_time - thingy.timer.time_left),
		true
	)



# - Internal


func connect_calls() -> void:
	thingy.level.increased.connect(level_increased)
	thingy.level.changed.connect(output_changed)
	th.output.changed.connect(output_changed)
	th.output_range.changed.connect(output_changed)
	th.output_increase.changed.connect(output_changed)
	thingy.timer_started.connect(duration_changed)
	xp_bar.attach_attribute(thingy.xp)
	thingy.xp.current.changed.connect(xp_current_changed)
	thingy.xp.total.changed.connect(xp_total_changed)
	output_changed()
	duration_changed()
	xp_current_changed()
	xp_total_changed()


func disconnect_calls() -> void:
	thingy.level.increased.disconnect(level_increased)
	thingy.level.changed.disconnect(output_changed)
	th.output.changed.disconnect(output_changed)
	th.output_range.changed.disconnect(output_changed)
	th.output_increase.changed.disconnect(output_changed)
	thingy.timer_started.disconnect(duration_changed)
	thingy.xp.current.changed.disconnect(xp_current_changed)
	thingy.xp.total.changed.disconnect(xp_total_changed)
	xp_bar.remove_value()



# - Signal


func selected_index_changed() -> void:
	var index: int = th.container.selected_index.get_value()
	match get_index():
		0:
			if th.has_thingy(index + 3):
				assign_thingy(th.get_thingy(index + 3))
			else:
				clear_thingy()
		1:
			if th.has_thingy(index + 2):
				assign_thingy(th.get_thingy(index + 2))
			else:
				clear_thingy()
		2:
			if th.has_thingy(index + 1):
				assign_thingy(th.get_thingy(index + 1))
			else:
				clear_thingy()
		3:
			assign_thingy(th.get_thingy(index))
		4:
			if th.has_thingy(index - 1):
				assign_thingy(th.get_thingy(index - 1))
			else:
				clear_thingy()
		5:
			if th.has_thingy(index - 2):
				assign_thingy(th.get_thingy(index - 2))
			else:
				clear_thingy()
		6:
			if th.has_thingy(index - 3):
				assign_thingy(th.get_thingy(index - 3))
			else:
				clear_thingy()


func output_changed() -> void:
	var text = "[b][i]+"
	if th.output_range.is_full():
		text = text + thingy.get_minimum_output().get_text()
	else:
		text = text + "%s-%s" % [
			thingy.get_minimum_output().get_text(),
			thingy.get_maximum_output().get_text()
		]
	output_label.text = text


func duration_changed() -> void:
	max_progress_label.text = "[i]" + tp.quick_parse(
		thingy.timer.wait_time,
		true
	)


func xp_current_changed() -> void:
	xp_label.text = thingy.xp.get_current_text()


func xp_total_changed() -> void:
	max_xp_label.text = thingy.xp.get_total_text()


func xp_unlocked_changed() -> void:
	if th.xp_unlocked.is_true():
		xp_labels.show()
		xp_bar.show()
	else:
		xp_labels.hide()
		xp_bar.hide()


func level_increased() -> void:
	gv.flash(self, thingy.details.color)



# - Action


func assign_thingy(_thingy: Thingy) -> void:
	clear_thingy()
	thingy = _thingy
	color = thingy.details.color
	connect_calls()
	progress_bar.attach_timer(thingy.timer)
	index_label.text = "[i]#" + str(thingy.index + 1)
	set_process(true)
	show()
	if _thingy.just_born:
		gv.flash(self, color)
		_thingy.just_born = false


func clear_thingy() -> void:
	if not thingy:
		return
	disconnect_calls()
	set_process(false)
	thingy = null
	hide()





# - Dev


func _on_dev_pressed():
	clear_thingy()
