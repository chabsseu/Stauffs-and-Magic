extends Area2D

@export var speed: float = 350.0
@export var damage: int = 1
@export var puddle_scene: PackedScene   # optional (still works on hit)

var velocity: Vector2 = Vector2.ZERO


# =========================
# SET DIRECTION FROM ENEMY
# =========================
func set_direction(dir: Vector2) -> void:
	velocity = dir.normalized() * speed


# =========================
# MOVEMENT
# =========================
func _process(delta: float) -> void:
	if velocity == Vector2.ZERO:
		return

	position += velocity * delta


# =========================
# HIT PLAYER
# =========================
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("take_armor_damage"):
			body.take_armor_damage(damage)

		_spawn_puddle()
		queue_free()


# =========================
# OPTIONAL EFFECT ON HIT
# =========================
func _spawn_puddle() -> void:
	if puddle_scene:
		var puddle = puddle_scene.instantiate()
		puddle.global_position = global_position
		get_tree().current_scene.add_child(puddle)