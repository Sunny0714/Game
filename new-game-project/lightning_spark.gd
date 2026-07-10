extends Area2D

@export var initial_speed: float = 600.0
@export var speed_increase_per_chain: float = 900.0

@export var damage: float = 6
@export var stun_time: float = 0.3

@export var chain_range: float = 1000.0
@export var max_chains: int = 25

@export var chain_delay: float = 0.1
@export var lifetime: float = 5.0


var direction: Vector2 = Vector2.ZERO
var current_speed: float
var shake_strength: float = 0.0
var chain_count: int = 0

var attached_to_enemy := false
var last_enemy = null


func _ready():
	current_speed = initial_speed

	if !body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	await get_tree().create_timer(lifetime).timeout

	if is_instance_valid(self):
		screen_shake(8.0)
		await get_tree().create_timer(0.05).timeout
		queue_free()


func _process(delta):
	if shake_strength > 0:

		var cam = get_viewport().get_camera_2d()

		if cam:
			cam.offset = Vector2(
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength)
			)

		shake_strength = lerp(shake_strength, 0.0, 0.35)

	else:

		var cam = get_viewport().get_camera_2d()

		if cam:
			cam.offset = Vector2.ZERO
	if !attached_to_enemy:
		global_position += direction * current_speed * delta


func _on_body_entered(body):

	if !is_instance_valid(body):
		return
	
	if body.is_in_group("projectile_blocker"):
		queue_free()
		return

	if !body.is_in_group("enemies") and !body.is_in_group("lightning_conductor"):
		return

	if body == last_enemy:
		return

	hit_enemy(body)


func hit_enemy(enemy):

	if !is_instance_valid(enemy):
		return

	attached_to_enemy = true
	last_enemy = enemy

	var hit_position = enemy.global_position

	global_position = hit_position

	# Damage
	if enemy.is_in_group("enemies"):
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)

	# Stun
	if is_instance_valid(enemy):
		if enemy.has_method("set_frozen"):
			enemy.set_frozen(true)

	await get_tree().create_timer(stun_time).timeout

	# Unstun if still alive
	if is_instance_valid(enemy):
		if enemy.has_method("set_frozen"):
			enemy.set_frozen(false)

	await get_tree().create_timer(chain_delay).timeout

	chain_to_next(hit_position)


func chain_to_next(from_position: Vector2):

	attached_to_enemy = false

	if chain_count >= max_chains:
		screen_shake(8.0)
		await get_tree().create_timer(0.05).timeout
		queue_free()
		return

	var next_enemy = find_closest_enemy(from_position)

	if next_enemy == null:
		screen_shake(8.0)
		await get_tree().create_timer(0.05).timeout
		queue_free()
		return

	chain_count += 1

	global_position = from_position

	direction = (
		next_enemy.global_position - from_position
	).normalized()

	current_speed = initial_speed + (
		chain_count * speed_increase_per_chain
	)


func find_closest_enemy(from_position: Vector2):

	var closest_target = null
	var closest_distance = chain_range

	# Search enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):

		if !is_instance_valid(enemy):
			continue

		if enemy == last_enemy:
			continue

		var distance = from_position.distance_to(enemy.global_position)

		if distance < closest_distance:
			closest_distance = distance
			closest_target = enemy

	# Search lightning conductors
	for conductor in get_tree().get_nodes_in_group("lightning_conductor"):

		if !is_instance_valid(conductor):
			continue

		if conductor == last_enemy:
			continue

		var distance = from_position.distance_to(conductor.global_position)

		if distance < closest_distance:
			closest_distance = distance
			closest_target = conductor

	return closest_target

func screen_shake(amount: float = 8.0):

	shake_strength = amount
