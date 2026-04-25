extends Area2D

@export var speed := 300
@export var damage := 1
var direction: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return
	position += direction * speed * delta
	rotation = direction.angle()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("take_armor_damage"):
			body.take_armor_damage(damage)
		queue_free()
