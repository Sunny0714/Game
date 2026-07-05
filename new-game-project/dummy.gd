extends CharacterBody2D

@export var max_health: float = 100.0
@export var damage_number_scene: PackedScene

@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

var health: float

func _ready():
	health = max_health

	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = false


func take_damage(amount: float):
	print("Dummy took ", amount, " damage!")

	health -= amount
	health = clamp(health, 0.0, max_health)

	print("Health:", health)

	# ENERGY GAIN (THIS WAS MISSING)
	if is_instance_valid(GameManager.player):
		GameManager.player.gain_energy(round(amount / 3.0))

	if health_bar:
		health_bar.visible = true
		health_bar.value = health

	show_damage_number(amount)
	flash_red()

	if health <= 0:
		die()


func die():
	print("Dummy died!")
	queue_free()


func flash_red():
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE


func show_damage_number(amount: float):
	if damage_number_scene == null:
		return

	var number = damage_number_scene.instantiate()
	get_tree().current_scene.add_child(number)

	number.global_position = global_position + Vector2(0, -40)

	if number is Label:
		number.text = str(int(amount))

	number.scale = Vector2(1.5, 1.5)
