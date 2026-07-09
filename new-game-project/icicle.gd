extends Area2D

@export var speed: float = 2000.0
@export var max_distance: float = 1500.0
@export var damage: float = 10.0
@export var slow_amount: float = 0.7
@export var slow_duration: float = 0.5
@export var pierce_chance: float = 0.33

var direction: Vector2 = Vector2.RIGHT
var traveled_distance: float = 0.0

var piercing: bool = false
var hit_enemies: Array = []


func _ready():
	add_to_group("projectile")

	# Decide once when spawned
	piercing = randf_range(0.0, 1.0) <= pierce_chance

	body_entered.connect(_on_body_entered)

	print("Piercing:", piercing)


func _process(delta):
	var movement = direction * speed * delta
	global_position += movement

	traveled_distance += movement.length()

	if traveled_distance >= max_distance:
		queue_free()


func _on_body_entered(body):
	if body.is_in_group("player"):
		return

	if hit_enemies.has(body):
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)

	if body.has_method("apply_slow"):
		body.apply_slow(slow_amount)

	hit_enemies.append(body)

	if piercing:
		return

	queue_free()
