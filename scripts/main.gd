extends Control

onready var Tab_Open = $"TabContainer/Open File"
var tab_racelog = preload("res://scenes/tab_racelog.tscn")

func _ready():
	Tab_Open.get_node("PathContainer/Editor").text = _return_executable_directory()

func _return_executable_directory() -> String:
	var current_directory = OS.get_executable_path()
	return current_directory.get_base_dir()

func _open_log_tab(tab_name : String, log_path : String, account_name : String):
	var instance = tab_racelog.instance()
	instance.log_name = tab_name
	instance.path_to_file = log_path
	instance.account_name = account_name
	get_node("TabContainer").add_child(instance)

func _on_Open_File_log_selected(log_name, log_path, account_name):
	_open_log_tab(log_name, log_path, account_name)
