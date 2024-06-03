class_name ThingyVico
extends MarginContainer



@onready var progress_bar = %"Progress Bar"
@onready var max_progress_label = %"Max Progress Label"
@onready var xp_bar = %"Xp Bar" as Bar
@onready var progress_label = %"Progress Label"
@onready var output_label = %"Output Label"
@onready var index_label = %"Index Label"
@onready var selected = %Selected
@onready var level_label = %"Level Label"
@onready var border = %Border
@onready var crit_success = %CritSuccess
@onready var button = %Button
@onready var flying_texts = %FlyingTexts
@onready var juiced = %Juiced
@onready var crit_success_die = %CritSuccessDie

var thingy: Thingy

var color: Color:
	set(val):
		color = val
		progress_bar.modulate = val
		index_label.modulate = val
		button.modulate = val
		crit_success_die.modulate = val
		if get_index() == 3:
			border.modulate = val



func _ready() -> void:
	set_process(false)
	juiced.modulate = wa.get_color("JUICE")
	level_label.hide()
	xp_bar.hide()
	xp_bar.color = wa.get_color("XP")
	crit_success.get_parent().hide()
	await th.container_loaded
	th.thingy_created.connect(thingy_created)
	th.container.selected_index.changed.connect(selected_index_changed)
	wa.get_unlocked("XP").changed.connect(xp_unlocked_changed)
	xp_unlocked_changed()
	
	match get_index():
		3:
			pass
		_:
			selected.queue_free()



func _process(_delta):
	progress_label.text = "[i]" + thingy.timer.get_time_elapsed_text()



# - Internal


func connect_calls() -> void:
	thingy.juiced.changed.connect(jucied_changed)
	jucied_changed()
	thingy.died.connect(clear_thingy)
	thingy.level.increased.connect(level_increased)
	thingy.timer.started.connect(timer_started)
	thingy.timer.wait_time.changed.connect(timer_wait_time_changed)
	thingy.crit_success.changed.connect(crit_success_changed)
	thingy.level.changed.connect(level_changed)
	xp_bar.attach_value_pair(thingy.xp)
	timer_wait_time_changed()
	level_changed()
	crit_success_changed()
	crit_success.attach_float(thingy.crit_multiplier)
	show()


func disconnect_calls() -> void:
	thingy.juiced.changed.disconnect(jucied_changed)
	thingy.died.disconnect(clear_thingy)
	thingy.level.increased.disconnect(level_increased)
	thingy.timer.started.disconnect(timer_started)
	thingy.timer.wait_time.changed.disconnect(timer_wait_time_changed)
	thingy.crit_success.changed.disconnect(crit_success_changed)
	thingy.level.changed.disconnect(level_changed)
	crit_success.clear_value()
	xp_bar.remove_value()



# - Signal


func jucied_changed() -> void:
	juiced.visible = thingy.juiced.get_value()


func selected_index_changed() -> void:
	if th.get_selected_index() == -1:
		return
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


func _on_button_pressed():
	if thingy:
		th.container.snap_to_index(thingy.index)


func timer_started() -> void:
	set_output_text()
	if thingy.crit_success.is_true():
		throw_crit_text()


func set_output_text() -> void:
	if not thingy.inhand:
		return
	var text: String
	match thingy.output_currency.get_value():
		"WILL":
			text = wa.get_details("WILL").get_color_text() % (
				"[b][i]+%s[/i][/b] %s" % [
					thingy.inhand.output[thingy.output_currency.get_value()].get_text(),
					wa.get_details("WILL").get_icon_text()
				]
			)
		"JUICE":
			text = wa.get_details("JUICE").get_color_text() % (
				"[b][i]+%s[/i][/b] %s" % [
					thingy.inhand.output[thingy.output_currency.get_value()].get_text(),
					wa.get_details("JUICE").get_icon_text()
				]
			)
	output_label.text = text


func crit_success_changed() -> void:
	crit_success.get_parent().visible = thingy.crit_success.get_value()


func timer_wait_time_changed() -> void:
	max_progress_label.text = "[i]" + thingy.timer.get_wait_time_text()


func level_changed() -> void:
	level_label.text = wa.get_details("XP").get_icon_text() + " [b][i]" + thingy.level.get_text()


func xp_unlocked_changed() -> void:
	if wa.is_unlocked("XP"):
		level_label.show()
		xp_bar.show()
	else:
		level_label.hide()
		xp_bar.hide()


func level_increased() -> void:
	gv.flash(level_label, thingy.color.get_value())


func thingy_created() -> void:
	if not thingy:
		if th.get_selected_index() - get_offset_index() == th.get_top_index():
			assign_thingy(th.get_latest_thingy())
			th.container.update_navigator_colors()



# - Action


func assign_thingy(_thingy: Thingy) -> void:
	if SaveManager.loading.is_true():
		await SaveManager.loading.became_false
	clear_thingy()
	thingy = _thingy
	color = thingy.color.get_value()
	connect_calls()
	set_output_text()
	progress_bar.attach_timer(thingy.timer)
	index_label.text = "[i]#" + str(thingy.index + 1)
	set_process(true)
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


func throw_crit_text() -> void:
	FlyingText.got_crit(flying_texts, thingy.crit_multiplier.get_text(), thingy.color.get_value())



# - Get


func get_offset_index() -> int:
	return get_index() - 3

