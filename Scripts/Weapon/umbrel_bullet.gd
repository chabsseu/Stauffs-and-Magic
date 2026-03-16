extends Area2D

@export var speed := 400
@export var damage := 1

var direction: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return

	# Move
	position += direction * speed * delta

	# Rotate to movement direction (THIS IS THE KEY)
	rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") or body.is_in_group("Boss") or body.is_in_group("Accessory"):
		body.take_damage(damage)
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
