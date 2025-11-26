extends Node2D

@onready var projectile_scene = preload("res://Scenes/Weapon/fireball.tscn")
@onready var skill_scene = preload("res://Scenes/Weapon/fireball_skill.tscn")
@onready var marker = $Marker2D

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("fire"):
		attack()
	
	if Input.is_action_just_pressed("skill"):
		fireball_skill()

func attack():
	var projectile = projectile_scene.instantiate()
	
	# ✅ Add projectile to the root scene (not inside player)
	get_tree().current_scene.add_child(projectile)
	
	# ✅ Set correct spawn position using Marker2D
	projectile.global_position = marker.global_position
	
	# ✅ Correct aiming direction toward mouse
	projectile.direction = (get_global_mouse_position() - projectile.global_position).normalized()

func fireball_skill():
	var skill = skill_scene.instantiate()

	get_tree().current_scene.add_child(skill)

	skill.global_position = marker.global_position

	skill.direction = (get_global_mouse_position() - skill.global_position).normalized() 