extends CharacterBody2D

var health = 1
var current_health = health
var active = false

@export var fire_scene: PackedScene

func _ready():
	current_health = health
	
	# wait a short time before enabling the hitbox
	await get_tree().process_frame
	active = true


func take_damage(amount: int):
	current_health -= amount

	if fire_scene:
		var fire = fire_scene.instantiate()
		fire.global_position = global_position
		get_parent().add_child(fire)

	if current_health <= 0:
		queue_free()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if not active:
		return
		
	take_damage(1)