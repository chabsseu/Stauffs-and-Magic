extends Node2D
class_name BaseWeapon

@onready var marker: Marker2D = $Marker2D
@export var skill_cooldown: float = 1.0
@export var weapon_level: int = 1

func _process(delta):
    look_at(get_global_mouse_position())

func get_mouse_direction() -> Vector2:
    return (get_global_mouse_position() - marker.global_position).normalized()

func spawn_projectile(scene: PackedScene) -> Node2D:
    var projectile = scene.instantiate()
    get_tree().current_scene.add_child(projectile)
    projectile.global_position = marker.global_position
    projectile.direction = get_mouse_direction()
    return projectile


func apply_upgrade():
    weapon_level += 1

func get_upgrade_cooldown_reduction() -> float:
    return 1.0

func attack():
    pass

func skill():
    pass