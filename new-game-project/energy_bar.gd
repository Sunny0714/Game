extends ProgressBar

var flash_timer: float = 0.0
var flashing: bool = false
var rainbow_timer: float = 0.0

var glow_panel: Panel
var glow_style: StyleBoxFlat


func _ready():
	glow_panel = Panel.new()
	glow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow_panel.z_index = -1
	
	glow_panel.position = Vector2(-5, -5)
	glow_panel.size = size + Vector2(10, 10)

	add_child(glow_panel)

	glow_style = StyleBoxFlat.new()
	glow_style.bg_color = Color(0, 0, 0, 0)

	glow_style.border_width_left = 25
	glow_style.border_width_right = 25
	glow_style.border_width_top = 25
	glow_style.border_width_bottom = 25

	glow_style.corner_radius_top_left = 15
	glow_style.corner_radius_top_right = 15
	glow_style.corner_radius_bottom_left = 15
	glow_style.corner_radius_bottom_right = 15

	glow_panel.add_theme_stylebox_override("panel", glow_style)

	glow_panel.hide()


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

	if value >= 100:
		glow_panel.show()

		rainbow_timer += delta

		var rainbow = Color.from_hsv(
			fmod(rainbow_timer * 0.5, 1.0),
			1.0,
			1.0
		)

		glow_style.border_color = rainbow

		var pulse = 25 + sin(rainbow_timer * 5.0) * 5

		glow_style.border_width_left = pulse
		glow_style.border_width_right = pulse
		glow_style.border_width_top = pulse
		glow_style.border_width_bottom = pulse

	else:
		glow_panel.hide()
