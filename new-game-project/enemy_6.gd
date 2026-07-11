extends CharacterBody2D

@export var max_health: float = 50.0

@export var explosion_radius: float = 225.0
@export var explosion_damage_radius: float = 285.0
@export var explosion_damage: float = 35.0

@export var damage_number_scene: PackedScene
@export var energy_pack_scene: PackedScene
@export var health_pack_scene: PackedScene

@export var normal_bomber_scene: PackedScene
@export var split_bomber_count: int = 2

@export var vision_range: float = 800.0
@export var move_speed: float = 300.0
@export var close_range: float = 500.0
@export var close_speed_multiplier: float = 3.0

@export var knockback_decay: float = 1800.0

var knockback_velocity: Vector2 = Vector2.ZERO

@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

var slow_multiplier: float = 1.0
var is_slowed: bool = false

var health: float
var player: Node2D

var aggroed := false
var dead := false
var frozen := false

var explosion_circle: Line2D
var shake_strength: float = 0.0



func set_frozen(state: bool):

	frozen = state
	velocity = Vector2.ZERO



func _ready():

	add_to_group("enemies")

	player = GameManager.player
	health = max_health

	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = false

	_setup_explosion_circle()



func _physics_process(delta):

	if frozen:

		velocity = Vector2.ZERO
		move_and_slide()
		return


	if player == null or dead or !is_instance_valid(player):
		return

	var look_dir = (player.global_position - global_position).normalized()
	sprite.rotation = look_dir.angle() - deg_to_rad(90)
	var dist = global_position.distance_to(
		player.global_position
	)


	velocity = knockback_velocity


	if dist <= vision_range or aggroed:

		var follow_dir = (
			player.global_position - global_position
		).normalized()


		var current_speed = move_speed


		# Speed boost when close to player
		if dist <= close_range:
			current_speed *= close_speed_multiplier


		velocity += follow_dir * current_speed * slow_multiplier



	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_decay * delta
	)


	move_and_slide()



	for i in range(get_slide_collision_count()):

		var col = get_slide_collision(i)
		var body = col.get_collider()


		if body and body.is_in_group("player"):

			if body.has_method("apply_knockback"):

				var knockback_dir = (
					body.global_position - global_position
				).normalized()


				body.apply_knockback(
					knockback_dir,
					700.0
				)


			explode()
			return

func screen_shake(amount: float = 16.0):

	shake_strength = amount



func _process(delta):

	var cam = get_viewport().get_camera_2d()

	if cam == null:
		return


	if shake_strength > 0:

		cam.offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)

		shake_strength = lerp(
			shake_strength,
			0.0,
			0.2
		)

	else:

		cam.offset = Vector2.ZERO




func take_damage(amount: float):

	if dead:
		return


	health -= amount

	health = clamp(
		health,
		0.0,
		max_health
	)


	aggroed = true


	if GameManager.player:

		GameManager.player.gain_energy(
			round(amount / 3.0)
		)


	_show_damage(amount)
	_update_ui()
	_flash_red()


	if health <= 0:

		explode()





func explode():

	if dead:
		return


	dead = true


	screen_shake(20.0)


	var space = get_world_2d().direct_space_state


	var shape = CircleShape2D.new()

	shape.radius = explosion_damage_radius



	var query = PhysicsShapeQueryParameters2D.new()

	query.shape = shape

	query.transform = Transform2D(
		0,
		global_position
	)

	query.collide_with_bodies = true
	query.collide_with_areas = true



	var results = space.intersect_shape(query)



	for hit in results:

		var body = hit.collider


		if body == null or body == self:
			continue


		# ONLY damage player
		if body.is_in_group("player"):

			if body.has_method("take_damage"):

				body.take_damage(
					explosion_damage
				)



	await _flash_explosion_circle()


	spawn_split_bombers()

	drop_pack()

	queue_free()




func spawn_split_bombers():

	if normal_bomber_scene == null:
		return


	for i in range(split_bomber_count):

		var bomber = normal_bomber_scene.instantiate()


		get_tree().current_scene.add_child(
			bomber
		)


		var angle = randf_range(
			0,
			TAU
		)


		var spawn_offset = Vector2(
			cos(angle),
			sin(angle)
		) * 80


		bomber.global_position = (
			global_position + spawn_offset
		)

func _setup_explosion_circle():

	explosion_circle = Line2D.new()
	add_child(explosion_circle)

	explosion_circle.width = 3

	explosion_circle.default_color = Color(
		0.8,
		0.2,
		0.9,
		0.5
	)

	explosion_circle.z_index = 100


	var segments = 64


	for i in range(segments + 1):

		var angle = TAU * i / segments

		explosion_circle.add_point(
			Vector2(cos(angle), sin(angle))
			* explosion_radius
		)





func _flash_explosion_circle():

	explosion_circle.width = 10

	explosion_circle.default_color = Color(
		0.5,
		0.8,
		1.0,
		1.0
	)


	await get_tree().create_timer(
		0.15
	).timeout


	explosion_circle.width = 3

	explosion_circle.default_color = Color(
		0.8,
		0.2,
		0.9,
		0.5
	)





func _show_damage(amount: float):

	if damage_number_scene == null:
		return


	var number = damage_number_scene.instantiate()


	get_tree().current_scene.add_child(
		number
	)


	number.global_position = (
		global_position + Vector2(0, -40)
	)


	if number is Label:

		number.text = str(int(amount))


	number.scale = Vector2(
		1.5,
		1.5
	)





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

	slow_multiplier = 1.0
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



	elif chance <= 0.14:

		if energy_pack_scene:

			var pack = energy_pack_scene.instantiate()

			get_tree().current_scene.add_child(
				pack
			)

			pack.global_position = global_position
