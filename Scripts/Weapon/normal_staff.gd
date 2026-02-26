extends BaseWeapon

@onready var projectile_scene = preload("res://Scenes/Weapon/normal_bullet.tscn")
@onready var skill_scene = preload("res://Scenes/Weapon/normal_bullet_skill.tscn")

func attack():
    spawn_projectile(projectile_scene)

func skill():
    var mana_cost = 5
    if PlayerState.use_mana(mana_cost):
        spawn_skill_projectile(skill_scene)

func get_upgrade_cooldown_reduction() -> float:
    return 1.0  # reduces cooldown faster

func get_upgrade_skill_damage_increase() -> float:
    return 2.0