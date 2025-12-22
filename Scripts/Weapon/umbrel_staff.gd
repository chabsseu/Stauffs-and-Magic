extends Node2D

@onready var projectile_scene = preload("res://Scenes/Weapon/umbrel_bullet.tscn")
@export var skill_cooldown: float = 10.0
@export var cooldown: float = 5
@onready var marker: Marker2D = $Marker2D

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())

func attack():
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = marker.global_position
	projectile.direction = (get_global_mouse_position() - projectile.global_position).normalized()


func skill():
	var mana_cost = 10
	if PlayerState.use_mana(mana_cost):
		$AnimationPlayer.play("skill")
		$SkillArea/CollisionShape2D.disabled = false
		await get_tree().create_timer(cooldown).timeout

		$AnimationPlayer.play("normal")
		$SkillArea/CollisionShape2D.disabled = true


func _on_skill_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("Projectile"):
		area.queue_free()
