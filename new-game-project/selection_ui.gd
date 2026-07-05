extends CanvasLayer

@onready var player = get_tree().get_first_node_in_group("player")

func _on_fire_pressed() -> void:
	GameManager.selected_element = "fire"
	print("Fire selected")


func _on_water_pressed() -> void:
	GameManager.selected_element = "water"
	print("Water selected")


func _on_lightning_pressed() -> void:
	GameManager.selected_element = "lightning"
	print("Lightning selected")


func _on_earth_pressed() -> void:
	GameManager.selected_element = "earth"
	print("Earth selected")


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://map_1.tscn")
