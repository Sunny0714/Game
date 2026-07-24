extends Node2D

@export var inner_radius := 25.0
@export var pulse_radius := 180.0
@export var max_charge := 10.0
@export var max_width := 14.0
@export var pulse_speed := 260.0

@onready var inner: Line2D = $InnerCircle
@onready var pulse: Line2D = $PulseCircle

var player: Node2D
var charge := 0.0

var current_pulse_radius := 180.0
var flash := false
var flash_timer := 0.0

func _ready():

	player = GameManager.player

	_make_circle(inner, inner_radius)
	_make_circle(pulse, pulse_radius)

	inner.width = 4
	pulse.width = 3

	inner.default_color = Color.BLACK
	pulse.default_color = Color.BLACK

	hide()

func _make_circle(line: Line2D, radius: float):

	line.clear_points()

	for i in range(65):

		var a = TAU * i / 64.0

		line.add_point(
			Vector2(
				cos(a),
				sin(a)
			) * radius
		)

	line.closed = true

func show_effect():

	show()

	charge = 0.0

	current_pulse_radius = pulse_radius

func hide_effect():

	hide()

	charge = 0.0

	current_pulse_radius = pulse_radius

	inner.default_color = Color.BLACK
	pulse.default_color = Color.BLACK

	inner.width = 4
	pulse.width = 3

func _process(delta):

	if !visible:
		return

	if player == null:
		player = GameManager.player
		return

	var dir = (
		get_global_mouse_position() -
		player.global_position
	).normalized()

	global_position = (
		player.global_position +
		dir * 80
	)

	rotation = dir.angle() + deg_to_rad(90)

	var percent = charge / max_charge

	inner.width = lerp(
		4.0,
		max_width,
		percent
	)

	pulse.width = lerp(
		3.0,
		max_width,
		percent
	)

	current_pulse_radius -= lerp(
		pulse_speed,
		pulse_speed * 3.0,
		percent
	) * delta

	if current_pulse_radius <= inner_radius:
		current_pulse_radius = pulse_radius

	_make_circle(
		pulse,
		current_pulse_radius
	)

	var alpha = lerp(
		0.25,
		1.0,
		percent
	)

	inner.modulate.a = alpha
	pulse.modulate.a = alpha

	if charge >= max_charge:

		flash_timer += delta

		if flash_timer >= 0.08:

			flash_timer = 0.0

			flash = !flash

			if flash:

				inner.default_color = Color.RED
				pulse.default_color = Color.RED

			else:

				inner.default_color = Color.BLACK
				pulse.default_color = Color.BLACK

	else:

		inner.default_color = Color.BLACK
		pulse.default_color = Color.BLACK

func set_charge(time: float):

	charge = clamp(
		time,
		0.0,
		max_charge
	)


func add_charge(delta: float):

	charge = clamp(
		charge + delta,
		0.0,
		max_charge
	)


func reset():

	charge = 0.0

	current_pulse_radius = pulse_radius

	inner.width = 4
	pulse.width = 3

	inner.modulate = Color.BLACK
	pulse.modulate = Color.BLACK

	inner.default_color = Color.BLACK
	pulse.default_color = Color.BLACK

	flash = false
	flash_timer = 0.0

	_make_circle(
		inner,
		inner_radius
	)

	_make_circle(
		pulse,
		pulse_radius
	)


func is_max_charge() -> bool:

	return charge >= max_charge


func get_damage() -> float:

	return lerp(
		5.0,
		75.0,
		charge / max_charge
	)
