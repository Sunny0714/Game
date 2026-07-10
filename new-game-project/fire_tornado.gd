extends Area2D

@export var speed := 200.0
@export var lifetime := 5.0

@export var pull_force := 900.0
@export var damage := 5.0
@export var damage_interval := 1.0

var direction := Vector2.RIGHT
var damage_timer := 0.0
var damage_radius := 0.0

@onready var radius_circle: Line2D = $Circle
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready():
	var shape = collision_shape.shape as CircleShape2D
	if shape:
		damage_radius = shape.radius

	_setup_circle()

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _process(delta):
	# Move tornado
	global_position += direction * speed * delta

	# Pull enemies every frame
	pull_enemies()

	# Damage once every second
	damage_timer -= delta

	if damage_timer <= 0:
		damage_timer = damage_interval
		damage_enemies()


func _setup_circle():
	radius_circle.clear_points()

	var points := 64

	for i in range(points):
		var angle = TAU * i / points
		radius_circle.add_point(
			Vector2(cos(angle), sin(angle)) * damage_radius
		)

	radius_circle.closed = true
	radius_circle.width = 3.0
	radius_circle.default_color = Color(1.0, 0.45, 0.1, 0.6)
	radius_circle.z_index = 100


func pull_enemies():
	for enemy in get_tree().get_nodes_in_group("enemies"):

		if !is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)

		if distance > damage_radius:
			continue

		var dir = (global_position - enemy.global_position).normalized()

		# Stronger pull the farther away they are
		var force = lerp(300.0, pull_force, distance / damage_radius)

		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(dir, force)


func damage_enemies():
	for enemy in get_tree().get_nodes_in_group("enemies"):

		if !is_instance_valid(enemy):
			continue

		if global_position.distance_to(enemy.global_position) > damage_radius:
			continue

		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
