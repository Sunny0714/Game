extends Node

var selected_element: String = "none"
var player = null
var checkpoints_enabled: bool = false

func save_settings():
	var config = ConfigFile.new()
	config.set_value("Settings", "checkpoints_enabled", checkpoints_enabled)
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")

	if err == OK:
		checkpoints_enabled = config.get_value("Settings", "checkpoints_enabled", false)
