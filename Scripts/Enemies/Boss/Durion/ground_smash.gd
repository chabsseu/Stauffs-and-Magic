extends Area2D

var direction : Vector2 = Vector2.ZERO
var speed : float = 200.0
var damage : int = 2
var lifetime : float = 3.0

func _ready():
	add_to_group("projectile")
	rotation = direction.angle()
	await get_tree().create_timer(lifetime).timeout
	queue_free()  # add this!

func _physics_process(delta: float):
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("take_armor_damage"):
			body.take_armor_damage(damage)
		queue_free()