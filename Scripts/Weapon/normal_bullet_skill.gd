extends Area2D

@export var speed: float = 400
@export var damage: int = 2
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var direction: Vector2 = Vector2.ZERO

# Status effect
@export var has_status_effect: bool = true
@export var effect_type: StatusEffectManager.EffectType = StatusEffectManager.EffectType.STUN
@export var effect_duration: float = 2.0
@export var effect_value: float = 0.0

func _process(delta: float) -> void:
	if direction != Vector2.ZERO:
		position += direction * speed * delta
		sprite.play("fire")
	
	# Flip sprite
	sprite.flip_h = direction.x < 0
	sprite.flip_v = direction.y < 0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		# Apply damage
		if body.has_method("take_damage"):
			body.take_damage(damage)

		# Apply status effect to this enemy only
		if has_status_effect and body.has_node("status_effects"):
			var enemy_status = body.get_node("status_effects")
			enemy_status.add_effect(effect_type, effect_duration, effect_value)
			print("Applied", effect_type, "to", body.name)

		queue_free()

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()