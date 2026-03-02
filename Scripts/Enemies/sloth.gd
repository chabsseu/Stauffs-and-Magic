extends CharacterBody2D

@export var max_health: int
@export var damage_node: PackedScene

@export var charge_speed: float = 600.0
@export var charge_range: float = 200.0
@export var charge_duration: float = 1.0
@export var windup_time: float = 1.0
@export var show_trajectory: bool = true
@export var trajectory_color: Color = Color(1, 0, 0, 0.5)
@export var min_attack_distance: float = 25.0
@export var retreat_distance: float = 250.0
@export var damage: int

# Status effect
@export var has_status_effect: bool = true
@export var effect_type: StatusEffectManager.EffectType = StatusEffectManager.EffectType.STUN
@export var effect_duration: float = 0.5
@export var effect_value: float = 0.0

# Patrol variables
@export var patrol_radius: float = 200.0
@export var patrol_speed: float = 100.0
@export var stop_duration: float = 1.5

@export var reward_mana : PackedScene

enum State { IDLE, WINDUP, CHARGING, RETREATING, COOLDOWN }

var current_health: int = 0
var current_speed: float = 0.0
var player: Node2D = null
var state = State.IDLE
var charge_direction: Vector2 = Vector2.ZERO
var charge_start_pos: Vector2 = Vector2.ZERO

# Patrol helpers
var patrol_target: Vector2
var is_stopping: bool = false
var stop_timer: float = 0.0
var start_position: Vector2

var status_effects: StatusEffectManager

@onready var charge_timer = $ChargeTimer

func _ready():
	current_health = max_health
	current_speed = patrol_speed
	status_effects = StatusEffectManager.new()
	add_child(status_effects)
	status_effects.effect_started.connect(_on_effect_started)
	status_effects.effect_ended.connect(_on_effect_ended)
	status_effects.burn_tick.connect(_on_burn_tick)
	start_position = global_position
	set_process(true)
	_pick_new_patrol_target()

func _draw():
	if not show_trajectory:
		return
	if state == State.WINDUP and charge_direction != Vector2.ZERO:
		var charge_distance = charge_speed * charge_duration
		var end_point = charge_direction * charge_distance
		draw_line(Vector2.ZERO, end_point, trajectory_color, 5.0)

func _physics_process(delta: float) -> void:
	var distance_to_player: float = 9999

	if player != null:
		distance_to_player = global_position.distance_to(player.global_position)

	queue_redraw()

	# If stunned, skip all movement (same as ranged enemy)
	if status_effects.has_effect(StatusEffectManager.EffectType.STUN):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match state:
		State.IDLE:
			if player != null and distance_to_player <= charge_range:
				start_charge()
			else:
				if is_stopping:
					stop_timer -= delta
					velocity = Vector2.ZERO
					if stop_timer <= 0:
						is_stopping = false
						_pick_new_patrol_target()
				else:
					var direction = (patrol_target - global_position).normalized()
					velocity = direction * patrol_speed
					if global_position.distance_to(patrol_target) < 5.0:
						is_stopping = true
						stop_timer = stop_duration
				move_and_slide()

		State.WINDUP:
			velocity = Vector2.ZERO
			move_and_slide()

		State.CHARGING:
			charge_at_player()
			if distance_to_player <= min_attack_distance:
				end_charge()
			elif global_position.distance_to(charge_start_pos) >= charge_speed * charge_duration:
				end_charge()
			elif get_slide_collision_count() > 0:
				end_charge()

		State.RETREATING:
			retreat_from_player()
			if distance_to_player >= retreat_distance:
				state = State.COOLDOWN
				charge_timer.start(0.5)

		State.COOLDOWN:
			velocity = Vector2.ZERO
			move_and_slide()

func move_toward_player():
	var dir := (player.global_position - global_position).normalized()
	velocity = dir * current_speed
	move_and_slide()

func charge_at_player():
	velocity = charge_direction * charge_speed
	move_and_slide()

func retreat_from_player():
	var dir := (global_position - player.global_position).normalized()
	velocity = dir * current_speed * 1.2
	move_and_slide()

func start_charge():
	charge_direction = (player.global_position - global_position).normalized()
	charge_start_pos = global_position
	state = State.WINDUP
	charge_timer.start(windup_time)
	queue_redraw()

func end_charge():
	state = State.RETREATING
	queue_redraw()

func _on_charge_timer_timeout() -> void:
	if state == State.WINDUP:
		state = State.CHARGING
		queue_redraw()
	elif state == State.COOLDOWN:
		state = State.IDLE

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = null

func take_damage(amount: int) -> void:
	if damage_node != null:
		var damage_instance = damage_node.instantiate()
		var label = damage_instance.get_node_or_null("Label")
		if label:
			label.text = str(amount)
		damage_instance.global_position = global_position
		get_parent().add_child(damage_instance)

	current_health -= amount
	print("Enemy Health: %d" % current_health)

	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(randf_range(2.5, 4.0))

	if current_health <= 0:
		if cam and cam.has_method("shake"):
			cam.shake(randf_range(5.0, 8.0))
		die()

func die() -> void:
	if reward_mana:
		var mana_count = randi_range(1, 3)
		for i in range(mana_count):
			var mana_drop = reward_mana.instantiate()
			# Scatter them randomly around the chest
			var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
			mana_drop.global_position = global_position + offset
			get_parent().add_child(mana_drop)
		print("Spawned ", mana_count, " mana drops!")
		
	queue_free()

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("take_armor_damage"):
			body.take_armor_damage(damage)
		if has_status_effect and damage > 0:
			PlayerState.status_effects.add_effect(effect_type, effect_duration, effect_value)
		take_damage(1)

# =========================
# STATUS EFFECT SIGNALS
# =========================
func _on_burn_tick(dmg):
	take_damage(dmg)

func _on_effect_started(eff_type):
	match eff_type:
		StatusEffectManager.EffectType.STUN:
			current_speed = 0
			charge_timer.stop()
		StatusEffectManager.EffectType.SLOW:
			current_speed = patrol_speed * 0.5

func _on_effect_ended(eff_type):
	current_speed = patrol_speed
	match eff_type:
		StatusEffectManager.EffectType.STUN:
			if state == State.WINDUP:
				charge_timer.start(windup_time)
			elif state == State.COOLDOWN:
				charge_timer.start(0.5)
			elif state == State.CHARGING:
				end_charge()


# =========================
# STATUS EFFECT GETTER
# =========================
func get_status_effects() -> StatusEffectManager:
	return status_effects

# ----------------------
# Patrol helper
func _pick_new_patrol_target() -> void:
	var angle = randf() * TAU
	var distance = randf() * patrol_radius
	patrol_target = start_position + Vector2(cos(angle), sin(angle)) * distance
