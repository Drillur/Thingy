extends Node


const dev_mode := true

var root_ready := LoudBool.new(false)




func get_random_color() -> Color:
	var r = randf_range(0, 1)
	var g = randf_range(0, 1)
	var b = randf_range(0, 1)
	return Color(r, g, b, 1.0)


func get_random_nondark_color() -> Color:
	var r = randf_range(0, 1)
	var g = randf_range(0, 1)
	var b = randf_range(0, 1)
	while r + g + b < 1.0:
		r *= 1.1
		g *= 1.1
		b *= 1.1
	return Color(r, g, b, 1.0)


func flash(parent: Node, color = Color(1, 0, 0)) -> void:
	if Engine.get_frames_per_second() < 60:
		return
	var _flash = bag.get_resource("flash").instantiate()
	parent.add_child(_flash)
	_flash.flash(color)
