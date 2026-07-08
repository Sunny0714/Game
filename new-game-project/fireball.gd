extends Area2D

@export var damage: float = 20.0
@export var burn_damage: float = 2.0
@export var burn_duration: float = 2.0

@export var min_time: float = 0.5
@export var max_time: float = 1.0
@export var arc_height: float = 120.0

var target_position: Vector2
var start_position: Vector2

var t := 0.0
var travel_time := 1.0
var has_exploded := false


func _ready():
	start_position = global_position

	var dist = start_position.distance_to(target_position)
	travel_time = clamp(dist / 800.0, min_time, max_time)


func _process(delta):
	if has_exploded:
		return

	t += delta
	var alpha = clamp(t / travel_time, 0.0, 1.0)

	var pos = start_position.lerp(target_position, alpha)
	pos.y -= sin(alpha * PI) * arc_height

	global_position = pos

	if alpha >= 1.0:
		_explode()


func _explode():
	if has_exploded:
		return

	has_exploded = true

	var space = get_world_2d().direct_space_state

	var shape = CircleShape2D.new()
	shape.radius = 80.0

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collide_with_bodies = true

	var results = space.intersect_shape(query)

	for hit in results:
		var body = hit.collider

		if body == null:
			continue

		# 🔥 SAFETY: ignore self-type or invalid objects
		if not body.has_method("take_damage"):
			continue

		# 🔥 ONLY BLOCK PLAYER IF GROUP EXISTS
		if body.is_in_group("player"):
			continue

		# 🔥 DAMAGE ALWAYS APPLIES FIRST
		body.take_damage(damage)

		# 🔥 BURN ALWAYS APPLIES IF POSSIBLE
		if body.has_method("apply_burn"):
			body.apply_burn(burn_damage, burn_duration)

	queue_free()
