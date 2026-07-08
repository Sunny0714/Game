extends CharacterBody2D

@export var base_speed: float = 400.0
@export var max_energy: float = 100.0
@export var max_health: float = 100.0

@export var icicle_scene: PackedScene
@export var earth_wipe_scene: PackedScene
@export var water_ult_scene: PackedScene
@export var inferno_scene: PackedScene
@export var lightning_conductor_scene: PackedScene

var current_conductor: Node = null

@export var absolute_zero_radius: float = 300.0
@export var absolute_zero_duration: float = 5.0
@export var absolute_zero_dps: float = 1.0

@export var fireball_scene: PackedScene
@export var fireball_damage: float = 20.0
@export var fireball_cooldown: float = 1.0
@export var burn_damage: float = 1.0
@export var burn_duration: float = 4.0
@export var energy_cooldown: float = 10.0
@export var earth_ult_scene: PackedScene
@export var lightning_scene: PackedScene
@export var lightning_cooldown: float = 0.8

var can_use_lightning: bool = true

@onready var sprite = $Sprite2D
@onready var energy_bar = $EnergyBar
@onready var health_bar = $HealthBar
@onready var hitbox: Area2D = $LightningHitbox
@onready var camera: Camera2D = $Camera2D

var energy: float
var health: float
var speed: float
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0
var can_shoot := true
var shoot_cooldown := 0.5
var pending_heal := 0.0


var can_earth := true
var earth_cooldown := 0.3
var energy_cd: bool = true
var can_fire := true

var lightning_ult_active := false

var freeze_circle: Line2D

var fire_target_circle: Line2D

var inferno_locked := false

var earth_buff := false

@export var earth_buff_duration := 5.0
@export var damage_reduction : float = 100
@export var earth_lifesteal := 1

var earth_circle: Line2D

func _ready():
	energy = 100
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
	_setup_earth_circle()


func _physics_process(delta):
	if inferno_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if pending_heal > 0:
		health += pending_heal
		health = clamp(health, 0, max_health)
		pending_heal = 0
	health_bar.set_health(health)
	var dir = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	).normalized()

	if knockback_timer > 0:

		velocity = knockback_velocity
		knockback_timer -= delta

	else:

		velocity = dir * speed

	move_and_slide()

	look_at(get_global_mouse_position())
	rotation += deg_to_rad(90)

	_update_freeze_circle()
	_update_fire_circle()

func _process(delta):
	if shake_strength > 0:
		var camera_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)

		$Camera2D.offset = camera_offset

		shake_strength = lerp(shake_strength, 0.0, 0.15)

		if shake_strength < 0.1:
			shake_strength = 0
			$Camera2D.offset = Vector2.ZERO

		
	energy = clamp(energy, 0, max_energy)
	health = clamp(health, 0, max_health)

	energy_bar.global_position = global_position + Vector2(160, 560)
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
		"lightning":
			lightning_attack()


func energy_ability():
	var cost = 25
	if energy < cost:
		return
	if !energy_cd:
		return
	energy_cd = false
	energy -= cost

	if GameManager.selected_element == "water":
		absolute_zero()

	if GameManager.selected_element == "earth":
		start_earth_buff()
		damage_reduction = 80
		await get_tree().create_timer(energy_cooldown).timeout
		damage_reduction = 100
	if GameManager.selected_element == "lightning":
		spawn_lightning_conductor()
	await get_tree().create_timer(energy_cooldown).timeout
	energy_cd = true

		

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


func _setup_fire_circle():
	fire_target_circle = Line2D.new()
	add_child(fire_target_circle)

	fire_target_circle.width = 2.5
	fire_target_circle.default_color = Color(1.0, 0.4, 0.1, 0.7)
	fire_target_circle.visible = false

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
			earth_ult()

		"fire":
			start_inferno()

		"lightning":
			lightning_ult_active = true
			speed = 3000
			damage_reduction = 10
			set_collision_mask_value(2, false)
			$CollisionShape2D.scale = Vector2(1.5, 1.5)

			if hitbox:
				hitbox.monitoring = true

			await get_tree().create_timer(20).timeout

			lightning_ult_active = false
			$CollisionShape2D.scale = Vector2(1, 1)
			speed = 750
			damage_reduction = 100
			set_collision_mask_value(2, true)

			if hitbox:
				hitbox.monitoring = false

	if GameManager.selected_element in ["water", "earth", "fire"]:
		speed = 650
		await get_tree().create_timer(10).timeout
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

	await get_tree().create_timer(0.5).timeout

	_start_fire_burn(target_pos)

	await get_tree().create_timer(1.5).timeout
	can_fire = true

func _start_fire_burn(pos: Vector2):
	var space = get_world_2d().direct_space_state

	var shape = CircleShape2D.new()
	shape.radius = 80.0

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collide_with_bodies = true

	var results = space.intersect_shape(query)

	var targets = []

	for hit in results:
		var body = hit.collider

		if body == null:
			continue

		# ignore player
		if body.is_in_group("player"):
			continue

		if body.has_method("take_damage"):
			targets.append(body)

	_run_fire_burn(targets)

func _run_fire_burn(targets: Array):
	var elapsed := 0.0

	while elapsed < 5.0:

		await get_tree().create_timer(0.8).timeout

		for e in targets:
			if is_instance_valid(e):
				if e.has_method("take_damage"):
					e.take_damage(2)

		elapsed += 0.8

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
	get_tree().current_scene.add_child(wipe)

	wipe.global_position = global_position + dir * 70

	wipe.global_rotation = dir.angle() + deg_to_rad(90)

	wipe.follow_player = self
	wipe.offset = dir * 70

	await get_tree().create_timer(earth_cooldown).timeout
	can_earth = true

func take_damage(amount: float):
	var final_damage := amount * damage_reduction / 100

	health -= final_damage
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
	var elapsed := 0.0

	while elapsed < duration:
		await get_tree().create_timer(randf_range(0.2, 0.4)).timeout
		health -= dmg
		elapsed += randf_range(0.2, 0.4)


func start_inferno():
	if inferno_scene == null:
		return

	var inferno = inferno_scene.instantiate()
	get_tree().current_scene.add_child(inferno)

	inferno.global_position = global_position + Vector2(0, -80)

	var dir = (get_global_mouse_position() - global_position).normalized()
	inferno.rotation = dir.angle() + deg_to_rad(90)

	inferno_locked = true
	speed = 0
	can_fire = false

	await get_tree().create_timer(4.0).timeout
	inferno_locked = false
	speed = base_speed
	can_fire = true


var shake_strength: float = 0.0

func screen_shake(amount: float = 18.0):
	shake_strength = amount


func start_earth_buff():
	if earth_buff:
		return

	earth_buff = true
	screen_shake(18.0)

	_pulse_earth_circle()

	await get_tree().create_timer(energy_cooldown).timeout

	earth_buff = false
	earth_circle.visible = false


func _setup_earth_circle():
	earth_circle = Line2D.new()
	add_child(earth_circle)

	earth_circle.width = 4.0
	earth_circle.default_color = Color(0.3, 1.0, 0.3, 0.6)
	earth_circle.visible = false
	earth_circle.z_index = 100


func _pulse_earth_circle():
	earth_circle.visible = true
	earth_circle.clear_points()

	var segments := 64
	var max_radius := 2500.0
	var steps := 20

	for i in range(steps):
		earth_circle.clear_points()

		var t := float(i) / float(steps)
		var radius: float = max_radius * (1.0 - t)

		for j in range(segments + 1):
			var angle = TAU * j / segments
			earth_circle.add_point(Vector2(cos(angle), sin(angle)) * radius)

		await get_tree().process_frame

	earth_circle.visible = false

func earth_ult():
	if earth_ult_scene == null:
		return

	var ult = earth_ult_scene.instantiate()
	get_tree().current_scene.add_child(ult)

func lightning_attack():
	if !can_use_lightning:
		return

	if lightning_scene == null:
		return

	can_use_lightning = false


	var lightning = lightning_scene.instantiate()
	get_tree().current_scene.add_child(lightning)

	lightning.global_position = global_position

	# Aim toward mouse
	lightning.direction = (
		get_global_mouse_position() - global_position
	).normalized()

	lightning.rotation = lightning.direction.angle()


	await get_tree().create_timer(lightning_cooldown).timeout

	can_use_lightning = true

func spawn_lightning_conductor():

	if lightning_conductor_scene == null:
		return


	# Destroy old conductor
	if is_instance_valid(current_conductor):

		print("OLD CONDUCTOR DESTROYED")

		for enemy in get_tree().get_nodes_in_group("enemies"):

			if !is_instance_valid(enemy):
				continue


			var distance = current_conductor.global_position.distance_to(
				enemy.global_position
			)


			if distance > 250:
				continue


			print("CONDUCTOR EXPLOSION HIT:", enemy.name)


			if enemy.has_method("take_damage"):
				enemy.take_damage(10)


		current_conductor.queue_free()



	# Spawn new conductor
	current_conductor = lightning_conductor_scene.instantiate()

	get_tree().current_scene.add_child(current_conductor)

	current_conductor.global_position = global_position

func apply_knockback(direction: Vector2, force: float, duration: float = 0.25):

	knockback_velocity = direction * force
	knockback_timer = duration
