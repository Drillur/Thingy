class_name ThingyVico
extends MarginContainer



@onready var progress_bar = %"Progress Bar"
@onready var max_progress_label = %"Max Progress Label"
@onready var xp_bar = %"Xp Bar" as Bar
@onready var progress_label = %"Progress Label"
@onready var output_label = %"Output Label"
@onready var index_label = %"Index Label"
@onready var selected = %Selected
@onready var xp_labels = %"XP Labels"
@onready var level_label = %"Level Label"
@onready var border = %Border
@onready var crit_success = %CritSuccess

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
	crit_success.hide()
	await th.container_loaded
	th.thingy_created.connect(thingy_created)
	th.container.selected_index.changed.connect(selected_index_changed)
	wa.get_unlocked(Currency.Type.XP).changed.connect(xp_unlocked_changed)
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
	thingy.inhand_will.changed.connect(output_changed)
	thingy.inhand_juice.changed.connect(output_changed)
	thingy.timer_started.connect(timer_wait_time_changed)
	thingy.crit_success.changed.connect(crit_success_changed)
	thingy.level.changed.connect(level_changed)
	xp_bar.attach_value_pair(thingy.xp)
	output_changed()
	timer_wait_time_changed()
	level_changed()
	crit_success_changed()


func disconnect_calls() -> void:
	thingy.level.increased.disconnect(level_increased)
	thingy.inhand_will.changed.disconnect(output_changed)
	thingy.inhand_juice.changed.disconnect(output_changed)
	thingy.timer_started.disconnect(timer_wait_time_changed)
	thingy.crit_success.changed.disconnect(crit_success_changed)
	thingy.level.changed.disconnect(level_changed)
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
	var text: String
	match thingy.output_currency.get_value():
		Currency.Type.WILL:
			text = wa.get_details(Currency.Type.WILL).color_text % (
				"[b][i]+%s[/i][/b] %s" % [
					thingy.inhand_will.get_text(),
					wa.get_details(Currency.Type.WILL).icon_text
				]
			)
		Currency.Type.JUICE:
			text = wa.get_details(Currency.Type.JUICE).color_text % (
				"[b][i]+%s[/i][/b] %s" % [
					thingy.inhand_juice.get_text(),
					wa.get_details(Currency.Type.JUICE).icon_text
				]
			)
	output_label.text = text


func crit_success_changed() -> void:
	if thingy.crit_success.is_true():
		crit_success.show()
		crit_success.text = "[img=<15> color=#%s]%s[/img] [b][i]x%s" % [
			thingy.details.color.to_html(),
			bag.get_resource("Dice").get_path(),
			thingy.crit_multiplier.get_text()
		]
	else:
		crit_success.hide()


func timer_wait_time_changed() -> void:
	max_progress_label.text = "[i]" + tp.quick_parse(
		thingy.timer.wait_time,
		true
	)


func level_changed() -> void:
	level_label.text = wa.get_details(Currency.Type.XP).icon_text + " [b][i]" + thingy.level.get_text()


func xp_unlocked_changed() -> void:
	if wa.is_unlocked(Currency.Type.XP):
		xp_labels.show()
		xp_bar.show()
	else:
		xp_labels.hide()
		xp_bar.hide()


func level_increased() -> void:
	gv.flash(level_label, thingy.details.color)


func thingy_created() -> void:
	if not thingy:
		if th.get_selected_index() - get_offset_index() == th.get_top_index():
			assign_thingy(th.get_latest_thingy())
			th.container.update_navigator_colors()



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



# - Get


func get_offset_index() -> int:
	return get_index() - 3



# - Dev


func _on_dev_pressed():
	clear_thingy()