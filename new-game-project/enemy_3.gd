extends CharacterBody2D

@export var min_health: float = 200.0
@export var max_health: float = 250.0
@export var health_pack_scene: PackedScene
@export var energy_pack_scene: PackedScene
@export var vision_range: float = 650.0
@export var move_speed: float = 150
@export var contact_damage: float = 12.0

@export var knockback_force: float = 400.0
@export var hit_cooldown: float = 0.4

@export var damage_number_scene: PackedScene
@export var knockback_decay: float = 1800.0
var knockback_velocity: Vector2 = Vector2.ZERO
@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

var health: float
var player: Node2D
var slow_multiplier: float = 1.0
var is_slowed: bool = false
var aggroed := false
var dead := false
var can_hit := true
var frozen := false


func set_frozen(state: bool):
	frozen = state
	velocity = Vector2.ZERO


func _ready():
	add_to_group("enemies")

	player = GameManager.player
	health = randf_range(min_health, max_health)

	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = false

func _physics_process(delta):

	if frozen:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player == null or !is_instance_valid(player) or dead:
		return

	var dist := global_position.distance_to(player.global_position)

	# Vision (only blocks if not aggroed)
	if !aggroed and dist > vision_range:
		velocity = knockback_velocity
		move_and_slide()

		knockback_velocity = knockback_velocity.move_toward(
			Vector2.ZERO,
			knockback_decay * delta
		)
		return

	# Base movement
	if dist > 0:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * move_speed * slow_multiplier
	else:
		velocity = Vector2.ZERO

	# Add knockback on top of movement
	velocity += knockback_velocity

	# Fade knockback over time
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_decay * delta
	)

	move_and_slide()

	# contact check
	if can_hit:
		for i in range(get_slide_collision_count()):
			var col = get_slide_collision(i)
			var body = col.get_collider()

			if body and body.is_in_group("player"):
				_do_hit(body)
				break


func _do_hit(body):
	if frozen:
		return

	can_hit = false
	aggroed = true

	if body.has_method("take_damage"):
		body.take_damage(contact_damage)

	if body.has_method("apply_knockback"):
		var push_dir = (body.global_position - global_position).normalized()
		body.apply_knockback(push_dir, knockback_force)

	var t = get_tree().create_timer(hit_cooldown)
	await t.timeout

	if frozen:
		can_hit = true
		return

	can_hit = true


func take_damage(amount: float):
	if dead:
		return
	if GameManager.player and GameManager.player.earth_buff:
		var heal_amount: float = amount * GameManager.player.earth_lifesteal

		GameManager.player.health += heal_amount
		GameManager.player.health = clamp(
			GameManager.player.health,
			0,
			GameManager.player.max_health
		)

		GameManager.player.health_bar.set_health(GameManager.player.health)

		print("PLAYER LIFESTEAL HEALED:", heal_amount)
	health -= amount
	health = clamp(health, 0.0, max_health)

	aggroed = true

	if is_instance_valid(GameManager.player):
		GameManager.player.gain_energy(round(amount / 3.0))

	show_damage_number(amount)
	flash_red()

	health_bar.visible = true
	health_bar.value = health

	if health <= 0:
		die()


func die():
	if dead:
		return
	dead = true
	drop_pack()
	queue_free()


func flash_red():
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE


func show_damage_number(amount: float):
	if damage_number_scene == null:
		return

	var number = damage_number_scene.instantiate()
	get_tree().current_scene.add_child(number)

	number.global_position = global_position + Vector2(0, -40)

	if number is Label:
		number.text = str(int(amount))

	number.scale = Vector2(1.5, 1.5)

func apply_knockback(direction: Vector2, force: float):

	knockback_velocity = direction.normalized() * force

	aggroed = true

func drop_pack():
	var chance = randf()

	if chance <= 0.05:
		var health_pack = health_pack_scene.instantiate()
		get_tree().current_scene.add_child(health_pack)
		health_pack.global_position = global_position
	elif randf() <= 0.09:
		var pack = energy_pack_scene.instantiate()
		get_tree().current_scene.add_child(pack)
		pack.global_position = global_position

func apply_slow(amount: float, element: String = "water"):
	slow_multiplier = amount
	is_slowed = true

	if has_node("Sprite2D"):
		if element == "earth":
			$Sprite2D.modulate = Color(0.7, 1.0, 0.7) # green
		elif element == "water":
			$Sprite2D.modulate = Color(0.75, 0.9, 1.0) # ice blue

func remove_slow():
	slow_multiplier = 1.0
	is_slowed = false

	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color.WHITE
