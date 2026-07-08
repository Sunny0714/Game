extends CharacterBody2D

@export var max_health: float = 5
@export var damage_number_scene: PackedScene

@export var projectile_scene: PackedScene
@export var attack_range: float = 700.0
@export var vision_range: float = 1000.0
@export var attack_cooldown: float = 1.0
@export var move_speed: float = 250.0

@export var self_damage_interval: float = 1.0
@export var knockback_decay: float = 1800.0

var health: float
var target: Node2D = null
var can_attack := true
var knockback_velocity := Vector2.ZERO

@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar
@export var vision_range_circle: float = 1000.0
var vision_circle: Line2D

func _ready():
	add_to_group("allies")
	_setup_vision_circle()
	health = max_health

	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = false

	self_damage_loop()


func _physics_process(delta):

	find_target()

	velocity = knockback_velocity

	if target and is_instance_valid(target):

		var distance = global_position.distance_to(target.global_position)

		if distance > attack_range:

			var direction = (
				target.global_position - global_position
			).normalized()

			velocity += direction * move_speed

		else:

			attack()

	else:

		velocity = knockback_velocity


	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_decay * delta
	)

	move_and_slide()


func find_target():

	var closest = null
	var closest_distance = vision_range

	for enemy in get_tree().get_nodes_in_group("enemies"):

		if !is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(
			enemy.global_position
		)

		if distance < closest_distance:

			closest_distance = distance
			closest = enemy

	target = closest


func attack():

	if !can_attack:
		return

	if target == null:
		return

	if projectile_scene == null:
		print("NO PROJECTILE")
		return


	can_attack = false

	var projectile = projectile_scene.instantiate()

	get_tree().current_scene.add_child(projectile)

	projectile.global_position = global_position


	var direction = (
		target.global_position - global_position
	).normalized()


	if "direction" in projectile:
		projectile.direction = direction

	elif projectile.has_method("set_direction"):
		projectile.set_direction(direction)

	else:
		print("PROJECTILE HAS NO DIRECTION")


	projectile.rotation = direction.angle() + deg_to_rad(90)


	await get_tree().create_timer(
		attack_cooldown
	).timeout

	can_attack = true


func self_damage_loop():

	while true:

		await get_tree().create_timer(
			self_damage_interval
		).timeout

		take_damage(1)


func take_damage(amount: float):

	health -= amount
	health = clamp(
		health,
		0,
		max_health
	)

	health_bar.visible = true
	health_bar.value = health

	show_damage_number(amount)
	flash_red()

	if health <= 0:
		queue_free()


func apply_knockback(direction: Vector2, force: float):

	knockback_velocity = direction.normalized() * force


func flash_red():

	sprite.modulate = Color(1,0.3,0.3)

	await get_tree().create_timer(0.1).timeout

	sprite.modulate = Color.WHITE


func show_damage_number(amount):

	if damage_number_scene == null:
		return

	var number = damage_number_scene.instantiate()

	get_tree().current_scene.add_child(number)

	number.global_position = global_position + Vector2(0,-40)

	if number is Label:
		number.text = str(int(amount))

	number.scale = Vector2(1.5,1.5)

func _setup_vision_circle():

	vision_circle = Line2D.new()
	add_child(vision_circle)

	vision_circle.width = 5
	vision_circle.default_color = Color(0.5, 0.9, 1.0, 0.35)
	vision_circle.z_index = 100

	var radius = vision_range_circle - 50
	var points = 64

	for i in range(points + 1):
		var angle = TAU * i / points
		vision_circle.add_point(
			Vector2(cos(angle), sin(angle)) * radius
		)
