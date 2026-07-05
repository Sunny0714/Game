extends Area2D

@export var speed: float = 2000.0
@export var max_distance: float = 1500.0
@export var damage: float = 15.0
@export var turn_speed: float = 8.0
@export var acquire_radius: float = 600.0

var direction: Vector2 = Vector2.RIGHT
var traveled_distance: float = 0.0
var target: Node2D = null


func _ready():
	add_to_group("projectile")
	body_entered.connect(_on_body_entered)

	# start with slight random spread so shots don't stack
	direction = Vector2.RIGHT.rotated(randf_range(-0.6, 0.6)).normalized()

	target = _find_random_enemy()


func _process(delta):
	# reacquire if invalid or too far
	if target == null or not is_instance_valid(target):
		target = _find_random_enemy()

	# homing behavior (with slight randomness so they split up)
	if target != null:
		var to_target = (target.global_position - global_position).normalized()

		# add small jitter so multiple projectiles don't stack
		to_target = (to_target + Vector2(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))).normalized()

		direction = direction.lerp(to_target, turn_speed * delta).normalized()

	# move
	var movement = direction * speed * delta
	global_position += movement

	traveled_distance += movement.length()

	if traveled_distance >= max_distance:
		queue_free()


func _find_random_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")

	var valid = []

	for e in enemies:
		if is_instance_valid(e):
			if global_position.distance_to(e.global_position) <= acquire_radius:
				valid.append(e)

	if valid.size() == 0:
		return null

	# pick random enemy instead of always closest
	return valid[randi() % valid.size()]


func _on_body_entered(body):
	if body.is_in_group("player"):
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)

	queue_free()
