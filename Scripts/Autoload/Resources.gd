class_name Bag
extends Node



var resources := {}
var chats := {}



func _ready():
	store_all_resources()
	Upgrade.data = get_json_category("Upgrades")



func store_all_resources() -> void:
	dir_contents("res://Art/")
	dir_contents("res://Hud/")
	dir_contents("res://Themes/")
	dir_contents("res://Resources/")
	dir_contents("res://Scripts/Dialogue/")


func dir_contents(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		if file_name in ["Animations",]:
			file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				dir_contents(path + "/" + file_name)
			else:
				if (
					file_name.ends_with(".png")
					or file_name.ends_with(".import")
					or file_name.ends_with(".svg")
					or file_name.ends_with(".tscn")
					or file_name.ends_with(".remap")
					or file_name.ends_with(".tres")
					or file_name.ends_with(".dialogue")
					or file_name.ends_with(".json")
				):
					var _name := file_name.split(".")[0]
					var _path: String = path + "/" + file_name
					_path = _path.trim_suffix(".remap")
					_path = _path.trim_suffix(".import")
					if file_name.ends_with(".json"):
						var file = FileAccess.open(_path, FileAccess.READ)
						var text = file.get_as_text()
						var json = JSON.new()
						json.parse(text)
						resources[_name] = json.data
					elif not resources.has(_name):
						resources[_name] = load(_path)
					if file_name.ends_with(".dialogue"):
						chats[_name] = resources[_name]
			file_name = dir.get_next()


func get_resource(_name: String) -> Resource:
	return resources[_name]


func get_icon(_name: String) -> Texture2D:
	return get_resource(_name)


func get_resource_path(_name: String) -> String:
	return resources[_name].get_path()


func get_scene(_name: String) -> PackedScene:
	return get_resource(_name)


func get_icon_text(_name: String, _color = 0) -> String:
	if _color == 0:
		return "[img=<15>]%s[/img]" % get_resource_path(_name)
	return "[img=<15> color=#%s]%s[/img]" % [
		_color.to_html(),
		get_resource_path(_name)
	]


func get_icon_text_know_html(_name: String, html: String) -> String:
	return "[img=<15> color=#%s]%s[/img]" % [
		html,
		get_resource_path(_name)
	]


func get_data(_name: String) -> Dictionary:
	if resources.has(_name):
		return resources[_name]
	return {}


func get_json_category(_category: String) -> Dictionary:
	return get_data("Thingy Data")[_category]
