extends CanvasLayer

@onready var menu = $Control

func _ready():
	menu.visible = false

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		toggle_pause()

func toggle_pause():
	var paused = !get_tree().paused
	get_tree().paused = paused
	menu.visible = paused


func _on_resume_pressed():
	get_tree().paused = false
	menu.visible = false


func _on_element_selection_pressed():
	get_tree().paused = false
	menu.visible = false
	get_tree().change_scene_to_file("res://selection_ui.tscn")


func _on_quit_pressed():
	get_tree().quit()



func _on_skip_pressed():
	get_tree().paused = false
	menu.visible = false
	get_tree().change_scene_to_file("res://map_2.tscn")
