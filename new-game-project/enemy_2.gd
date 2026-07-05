extends CharacterBody2D

@export var max_health: float = 25.0

@export var explosion_radius: float = 150.0
@export var explosion_damage: float = 25.0

@export var damage_number_scene: PackedScene

@export var vision_range: float = 400.0
@export var move_speed: float = 300.0

@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

var health: float
var player: Node2D

var aggroed := false
var dead := false
var frozen := false


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


func _physics_process(delta):
	if frozen:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player == null or dead:
		return

	var dist = global_position.distance_to(player.global_position)

	# vision lock (only before aggro)
	if dist > vision_range and not aggroed:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# chase player
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()

	# contact explosion
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var body = col.get_collider()

		if body and body.is_in_group("player"):
			explode()
			return


func take_damage(amount: float):
	if dead:
		return

	health -= amount
	health = clamp(health, 0.0, max_health)

	aggroed = true

	if is_instance_valid(GameManager.player):
		GameManager.player.gain_energy(round(amount / 3.0))

	_show_damage(amount)
	_update_ui()
	_flash_red()

	if health <= 0:
		explode()


func explode():
	if dead:
		return

	dead = true

	var space = get_world_2d().direct_space_state

	var shape = CircleShape2D.new()
	shape.radius = explosion_radius

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collide_with_bodies = true

	var results = space.intersect_shape(query)

	for hit in results:
		var body = hit.collider
		if body and body.has_method("take_damage"):
			body.take_damage(explosion_damage)

	queue_free()


func _show_damage(amount: float):
	if damage_number_scene == null:
		return

	var number = damage_number_scene.instantiate()
	get_tree().current_scene.add_child(number)

	number.global_position = global_position + Vector2(0, -40)

	if number is Label:
		number.text = str(int(amount))

	number.scale = Vector2(1.5, 1.5)


func _update_ui():
	health_bar.visible = true
	health_bar.value = health


func _flash_red():
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
