extends CharacterBody2D

@export var max_health := 40.0
@export var move_speed := 170.0
@export var vision_range := 900.0
@export var min_distance := 800.0
@export var max_distance := 900.0

@export var damage := 20.0

@export var aim_time := 2.0
@export var lock_time := 0.4
@export var cooldown := 1.2

@export var strafe_speed := 120.0
@export var knockback_decay := 1800.0

@export var damage_number_scene: PackedScene
@export var energy_pack_scene: PackedScene
@export var health_pack_scene: PackedScene

@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar
@onready var aim_line: Line2D = $AimLine
@onready var laser_line: Line2D = $LaserLine

var player: Node2D
var health: float

var knockback_velocity := Vector2.ZERO
var slow_multiplier := 1.0
var is_slowed := false

var aggroed := false
var dead := false
var frozen := false

enum {
	MOVE,
	AIM,
	LOCK,
	FIRE,
	COOLDOWN
}

var state := MOVE
var state_timer := 0.0

var laser_direction := Vector2.RIGHT
var locked_direction := Vector2.RIGHT

var strafe_dir := 1.0
var strafe_timer := 0.0

func set_frozen(value: bool):
	frozen = value
	velocity = Vector2.ZERO


func _ready():
	add_to_group("enemies")

	player = GameManager.player
	health = max_health

	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = false

	aim_line.visible = false
	laser_line.visible = false

	randomize()


func _physics_process(delta):

	if frozen:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if dead:
		return

	if player == null or !is_instance_valid(player):
		player = GameManager.player
		return

	state_timer -= delta
	strafe_timer -= delta

	if strafe_timer <= 0:
		strafe_timer = randf_range(0.8, 1.5)
		strafe_dir = -strafe_dir
	var look_dir = (player.global_position - global_position).normalized()
	sprite.rotation = look_dir.angle() - deg_to_rad(90)
	var dist = global_position.distance_to(player.global_position)

	if dist <= vision_range:
		aggroed = true

	velocity = knockback_velocity

	if aggroed:

		var dir = (player.global_position - global_position).normalized()
		var perp = Vector2(-dir.y, dir.x)

		if state == MOVE:

			if dist < min_distance:
				velocity -= dir * move_speed * slow_multiplier

			elif dist > max_distance:
				velocity += dir * move_speed * slow_multiplier

			velocity += perp * strafe_speed * strafe_dir * slow_multiplier

			if dist <= vision_range and state_timer <= 0:
				state = AIM
				state_timer = aim_time

		elif state == AIM:

			laser_direction = (player.global_position - global_position).normalized()

			locked_direction = laser_direction

			if state_timer <= 0:
				state = LOCK
				state_timer = lock_time

		elif state == LOCK:

			if state_timer <= 0:
				state = FIRE
				fire_laser()

		elif state == COOLDOWN:

			if dist < min_distance:
				velocity -= dir * move_speed * slow_multiplier

			elif dist > max_distance:
				velocity += dir * move_speed * slow_multiplier

			velocity += perp * strafe_speed * strafe_dir * slow_multiplier

			if state_timer <= 0:
				state = MOVE

	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_decay * delta
	)

	move_and_slide()
func _process(delta):

	if dead or player == null or !is_instance_valid(player):
		return

	match state:

		AIM:
			aim_line.visible = true
			laser_line.visible = false

			var aim_length := 1000000.0

			aim_line.clear_points()
			aim_line.add_point(Vector2.ZERO)
			aim_line.add_point(
				locked_direction * aim_length
			)

			aim_line.width = 4
			aim_line.default_color = Color(0.655, 0.0, 0.116, 0.8)

		LOCK:
			aim_line.visible = true
			laser_line.visible = false

			var lock_length := 1000000.0

			aim_line.clear_points()
			aim_line.add_point(Vector2.ZERO)
			aim_line.add_point(
			locked_direction * lock_length
			)

			aim_line.width = 8
			aim_line.default_color = Color(1.0,0.8,0.2,1.0)
		FIRE:
			aim_line.visible = false
			laser_line.visible = true
			
		COOLDOWN:

			aim_line.visible = false
			laser_line.visible = false

		_:

			aim_line.visible = false
			laser_line.visible = false



func fire_laser():

	state = FIRE

	var laser_length := 1000000.0
	var laser_end := global_position + locked_direction * laser_length

	laser_line.clear_points()
	laser_line.add_point(Vector2.ZERO)
	laser_line.add_point(to_local(laser_end))

	laser_line.width = 16
	laser_line.default_color = Color.RED
	laser_line.visible = true

	if player and is_instance_valid(player):

		var closest_point = Geometry2D.get_closest_point_to_segment(
			player.global_position,
			global_position,
			laser_end
		)

		if player.global_position.distance_to(closest_point) <= 40:
			print("LASER HIT AT: ", Time.get_ticks_msec())
			player.take_damage(damage)

	await get_tree().create_timer(0.1).timeout

	laser_line.visible = false

	state = COOLDOWN
	state_timer = cooldown

func take_damage(amount: float):

	if dead:
		return

	health -= amount
	health = clamp(health, 0.0, max_health)

	aggroed = true

	if GameManager.player:
		GameManager.player.gain_energy(round(amount / 3.0))

	_show_damage(amount)
	_update_ui()
	_flash_red()

	if health <= 0:
		die()


func die():

	if dead:
		return

	dead = true

	drop_pack()

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

	if !is_slowed:
		sprite.modulate = Color.WHITE


func apply_knockback(direction: Vector2, force: float):

	knockback_velocity = direction.normalized() * force
	aggroed = true


func apply_slow(amount: float, element: String = "water"):

	slow_multiplier = amount
	is_slowed = true

	match element:

		"earth":
			sprite.modulate = Color(0.7, 1.0, 0.7)

		"water":
			sprite.modulate = Color(0.75, 0.9, 1.0)

		_:
			sprite.modulate = Color.WHITE


func remove_slow():

	slow_multiplier = 1.0
	is_slowed = false

	sprite.modulate = Color.WHITE


func drop_pack():

	var chance = randf()

	if chance <= 0.05:

		if health_pack_scene:

			var pack = health_pack_scene.instantiate()

			get_tree().current_scene.add_child(pack)

			pack.global_position = global_position

	elif chance <= 0.14:

		if energy_pack_scene:

			var pack = energy_pack_scene.instantiate()

			get_tree().current_scene.add_child(pack)

			pack.global_position = global_position
