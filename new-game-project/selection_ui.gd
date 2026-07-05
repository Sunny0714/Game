extends CanvasLayer

@onready var player = get_tree().get_first_node_in_group("player")

@onready var fire = $Fire
@onready var water = $Water
@onready var lightning = $Lightning
@onready var earth = $Earth

func _ready():
	update_buttons()

func update_buttons():
	var normal = Color(1, 1, 1)
	var selected = Color(0.5, 0.5, 0.5)

	fire.modulate = selected if GameManager.selected_element == "fire" else normal
	water.modulate = selected if GameManager.selected_element == "water" else normal
	lightning.modulate = selected if GameManager.selected_element == "lightning" else normal
	earth.modulate = selected if GameManager.selected_element == "earth" else normal

func _on_fire_pressed() -> void:
	GameManager.selected_element = "fire"
	update_buttons()
	print("Fire selected")


func _on_water_pressed() -> void:
	GameManager.selected_element = "water"
	update_buttons()
	print("Water selected")


func _on_lightning_pressed() -> void:
	GameManager.selected_element = "lightning"
	update_buttons()
	print("Lightning selected")


func _on_earth_pressed() -> void:
	GameManager.selected_element = "earth"
	update_buttons()
	print("Earth selected")


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://map_1.tscn")
