extends StaticBody2D


@onready var explosion_circle: Line2D = $ExplosionCircle
@onready var health_bar = $HealthBar


@export var max_health: float = 500.0

@export var explosion_damage: float = 10.0
@export var explosion_radius: float = 250.0
@export var knockback_force: float = 900.0

@export var damage_number_scene: PackedScene


var health: float
var exploding := false

var shake_strength: float = 0.0



func _ready():

	health = max_health

	add_to_group("lightning_conductor")


	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = false


	_setup_explosion_circle()



func _process(delta):

	if shake_strength > 0:

		var cam = get_viewport().get_camera_2d()

		if cam:
			cam.offset = Vector2(
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength)
			)

		shake_strength = lerp(shake_strength, 0.0, 0.2)


	else:

		var cam = get_viewport().get_camera_2d()

		if cam:
			cam.offset = Vector2.ZERO



func screen_shake(amount: float):

	shake_strength = amount



func take_damage(amount: float):

	if exploding:
		return


	health -= amount
	health = clamp(health, 0, max_health)


	print("CONDUCTOR HP:", health)


	health_bar.visible = health < max_health
	health_bar.value = health


	show_damage_number(amount)


	if health <= 0:
		explode()



func replace_destroy():

	if exploding:
		return


	print("REPLACING CONDUCTOR")

	explode()
	take_damage(500)



func explode():

	if exploding:
		return


	exploding = true


	print("BOOM!")


	screen_shake(16.0)


	_deal_explosion_damage()
	queue_free()




func _deal_explosion_damage():

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


		if body == self:
			continue


		if body == null:
			continue


		print("CONDUCTOR EXPLOSION HIT:", body.name)



		if body.has_method("take_damage"):
			body.take_damage(explosion_damage)



		if body is CharacterBody2D:

			var direction = (
				body.global_position - global_position
			).normalized()


			body.velocity += direction * knockback_force



func show_damage_number(amount: float):

	if damage_number_scene == null:
		return


	var number = damage_number_scene.instantiate()


	get_tree().current_scene.add_child(number)


	number.global_position = global_position + Vector2(0, -40)


	if number is Label:
		number.text = str(int(amount))


	number.scale = Vector2(1.5, 1.5)



func _setup_explosion_circle():

	explosion_circle.clear_points()


	var points := 64


	for i in range(points + 1):

		var angle = TAU * i / points


		explosion_circle.add_point(
			Vector2(cos(angle), sin(angle)) * explosion_radius
		)


	explosion_circle.width = 4.0
	explosion_circle.default_color = Color(0.7, 0.7, 0.7, 0.6)
	explosion_circle.closed = true
	explosion_circle.z_index = 100
