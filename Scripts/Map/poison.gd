extends Area2D

@export var damage_per_tick : int = 1
@export var tick_rate : float = 1.0
@export var poison_chance : float = 0.3
@export var poison_damage : int = 1
@export var poison_duration : float = 3.0
@export var poison_tick_rate : float = 1.0
@export var poison_radius : float = 32.0
@export var lifetime : float = 5.0

var bodies_inside : Array = []
var tick_timer : float = 0.0
var poisoning_bodies : Dictionary = {}
var pulse_timer : float = 0.0


func _ready() -> void:
	# Setup collision radius
	var shape = $CollisionShape2D.shape
	if shape is CircleShape2D:
		shape.radius = poison_radius

	# Setup particle radius
	var particles = $CPUParticles2D
	if particles:
		particles.emission_sphere_radius = poison_radius

	# Poison cloud disappears after lifetime seconds
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _process(delta: float) -> void:
	pulse_timer += delta
	tick_timer += delta

	if tick_timer >= tick_rate:
		tick_timer = 0.0

		var current_overlaps = get_overlapping_bodies()

		bodies_inside = bodies_inside.filter(func(b):
			return is_instance_valid(b) and b in current_overlaps
		)

		for body in bodies_inside:
			_apply_damage(body)

			if not poisoning_bodies.has(body) and randf() < poison_chance:
				apply_poison(body)

	_process_poison(delta)
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.is_in_group("Enemy") or body.is_in_group("Boss"):
		if body not in bodies_inside:
			bodies_inside.append(body)

			if not poisoning_bodies.has(body) and randf() < poison_chance:
				apply_poison(body)


func _on_body_exited(body: Node2D) -> void:
	bodies_inside.erase(body)


func _apply_damage(body: Node2D) -> void:
	if not is_instance_valid(body):
		return

	if body.has_method("take_armor_damage"):
		body.take_armor_damage(damage_per_tick)
	elif body.has_method("take_damage"):
		body.take_damage(damage_per_tick)


func apply_poison(body: Node2D) -> void:
	poisoning_bodies[body] = {
		"timer": poison_duration,
		"tick_timer": 0.0
	}

	if body.has_method("set_poison_visual"):
		body.set_poison_visual(true)


func _process_poison(delta: float) -> void:
	var to_remove : Array = []

	for body in poisoning_bodies.keys():

		if not is_instance_valid(body):
			to_remove.append(body)
			continue

		var data = poisoning_bodies[body]
		data["timer"] -= delta
		data["tick_timer"] += delta

		if data["tick_timer"] >= poison_tick_rate:
			data["tick_timer"] = 0.0

			if body.has_method("take_armor_damage"):
				body.take_armor_damage(poison_damage)
			elif body.has_method("take_damage"):
				body.take_damage(poison_damage)

		if data["timer"] <= 0.0:
			to_remove.append(body)

			if is_instance_valid(body) and body.has_method("set_poison_visual"):
				body.set_poison_visual(false)

	for body in to_remove:
		poisoning_bodies.erase(body)


func _draw() -> void:
	var pulse = (sin(pulse_timer * 2.5) + 1.0) / 2.0

	draw_circle(Vector2.ZERO, poison_radius, Color(0.0, 1.0, 0.15, 0.08 + 0.05 * pulse))
	draw_arc(Vector2.ZERO, poison_radius, 0, TAU, 64, Color(0.0, 0.8, 0.35, 0.6 + 0.4 * pulse), 3.0)

	var dash_count = 12

	for i in range(dash_count):
		var start_angle = (TAU / dash_count) * i + pulse_timer * 0.4
		var end_angle = start_angle + (TAU / dash_count) * 0.5

		draw_arc(
			Vector2.ZERO,
			poison_radius + 4.0,
			start_angle,
			end_angle,
			10,
			Color(0.1, 1.0, 0.4, 0.8),
			2.0
		)