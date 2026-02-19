extends Node2D

@onready var projectile_scene = preload("res://Scenes/Weapon/force_bullet.tscn")
@onready var marker: Marker2D = $Marker2D
var skill_ready: bool = true
@export var skill_cooldown: float = 1.0


func _process(delta):
	# Rotate weapon toward mouse
	look_at(get_global_mouse_position())


func attack():
	var mana_cost = 1
	if PlayerState.use_mana(mana_cost):
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)

		projectile.global_position = marker.global_position
		projectile.direction = (get_global_mouse_position() - projectile.global_position).normalized()

func skill():
	if not skill_ready:
		return  # Skill is on cooldown
	
	var player = get_tree().get_first_node_in_group("Player")
	var direction = (get_global_mouse_position() - player.global_position).normalized()
	player.dash(direction)
	
	# Start cooldown
	skill_ready = false
	await get_tree().create_timer(skill_cooldown).timeout
	skill_ready = true