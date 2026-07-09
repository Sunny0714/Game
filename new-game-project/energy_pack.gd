extends Area2D

@export var energy_amount: int = 50

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
		use_energy_pack()


func _on_mouse_entered():
	hovering = true

	if player.energy < player.max_energy:
		label.text = "[center][b]ENERGY CELL[/b]\n[color=gray]Right click to use[/color][/center]"
		label.show()
	else:
		label.text = "[center][b]ENERGY FULL[/b][/center]"
		label.show()


func _on_mouse_exited():
	hovering = false
	label.hide()


func use_energy_pack():
	if player == null:
		return

	# Don't allow using if already full
	if player.energy >= player.max_energy:
		return

	player.energy += energy_amount
	player.energy = clamp(player.energy, 0, player.max_energy)

	queue_free()
