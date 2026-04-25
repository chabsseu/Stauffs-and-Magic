extends Area2D

@export var speed := 300
@export var damage := 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var direction: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return

	# Move
	position += direction * speed * delta

	# Rotate to movement direction (THIS IS THE KEY)
	rotation = direction.angle()

	# Play animation
	sprite.play("fire")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") or body.is_in_group("Boss") or body.is_in_group("Accessory"):
		var hit_dir = (body.global_position - global_position).normalized()
		body.take_damage(damage, hit_dir)
		queue_free()
	
	if is_in_group("EnemyProjectile") and body.is_in_group("Player"):
			if body.has_method("take_armor_damage"):
				body.take_armor_damage(damage)
			queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
