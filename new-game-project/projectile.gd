extends Area2D

@export var speed: float = 1200.0
@export var max_distance: float = 1000.0
@export var damage: float = 8.0

var direction: Vector2 = Vector2.RIGHT
var traveled_distance: float = 0.0

func _ready():
	add_to_group("projectile")
	body_entered.connect(_on_body_entered)

func _process(delta):
	var movement = direction * speed * delta
	global_position += movement

	traveled_distance += movement.length()

	if traveled_distance >= max_distance:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		return
	
	if body.is_in_group("projectile_blocker"):
		queue_free()
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage)

	queue_free()
