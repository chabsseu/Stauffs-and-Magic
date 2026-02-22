extends BaseWeapon

@onready var projectile_scene = preload("res://Scenes/Weapon/iceball.tscn")
@onready var skill_scene = preload("res://Scenes/Weapon/iceball_skill.tscn")

func attack():
    spawn_projectile(projectile_scene)

func skill():
    var mana_cost = 5
    if PlayerState.use_mana(mana_cost):
        spawn_projectile(skill_scene)

func get_upgrade_cooldown_reduction() -> float:
    return 3.0  # reduces cooldown faster