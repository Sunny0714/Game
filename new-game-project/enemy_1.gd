extends CharacterBody2D

@export var max_health: float = 100.0
@export var damage_number_scene: PackedScene
@export var contact_damage: float = 10.0

@export var projectile_scene: PackedScene
@export var attack_range: float = 1000.0
@export var vision_range: float = 1000.0
@export var shoot_cooldown: float = 1.0
@export var move_speed: float = 150.0
@export var follow_distance: float = 300.0

@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

var health: float
var player: Node2D
var can_shoot := true

var aggroed := false
var frozen := false


func set_frozen(state: bool):
	frozen = state
	velocity = Vector2.ZERO


func _ready():
	add_to_group("enemies")

	health = max_health
	player = GameManager.player

	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = false


func _physics_process(delta):
	if frozen:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)

	# vision (only if not aggroed)
	if dist > vision_range and not aggroed:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# movement
	if dist > follow_distance:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# shooting
	if dist <= attack_range:
		shoot()


func shoot():
	if frozen:
		return

	if !can_shoot or projectile_scene == null:
		return

	can_shoot = false

	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)

	proj.global_position = global_position

	var dir = (player.global_position - global_position).normalized()
	proj.direction = dir
	proj.rotation = dir.angle() + deg_to_rad(90)
	proj.add_to_group("enemy_projectile")

	var t = get_tree().create_timer(shoot_cooldown)
	await t.timeout

	if frozen:
		can_shoot = true
		return

	can_shoot = true


func take_damage(amount: float):
	health -= amount
	health = clamp(health, 0.0, max_health)

	aggroed = true

	if is_instance_valid(GameManager.player):
		GameManager.player.gain_energy(round(amount / 3.0))

	health_bar.visible = true
	health_bar.value = health

	show_damage_number(amount)
	flash_red()

	if health <= 0:
		die()


func die():
	queue_free()


func flash_red():
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE


func show_damage_number(amount: float):
	if damage_number_scene == null:
		return

	if GameManager.player and GameManager.player.earth_buff:
		var heal_amount: float = amount * GameManager.player.earth_lifesteal

		GameManager.player.health += heal_amount
		GameManager.player.health = clamp(
			GameManager.player.health,
			0,
			GameManager.player.max_health
		)

		GameManager.player.health_bar.set_health(GameManager.player.health)

		print("PLAYER LIFESTEAL HEALED:", heal_amount)

	var number = damage_number_scene.instantiate()
	get_tree().current_scene.add_child(number)

	number.global_position = global_position + Vector2(0, -40)

	if number is Label:
		number.text = str(int(amount))

	number.scale = Vector2(1.5, 1.5)
