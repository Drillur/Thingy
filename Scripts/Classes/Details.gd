class_name Details
extends RefCounted



signal icon_set
signal name_set
signal title_set
signal color_set


var data := {
	"icon": {
		"set": false,
		"texture": Texture2D,
		"is_colored": false,
		"path": "",
		"text": "",
	},
	"color": {
		"set": false,
		"html": "",
		"color": Color.WHITE,
		"text": "",
	},
	"name": {
		"set": false,
		"text": "",
		#"colored": "",
		"plural": "",
	},
	"title": {
		"set": false,
		"text": "",
		"colored": "",
	},
	"icon_and_name": "",
	"icon_and_title": "",
	"icon_and_colored_name": "",
	"description": "",
	"colored_name": "",
	"bright_color": Color.WHITE,
}


func _init() -> void:
	icon_set.connect(value_set)
	color_set.connect(value_set)
	name_set.connect(value_set)
	title_set.connect(value_set)


#region Signals


func value_set() -> void:
	if data.color.set and data.icon.set and not data.icon.is_colored:
		data.icon.text = data.icon.text % data.color.html
	if data.name.set and data.icon.set:
		data.icon_and_name = data.icon.text + " " + data.name.text
	if data.title.set and data.color.set:
		data.title.colored = data.color.text % data.title.text
	if data.title.set and data.icon.set:
		data.icon_and_title = data.icon.text + " " + data.title.text
	if data.name.set and data.color.set:
		data.colored_name = data.color.text % data.name.text
	if data.name.set and data.color.set and data.icon.set:
		data.icon_and_colored_name = data.icon.text + " " + data.color.text % data.name.text


#endregion


#region Action


func set_color(_color: Color) -> void:
	data.color.color = _color
	data.color.html = _color.to_html()
	data.color.set = true
	data.color.text = "[color=#" + data.color.html + "]%s[/color]"
	
	_color.r *= 1.15
	_color.g *= 1.15
	_color.b *= 1.15
	data.bright_color = _color
	color_set.emit()


func set_icon(_icon: Texture2D, is_colored_icon: bool = true) -> void:
	data.icon.texture = _icon
	data.icon.is_colored = is_colored_icon
	data.icon.path = _icon.get_path()
	if is_colored_icon:
		data.icon.text = "[img=<15>]" + data.icon.path + "[/img]"
	else:
		data.icon.text = "[img=<15> color=#%s]" + data.icon.path + "[/img]"
	data.icon.set = true
	icon_set.emit()


func set_name(_name: String) -> void:
	data.name.text = _name
	data.name.plural = (
		data.name.text.replace("y", "ies") if data.name.text.ends_with("y") else (
			data.name.text + "s"
		)
	)
	data.name.set = true
	name_set.emit()


func set_title(_title: String) -> void:
	data.title.text = _title
	data.title.set = true
	title_set.emit()


func set_description(_description: String) -> void:
	data.description = _description


#endregion



#region Get


func get_icon() -> Texture2D:
	return data.icon.texture


func get_icon_path() -> String:
	return data.icon.path


func get_icon_text() -> String:
	return data.icon.text


func get_icon_and_title() -> String:
	return data.icon_and_title


func get_icon_and_name() -> String:
	return data.icon_and_name


func get_name() -> String:
	return data.name.text


func get_title() -> String:
	return data.title.text


func get_colored_title() -> String:
	return data.title.colored


func get_plural_name() -> String:
	return data.name.plural


func get_color_text() -> String:
	return data.color.text


func get_html() -> String:
	return data.color.html


func get_colored_name() -> String:
	return data.colored_name


func get_color() -> Color:
	return data.color.color


func get_bright_color() -> Color:
	return data.bright_color


func get_icon_and_colored_name() -> String:
	return data.icon_and_colored_name


func is_color_set() -> bool:
	return data.color.set


func is_icon_set() -> bool:
	return data.icon.set


func get_description() -> String:
	return data.description


func is_description_set() -> bool:
	return data.description != ""


static func get_value(value: String, singleton, type: int):
	var d = singleton.get_details(type)
	return d.call("get_" + value)


#endregion
