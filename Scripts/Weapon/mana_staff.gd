extends Node2D

#@onready var skill_scene = preload("res://Scenes/Weapon/mana_staff_particles.tscn")
#

func _process(delta):
	look_at(get_global_mouse_position())

func attack():
	pass 

func skill(amount: int = 10):
	PlayerState.add_mana(amount)