extends Area2D

@export var speed = 250.0
@export var arc_gravity = 1000.0
@export var arc_height = 400.0
@export var damage = 1
@export var puddle_scene: PackedScene

var velocity = Vector2.ZERO
var height = 0.0
var vertical_velocity = 0.0
var travel_time = 0.0
var flight_duration = 0.0
@onready var sprite: Sprite2D = $Sprite2D


func launch(from: Vector2, to: Vector2) -> void:
	global_position = from
	var direction = (to - from).normalized()
	var distance = from.distance_to(to)

	# Estimate flight duration based on distance
	flight_duration = distance / speed
	travel_time = 0.0

	velocity = direction * speed
	vertical_velocity = arc_height
	height = 0.0


func _process(delta: float) -> void:
	if velocity == Vector2.ZERO:
		return

	position += velocity * delta

	# Arc motion
	vertical_velocity -= arc_gravity * delta
	height += vertical_velocity * delta

	sprite.position.y = -height * 0.25  # Adjust this value for how "tall" the arc looks

	if height <= 0.0 and vertical_velocity < 0.0:
		_spawn_puddle()
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.take_armor_damage(damage)
		_spawn_puddle()
		queue_free()


func _spawn_puddle() -> void:
	if puddle_scene:
		var puddle = puddle_scene.instantiate()
		puddle.global_position = global_position
		get_tree().current_scene.add_child(puddle)