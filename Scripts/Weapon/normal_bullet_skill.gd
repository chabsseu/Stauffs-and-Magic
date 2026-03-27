extends Area2D

@export var speed: float = 400
@export var damage: int = 2
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var direction: Vector2 = Vector2.ZERO

# Status effect
@export var has_status_effect: bool = true
@export var effect_type: StatusEffectManager.EffectType = StatusEffectManager.EffectType.STUN
@export var effect_duration: float = 1.0
@export var effect_value: float = 0.0

func _process(delta: float):
	if direction != Vector2.ZERO:
		position += direction * speed * delta
		sprite.play("fire")

	rotation = direction.angle()

func _on_body_entered(body: Node2D):
	if body.is_in_group("Enemy") or body.is_in_group("Boss") or body.is_in_group("Accessory"):
		# Apply damage
		var hit_dir = (body.global_position - global_position).normalized()
		
		if body.has_method("take_damage"):
			body.take_damage(damage, hit_dir)

		# Apply status effect via getter
		if has_status_effect and body.has_method("get_status_effects"):
			var se = body.get_status_effects()
			se.add_effect(effect_type, effect_duration, effect_value)
			print("Applied", effect_type, "to", body.name)

		queue_free()

func _on_visible_on_screen_enabler_2d_screen_exited():
	queue_free()