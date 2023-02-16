extends VBoxContainer

var players_list : Dictionary = {}
var logs_list : Dictionary = {}
var active_account : String
signal log_selected(log_name, log_path, account_name)
var list_mode : String = "EMPTY"
var current_path : String = ""
#var thread = Thread.new()
var multithread : bool = false

func _ready():
	if $SearchContainer/Day.selected == 0:
		$SearchContainer/Day.text = "D"
	if $SearchContainer/Hour.selected == 0:
		$SearchContainer/Hour.text = "H"
	if $SearchContainer/Minute.selected == 0:
		$SearchContainer/Minute.text = "M"

func _on_OpenButton_pressed():
	current_path = $PathContainer/Editor.text
	_select_import_action_based_on_path(current_path)

func _select_import_action_based_on_path(path):
	var folder_names : Array = path.split("%c" % [092], false)
	if folder_names.has("RECORDS") or folder_names.has("RECORDS_SUSP"):
		if folder_names.back().begins_with("RECORDS"):
			print("Path is RECORDS folder")
			if multithread:
				var thread = Thread.new()
				thread.start(self, "_populate_players_list", path, 0)
			else:
				_populate_players_list(path)
			list_mode = "PLAYERS"
		elif folder_names[-2].begins_with("RECORDS") or (folder_names.back().begins_with("20") and folder_names.back()[4] == "-"): #MONTH
			print("Path is month folder")
			if multithread:
				var thread = Thread.new()
				thread.start(self, "_populate_player_list_of_single_month", path, 1)
			else:
				_populate_player_list_of_single_month(path)
			list_mode = "PLAYERS"
		elif folder_names[-3].begins_with("RECORDS") or (folder_names[-2].begins_with("20") and folder_names[-2][4] == "-"): #PLAYER
			print("Path is player folder")
			if multithread:
				var thread = Thread.new()
				thread.start(self, "_populate_logs_list_from_player_folder", path, 1)
			else:
				_populate_logs_list_from_player_folder(path)
			list_mode = "LOGS"
		elif folder_names[-4].begins_with("RECORDS") or (folder_names[-3].begins_with("20") and folder_names[-3][4] == "-"): #DAY
			print("Path is day folder")
			if multithread:
				var thread = Thread.new()
				thread.start(self, "_populate_player_logs_from_day_folder", path, 1)
			else:
				_populate_player_logs_from_day_folder(path)
			list_mode = "LOGS"
		elif folder_names[-5].begins_with("RECORDS") or (folder_names[-4].begins_with("20") and folder_names[-4][4] == "-"): #CAR
			print("Path is car folder")
			if multithread:
				var thread = Thread.new()
				thread.start(self, "_populate_player_logs_from_car_folder", path, 1)
			else:
				_populate_player_logs_from_car_folder(path)
			list_mode = "LOGS"
	else:
		var present_files : Array = utilities._list_files_in_directory(path)
		if not present_files.has("lastnickname.txt") or not present_files.has("lastserial.txt"):
			var files_found : bool = false
			for file in present_files:
				if file.ends_with(".txt") and file[2] == " ":
					files_found = true
					# And add it to the list <--
					list_mode = "LOGS"
				elif file.begins_with("RECORDS") and not "." in file:
					files_found = true
					# enter folders and add players to the list <--
					list_mode = "PLAYERS"
			if not files_found:
				$PathContainer/Editor.text = "Path to RECORDS or any of its subfolders here"
				list_mode = "EMPTY"
				$ItemList.clear()
		else:
			pass

func _populate_player_logs_from_day_folder(path):
	var start_time : float = Time.get_unix_time_from_system() 
	$Status.text = "Loading logs..."
	$ItemList.clear()
	logs_list = {}
	var folders_list : Array = utilities._list_files_in_directory(path)
	var nickname : String
	for car in folders_list:
		var car_folder : String = path + "%c" % [092] + car
		var files_list : Array = utilities._list_files_in_directory(car_folder)
		if files_list.has("lastnickname.txt"):
			nickname = utilities._get_text_from_file(car_folder + "%c" % [092] + "lastnickname.txt")
			break
	if not nickname:
		var split_path : Array = path.split("%c" % [092], false)
		nickname = split_path[-2]
	active_account = nickname
	for car in folders_list:
		if $SearchContainer/CarName.text in car or not $SearchContainer/CarName.text:
			var files_list : Array = utilities._list_files_in_directory(path + "%c" % [092] + car)
			for file in files_list:
				if file != "lastnickname.txt" and file != "lastserial.txt":
					if ($SearchContainer/Hour.get_item_text($SearchContainer/Hour.selected) == "All" or $SearchContainer/Hour.get_item_text($SearchContainer/Hour.selected).pad_zeros(2) == file.substr(0, 2)) and ($SearchContainer/Minute.get_item_text($SearchContainer/Minute.selected) == "All" or $SearchContainer/Minute.get_item_text($SearchContainer/Minute.selected).pad_zeros(2) == file.substr(3, 2)):
						var file_name : String = file.substr(0, 2) + "h" + file.substr(3, 2) + " (" + car + ")"
						var file_path : String = path + "%c" % [092] + car + "%c" % [092] + file
						logs_list[file_name] = file_path
						$ItemList.add_item(file_name)
						$ItemList.sort_items_by_text()
	var time_elapsed : float = Time.get_unix_time_from_system() - start_time 
	$Status.text = "All " + str(logs_list.size()) + " logs from " + nickname + " in the list. (Took " + str(time_elapsed) + " seconds)"

func _populate_player_logs_from_car_folder(path):
	var start_time : float = Time.get_unix_time_from_system() 
	$Status.text = "Loading logs..."
	$ItemList.clear()
	logs_list = {}
	#var split_path : Array = path.split("%c" % [092], false)
	var files_list : Array = utilities._list_files_in_directory(path)
	var nickname : String
	if files_list.has("lastnickname.txt"):
		 nickname = utilities._get_text_from_file(path + "%c" % [092] + "lastnickname.txt")
	else:
		var split_path : Array = path.split("%c" % [092], false)
		nickname = split_path[-3]
	active_account = nickname
	for file in files_list:
		if file.ends_with(".txt") and file != "lastnickname.txt" and file != "lastserial.txt":
			if ($SearchContainer/Hour.get_item_text($SearchContainer/Hour.selected) == "All" or $SearchContainer/Hour.get_item_text($SearchContainer/Hour.selected).pad_zeros(2) == file.substr(0, 2)) and ($SearchContainer/Minute.get_item_text($SearchContainer/Minute.selected) == "All" or $SearchContainer/Minute.get_item_text($SearchContainer/Minute.selected).pad_zeros(2) == file.substr(3, 2)):
				var file_name : String = file.substr(0, 2) + "h" + file.substr(3, 2)
				var file_path : String = path + "%c" % [092] + file
				#var file_instance = File.new()
				#var modification_unix_time : int = file_instance.get_modified_time(file_path)
				#var modification_date : String = Time.get_datetime_string_from_unix_time(modification_unix_time, true)
				#modification_date.erase(-3, 3)
				#var tab_name : String = nickname + ", " + modification_date.substr(0, -3) + " (" + split_path[-1] + ")"
				logs_list[file_name] = file_path
				$ItemList.add_item(file_name)
				$ItemList.sort_items_by_text()
	var time_elapsed : float = Time.get_unix_time_from_system() - start_time 
	$Status.text = "All " + str(logs_list.size()) + " logs from " + nickname + " in the list. (Took " + str(time_elapsed) + " seconds)"

func _populate_players_list(path) -> void:
	var start_time : float = Time.get_unix_time_from_system() 
	$Status.text = "Loading players..."
	$ItemList.clear()
	players_list = {}
	var records : Array = utilities._list_files_in_directory(path)
	var months : Array = $SearchContainer/MonthsButton.checked_items
	var enabled_folders : Array = []
	for folder in records:
		if months.has(folder.substr(5)):
			enabled_folders.append(folder)
	for month in enabled_folders:
		var month_path : String = path + "%c" % [092] + month
		var accounts : Array = utilities._list_files_in_directory(month_path)
		for account in accounts:
			var account_path : String = month_path + "%c" % [092] + account
			var nickname : String = _dig_into_account_for_last_nickname(account_path)
			if nickname:
				_assemble_player_name_and_add_to_itemlist(account, nickname, account_path)
	var time_elapsed : float = Time.get_unix_time_from_system() - start_time 
	$Status.text = "All " + str(players_list.size()) + " players in the list. (Took " + str(time_elapsed) + " seconds)"

func _assemble_player_name_and_add_to_itemlist(account : String, nickname : String, path : String) -> void:
	var entry : String = nickname + " (" + account + ")"
	if not players_list.has(entry):
		if not $SearchContainer/PlayerName.text or $SearchContainer/PlayerName.text.to_lower() in entry.to_lower():
			players_list[entry] = [account, nickname]
			$ItemList.add_item(entry)
			$ItemList.sort_items_by_text()

func _populate_player_list_of_single_month(path) -> void:
	var start_time : float = Time.get_unix_time_from_system() 
	$Status.text = "Loading players..."
	$ItemList.clear()
	players_list = {}
	var accounts : Array = utilities._list_files_in_directory(path)
	for account in accounts:
		var account_path : String = path + "%c" % [092] + account
		var nickname : String = _dig_into_account_for_last_nickname(account_path)
		if nickname:
			_assemble_player_name_and_add_to_itemlist(account, nickname, account_path)
	var time_elapsed : float = Time.get_unix_time_from_system() - start_time 
	$Status.text = "All " + str(players_list.size()) + " players in the list. (Took " + str(time_elapsed) + " seconds)"

func _populate_logs_list_from_player_folder(path) -> void:
	var start_time : float = Time.get_unix_time_from_system() 
	var nickname : String = _dig_into_account_for_last_nickname(path)
	var player_account_name : String = str(path.split("%c" % [092], false)[-1])
	active_account = player_account_name
	var player_full_name : String = nickname + " (" + player_account_name + ")"
	$Status.text = "Loading logs from " + player_full_name + "..."
	$ItemList.clear()
	logs_list = {}
	var folder_days : Array = utilities._list_files_in_directory(path)
	for day in folder_days:
		var folder_cars : Array = utilities._list_files_in_directory(path + "%c" % [092] + day)
		for car in folder_cars:
			if not $SearchContainer/CarName.text or $SearchContainer/CarName.text.to_lower() in car.to_lower():
				var txt_files : Array = utilities._list_files_in_directory(path + "%c" % [092] + day + "%c" % [092] + car)
				var nickname_says_do_import_file : bool = false
				var serial_says_do_import_file : bool = false
				if txt_files.has("lastnickname.txt"):
					var local_nickname : String = utilities._get_text_from_file(path + "%c" % [092] + day + "%c" % [092] + car + "%c" % [092] + "lastnickname.txt")
					if not $SearchContainer/PlayerName.text or $SearchContainer/PlayerName.text.to_lower() in local_nickname.to_lower() or $SearchContainer/PlayerName.text.to_lower() in player_account_name.to_lower():
						nickname_says_do_import_file = true
				if txt_files.has("lastserial.txt"):
					var local_serial : String = utilities._get_text_from_file(path + "%c" % [092] + day + "%c" % [092] + car + "%c" % [092] + "lastserial.txt")
					if not $SearchContainer/SerialNumber.text or $SearchContainer/SerialNumber.text.to_upper() in local_serial:
						serial_says_do_import_file = true
				if nickname_says_do_import_file and serial_says_do_import_file:
					for file in txt_files:
						if file != "lastnickname.txt" and file != "lastserial.txt":
							var entry_name : String = "Day " + day + ", " + file.trim_suffix(".txt").replace(" ", ":") + " (" + car + ")"
							logs_list[entry_name] = path + "%c" % [092] + day + "%c" % [092] + car + "%c" % [092] + file
							$ItemList.add_item(entry_name)
							$ItemList.sort_items_by_text()
	var time_elapsed : float = Time.get_unix_time_from_system() - start_time 
	$Status.text = "All " + str(logs_list.size()) + " logs from " + player_full_name + " in the list. (Took " + str(time_elapsed) + " seconds)"

func _dig_into_account_for_last_nickname(path) -> String:
	var car_search : String = $SearchContainer/CarName.text
	var days : Array = utilities._list_files_in_directory(path)
	var cars : Array
	var found_car : String
	var found_day : String
	var found : bool = false
	if car_search:
		days.invert()
		for day in days:
			if not found:
				found_day = day
				cars = utilities._list_files_in_directory(path + "%c" % [092] + day)
				cars.invert()
				for car in cars:
					if car_search.to_lower() in car.to_lower():
						found_car = car
						found = true
						break
			else:
				break
	else:
		found = true
		cars = utilities._list_files_in_directory(path + "%c" % [092] + days.back())
		found_car = cars.back()
		found_day = days.back()
	if found:
		var lastnicknametxt_path : String = path + "%c" % [092] + found_day + "%c" % [092] + found_car + "%c" % [092] + "lastnickname.txt"
		var nickname : String = utilities._get_text_from_file(lastnicknametxt_path)
#	if not nickname:
#		lastnicknametxt_path = path + "%c" % [092] + days.back() + "%c" % [092] + cars.front() + "%c" % [092] + "lastnickname.txt"
#		nickname = utilities._get_text_from_file(lastnicknametxt_path)
		return nickname
	else:
		return ""

func _on_ItemList_item_selected(index):
	var node = $ItemList
	var item_name : String = node.get_item_text(index)
	match list_mode:
		"LOGS":
			emit_signal("log_selected", item_name, logs_list[item_name], active_account)
		"PLAYERS": # CHANGE THIS TO A FILTER SO IT INCLUDES ALL MONTHS
			var file_list : Array = utilities._list_files_in_directory(current_path)
			if file_list.has(players_list[item_name][0]):
				current_path += "%c" % [092] + players_list[item_name][0]
				_populate_logs_list_from_player_folder(current_path)
				list_mode = "LOGS"
			else:
				_populate_logs_list_from_records_folder(item_name, players_list[item_name][0], file_list, current_path)
				list_mode = "LOGS"
			$PathContainer/Editor.text = current_path

func _populate_logs_list_from_records_folder(item_name : String, account_name : String, file_list : Array, path : String = current_path):
	var start_time : float = Time.get_unix_time_from_system() 
	$Status.text = "Loading logs from " + item_name + "..."
	var months : Array = $SearchContainer/MonthsButton.checked_items
	var enabled_folders : Array = []
	logs_list = {}
	$ItemList.clear()
	active_account = account_name
	for folder in file_list:
		if months.has(folder.substr(5)):
			enabled_folders.append(folder)
	var selected_day : String = str($SearchContainer/Day.selected).pad_zeros(2)
	var selected_hour : String = $SearchContainer/Hour.get_item_text($SearchContainer/Hour.selected).pad_zeros(2)
	var selected_minute : String = $SearchContainer/Minute.get_item_text($SearchContainer/Minute.selected)
	for folder in enabled_folders:
		if folder[4] == "-" and not "." in folder:
			var player_folder = path + "%c" % [092] + folder + "%c" % [092] + account_name
			var folder_days : Array = utilities._list_files_in_directory(player_folder)
			for day in folder_days:
				if selected_day == "00" or selected_day == day:
					var folder_cars : Array = utilities._list_files_in_directory(player_folder + "%c" % [092] + day)
					for car in folder_cars:
						if not $SearchContainer/CarName.text or $SearchContainer/CarName.text.to_lower() in car.to_lower():
							var txt_files : Array = utilities._list_files_in_directory(player_folder + "%c" % [092] + day + "%c" % [092] + car)
							var nickname_says_do_import_file : bool = false
							var serial_says_do_import_file : bool = false
							if txt_files.has("lastnickname.txt"):
								var local_nickname : String = utilities._get_text_from_file(player_folder + "%c" % [092] + day + "%c" % [092] + car + "%c" % [092] + "lastnickname.txt")
								if not $SearchContainer/PlayerName.text or $SearchContainer/PlayerName.text.to_lower() in local_nickname.to_lower() or $SearchContainer/PlayerName.text.to_lower() in item_name.to_lower():
									nickname_says_do_import_file = true
							if txt_files.has("lastserial.txt"):
								var local_serial : String = utilities._get_text_from_file(player_folder + "%c" % [092] + day + "%c" % [092] + car + "%c" % [092] + "lastserial.txt")
								if not $SearchContainer/SerialNumber.text or $SearchContainer/SerialNumber.text.to_upper() in local_serial:
									serial_says_do_import_file = true
							if nickname_says_do_import_file and serial_says_do_import_file:
								for file in txt_files:
									if file != "lastnickname.txt" and file != "lastserial.txt":
										if selected_hour == "All" or file.begins_with(selected_hour):
											if selected_minute == "All" or file.substr(3).begins_with(selected_minute):
												var date : String = folder.substr(0, 4) + "/" + folder.substr(5) + "/" + day
												var entry_name : String = date + ", " + file.trim_suffix(".txt").replace(" ", ":") + " (" + car + ")"
												logs_list[entry_name] = player_folder + "%c" % [092] + day + "%c" % [092] + car + "%c" % [092] + file
												$ItemList.add_item(entry_name)
												$ItemList.sort_items_by_text()
	var time_elapsed : float = Time.get_unix_time_from_system() - start_time 
	$Status.text = "All " + str(logs_list.size()) + " logs from " + item_name + " in the list. (Took " + str(time_elapsed) + " seconds)"


func _on_MTButton_pressed():
	if $PathContainer/MTButton.pressed:
		multithread = true
	else:
		multithread = false
