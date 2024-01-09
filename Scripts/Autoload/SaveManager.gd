extends Node



enum SaveMethod {
	TO_FILE,
	TO_CLIPBOARD,
	TO_CONSOLE,
	TEST,
}

enum LoadMethod {
	FROM_FILE,
	FROM_CLIPBOARD,
	TEST,
}

const SAVE_BASE_PATH := "user://"
const SAVE_EXTENSION := ".thingy"

const RANDOM_PATH_POOL := [
	"PaperPilot",
	"Carl",
	"MEE6",
	"Captain Succ",
	"Cullect",
	"Ohtil",
	"Buhthul",
	"Stangmouse",
	"Stonkmaus",
	"Baby Shark", # kill me
	"And a little bonus for Merp. Fock you, Stangmouse",
	"CrimsonFrost",
	"CryptoGrounds",
	"CGGamesLLCInc.Company.Com",
	"Dimelsondr",
	"Raptors",
	"Srotpar",
	"Merp",
	"SteelDusk",
	"Water",
	"Flamemaster",
	"VoidCloud",
	"Peekabluu",
	"Peekambluu",
	"vgCollosus",
	"Aylienne",
	"Kam",
	"Master Polaris",
	"YouTube Superstar",
	"Dread Dude",
	"Blood4All",
	"Pizza",
	"PacBrad",
	"Univenon",
	"Wintermaul Wars",
	"SSJ10",
	"Pent",
	"Pent",
	"Semicolon",
	"ASMR",
	"Magic Hag",
	"retchleaf",
]

var default_save_method := SaveMethod.TO_FILE
var default_load_method := LoadMethod.FROM_FILE

@export var save_name: String = "Save"
@export var color := LoudColor.new(Color(1, 0, 0.282))
@export var save_version := {
	"major": 1,
	"minor": 0,
	"revision": 0,
}

var loaded_data: Dictionary
var last_save_clock := Time.get_unix_time_from_system()
var patched := false
var saving := LoudBool.new(false)
var loading := LoudBool.new(false)

var test_data: String
var singletons_with_exports := {}



func _ready() -> void:
	setup_singletons_with_exports()


func setup_singletons_with_exports() -> void:
	for node in get_tree().root.get_children():
		if get_tree().current_scene and node.name == get_tree().current_scene.name:
			continue
		if script_has_exported_variable(node.get_script()):
			singletons_with_exports[node.name] = node



func save_game(method := default_save_method) -> void:
	saving.set_to(true)
	
	var packed_vars = pack_singleton_export_properties()
	var save_text = JSON.stringify(packed_vars)
	
	match method:
		SaveMethod.TO_FILE:
			var save_file := FileAccess.open(get_save_path(), FileAccess.WRITE)
			save_file.store_line(Marshalls.variant_to_base64(save_text))
		SaveMethod.TO_CLIPBOARD:
			DisplayServer.clipboard_set(save_text)
		SaveMethod.TO_CONSOLE:
			print("Your LORED save data is below! Click Expand, if necessary, for your save may be very large, and then save it in any text document!")
			print(Marshalls.variant_to_base64(save_text))
		SaveMethod.TEST:
			test_data = save_text
			print("- * - GAME SAVED - * -")
			print(save_text)
	
	last_save_clock = Time.get_unix_time_from_system()
	saving.reset()



func load_game(method := default_load_method) -> void:
	loading.set_to(true)
	loaded_data = get_save_data(method)
	unpack_data(loaded_data)
	loading.reset()
	update_save_version()


func delete_save(path := save_name):
	DirAccess.remove_absolute(get_save_path(path))


func duplicate_save(path := save_name) -> void:
	var new_path = get_unique_filename(path + " (Copy)")
	DirAccess.copy_absolute(path, new_path)


func rename_path(path: String, new_path: String):
	DirAccess.rename_absolute(get_save_path(path), get_unique_filename(new_path))



# - Actions


func pack_singleton_export_properties() -> Dictionary:
	var data := {}
	for singleton in singletons_with_exports:
		data[singleton] = pack_exported_properties(singletons_with_exports[singleton])
	return data



func pack_exported_properties(object) -> Dictionary:
	var data := {}
	for variable_name in get_exported_script_property_names(object.get_script()):
		var variable = object.get(variable_name)
		if variable is Dictionary:
			data[variable_name] = pack_dictionary(variable)
		elif variable is Array:
			data[variable_name] = pack_array(variable)
		elif variable is Object:
			data[variable_name] = pack_exported_properties(variable)
		elif variable is Color:
			data[variable_name] = pack_color(variable)
		else:
			data[variable_name] = variable
	return data


func pack_dictionary(dictionary: Dictionary) -> Dictionary:
	var data := {}
	for key in dictionary:
		var value = dictionary[key]
		if value is Dictionary:
			data[key] = pack_dictionary(value)
		elif value is Object:
			data[key] = pack_exported_properties(value)
		elif value is Color:
			data[key] = pack_color(value)
		else:
			data[key] = dictionary[key]
	return data


func pack_array(array: Array) -> Dictionary:
	var data := {}
	var i := 0
	for value in array:
		var variable_class: String
		if value is Array:
			data[i] = pack_array(value)
		elif value is int:
			variable_class = "int"
			data[variable_class + str(i)] = value
		else:
			data[i] = value
		i += 1
	return data


func pack_color(value: Color) -> Dictionary:
	return {
		"r": value.r,
		"g": value.g,
		"b": value.b,
		"a": value.a,
	}



func unpack_data(data: Dictionary) -> void:
	for singleton in singletons_with_exports:
		if not singleton in data.keys():
			continue
		unpack_vars(singletons_with_exports[singleton], data[singleton])


func unpack_vars(object, packed_vars: Dictionary) -> void:
	for variable_name in get_exported_script_property_names(object.get_script()):
		if not variable_name in packed_vars.keys():
			continue
		var variable = object.get(variable_name)
		var packed_variable = packed_vars[variable_name]
		
		if variable is Dictionary:
			object.set(variable_name, unpack_dictionary(variable, packed_variable))
		elif variable is Array:
			object.set(variable_name, unpack_array(packed_variable))
		elif variable is Object:
			unpack_vars(object.get(variable_name), packed_variable)
			if variable is Big:
				variable.emit_change()
				variable.emit_increase()
				variable.emit_decrease()
		elif variable is Color:
			unpack_color(object.get(variable_name), packed_variable)
		else:
			object.set(variable_name, packed_variable)


func unpack_dictionary(dictionary: Dictionary, packed_dictionary: Dictionary) -> Dictionary:
	if dictionary.is_empty():
		return unpack_dictionary_to_empty_dictionary(dictionary, packed_dictionary)
	for key in dictionary:
		if not key in packed_dictionary.keys():
			continue
		var value = dictionary[key]
		var packed_value = packed_dictionary[key]
		if value is Dictionary:
			dictionary[key] = unpack_dictionary(value, packed_value)
		elif value is Object:
			unpack_vars(dictionary[key], packed_value)
			if value is Big:
				value.emit_change()
				value.emit_increase()
				value.emit_decrease()
		elif value is Color:
			unpack_color(dictionary[key], packed_value)
		else:
			dictionary[key] = packed_value
	return dictionary


func unpack_dictionary_to_empty_dictionary(dictionary: Dictionary, packed_dictionary: Dictionary) -> Dictionary:
	for key in packed_dictionary.keys():
		var new_key = key
		if key is String and int(key) == round(int(key)):
			new_key = int(key)
		match packed_dictionary[key]["_class_name"]:
			"Thingy":
				th.new_thingy()
				dictionary[new_key] = th.get_latest_thingy()
				unpack_vars(dictionary[new_key], packed_dictionary[key])
	return dictionary


func unpack_array(packed_array: Dictionary) -> Array:
	var array := []
	for key in packed_array:
		var data = packed_array[key]
		var variable_class = key.rstrip("0123456789")
		
		if variable_class == "int":
			array.append(int(data))
		
		else:
			array.append(data)
	
	return array


func unpack_color(_color: Color, packed_color: Dictionary) -> void:
	_color = Color(
		packed_color["r"],
		packed_color["g"],
		packed_color["b"],
		packed_color["a"],
	)



func update_save_version() -> void:
	var version_text = ProjectSettings.get("application/config/Version").split(".")
	save_version.major = version_text[0]
	save_version.minor = version_text[1]
	save_version.revision = version_text[2]



#region Get


func get_save_data(method := default_load_method, filename := save_name) -> Dictionary:
	var save_text: String = get_save_text(method, filename)
	var json = JSON.new()
	json.parse(save_text)
	if method == LoadMethod.TEST:
		print(json.data)
	return json.data


func get_save_text(method := default_load_method, filename := save_name) -> String:
	var save_text: String
	match method:
		LoadMethod.FROM_FILE:
			var save_file := FileAccess.open(get_save_path(filename), FileAccess.READ)
			save_text = Marshalls.base64_to_variant(save_file.get_line())
		LoadMethod.FROM_CLIPBOARD:
			save_text = DisplayServer.clipboard_get()
		LoadMethod.TEST:
			print("- * - LOADING GAME - * -")
			save_text = test_data
	return save_text


func save_exists(filename := save_name) -> bool:
	return FileAccess.file_exists(get_save_path(filename))


func is_compatible_save(data: Dictionary) -> bool:
	if data == {}:
		return false
	if not "SaveManager" in data.keys():
		return false
	return true


func can_load_game(method := default_load_method, filename = save_name) -> bool:
	if not save_exists(filename):
		return false
	var json = JSON.new()
	var error = json.parse(get_save_text(method, filename))
	if error != OK:
		print("Loading error. ", error)
		return false
	var data := get_save_data()
	return is_compatible_save(data)


func get_exported_script_property_names(script: Script) -> Array[String]:
	var variable_names: Array[String]
	for property in script.get_script_property_list():
		if property.usage == 4102:
			variable_names.append(property.name)
	return variable_names


func script_has_exported_variable(script: Script) -> bool:
	for property in script.get_script_property_list():
		if property.usage == 4102:
			return true
	return false


func is_version_changed_since_save() -> bool:
	var version_text = ProjectSettings.get("application/config/Version").split(".")
	var version := {
		"major": version_text[0],
		"minor": version_text[1],
		"revision": version_text[2],
	}
	if save_version.major < version.major:
		return true
	if save_version.minor < version.minor:
		return true
	return save_version.revision < version.revision


func get_save_path(filename := save_name) -> String:
	return SAVE_BASE_PATH + filename + SAVE_EXTENSION


func get_unique_filename(filename: String) -> String:
	randomize()
	var new_filename := filename
	while save_exists(new_filename):
		new_filename += str(Time.get_unix_time_from_system() + randi())
	return new_filename


func get_random_filename() -> String:
	return get_unique_filename(RANDOM_PATH_POOL[randi() % RANDOM_PATH_POOL.size()])


func get_time_since_last_save() -> float:
	return gv.current_clock - last_save_clock


#endregion
