extends CanvasLayer

@onready var menu = $Control

func _ready():
	menu.visible = false
	
	$Control/Panel/CheckBox.scale = Vector2(1.5, 1.5)
	$Control/Panel/CheckBox.custom_minimum_size = Vector2(250, 50)
	$Control/Panel/CheckBox.add_theme_font_size_override("font_size", 16)
	$Control/Panel/CheckBox.modulate = Color(0.5, 0.5, 0.5, 1)
	
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



func _on_check_box_toggled(toggled_on: bool) -> void:
	GameManager.checkpoints_enabled = toggled_on
	GameManager.save_settings()
