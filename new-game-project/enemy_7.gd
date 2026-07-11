extends CharacterBody2D

@export var max_health: float = 100.0

@export var damage_number_scene: PackedScene
@export var health_pack_scene: PackedScene
@export var energy_pack_scene: PackedScene
@export var enemy_projectile_1: PackedScene
@export var enemy_projectile_2: PackedScene
@export var enemy_projectile_3: PackedScene
@export var enemy_projectile_4: PackedScene
@export var enemy_projectile_5: PackedScene
@export var enemy_projectile_6: PackedScene
@export var enemy_projectile_8: PackedScene
@export var vision_range: float = 1200.0
@export var attack_range: float = 1200.0
@export var shoot_cooldown: float = 10.0

@export var move_speed: float = 60.0
@export var preferred_distance: float = 1000.0

@export var dodge_distance: float = 900.0
@export var strafe_speed: float = 80.0


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


var strafe_direction := 1.0
var strafe_timer := 0.0



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

	randomize()




func _physics_process(delta):

	if frozen:

		velocity = Vector2.ZERO
		move_and_slide()
		return


	if player == null or !is_instance_valid(player):

		player = GameManager.player
		return


	var dist = global_position.distance_to(
		player.global_position
	)
	velocity = knockback_velocity


	if dist <= vision_range:

		aggroed = true



	if aggroed:

		var look_dir = (player.global_position - global_position).normalized()
		sprite.rotation = look_dir.angle() - deg_to_rad(90)
		var dir = (
			player.global_position - global_position
		).normalized()



		if dist < preferred_distance - 100:

			velocity -= dir * move_speed * slow_multiplier


		elif dist > preferred_distance + 100:

			velocity += dir * move_speed * slow_multiplier



		# Random side movement when far away

		if dist >= dodge_distance:

			strafe_timer -= delta


			if strafe_timer <= 0:

				strafe_timer = randf_range(
					1.0,
					2.5
				)

				strafe_direction *= -1



			var side = Vector2(
				-dir.y,
				dir.x
			)


			velocity += side * strafe_speed * strafe_direction




		if dist <= attack_range:

			shoot()



	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_decay * delta
	)


	move_and_slide()

func shoot():
	if frozen:
		return


	if !can_shoot:
		return
	can_shoot = false
	var possible_projectiles = [
		enemy_projectile_1,
		enemy_projectile_2,
		enemy_projectile_3,
		enemy_projectile_4,
		enemy_projectile_5,
		enemy_projectile_6,
		enemy_projectile_8
	]

	var available = []
	for projectile in possible_projectiles:
		if projectile != null:
			available.append(projectile)

	if available.size() == 0:

		can_shoot = true
		return

	var chosen_scene = available.pick_random()
	var enemy = chosen_scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = global_position
	if enemy.has_method("set_target"):
		enemy.set_target(player)

	elif "direction" in enemy:

		var dir = (
			player.global_position - global_position
		).normalized()
		enemy.direction = dir
		if enemy.has_node("Sprite2D"):
			enemy.rotation = dir.angle() + deg_to_rad(90)
	
	await get_tree().create_timer(
		shoot_cooldown
	).timeout

	can_shoot = true

func take_damage(amount: float):

	health -= amount
	health = clamp(
		health,
		0.0,
		max_health
	)
	aggroed = true

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




func die():
	drop_pack()
	queue_free()

func flash_red():

	sprite.modulate = Color(
		1,
		0.3,
		0.3
	)

	await get_tree().create_timer(
		0.1
	).timeout
	if !is_slowed:

		sprite.modulate = Color.WHITE

func show_damage_number(amount: float):
	if damage_number_scene == null:
		return
	var number = damage_number_scene.instantiate()
	get_tree().current_scene.add_child(
		number
	)
	number.global_position = (
		global_position + Vector2(0,-40)
	)
	if number is Label:
		number.text = str(int(amount))
	number.scale = Vector2(
		1.5,
		1.5
	)

func _setup_vision_circle():
	vision_circle.clear_points()
	var points := 64
	for i in range(points + 1):
		var angle = TAU * i / points
		vision_circle.add_point(
			Vector2(
				cos(angle),
				sin(angle)
			) * vision_range
		)
	vision_circle.width = 3.0

	vision_circle.default_color = Color(
		0.6,
		0.6,
		0.6,
		0.35
	)

	vision_circle.closed = true
	vision_circle.z_index = 100


func apply_knockback(direction: Vector2, force: float):
	knockback_velocity = (
		direction.normalized()
		* force
	)
	aggroed = true

func apply_slow(amount: float, element: String = "water"):
	slow_multiplier = amount
	is_slowed = true

	if has_node("Sprite2D"):

		if element == "earth":
			sprite.modulate = Color(
				0.7,
				1.0,
				0.7
			)
		elif element == "water":
			sprite.modulate = Color(
				0.75,
				0.9,
				1.0
			)





func remove_slow():
	slow_multiplier = 1
	is_slowed = false
	if has_node("Sprite2D"):

		sprite.modulate = Color.WHITE

func drop_pack():
	var chance = randf()
	if chance <= 0.05:
		if health_pack_scene:
			var health_pack = health_pack_scene.instantiate()
			get_tree().current_scene.add_child(
				health_pack
			)
			health_pack.global_position = global_position
	elif chance <= 0.09:

		if energy_pack_scene:

			var pack = energy_pack_scene.instantiate()

			get_tree().current_scene.add_child(
				pack
			)

			pack.global_position = global_position
