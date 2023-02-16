extends Control

export var log_name : String
export var path_to_file : String
export var account_name : String
var race_log_text = "SAMPLE LOG"
var decomposed_log : Dictionary = {
	"FPS" : [],
	"Speed" : [],
	"Acceleration" : [],
	"Brakes" : [],
	"Handbrake" : [],
	"Nitro" : [],
	"Gear" : []
}
var predyno_handling : Dictionary
var aftdyno_handling : Dictionary
var last_handling_change : Dictionary
var parser_mode : String = "HEADER"
var thread = Thread.new()
var checks = {
	"FPS" : [true],
	"Gas Taps" : [true],
	"Brake Taps" : [true],
	"NOS Taps" : [true],
	"Analogue Input" : [true, false]
}
var linechart = preload("res://scenes/racelog_linechart.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	self.name = account_name + ", " + log_name.replace(":", "h")
	race_log_text = utilities._get_text_from_file(path_to_file)
	$VBoxContainer/HSplitContainer/FileReader/Text.text = race_log_text
	#thread.start(self, _parse_log(), null, Thread.PRIORITY_LOW)
	_parse_log()
	#_generate_fps_chart()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_CloseButton_pressed():
	self.queue_free()

func _parse_log(): #THIS SHIT GOTTA BE MADE BETTER, TOO MUCH COPY PASTE
	var lines : Array = race_log_text.split("\n", false)
	for line in lines:
		if line == "HANDLING BEFORE DYNOSETUP:":
			parser_mode = "PREDYNO_HANDLING"
		else:
			match parser_mode:
				"PREDYNO_HANDLING":
					_decompose_handling(line)
					parser_mode = "HEADER"
				"HEADER":
					parser_mode = "FIRST_LINE"
				"FIRST_LINE":
					var split_line : Array = line.split("	", false)
					_log_values(split_line)
					parser_mode = "AFTDYNO_HANDLING"
				"AFTDYNO_HANDLING":
					if line.begins_with("("):
						_decompose_handling(line)
						var change = _compare_handlings(predyno_handling, aftdyno_handling)
						$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/Text.text += "DYNO CHANGES:\n"
						for field in change:
							$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/Text.text += field + ": " + str(change[field]) + "\n"
						parser_mode = "LOG"
					else:
						var split_line : Array = line.split("	", false)
						_log_values(split_line)
						parser_mode = "LOG"
				"LOG":
					var split_line : Array = line.split("	", false)
					_log_values(split_line)
					_run_checks(split_line)
				"HANDLING_CHANGE":
					_decompose_handling(line)
					var change = _compare_handlings(aftdyno_handling, last_handling_change)
					$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/Text.text += "\nHANDLING CHANGES DETECTED:\n"
					for field in change:
						$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/Text.text += field + ": " + str(change[field]) + "\n"
					parser_mode = "LOG"
	_analyse_fps(decomposed_log["FPS"])
	_score_likelihood_of_gas_tapping(decomposed_log["Acceleration"])
	_score_likelihood_of_nitro_tapping(decomposed_log["Nitro"])
	_score_likelihood_of_brake_tapping(decomposed_log["Acceleration"], decomposed_log["Brakes"])

func _log_values(split_line : Array, log_dictionary : Dictionary = decomposed_log):
	log_dictionary["FPS"].append(int(split_line[0]))
	log_dictionary["Speed"].append(int(split_line[1]))
	log_dictionary["Acceleration"].append(int(split_line[2]))
	log_dictionary["Brakes"].append(int(split_line[3]))
	log_dictionary["Handbrake"].append(int(split_line[4]))
	log_dictionary["Nitro"].append(int(split_line[5]))
	log_dictionary["Gear"].append(int(split_line[6]))

func _decompose_handling(handling_line : String):
	var handling_array = handling_line.trim_prefix("( ").trim_suffix(" )").split(" ", false)
	var counter = 0
	for field in handling_array:
		print(field)
		var centerOfMass : Array  = []
		var separated : Array = field.split("=", false)
		print(separated)
		if separated[0] == "centerOfMass" or counter > 0 or field.ends_with(","): 
			match counter:
				0:
					centerOfMass.append(float(separated[1].trim_suffix(",")))
					counter = 1
				1:
					centerOfMass.append(float(field.trim_suffix(",")))
					counter = 2
				2:
					centerOfMass.append(float(field))
					match parser_mode:
						"PREDYNO_HANDLING":
							predyno_handling["centerOfMass"] = centerOfMass
						"AFTDYNO_HANDLING":
							aftdyno_handling["centerOfMass"] = centerOfMass
						"HANDLING_CHANGE":
							last_handling_change["centerOfMass"] = centerOfMass
					counter = 0
		else:
			match parser_mode:
				"PREDYNO_HANDLING":
					predyno_handling[separated[0]] = separated[1]
				"AFTDYNO_HANDLING":
					aftdyno_handling[separated[0]] = separated[1]
				"HANDLING_CHANGE":
					last_handling_change[separated[0]] = separated[1]

func _compare_handlings(handling1 : Dictionary, handling2 : Dictionary) -> Dictionary:
	var changes : Dictionary = {}
	for field in handling1:
		if handling1[field] != handling2[field]:
#			if float(handling1[field]) and float(handling2[field]):
#				changes[field] = float(handling1[field]) - float(handling2[field])
#			else:
			if handling1[field] is String and handling2[field] is String:
				changes[field] = handling1[field] + " -> " + handling2[field]
			elif handling1[field] is Array and handling2[field] is Array:
				#changes[field] = "{ " + str(handling1[field][0]) + ", " + str(handling1[field][1]) + ", " + str(handling1[field][2]) + " }" + " -> " + "{ " + str(handling2[field][0]) + ", " + str(handling2[field][1]) + ", " + str(handling2[field][2]) + " }"
				pass
	return changes

func _run_checks(log_line : Array):
	if checks["Analogue Input"][0]:
		if log_line[2] != "0" and log_line[2] != "15" and log_line[2] != "16":
			$VBoxContainer/HBoxContainer/KeyboardIcon.visible = false
			$VBoxContainer/HBoxContainer/GamepadIcon.visible = true
			$VBoxContainer/HBoxContainer/ControllerType.text = "Used GAMEPAD"
			checks["Analogue Input"][0] = false
	if log_line.size() > 7:
		if log_line[7] == "HANDLING CHANGE DETECTED":
			$VBoxContainer/HBoxContainer/HandlingChanged.pressed = true
			parser_mode = "HANDLING_CHANGE"
	if checks["FPS"][0]:
		if int(log_line[0]) < 58:
			$VBoxContainer/HBoxContainer/UnstableFPS.pressed = true
			checks["FPS"][0] = false

func _analyse_fps(fps_log : Array):
	var average_fps
#	var one_percent_lows
	var fps_sum : int = 0
	var race_time : float = 0.0
	for value in fps_log:
		race_time += 1.0/value
		fps_sum += value
	$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/RaceTimeContainer/RaceTime.text += str(floor(race_time/60)) + "m" + str(int(fmod(race_time, 60.0))) + "s."
	average_fps = int(fps_sum / fps_log.size())
	$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/FPSContainer/FPSAverage.text += str(average_fps) + " "
	var sorted_fps_log : Array = _sort_fps_array(fps_log)
	var one_percent_lows_thread = Thread.new()
	one_percent_lows_thread.start(self, "_calc_1percent_lows", sorted_fps_log, Thread.PRIORITY_LOW)
	var fps_mode_thread = Thread.new()
	fps_mode_thread.start(self, "_calc_fps_mode", sorted_fps_log, Thread.PRIORITY_LOW)
	#_calc_fps_mode(sorted_fps_log)
	var fps_min_max_thread = Thread.new()
	fps_min_max_thread.start(self, "_calc_min_and_max", fps_log, Thread.PRIORITY_LOW)

func _sort_fps_array(fps_log : Array) -> Array:
	var padded_fps_log : Array = []
	for value in fps_log:
		padded_fps_log.append(str(value).pad_zeros(2))
	padded_fps_log.sort()
	return padded_fps_log

func _calc_1percent_lows(sorted_fps_log : Array):
	var result 
	var fps_sum = 0
	for i in sorted_fps_log.size()*0.01:
		fps_sum += int(sorted_fps_log[i])
	result = int(fps_sum / (sorted_fps_log.size()*0.01))
	$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/FPSContainer/FPS1PercentLows.text += str(result) + " "

func _calc_fps_mode(fps_log : Array):
	var dictionary : Dictionary = {}
	for value in fps_log:
		dictionary = utilities._add_array_item_to_key(dictionary, value, value)
	var fps_mode : String
	var mode_counter : int = 0 
	for key in dictionary:
		if dictionary[key].size() > mode_counter:
			fps_mode = str(key)
		elif dictionary[key].size() == mode_counter:
			fps_mode += " and " + str(key)
	$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/FPSContainer/FPSMode.text += fps_mode + " "

func _calc_min_and_max(fps_log : Array) -> void:
	var minimum_fps : int = 62
	var maximum_fps : int = 0
	for value in fps_log:
		if int(value) > maximum_fps:
			maximum_fps = int(value)
		if int(value) < minimum_fps:
			minimum_fps = int(value)
	$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/FPSContainer/FPSMinimum.text += str(minimum_fps) + " "
	$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/FPSContainer/FPSMaximum.text += str(maximum_fps) + " "

func _score_likelihood_of_gas_tapping(gas_log : Array = decomposed_log["Acceleration"]):
	var gas_tap_likelihood_score : float = 0.0
	var instances_detected : int = 0
	var last_gas_values : Array = [0, 0, 0, 0]
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
		$VBoxContainer/HBoxContainer/GasTaps.pressed = true
	$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/TapsScoreContainer/GasTapsScore.text += str(gas_tap_likelihood_score).pad_decimals(1) + " (" + str(instances_detected) + ")"
	# FIND OUT WHAT TO DO WITH CHECK DICT

func _score_likelihood_of_nitro_tapping(nos_log : Array = decomposed_log["Nitro"]):
	var nos_tap_likelihood_score : float = 0.0
	var instances_detected : int = 0
	var last_nos_values : Array = [0, 0, 0, 0]
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
		$VBoxContainer/HBoxContainer/NosTaps.pressed = true
	$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/TapsScoreContainer/NOSTapsScore.text += str(nos_tap_likelihood_score).pad_decimals(1) + " (" + str(instances_detected) + ")"
	# FIND OUT WHAT TO DO WITH CHECK DICT

func _score_likelihood_of_brake_tapping(gas_log : Array = decomposed_log["Acceleration"], brakes_log : Array = decomposed_log["Brakes"]):
	var brake_tap_likelihood_score : float = 0.0
	var instances_detected : int = 0
	var last_brake_values : Array = [0, 0, 0, 0, 0, 0, 0]
	var last_gas_values : Array = [0, 0, 0, 0, 0, 0, 0]
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
		$VBoxContainer/HBoxContainer/BrakeTaps.pressed = true
	$VBoxContainer/HSplitContainer/VSplitContainer/DynoChanges/TapsScoreContainer/BrakeTapsScore.text += str(brake_tap_likelihood_score).pad_decimals(1) + " (" + str(instances_detected) + ")"
	# FIND OUT WHAT TO DO WITH CHECK DICT

func _spawn_the_chart(title : String, x : Array, y : Array, x_label : String, y_label : String, x_scale : float, y_scale : float):
	var chart_instance : LineChart = Chart.instance()
	chart_instance.title = title
	chart_instance.x = x
	chart_instance.y = y
	chart_instance.x_label = x_label
	chart_instance.y_label = y_label
	chart_instance.x_scale = x_scale
	chart_instance.y_scale = y_scale
	$VBoxContainer/HSplitContainer/VSplitContainer/Chart/Control.add_child(chart_instance)

func _generate_fps_chart():
	var x : Array = _get_timeframe(decomposed_log["FPS"])
	var y : Array = [decomposed_log["FPS"]]
	var title : String = ""
	var x_label : String = ("Time")
	var y_label : String = ("FPS")
	var x_scale : float = 30.0
	var y_scale : float = 31.0
	_spawn_the_chart(title, x, y, x_label, y_label, x_scale, y_scale)

func _get_timeframe(input_array : Array) -> Array:
	var output_array : Array = []
	for i in range(1, input_array.size()):
		if output_array.empty():
			output_array.append(float(input_array[i])/1)
		else:
			output_array.append(float(input_array[i])/1 + output_array.back())
	return output_array

func _on_OpenFolderButton_pressed():
	var path_decomposed : Array = path_to_file.split("%c" % [092], false)
	var path : String = ""
	for i in range(0, path_decomposed.size() - 1):
		path += path_decomposed[i] + "%c" % [092]
	OS.shell_open(path)

func _on_FileReader_OptionButton_item_selected(index):
	match index:
		0:
			$VBoxContainer/HSplitContainer/FileReader/Text.text = race_log_text
		1:
			var text : String = "FPS | Speed | Gas | Brake | E-brake | Nitro | Gear\n"
			for i in range(0, decomposed_log["FPS"].size() - 1):
				text += " " + str(decomposed_log["FPS"][i]).pad_zeros(2) + "      " + str(decomposed_log["Speed"][i]).pad_zeros(3) + "       " + str(decomposed_log["Acceleration"][i]).pad_zeros(2) + "       " + str(decomposed_log["Brakes"][i]).pad_zeros(2) + "            " + str(decomposed_log["Handbrake"][i]/8) + "          " + str(decomposed_log["Nitro"][i]).pad_zeros(2) + "         " + str(decomposed_log["Gear"][i]) + "\n"
			$VBoxContainer/HSplitContainer/FileReader/Text.text = text
