extends Area2D

@export var weapon_scene: PackedScene
@onready var icon: Sprite2D = $Icon  # make sure path is correct
var weapon_level: int = 1
func _ready():
	if weapon_scene:
		var temp_weapon = weapon_scene.instantiate()
		var sprite = temp_weapon.get_node("Sprite2D")
		if icon != null and sprite != null:
			icon.texture = sprite.texture
		temp_weapon.queue_free()
