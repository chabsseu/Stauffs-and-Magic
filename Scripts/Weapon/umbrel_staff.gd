extends BaseWeapon

@onready var projectile_scene = preload("res://Scenes/Weapon/umbrel_bullet.tscn")
@export var skill_duration: float = 5.0

func attack():
    spawn_projectile(projectile_scene)

func skill():
    var mana_cost = 10
    if PlayerState.use_mana(mana_cost):
        $AnimationPlayer.play("skill")
        $SkillArea/CollisionShape2D.disabled = false
        await get_tree().create_timer(skill_duration).timeout
        $AnimationPlayer.play("normal")
        $SkillArea/CollisionShape2D.disabled = true

func _on_skill_area_area_entered(area: Area2D) -> void:
    if area.is_in_group("Projectile"):
        area.queue_free()