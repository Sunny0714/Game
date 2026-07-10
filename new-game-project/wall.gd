extends StaticBody2D

@export var blocks_vision := true
@export var blocks_projectiles := true

func _ready():
	add_to_group("wall")

	if blocks_vision:
		add_to_group("vision_blocker")

	if blocks_projectiles:
		add_to_group("projectile_blocker")
