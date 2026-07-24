extends CanvasLayer

@onready var player = get_tree().get_first_node_in_group("player")

@onready var fire = $Fire
@onready var water = $Water
@onready var lightning = $Lightning
@onready var earth = $Earth
@onready var start = $Start

var element_selected := false

var button_offset := Vector2(4, 4)
var start_pos: Vector2
var fire_pos: Vector2
var water_pos: Vector2
var lightning_pos: Vector2
var earth_pos: Vector2


func _ready():
	start_pos = start.position
	GameManager.selected_element = "none"

	fire_pos = fire.position
	water_pos = water.position
	lightning_pos = lightning.position
	earth_pos = earth.position

	update_buttons()

func _process(_delta):
	if element_selected:
		if start.get_global_rect().has_point(get_viewport().get_mouse_position()):
			start.position = start_pos + button_offset
		else:
			start.position = start_pos

func update_buttons():

	var normal = Color(1, 1, 1)
	var selected = Color(0.5, 0.5, 0.5)

	fire.modulate = selected if GameManager.selected_element == "fire" else normal
	water.modulate = selected if GameManager.selected_element == "water" else normal
	lightning.modulate = selected if GameManager.selected_element == "lightning" else normal
	earth.modulate = selected if GameManager.selected_element == "earth" else normal

	fire.position = fire_pos + (button_offset if GameManager.selected_element == "fire" else Vector2.ZERO)
	water.position = water_pos + (button_offset if GameManager.selected_element == "water" else Vector2.ZERO)
	lightning.position = lightning_pos + (button_offset if GameManager.selected_element == "lightning" else Vector2.ZERO)
	earth.position = earth_pos + (button_offset if GameManager.selected_element == "earth" else Vector2.ZERO)

	start.disabled = !element_selected


func _on_fire_pressed() -> void:

	element_selected = true
	GameManager.selected_element = "fire"
	update_buttons()

	print("Fire selected")


func _on_water_pressed() -> void:

	element_selected = true
	GameManager.selected_element = "water"
	update_buttons()

	print("Water selected")


func _on_lightning_pressed() -> void:

	element_selected = true
	GameManager.selected_element = "lightning"
	update_buttons()

	print("Lightning selected")


func _on_earth_pressed() -> void:

	element_selected = true
	GameManager.selected_element = "earth"
	update_buttons()

	print("Earth selected")


func _on_start_pressed() -> void:

	if !element_selected:
		return

	match GameManager.selected_element:

		"fire":
			get_tree().change_scene_to_file("res://map_1fire.tscn")

		"water":
			get_tree().change_scene_to_file("res://map_1water.tscn")

		"lightning":
			get_tree().change_scene_to_file("res://map_1.tscn")

		"earth":
			get_tree().change_scene_to_file("res://map_1earth.tscn")


func _on_fire_mouse_entered():

	if GameManager.selected_element != "fire":
		fire.position = fire_pos + button_offset


func _on_fire_mouse_exited():

	if GameManager.selected_element != "fire":
		fire.position = fire_pos


func _on_water_mouse_entered():

	if GameManager.selected_element != "water":
		water.position = water_pos + button_offset


func _on_water_mouse_exited():

	if GameManager.selected_element != "water":
		water.position = water_pos


func _on_lightning_mouse_entered():

	if GameManager.selected_element != "lightning":
		lightning.position = lightning_pos + button_offset


func _on_lightning_mouse_exited():

	if GameManager.selected_element != "lightning":
		lightning.position = lightning_pos


func _on_earth_mouse_entered():

	if GameManager.selected_element != "earth":
		earth.position = earth_pos + button_offset


func _on_earth_mouse_exited():

	if GameManager.selected_element != "earth":
		earth.position = earth_pos
