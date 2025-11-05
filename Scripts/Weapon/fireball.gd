extends Area2D

@export var speed = 300
@export var damage = 1
@onready var sprite = $AnimatedSprite2D
var direction = Vector2.ZERO


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if direction != Vector2.ZERO:
		position += direction * speed * delta
		$AnimatedSprite2D.play("fire")
		
	# ✅ Flip horizontally when going left
	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	
	# Flip vertically
	if direction.x < 0:
		sprite.flip_v = true
	else:
		sprite.flip_v = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		body.take_damage(damage)
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
