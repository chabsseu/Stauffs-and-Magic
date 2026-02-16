extends Area2D

@export var target_scene : PackedScene

var sprite : Sprite2D

func _ready():
	sprite = $Sprite2D
	self.visible = false
	# Connect the body_entered signal
	self.body_entered.connect(_on_body_entered)

# Called when player enters portal
func _on_body_entered(body):
	if body.is_in_group("Player"):  # adjust to your player node's name
		print("Player entered the portal!")
		_go_to_next_level()

func _go_to_next_level():
	if target_scene:
		get_tree().change_scene_to_packed(target_scene)
