extends Node



var resource_preloader := ResourcePreloader.new()



func _ready():
	store_all_resources()



func store_all_resources() -> void:
	dir_contents("res://Hud/")
	dir_contents("res://Art/")
	dir_contents("res://Themes/")


func dir_contents(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		if file_name in ["Animations", "Terrain"]:
			file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				dir_contents(path + "/" + file_name)
			else:
				if (
					file_name.ends_with(".png")
					or file_name.ends_with(".svg")
					or file_name.ends_with(".tscn")
					or file_name.ends_with(".tres")
					or file_name.ends_with(".dialogue")
				):
					var _name := file_name.split(".")[0]
					var _path = path + "/" + file_name
					if gv.dev_mode:
						if resource_preloader.has_resource(_name):
							printerr(_name, " already in resource_preloader! Change resource name!")
					resource_preloader.add_resource(_name, load(_path))
			file_name = dir.get_next()



func get_icon_text(_name: String, size := 15) -> String:
	return "[img=<%s>]%s[/img]" % [str(size), get_resource_path(_name)]


func get_resource(_name: String) -> Resource:
	return resource_preloader.get_resource(_name)


func get_icon(_name: String) -> Texture2D:
	return get_resource(_name)


func get_progress_icon(percent: float) -> Texture2D:
	if percent <= 0.125:
		return get_icon("progress 1")
	if percent <= 0.25:
		return get_icon("progress 2")
	if percent <= 0.375:
		return get_icon("progress 3")
	if percent <= 0.5:
		return get_icon("progress 4")
	if percent <= 0.625:
		return get_icon("progress 5")
	if percent <= 0.75:
		return get_icon("progress 6")
	if percent <= 0.875:
		return get_icon("progress 7")
	return get_icon("progress 8")


func get_resource_path(_name: String) -> String:
	return resource_preloader.get_resource(_name).get_path()
