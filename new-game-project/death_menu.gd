extends CanvasLayer

@onready var menu = $Control


func _ready():
	menu.visible = false

func show_death_menu():
	menu.visible = true
	get_tree().paused = true

func _on_respawn_pressed():
	get_tree().paused = false
	menu.visible = false

	if GameManager.checkpoints_enabled:
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file("res://map_2.tscn")

func _on_element_selection_pressed():
	get_tree().paused = false
	menu.visible = false
	get_tree().change_scene_to_file("res://selection_ui.tscn")

func _on_quit_pressed():
	get_tree().quit()
