extends Area2D

@export var damage: float = 15.0
@export var lifetime: float = 0.2

@onready var anim = $AnimationPlayer


func _ready():
	body_entered.connect(_on_body_entered)

	if anim:
		anim.play("wipe")

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _on_body_entered(body):
	if body.is_in_group("player"):
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)
