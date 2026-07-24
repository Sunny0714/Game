extends CharacterBody2D

@export var max_health: float = 200.0
@export var damage_number_scene: PackedScene

@export var shockwave_damage: float = 15.0
@export var shockwave_radius: float = 500.0
@export var shockwave_cooldown: float = 2.5

@export var bomber_scene: PackedScene
@export var bomber_spawn_distance_min: float = 250.0
@export var bomber_spawn_distance_max: float = 450.0
@export var bomber_cooldown: float = 30.0

@export var player_detection_range: float = 1000.0

@export var knockback_decay: float = 1800.0

@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

var health: float

var player: Node2D

var frozen := false
var dead := false

var slow_multiplier: float = 1.0
var is_slowed: bool = false

var knockback_velocity := Vector2.ZERO

var shockwave_timer: float = 0.0
var bomber_timer: float = 0.0

var shockwave_circle: Line2D
var shockwave_wave: Line2D


func set_frozen(value: bool):
	frozen = value
	velocity = Vector2.ZERO


func _ready():

	add_to_group("enemies")

	health = max_health
	player = GameManager.player

	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = false

	# Attacks are ready, but do not start until player enters range
	shockwave_timer = shockwave_cooldown
	bomber_timer = bomber_cooldown

	_setup_shockwave_circle()

func _physics_process(delta):

	if dead:
		return

	# Enemy never moves
	velocity = Vector2.ZERO

	# Apply knockback decay
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_decay * delta
	)

	# Keep knockback support
	velocity += knockback_velocity

	move_and_slide()


func _process(delta):

	if dead:
		return

	if player == null or !is_instance_valid(player):
		player = GameManager.player
		return

	var look_dir = (player.global_position - global_position).normalized()
	sprite.rotation = look_dir.angle() - deg_to_rad(90)
	var distance = global_position.distance_to(
		player.global_position
	)


	# Only run timers when player is close enough
	if distance <= player_detection_range:

		shockwave_timer -= delta
		bomber_timer -= delta


		if shockwave_timer <= 0:

			shockwave_timer = shockwave_cooldown
			fire_shockwave()


		if bomber_timer <= 0:

			bomber_timer = bomber_cooldown
			spawn_bomber()

func _setup_shockwave_circle():

	shockwave_circle = Line2D.new()
	add_child(shockwave_circle)

	shockwave_circle.width = 3.0
	shockwave_circle.default_color = Color(0.3, 0.4, 1.0, 0.5)
	shockwave_circle.z_index = 100

	var points := 64

	for i in range(points + 1):
		var angle = TAU * i / points

		shockwave_circle.add_point(
			Vector2(cos(angle), sin(angle)) * shockwave_radius
		)


	shockwave_wave = Line2D.new()
	add_child(shockwave_wave)

	shockwave_wave.width = 6.0
	shockwave_wave.default_color = Color(0.5, 0.2, 1.0, 0.9)
	shockwave_wave.z_index = 101

	shockwave_wave.visible = false



func fire_shockwave():

	play_shockwave()

	if player == null:
		return

	var distance = global_position.distance_to(
		player.global_position
	)

	if distance <= shockwave_radius:

		if player.has_method("take_damage"):
			player.take_damage(shockwave_damage)


		# Push player away
		if player.has_method("apply_knockback"):

			var direction = (
				player.global_position - global_position
			).normalized()

			player.apply_knockback(
				direction,
				700.0
			)



func play_shockwave():

	shockwave_wave.visible = true

	var points := 64
	var radius := 0.0

	while radius < shockwave_radius:

		shockwave_wave.clear_points()

		for i in range(points + 1):

			var angle = TAU * i / points

			shockwave_wave.add_point(
				Vector2(cos(angle), sin(angle)) * radius
			)

		radius += 25

		await get_tree().process_frame


	shockwave_wave.visible = false



func spawn_bomber():

	if bomber_scene == null:
		return


	var angle = randf_range(
		0,
		TAU
	)

	var distance = randf_range(
		bomber_spawn_distance_min,
		bomber_spawn_distance_max
	)


	var spawn_position = global_position + Vector2(
		cos(angle),
		sin(angle)
	) * distance


	var bomber = bomber_scene.instantiate()

	get_tree().current_scene.add_child(bomber)

	bomber.global_position = spawn_position



func apply_knockback(direction: Vector2, force: float):

	knockback_velocity = direction.normalized() * force



func apply_slow(amount: float, element: String = "water"):

	slow_multiplier = amount
	is_slowed = true


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

	slow_multiplier = 1.0
	is_slowed = false

	sprite.modulate = Color.WHITE

func take_damage(amount: float):

	if dead:
		return

	health -= amount
	health = clamp(
		health,
		0.0,
		max_health
	)

	if GameManager.player:
		GameManager.player.gain_energy(
			round(amount / 3.0)
		)

	_update_ui()
	_show_damage(amount)
	_flash_red()

	if health <= 0:
		die()



func _update_ui():

	health_bar.visible = true
	health_bar.value = health



func _flash_red():

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



func _show_damage(amount: float):

	if damage_number_scene == null:
		return


	var number = damage_number_scene.instantiate()

	get_tree().current_scene.add_child(number)

	number.global_position = (
		global_position + Vector2(0, -40)
	)


	if number is Label:
		number.text = str(int(amount))


	number.scale = Vector2(
		1.5,
		1.5
	)



func die():

	if dead:
		return

	dead = true

	drop_pack()

	queue_free()



func drop_pack():

	var chance = randf()


	if chance <= 0.05:

		if has_node("HealthPack"):

			return


	elif chance <= 0.14:

		pass
