extends ProgressBar


func set_health(value: float):
	value = clamp(value, 0, max_value)
	self.value = value


func set_max_health(value: float):
	max_value = value
