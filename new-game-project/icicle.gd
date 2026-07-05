extends Area2D

@export var speed: float = 2000.0
@export var max_distance: float = 1500.0
@export var damage: float = 10.0

var direction: Vector2 = Vector2.RIGHT
var traveled_distance: float = 0.0


func _ready():
	add_to_group("projectile")
	connect("body_entered", Callable(self, "_on_body_entered"))


func _process(delta):
	var movement = direction * speed * delta
	global_position += movement

	traveled_distance += movement.length()

	if traveled_distance >= max_distance:
		queue_free()
