extends CharacterBody2D

@export var max_health: float = 100.0
@export var damage_number_scene: PackedScene
@export var contact_damage: float = 10.0
@export var health_pack_scene: PackedScene
@export var energy_pack_scene: PackedScene
@export var projectile_scene: PackedScene
@export var attack_range: float = 1000.0
@export var vision_range: float = 1000.0
@export var shoot_cooldown: float = 1.0
@export var move_speed: float = 150.0
@export var follow_distance: float = 300.0
@export var knockback_decay: float = 1800.0
var knockback_velocity: Vector2 = Vector2.ZERO
@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar
@onready var vision_circle: Line2D = $VisionCircle

var health: float
var player: Node2D
var can_shoot := true
var slow_multiplier: float = 1.0
var is_slowed: bool = false
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
	_setup_vision_circle()

func _physics_process(delta):

	if frozen:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)

	velocity = knockback_velocity

	if aggroed or dist <= vision_range:

		if dist > follow_distance:
			var dir = (player.global_position - global_position).normalized()
			velocity += dir * move_speed * slow_multiplier

		# Shooting
		if dist <= attack_range:
			shoot()

	# Decay knockback
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_decay * delta
	)

	move_and_slide()


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
	drop_pack()
	queue_free()


func flash_red():
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE


func show_damage_number(amount: float):
	if damage_number_scene == null:
		return

	if GameManager.player and GameManager.player.earth_buff:
		var heal_amount: float = amount * GameManager.player.earth_lifesteal * 0.8

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
func _setup_vision_circle():

	vision_circle.clear_points()

	var points := 64

	for i in range(points + 1):
		var angle = TAU * i / points

		vision_circle.add_point(
			Vector2(cos(angle), sin(angle)) * (vision_range - 100)
		)

	vision_circle.width = 3.0
	vision_circle.default_color = Color(0.6, 0.6, 0.6, 0.35)
	vision_circle.closed = true
	vision_circle.z_index = 100

func apply_knockback(direction: Vector2, force: float):

	knockback_velocity = direction.normalized() * force

	aggroed = true

func drop_pack():
	var chance = randf()

	if chance <= 0.05: # 5% chance
		var health_pack = health_pack_scene.instantiate()
		get_tree().current_scene.add_child(health_pack)
		health_pack.global_position = global_position
	elif randf() <= 0.09:
		var pack = energy_pack_scene.instantiate()
		get_tree().current_scene.add_child(pack)
		pack.global_position = global_position

func apply_slow(amount: float, element: String = "water"):
	slow_multiplier = amount
	is_slowed = true

	if has_node("Sprite2D"):
		if element == "earth":
			$Sprite2D.modulate = Color(0.7, 1.0, 0.7) # green
		elif element == "water":
			$Sprite2D.modulate = Color(0.75, 0.9, 1.0) # ice blue

func remove_slow():
	slow_multiplier = 1.0
	is_slowed = false

	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color.WHITE
