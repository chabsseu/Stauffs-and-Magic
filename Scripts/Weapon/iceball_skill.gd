extends Area2D

@export var speed: float = 400
@export var damage: int = 2
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var direction: Vector2 = Vector2.ZERO

# Status effect
@export var has_status_effect: bool = true
@export var effect_type: StatusEffectManager.EffectType = StatusEffectManager.EffectType.SLOW
@export var effect_duration: float = 2.0
@export var effect_value: float = 0.0

# Reference to EnemyState (make sure EnemyState is an autoload or adjust path)
@onready var enemy_state = $"/root/EnemyState"

func _process(delta: float) -> void:
	if direction != Vector2.ZERO:
		# Safety check to prevent multiplying by Nil
		if speed != null and delta != null:
			position += direction * speed * delta
			sprite.play("skill")
	
	# Flip horizontally based on movement
	sprite.flip_h = direction.x < 0
	# Flip vertically based on vertical movement
	sprite.flip_v = direction.y < 0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()

		if has_status_effect:
			print("Applying effect:", effect_type, "for", effect_duration, "seconds")
			if enemy_state != null and enemy_state.status_effects != null:
				enemy_state.status_effects.add_effect(effect_type, effect_duration, effect_value)
				print("Effect applied to Enemy global!")
			else:
				push_warning("EnemyState or its status_effects is null!")

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
