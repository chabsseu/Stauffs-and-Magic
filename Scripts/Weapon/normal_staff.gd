extends Node2D

@onready var projectile_scene = preload("res://Scenes/Weapon/fireball.tscn")
@onready var skill_scene = preload("res://Scenes/Weapon/fireball_skill.tscn")
@onready var marker: Marker2D = $Sprite2D/Marker2D

func attack():
	if marker == null:
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = marker.global_position
	projectile.direction = (get_global_mouse_position() - projectile.global_position).normalized()

func fireball_skill():
	if marker == null:
		return

	var mana_cost = 5
	if PlayerState.use_mana(mana_cost):
		var skill = skill_scene.instantiate()
		get_tree().current_scene.add_child(skill)

		skill.global_position = marker.global_position
		skill.direction = (get_global_mouse_position() - skill.global_position).normalized()
