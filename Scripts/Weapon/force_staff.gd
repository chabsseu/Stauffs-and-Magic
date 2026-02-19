extends BaseWeapon

@onready var projectile_scene = preload("res://Scenes/Weapon/force_bullet.tscn")
var skill_ready: bool = true

func attack():
    var mana_cost = 1
    if PlayerState.use_mana(mana_cost):
        spawn_projectile(projectile_scene)

func skill():
    if not skill_ready:
        return

    var player = get_tree().get_first_node_in_group("player")
    if player == null:
        return
    var direction = (get_global_mouse_position() - player.global_position).normalized()
    player.dash(direction)

    skill_ready = false
    await get_tree().create_timer(skill_cooldown).timeout
    skill_ready = true