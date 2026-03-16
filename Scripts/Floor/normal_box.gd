extends CharacterBody2D

var health = 1
var current_health = health

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func take_damage(amount: int):
	current_health -= amount
	
	if current_health <= 0:
		queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Projectile"):
		take_damage(1)
	
