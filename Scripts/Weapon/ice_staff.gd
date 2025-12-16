extends Node2D

@onready var projectile_scene = preload("res://Scenes/Weapon/iceball.tscn")
@onready var skill_scene = preload("res://Scenes/Weapon/fireball_skill.tscn")
@onready var marker: Marker2D = $Marker2D

func _process(delta):
	look_at(get_global_mouse_position())

func attack():
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = marker.global_position
	projectile.direction = (get_global_mouse_position() - projectile.global_position).normalized()

func fireball_skill():
	var mana_cost = 5
	if PlayerState.use_mana(mana_cost):
		var skill = skill_scene.instantiate()
		get_tree().current_scene.add_child(skill)

		skill.global_position = marker.global_position
		skill.direction = global_transform.x.normalized()
