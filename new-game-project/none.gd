extends Area2D

@onready var label = $RichTextLabel

var hovering := false


func _ready():

	label.hide()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _process(_delta):

	if hovering and Input.is_action_just_pressed("mouse_right"):
		use_element_reset()


func _on_mouse_entered():

	hovering = true

	if GameManager.selected_element != "none":
		label.text = "[center][b]DARK MAGIC[/b]\n[color=gray]Right click to use[/color][/center]"
	else:
		label.text = "[center][b]NO ELEMENT EQUIPPED[/b][/center]"

	label.show()


func _on_mouse_exited():

	hovering = false
	label.hide()


func use_element_reset():

	if GameManager.selected_element == "none":
		return

	GameManager.selected_element = "none"

	queue_free()
