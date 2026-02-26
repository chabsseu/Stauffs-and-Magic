extends Area2D

@export var possible_weapons: Array[PackedScene] = []
@onready var icon: Sprite2D = $Icon

var weapon_scene: PackedScene = null
var weapon_level: int = 1

func _ready():
    # Only randomize if weapon_scene wasn't already assigned (e.g. from a drop)
    if weapon_scene == null:
        if possible_weapons.size() > 0:
            weapon_scene = possible_weapons[randi() % possible_weapons.size()]
    
    # Show the correct icon
    if weapon_scene:
        var temp_weapon = weapon_scene.instantiate()
        var sprite = temp_weapon.get_node("Sprite2D")
        if icon != null and sprite != null:
            icon.texture = sprite.texture
        temp_weapon.queue_free()