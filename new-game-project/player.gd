extends CharacterBody2D

@export var base_speed: float = 400.0
@export var max_energy: float = 100.0
@export var max_health: float = 100.0

@export var icicle_scene: PackedScene
@export var earth_wipe_scene: PackedScene
@export var water_ult_scene: PackedScene

@export var absolute_zero_radius: float = 300.0
@export var absolute_zero_duration: float = 12.0
@export var absolute_zero_dps: float = 1.0

@export var fireball_scene: PackedScene
@export var fireball_damage: float = 20.0
@export var fireball_cooldown: float = 1.0
@export var burn_damage: float = 1.0
@export var burn_duration: float = 4.0

@onready var sprite = $Sprite2D
@onready var energy_bar = $EnergyBar
@onready var health_bar = $HealthBar
@onready var hitbox: Area2D = $LightningHitbox

var energy: float
var health: float
var speed: float

var can_shoot := true
var shoot_cooldown := 0.5

var can_earth := true
var earth_cooldown := 0.3

var can_fire := true

var lightning_ult_active := false

var freeze_circle: Line2D

# ---------------- ADDED ----------------
var fire_target_circle: Line2D
# --------------------------------------


func _ready():
	energy = 50
	health = max_health
	speed = base_speed

	_setup_freeze_circle()
	_setup_fire_circle()

	if GameManager.selected_element == "lightning":
		speed = 750

	if GameManager.selected_element == "earth":
		earth_regen()

	energy_bar.max_value = max_energy
	energy_bar.value = energy

	health_bar.set_max_health(max_health)
	health_bar.set_health(health)

	GameManager.player = self

	if hitbox and not hitbox.body_entered.is_connected(_on_lightning_hit):
		hitbox.body_entered.connect(_on_lightning_hit)


func _physics_process(delta):
	var dir = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	).normalized()

	velocity = dir * speed
	move_and_slide()

	look_at(get_global_mouse_position())
	rotation += deg_to_rad(90)

	_update_freeze_circle()
	_update_fire_circle()


func _process(delta):
	energy = clamp(energy, 0, max_energy)
	health = clamp(health, 0, max_health)

	energy_bar.global_position = global_position + Vector2(-40, 520)
	health_bar.global_position = global_position + Vector2(-40, 500)

	energy_bar.value = energy
	health_bar.set_health(health)


func _input(event):
	if event.is_action_pressed("attack"):
		basic_attack()

	if event.is_action_pressed("energy_ability"):
		energy_ability()

	if event.is_action_pressed("ultimate"):
		ultimate()


func basic_attack():
	match GameManager.selected_element:
		"water":
			shoot_icicle()
		"earth":
			earth_wipe_attack()
		"fire":
			fireball_attack()


func energy_ability():
	var cost = 25
	if energy < cost:
		return

	energy -= cost

	if GameManager.selected_element == "water":
		await absolute_zero()


# ---------------- FREEZE CIRCLE ----------------

func _setup_freeze_circle():
	freeze_circle = Line2D.new()
	add_child(freeze_circle)

	freeze_circle.width = 3.0
	freeze_circle.default_color = Color(0.4, 0.7, 1.0, 0.6)
	freeze_circle.visible = false


func _update_freeze_circle():
	if GameManager.selected_element != "water":
		freeze_circle.visible = false
		return

	freeze_circle.visible = true
	freeze_circle.global_position = global_position

	var points = []
	var segments = 32

	for i in range(segments + 1):
		var angle = (TAU / segments) * i
		points.append(Vector2(cos(angle), sin(angle)) * absolute_zero_radius)

	freeze_circle.clear_points()
	for p in points:
		freeze_circle.add_point(p)

# ---------------- FIRE AIM CIRCLE (ADDED) ----------------

func _setup_fire_circle():
	fire_target_circle = Line2D.new()
	add_child(fire_target_circle)

	fire_target_circle.width = 2.5
	fire_target_circle.default_color = Color(1.0, 0.4, 0.1, 0.7)
	fire_target_circle.visible = false

	# higher render priority (draw above most things)
	fire_target_circle.z_index = 100


func _update_fire_circle():
	if GameManager.selected_element != "fire":
		fire_target_circle.visible = false
		return

	fire_target_circle.visible = true
	fire_target_circle.global_position = get_global_mouse_position()

	var points = []
	var segments = 32

	for i in range(segments + 1):
		var angle = (TAU / segments) * i
		points.append(Vector2(cos(angle), sin(angle)) * 80) # BIGGER RADIUS

	fire_target_circle.clear_points()
	for p in points:
		fire_target_circle.add_point(p)

# --------------------------------------------------------


func absolute_zero():
	var space = get_world_2d().direct_space_state

	var shape = CircleShape2D.new()
	shape.radius = absolute_zero_radius

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collide_with_bodies = true

	var results = space.intersect_shape(query)

	var targets = []

	for hit in results:
		var body = hit.collider

		if body and body.is_in_group("enemies"):
			if body.has_method("set_frozen"):
				body.set_frozen(true)

			body.modulate = Color(0.4, 0.7, 1.0)
			targets.append(body)

	for sec in range(int(absolute_zero_duration)):
		await get_tree().create_timer(1.0).timeout

		for e in targets:
			if is_instance_valid(e):
				if e.has_method("take_damage"):
					e.take_damage(absolute_zero_dps)

	for e in targets:
		if is_instance_valid(e):
			if e.has_method("set_frozen"):
				e.set_frozen(false)

			e.modulate = Color.WHITE


func ultimate():
	if energy < max_energy:
		return

	energy = 0

	match GameManager.selected_element:
		"water":
			await spawn_water_ult()

		"earth":
			pass

		"fire":
			pass

		"lightning":
			lightning_ult_active = true
			speed = 3000

			set_collision_mask_value(2, false)

			if hitbox:
				hitbox.monitoring = true

			await get_tree().create_timer(10).timeout

			lightning_ult_active = false
			speed = 750

			set_collision_mask_value(2, true)

			if hitbox:
				hitbox.monitoring = false

	if GameManager.selected_element in ["water", "earth", "fire"]:
		speed = 650
		await get_tree().create_timer(5).timeout
		speed = base_speed


func fireball_attack():
	if fireball_scene == null or !can_fire:
		return

	can_fire = false

	var target_pos = get_global_mouse_position()

	var proj = fireball_scene.instantiate()
	get_tree().current_scene.add_child(proj)

	proj.global_position = global_position + Vector2(0, -80)
	proj.start_position = proj.global_position
	proj.target_position = target_pos

	proj.damage = fireball_damage
	proj.burn_damage = burn_damage
	proj.burn_duration = burn_duration

	await get_tree().create_timer(fireball_cooldown).timeout
	can_fire = true


func spawn_water_ult():
	if water_ult_scene == null:
		return

	for wave in range(3):
		await _spawn_wave()

		if wave < 2:
			await get_tree().create_timer(0.6).timeout


func _spawn_wave():
	var forward = -transform.y
	var count = randi_range(4, 7)

	for i in range(count):
		var proj = water_ult_scene.instantiate()
		get_tree().current_scene.add_child(proj)

		var base_dir = forward.rotated(randf_range(-0.8, 0.8)).normalized()

		var angle = randf_range(0, TAU)
		var dist = randf_range(60, 140)

		var offset = Vector2(cos(angle), sin(angle)) * dist

		proj.global_position = global_position + offset + forward * 40
		proj.direction = base_dir


func _on_lightning_hit(body):
	if not lightning_ult_active:
		return

	if body.has_method("take_damage"):
		body.take_damage(35)


func shoot_icicle():
	if icicle_scene == null or !can_shoot:
		return

	can_shoot = false

	var proj = icicle_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position

	var dir = (get_global_mouse_position() - global_position).normalized()
	proj.direction = dir
	proj.rotation = dir.angle() + deg_to_rad(90)

	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true


func earth_wipe_attack():
	if earth_wipe_scene == null or !can_earth:
		return

	can_earth = false

	var dir = (get_global_mouse_position() - global_position).normalized()

	var wipe = earth_wipe_scene.instantiate()
	add_child(wipe)

	wipe.position = dir * 70
	wipe.rotation = dir.angle() + deg_to_rad(90)

	await get_tree().create_timer(earth_cooldown).timeout
	can_earth = true


func take_damage(amount: float):
	health -= amount
	health = clamp(health, 0, max_health)

	health_bar.set_health(health)
	flash_red()

	if health <= 0:
		get_tree().reload_current_scene()


func flash_red():
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE


func gain_energy(amount: float):
	energy += amount
	energy = clamp(energy, 0, max_energy)


func earth_regen():
	while GameManager.selected_element == "earth":
		await get_tree().create_timer(10.0).timeout
		health += 5
		health = clamp(health, 0, max_health)
		health_bar.set_health(health)


func apply_burn(dmg: float, duration: float):
	for i in range(int(duration)):
		await get_tree().create_timer(1.0).timeout
		health -= dmg
