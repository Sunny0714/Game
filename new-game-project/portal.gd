extends Area2D

@export var next_level: String

var unlocked = false


func _ready():
	body_entered.connect(_on_body_entered)


func _process(delta):
	if get_tree().get_nodes_in_group("enemies").size() == 0:
		unlocked = true
		$Sprite2D.modulate = Color.GREEN


func _on_body_entered(body):
	if body.is_in_group("player") and unlocked:
		get_tree().change_scene_to_file(next_level)
