extends CharacterBody2D

@export var speed: float = 400.0
@export var max_energy: float = 100.0
@export var max_health: float = 100.0
@export var icicle_scene: PackedScene
@export var earth_wipe_scene: PackedScene

@onready var energy_bar = $"EnergyBar"
@onready var health_bar = $"HealthBar"

var energy: float = 100.0
var health: float = 100.0

var can_shoot: bool = true
var shoot_cooldown: float = 0.5

var can_earth: bool = true
var earth_cooldown: float = 0.3

func _ready():
	energy = max_energy
	health = max_health
	energy_bar.max_value = max_energy
	energy_bar.value = energy
	health_bar.set_max_health(max_health)
	health_bar.set_health(health)
	GameManager.player = self

func _physics_process(delta):
	var dir = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	).normalized()
	velocity = dir * speed
	move_and_slide()

func _process(delta):
	energy = clamp(energy, 0, max_energy)
	health = clamp(health, 0, max_health)
	energy_bar.value = energy
	health_bar.set_health(health)
	if GameManager.selected_element == "lightning":
		speed = 750

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		basic_attack()

func basic_attack():
	match GameManager.selected_element:
		"water":
			shoot_icicle()
		"earth":
			earth_wipe_attack()

func shoot_icicle():
	if icicle_scene == null or not can_shoot:
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
	if earth_wipe_scene == null or not can_earth:
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
	if health <= 0:
		die()

func die():
	get_tree().reload_current_scene()
