extends Node2D

@onready var mana_particle: CPUParticles2D = $ManaParticle

func _process(delta):
	look_at(get_global_mouse_position())

func attack():
	pass 

func skill(amount: int = 10):
	var mana_added = PlayerState.add_mana(amount)

	if mana_added:
		mana_particle.restart()
		mana_particle.emitting = true