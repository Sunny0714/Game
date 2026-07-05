extends Label

var velocity := Vector2(
	randf_range(-40, 40),
	-120
)

var gravity := 300.0
var lifetime := 0.6

func _process(delta):
	lifetime -= delta

	velocity.y += gravity * delta
	position += velocity * delta

	scale -= Vector2.ONE * delta
	modulate.a = lifetime / 0.6

	if lifetime <= 0:
		queue_free()
