extends Area2D

@export var heal_amount: int = 25

var player
@onready var label = $RichTextLabel
@onready var animation_player = $AnimationPlayer

var hovering := false


func _ready():
	player = get_tree().get_first_node_in_group("player")

	label.hide()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	animation_player.play("drop")


func _process(_delta):
	if hovering and Input.is_action_just_pressed("mouse_right"):
		use_health_pack()


func _on_mouse_entered():
	hovering = true

	if player.health < player.max_health:
		label.text = "[center][b]BANDAGES[/b]\n[color=gray]Right click to use[/color][/center]"
	else:
		label.text = "[center][b]HEALTH FULL[/b][/center]"

	label.show()


func _on_mouse_exited():
	hovering = false
	label.hide()


func use_health_pack():
	if player == null:
		return

	if player.health >= player.max_health:
		return

	player.health += heal_amount
	player.health = clamp(player.health, 0, player.max_health)

	player.health_bar.set_health(player.health)

	queue_free()
