extends ProgressBar

var flash_timer: float = 0.0
var flashing: bool = false


func set_energy(value: float):
	self.value = value


func set_max_energy(value: float):
	self.max_value = value


func set_low_energy_state(is_low: bool):
	flashing = is_low


func _process(delta):
	if flashing:
		flash_timer += delta

		if int(flash_timer * 10) % 2 == 0:
			modulate = Color(1, 0.5, 0)
		else:
			modulate = Color(1, 1, 1)
	else:
		modulate = Color(1, 1, 1)
