extends Area2D

signal inferno_started
signal inferno_ended

@export var damage: float = 10.0
@export var duration: float = 4.0
@export var tick_rate: float = 0.2

@onready var anim: AnimationPlayer = $AnimationPlayer

var bodies_inside: Array = []
var frozen_targets: Array = []
var _alive := true


func _ready():
	if anim:
		anim.play("fire")

	inferno_started.emit()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_start_inferno()


func _on_body_entered(body):
	if body.is_in_group("player"):
		return

	if body.has_method("set_frozen"):
		body.set_frozen(true)
		frozen_targets.append(body)

	bodies_inside.append(body)


func _on_body_exited(body):
	bodies_inside.erase(body)


func _start_inferno():
	var elapsed := 0.0

	while elapsed < duration and _alive:
		await get_tree().create_timer(tick_rate).timeout
		_deal_damage()
		elapsed += tick_rate

	_end_inferno()


func _end_inferno():
	# 🔥 UNFREEZE EVERYTHING WE FROZE
	for body in frozen_targets:
		if is_instance_valid(body):
			if body.has_method("set_frozen"):
				body.set_frozen(false)

	frozen_targets.clear()

	inferno_ended.emit()
	queue_free()


func _deal_damage():
	for body in bodies_inside:
		if not is_instance_valid(body):
			continue

		if body.has_method("take_damage"):
			body.take_damage(damage)
