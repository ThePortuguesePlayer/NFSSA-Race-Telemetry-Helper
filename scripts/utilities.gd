extends Node

#var current_log : Array = ["SAMPLE_TITLE", "SAMPLE_PATH"]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _list_files_in_directory(path) -> Array:
	var files : Array = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)
	dir.list_dir_end()
	return files

func _get_text_from_file(path_to_file) -> String:
	var file = File.new()
	var error = file.open(path_to_file, File.READ)
	if error:
		print("utilities._get_text_from_file.file.open returned: " + str(error))
	var text : String = ""
	if not error:
		text = file.get_as_text()
	file.close()
	return text

func _add_array_item_to_key(input_dictionary : Dictionary, key, value_to_add) -> Dictionary:
	if input_dictionary.has(key):
		input_dictionary[key].append(value_to_add)
	else:
		input_dictionary[key] = [value_to_add]
	return input_dictionary
