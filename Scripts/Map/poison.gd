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

	# Auto destroy
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


# ----------------------------
# DAMAGE (FIXED → ALWAYS ARMOR SAFE)
# ----------------------------
func _apply_damage(body: Node2D) -> void:
	if not is_instance_valid(body):
		return

	# ALWAYS use armor system first
	if body.has_method("take_armor_damage"):
		body.take_armor_damage(damage_per_tick)
	elif body.has_method("take_damage"):
		body.take_damage(damage_per_tick)


# ----------------------------
# POISON APPLY (FIXED)
# ----------------------------
func apply_poison(body: Node2D) -> void:
	if poisoning_bodies.has(body):
		return

	poisoning_bodies[body] = {
		"timer": poison_duration,
		"tick_timer": 0.0
	}

	if body.has_method("set_poison_visual"):
		body.set_poison_visual(true)

	# ONLY APPLY STATUS EFFECT ON PLAYER (UI + SYSTEM)
	if body.is_in_group("Player"):
		PlayerState.status_effects.add_effect(
			StatusEffectManager.EffectType.POISON,
			poison_duration,
			poison_damage
		)


# ----------------------------
# POISON TICK (FIXED → ARMOR SAFE)
# ----------------------------
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

			# 💥 FIX: ALWAYS USE ARMOR SYSTEM FIRST
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


# ----------------------------
# VISUALS (UNCHANGED)
# ----------------------------
func _draw() -> void:
	var pulse = 0.1 + ((sin(pulse_timer * 2.0) + 1.0) / 2.0) * 0.2

	var base_color = Color(0.25, 0.0, 0.4)
	var inner_color = Color(0.6, 0.2, 1.0)

	var steps = 65

	for i in range(steps):
		var t = float(i) / steps
		var radius = poison_radius * (1.0 - t)

		var r = lerp(base_color.r, inner_color.r, 1.0 - t)
		var g = lerp(base_color.g, inner_color.g, 1.0 - t)
		var b = lerp(base_color.b, inner_color.b, 1.0 - t)

		var alpha = (0.03 + 0.07 * pulse) * (1.0 - t)

		draw_circle(Vector2.ZERO, radius, Color(r, g, b, alpha))

	var arc_color = base_color
	arc_color.a = 0.6 + 0.4 * pulse

	draw_arc(Vector2.ZERO, poison_radius, 0, TAU, 64, arc_color, 3.0)

	var dash_count = 12
	for i in range(dash_count):
		var start_angle = (TAU / dash_count) * i + pulse_timer * 0.4
		var end_angle = start_angle + (TAU / dash_count) * 0.5

		var dash_color = base_color
		dash_color.a = 0.5

		draw_arc(
			Vector2.ZERO,
			poison_radius + 4.0,
			start_angle,
			end_angle,
			10,
			dash_color,
			2.0
		)
