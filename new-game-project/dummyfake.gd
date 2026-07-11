extends CharacterBody2D

@export var max_health: float = 100.0
@export var damage_number_scene: PackedScene

@export var enemy_scene_1: PackedScene
@export var enemy_scene_2: PackedScene
@export var enemy_scene_3: PackedScene
@export var enemy_scene_4: PackedScene
@export var enemy_scene_5: PackedScene
@export var enemy_scene_6: PackedScene
@export var enemy_scene_7: PackedScene
@export var enemy_scene_8: PackedScene
@export var spawn_amount: int = 8
@export var health_pack_scene: PackedScene

@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

var health: float
var player: Node2D

func _ready():
	health = max_health
	player = GameManager.player
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = false

	randomize()


func die():
	print("Dummy died!")

	spawn_enemies()
	drop_health_pack()

	queue_free()


func spawn_enemies():

	var possible_enemies = [
		enemy_scene_1,
		enemy_scene_2,
		enemy_scene_3,
		enemy_scene_4,
		enemy_scene_5,
		enemy_scene_6,
		enemy_scene_7,
		enemy_scene_8
	]

	var available = []

	for enemy in possible_enemies:
		if enemy != null:
			available.append(enemy)

	if available.size() == 0:
		return

	for i in range(spawn_amount):

		var enemy = available.pick_random().instantiate()

		get_tree().current_scene.add_child(enemy)

		var angle = randf_range(0, TAU)
		var distance = randf_range(80, 150)

		enemy.global_position = global_position + Vector2(
			cos(angle),
			sin(angle)
		) * distance


func drop_health_pack():

	if health_pack_scene == null:
		return

	var health_pack = health_pack_scene.instantiate()

	get_tree().current_scene.add_child(health_pack)

	health_pack.global_position = global_position


func flash_red():

	sprite.modulate = Color(1, 0.3, 0.3)

	await get_tree().create_timer(0.1).timeout

	if is_instance_valid(sprite):
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

func take_damage(amount: float):

	print("Dummy took ", amount, " damage!")

	if GameManager.player and GameManager.player.earth_buff:

		var heal_amount: float = (
			amount * GameManager.player.earth_lifesteal
		)

		GameManager.player.health += heal_amount

		GameManager.player.health = clamp(
			GameManager.player.health,
			0,
			GameManager.player.max_health
		)

		GameManager.player.health_bar.set_health(
			GameManager.player.health
		)

		print("PLAYER LIFESTEAL HEALED:", heal_amount)


	health -= amount

	health = clamp(
		health,
		0.0,
		max_health
	)


	if is_instance_valid(GameManager.player):

		GameManager.player.gain_energy(
			round(amount / 3.0)
		)


	health_bar.visible = true
	health_bar.value = health


	show_damage_number(amount)
	flash_red()


	if health <= 0:
		die()

func _physics_process(delta):
	if player == null or !is_instance_valid(player):
		return

	var look_dir = (player.global_position - global_position).normalized()
	sprite.rotation = look_dir.angle() - deg_to_rad(90)
