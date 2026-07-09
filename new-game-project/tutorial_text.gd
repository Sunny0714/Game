extends Label

var time := 0.0
var start_position: Vector2

func _ready():
	start_position = position

	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	modulate = Color(0.998, 0.865, 0.794, 1.0)

func _process(delta):
	time += delta

	position.y = start_position.y + sin(time * 3.0) * 8

	var brightness = 0.85 + 0.15 * sin(time * 4.0)
	modulate = Color(
		brightness,
		brightness * 0.9,
		0.35
	)
