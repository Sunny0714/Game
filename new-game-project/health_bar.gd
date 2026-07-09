extends ProgressBar

var flash_timer: float = 0.0
var flashing: bool = false


func set_health(value: float):
	value = clamp(value, 0, max_value)
	self.value = value
	
	# Start flashing when health is below 25
	if value <= 25:
		flashing = true
	else:
		flashing = false


func set_max_health(value: float):
	max_value = value


func _process(delta):
	if flashing:
		flash_timer += delta

		if int(flash_timer * 5) % 2 == 0:
			modulate = Color(1, 0.2, 0.2)
		else:
			modulate = Color(1, 1, 1)
	else:
		modulate = Color(1, 1, 1)
