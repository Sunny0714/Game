extends Area2D

@export var lifetime := 0.65

var damage := 5.0
var knockback := 1000.0

var charge := 0.0
var max_charge := 10.0

var freeze := false


func _ready():

	var percent = clamp(charge / max_charge, 0.0, 1.0)

	damage = lerp(5.0, 75.0, percent)

	knockback = 1000.0 * (1.0 + percent * 2.0)


	print("CHARGE:", charge)
	print("DAMAGE:", damage)
	print("KB:", knockback)


	body_entered.connect(_on_body_entered)

	$Timer.wait_time = lifetime
	$Timer.one_shot = true
	$Timer.timeout.connect(queue_free)
	$Timer.start()



func _on_body_entered(body):

	if !body.is_in_group("enemies"):
		return


	print("FINAL DAMAGE:", damage)
	print("FINAL KB:", knockback)


	if body.has_method("take_damage"):
		body.take_damage(damage)


	if body.has_method("apply_knockback"):

		var dir = (
			body.global_position - global_position
		).normalized()

		body.apply_knockback(dir, knockback)


	if freeze and body.has_method("set_frozen"):

		get_tree().create_timer(0.3).timeout.connect(
			func():
				if is_instance_valid(body):
					body.set_frozen(true)

					get_tree().create_timer(1.0).timeout.connect(
						func():
							if is_instance_valid(body):
								body.set_frozen(false)
					)
		)


	queue_free()
