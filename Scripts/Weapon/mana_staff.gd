extends BaseWeapon

@onready var mana_particle: CPUParticles2D = $ManaParticle

func attack():
    pass

func skill():
    if PlayerState.add_mana(10):
        mana_particle.restart()
        mana_particle.emitting = true

func get_upgrade_cooldown_reduction() -> float:
    return 5.0  # reduces cooldown faster