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

func _get_decomposed_log(path : String) -> Dictionary:
	var text : String = _get_text_from_file(path)
	var decomposed_log : Dictionary = {
		"FPS" : [],
		"Speed" : [],
		"Acceleration" : [],
		"Brakes" : [],
		"Handbrake" : [],
		"Nitro" : [],
		"Gear" : [],
		"Handling Change" : false
	}
	var parser_mode : String = "HEADER"
	var lines : Array = text.split("\n", false)
	for line in lines:
		if line == "HANDLING BEFORE DYNOSETUP:" or line == "NON-DYNO'D RACE START HANDLING":
			parser_mode = "PREDYNO_HANDLING"
		else:
			match parser_mode:
				"PREDYNO_HANDLING":
					#_decompose_handling(line)
					parser_mode = "HEADER"
				"HEADER":
					parser_mode = "FIRST_LINE"
				"FIRST_LINE":
					var split_line : Array = line.split("	", false)
					decomposed_log = _log_decomposed_values(split_line, decomposed_log)
					parser_mode = "AFTDYNO_HANDLING"
				"AFTDYNO_HANDLING":
					if line.begins_with("("):
						#_decompose_handling(line)
						#var change = _compare_handlings(predyno_handling, aftdyno_handling)
						#$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/Text.text += "DYNO CHANGES:\n"
						#for field in change:
						#	$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/Text.text += field + ": " + str(change[field]) + "\n"
						parser_mode = "LOG"
					else:
						var split_line : Array = line.split("	", false)
						decomposed_log = _log_decomposed_values(split_line, decomposed_log)
						parser_mode = "LOG"
				"LOG":
					var split_line : Array = line.split("	", false)
					decomposed_log = _log_decomposed_values(split_line, decomposed_log)
					if split_line.size() > 7:
						if split_line[7] == "HANDLING CHANGE DETECTED":
							parser_mode = "HANDLING_CHANGE"
							decomposed_log["Handling Change"] = true
				"HANDLING_CHANGE":
					#_decompose_handling(line)
					#var change = _compare_handlings(aftdyno_handling, last_handling_change)
					#$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/Text.text += "\nHANDLING CHANGES DETECTED:\n"
					#for field in change:
					#	$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/Text.text += field + ": " + str(change[field]) + "\n"
					parser_mode = "LOG"
	return decomposed_log

func _log_decomposed_values(split_line : Array, log_dictionary : Dictionary) -> Dictionary:
	log_dictionary["FPS"].append(int(split_line[0]))
	log_dictionary["Speed"].append(int(split_line[1]))
	log_dictionary["Acceleration"].append(int(split_line[2]))
	log_dictionary["Brakes"].append(int(split_line[3]))
	log_dictionary["Handbrake"].append(int(split_line[4]))
	log_dictionary["Nitro"].append(int(split_line[5]))
	log_dictionary["Gear"].append(int(split_line[6]))
	return log_dictionary

func _get_fps_analysis(fps_log : Array, enabled_metrics : Array = ["average", "1%lows", "lowest", "highest", "racetime", "stability"]) -> Dictionary:
	var fps_sum : int = 0
	var average_fps : int
	var one_percent_lows : int
	var lowest_fps : int = 62
	var highest_fps : int = 0
	#var mode_fps : String
	var race_time : float = 0.0
	var unstable_fps : bool = false
	var output : Dictionary = {}
	for value in fps_log:
		if enabled_metrics.has("racetime"):
			race_time += 1.0/value
		if enabled_metrics.has("average"):
			fps_sum += value
		if enabled_metrics.has("highest") and value > highest_fps:
			highest_fps = value
		if enabled_metrics.has("lowest") and value < lowest_fps:
			lowest_fps = value
		if enabled_metrics.has("stability") and not unstable_fps:
			if value < 58:
				unstable_fps = true
	if enabled_metrics.has("average"):
		average_fps = int(fps_sum / fps_log.size())
	if enabled_metrics.has("1%lows"):
		var sorted_fps_log : Array = _sort_fps_array(fps_log)
		fps_sum = 0
		for i in sorted_fps_log.size()*0.01:
			fps_sum += int(sorted_fps_log[i])
		if sorted_fps_log.size():
			one_percent_lows = int(fps_sum / (sorted_fps_log.size()*0.01))
		else:
			one_percent_lows = sorted_fps_log[0]
	# Mode is missing from here.
	if enabled_metrics.has("average"):
		output["Average"] = average_fps
	if enabled_metrics.has("1%lows"):
		output["1% Lows"] = one_percent_lows
	if enabled_metrics.has("lowest"):
		output["Lowest"] = lowest_fps
	if enabled_metrics.has("highest"):
		output["Highest"] = highest_fps
	#output["Mode"] = mode_fps
	if enabled_metrics.has("racetime"):
		output["Race Time"] = str(floor(race_time/60)) + "m" + str(int(fmod(race_time, 60.0))) + "s"
	if enabled_metrics.has("stability"):
		output["Unstable?"] = unstable_fps
	return output

func _sort_fps_array(fps_log : Array) -> Array:
	var padded_fps_log : Array = []
	for value in fps_log:
		padded_fps_log.append(str(value).pad_zeros(2))
	padded_fps_log.sort()
	return padded_fps_log

func _get_likelihood_score_of_gas_tapping(gas_log : Array) -> Dictionary:
	var gas_tap_likelihood_score : float = 0.0
	var instances_detected : int = 0
	var last_gas_values : Array = [0, 0, 0, 0]
	var is_tapping : bool = false
	var output : Dictionary
	for value in gas_log:
		value = int(value)
		last_gas_values[0] = last_gas_values[1]
		last_gas_values[1] = last_gas_values[2]
		last_gas_values[2] = last_gas_values[3]
		last_gas_values[3] = value
		if last_gas_values[0] >= 15 and last_gas_values[1] >= 15 and last_gas_values[3] >= 15 and last_gas_values[2] < 6:
			gas_tap_likelihood_score += 1.0
			instances_detected += 1
		elif last_gas_values[0] >= 15 and last_gas_values[1] < 6 and last_gas_values[2] < 6 and last_gas_values[3] >= 15:
			gas_tap_likelihood_score += 0.9
			instances_detected += 1
		elif last_gas_values[0] >= 15 and last_gas_values[1] < 14 and last_gas_values[2] < 14 and last_gas_values[3] >= 15:
			gas_tap_likelihood_score += 0.6
			instances_detected += 1
		elif last_gas_values[0] > 6 and last_gas_values[1] < 6 and last_gas_values[2] < 6 and last_gas_values[3] >= 15:
			gas_tap_likelihood_score += 0.3
			instances_detected += 1
		elif last_gas_values[0] > 6 and last_gas_values[1] < 6 and last_gas_values[2] < 6 and last_gas_values[3] > 6:
			gas_tap_likelihood_score += 0.2
			instances_detected += 1
	if gas_tap_likelihood_score > 6.0:
		is_tapping = true
	output["Score"] = gas_tap_likelihood_score
	output["Instances"] = instances_detected
	output["Tapping?"] = is_tapping
	output["Text Format"] = str(gas_tap_likelihood_score).pad_decimals(1) + " (" + str(instances_detected) + ")"
	return output

func _get_likelihood_score_of_nitro_tapping(nos_log : Array) -> Dictionary:
	var nos_tap_likelihood_score : float = 0.0
	var instances_detected : int = 0
	var last_nos_values : Array = [0, 0, 0, 0]
	var is_tapping : bool = false
	var output : Dictionary
	for value in nos_log:
		value = int(value)
		last_nos_values[0] = last_nos_values[1]
		last_nos_values[1] = last_nos_values[2]
		last_nos_values[2] = last_nos_values[3]
		last_nos_values[3] = value
		if last_nos_values[0] == 14 and last_nos_values[1] == 14 and last_nos_values[2] == 0 and last_nos_values[3] == 14:
			nos_tap_likelihood_score += 1.0
			instances_detected += 1
		elif last_nos_values[0] == 15 and last_nos_values[1] == 0 and last_nos_values[2] == 0 and last_nos_values[3] == 14:
			nos_tap_likelihood_score += 0.8
			instances_detected += 1
	if nos_tap_likelihood_score > 6.0:
		is_tapping = true
	output["Score"] = nos_tap_likelihood_score
	output["Instances"] = instances_detected
	output["Tapping?"] = is_tapping
	output["Text Format"] = str(nos_tap_likelihood_score).pad_decimals(1) + " (" + str(instances_detected) + ")"
	return output

func _get_likelihood_score_of_brake_tapping(gas_log : Array, brakes_log : Array) -> Dictionary:
	var brake_tap_likelihood_score : float = 0.0
	var instances_detected : int = 0
	var last_brake_values : Array = [0, 0, 0, 0, 0, 0, 0]
	var last_gas_values : Array = [0, 0, 0, 0, 0, 0, 0]
	var is_tapping : bool = false
	var output : Dictionary
	for i in range(0, gas_log.size() - 1):
		last_brake_values[0] = last_brake_values[1]
		last_brake_values[1] = last_brake_values[2]
		last_brake_values[2] = last_brake_values[3]
		last_brake_values[3] = last_brake_values[4]
		last_brake_values[4] = last_brake_values[5]
		last_brake_values[5] = last_brake_values[6]
		last_brake_values[6] = int(brakes_log[i])
		last_gas_values[0] = last_gas_values[1]
		last_gas_values[1] = last_gas_values[2]
		last_gas_values[2] = last_gas_values[3]
		last_gas_values[3] = last_gas_values[4]
		last_gas_values[4] = last_gas_values[5]
		last_gas_values[5] = last_gas_values[6]
		last_gas_values[6] = int(gas_log[i])
		if last_brake_values[0] == 0 and last_brake_values[1] > 0 and last_brake_values[2] > 1 and last_brake_values[3] > 1 and last_brake_values[4] > 1 and last_brake_values[5] > 0 and last_brake_values[6] == 0 and last_gas_values[0] == 15 and last_gas_values[1] == 15 and last_gas_values[2] == 15 and last_gas_values[3] == 15 and last_gas_values[4] == 15 and last_gas_values[5] == 15 and last_gas_values[6] == 15:
			brake_tap_likelihood_score += 0.6
			instances_detected += 1
		elif last_brake_values[0] == 0 and last_brake_values[1] > 0 and last_brake_values[2] > 1 and last_brake_values[3] > 0 and last_brake_values[4] > 0 and last_brake_values[5] == 0 and last_brake_values[6] == 0 and last_gas_values[0] == 15 and last_gas_values[1] == 15 and last_gas_values[2] == 15 and last_gas_values[3] == 15 and last_gas_values[4] == 15 and last_gas_values[5] == 15 and last_gas_values[6] == 15:
			brake_tap_likelihood_score += 0.7
			instances_detected += 1
		elif last_brake_values[0] == 0 and last_brake_values[1] == 0 and last_brake_values[2] > 0 and last_brake_values[3] > 1 and last_brake_values[4] > 0 and last_brake_values[5] == 0 and last_brake_values[6] == 0 and last_gas_values[0] == 15 and last_gas_values[1] == 15 and last_gas_values[2] == 15 and last_gas_values[3] == 15 and last_gas_values[4] == 15 and last_gas_values[5] == 15 and last_gas_values[6] == 15:
			brake_tap_likelihood_score += 0.8
			instances_detected += 1
		elif last_brake_values[0] == 0 and last_brake_values[1] == 0 and last_brake_values[2] > 1 and last_brake_values[3] > 1 and last_brake_values[4] == 0 and last_brake_values[5] == 0 and last_brake_values[6] == 0 and last_gas_values[0] == 15 and last_gas_values[1] == 15 and last_gas_values[2] == 15 and last_gas_values[3] == 15 and last_gas_values[4] == 15 and last_gas_values[5] == 15 and last_gas_values[6] == 15:
			brake_tap_likelihood_score += 0.9
			instances_detected += 1
		elif last_brake_values[0] == 0 and last_brake_values[1] == 0 and last_brake_values[2] == 0 and last_brake_values[3] > 1 and last_brake_values[4] == 0 and last_brake_values[5] == 0 and last_brake_values[6] == 0 and last_gas_values[0] == 15 and last_gas_values[1] == 15 and last_gas_values[2] == 15 and last_gas_values[3] == 15 and last_gas_values[4] == 15 and last_gas_values[5] == 15 and last_gas_values[6] == 15:
			brake_tap_likelihood_score += 1.0
			instances_detected += 1
	if brake_tap_likelihood_score > 6.0:
		is_tapping = true
	output["Score"] = brake_tap_likelihood_score
	output["Instances"] = instances_detected
	output["Tapping?"] = is_tapping
	output["Text Format"] = str(brake_tap_likelihood_score).pad_decimals(1) + " (" + str(instances_detected) + ")"
	return output

func _get_modification_timestamp_from_file(file_path : String) -> String:
	var file_instance = File.new()
	var modification_unix_time : int = file_instance.get_modified_time(file_path)
	#print(modification_unix_time)
	var modification_date : String = Time.get_datetime_string_from_unix_time(modification_unix_time, true)
	#print(modification_date)
	#print(modification_date.substr(0, 16))
	#modification_date.erase(-3, 3)
	return modification_date.substr(0, 16)
