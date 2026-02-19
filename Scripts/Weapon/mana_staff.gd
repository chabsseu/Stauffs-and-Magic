extends BaseWeapon

@onready var mana_particle: CPUParticles2D = $ManaParticle

func attack():
    pass

func skill():
    if PlayerState.add_mana(10):
        mana_particle.restart()
        mana_particle.emitting = true