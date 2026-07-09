extends Node2D

@export var visual_radius: float = 200.0
@export var damage_radius: float = 240.0
@export var damage: float = 3.0
@export var damage_interval: float = 0.1
@export var duration: float = 7.0
@export var slow_amount: float = 0.3 # 70% slow

@onready var circle: Line2D = $Circle

var damage_timer: float = 0.0


func _ready():
	_setup_circle()

	await get_tree().create_timer(duration).timeout

	# Reset enemies when ult ends
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("remove_slow"):
			enemy.remove_slow()

	queue_free()


func _process(delta):
	# Follow mouse
	global_position = get_global_mouse_position()

	damage_timer -= delta

	if damage_timer <= 0:
		damage_timer = damage_interval
		deal_damage()


func _setup_circle():
	circle.clear_points()

	var points := 64

	for i in range(points):
		var angle = TAU * i / points
		circle.add_point(
			Vector2(cos(angle), sin(angle)) * visual_radius
		)

	circle.closed = true
	circle.width = 4.0
	circle.default_color = Color(0.2, 1.0, 0.2, 0.6)
	circle.z_index = 100


func deal_damage():
	for enemy in get_tree().get_nodes_in_group("enemies"):

		if !is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)

		if distance <= damage_radius:

			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)

			if enemy.has_method("apply_slow"):
				enemy.apply_slow(slow_amount)

		else:
			if enemy.has_method("remove_slow"):
				enemy.remove_slow()
