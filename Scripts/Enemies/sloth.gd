extends CharacterBody2D

# =========================
# EXPORTS
# =========================
@export var max_health: int = 20
@export var damage_node: PackedScene
@export var charge_speed: float = 600.0
@export var damage: int
@export var charge_range: float = 200.0
@export var charge_duration: float = 1.0
@export var windup_time: float = 1.0
@export var min_attack_distance: float = 25.0
@export var retreat_distance: float = 250.0
@export var patrol_radius: float = 200.0
@export var patrol_speed: float = 100.0
@export var stop_duration: float = 1.5

# Status effect
@export var has_status_effect: bool = true
@export var effect_type: StatusEffectManager.EffectType = StatusEffectManager.EffectType.STUN
@export var effect_duration: float = 0.5
@export var effect_value: float = 0.0

# =========================
# NODES
# =========================
@onready var charge_timer: Timer = $ChargeTimer

# =========================
# STATE
# =========================
enum State { IDLE, WINDUP, CHARGING, RETREATING, COOLDOWN }
var state = State.IDLE

# =========================
# VARIABLES
# =========================
var current_health: int
var player: Node2D = null
var charge_direction: Vector2 = Vector2.ZERO
var charge_start_pos: Vector2 = Vector2.ZERO

# Patrol helpers
var patrol_target: Vector2
var start_position: Vector2
var is_stopping: bool = false
var stop_timer: float = 0.0

# Movement speed affected by status effects
var current_speed: float

# Status effect manager
var status_effects: StatusEffectManager

# =========================
# READY
# =========================
func _ready():
	current_health = max_health
	start_position = global_position
	current_speed = patrol_speed

	# Initialize StatusEffectManager
	status_effects = StatusEffectManager.new()
	add_child(status_effects)
	status_effects.burn_tick.connect(_on_burn_tick)
	status_effects.effect_started.connect(_on_effect_started)
	status_effects.effect_ended.connect(_on_effect_ended)

	_pick_new_patrol_target()
	set_process(true)

# =========================
# PHYSICS
# =========================
func _physics_process(delta: float) -> void:
	status_effects.update(delta)

	var distance_to_player: float = INF
	if player != null:
		distance_to_player = global_position.distance_to(player.global_position)

	match state:
		State.IDLE:
			if player != null and distance_to_player <= charge_range:
				start_charge()
			else:
				# Patrol logic
				_handle_patrol(delta)
		State.WINDUP:
			velocity = Vector2.ZERO
			move_and_slide()
		State.CHARGING:
			_charge_movement()
			if distance_to_player <= min_attack_distance:
				end_charge()
			elif global_position.distance_to(charge_start_pos) >= charge_speed * charge_duration:
				end_charge()
			elif get_slide_collision_count() > 0:
				end_charge()
		State.RETREATING:
			_retreat_movement()
			if distance_to_player >= retreat_distance:
				state = State.COOLDOWN
				charge_timer.start(0.5)
		State.COOLDOWN:
			velocity = Vector2.ZERO
			move_and_slide()

# =========================
# MOVEMENT HELPERS
# =========================
func _handle_patrol(delta: float) -> void:
	if is_stopping:
		stop_timer -= delta
		velocity = Vector2.ZERO
		if stop_timer <= 0:
			is_stopping = false
			_pick_new_patrol_target()
	else:
		var dir = (patrol_target - global_position)
		if dir.length() > 0:
			velocity = dir.normalized() * current_speed
		else:
			velocity = Vector2.ZERO
		if global_position.distance_to(patrol_target) < 5.0:
			is_stopping = true
			stop_timer = stop_duration
	move_and_slide()

func _charge_movement() -> void:
	velocity = charge_direction * current_speed
	move_and_slide()

func _retreat_movement() -> void:
	if player == null:
		return
	var dir = (global_position - player.global_position).normalized()
	velocity = dir * current_speed * 1.2
	move_and_slide()

# =========================
# CHARGE
# =========================
func start_charge() -> void:
	if player == null:
		return
	charge_direction = (player.global_position - global_position).normalized()
	charge_start_pos = global_position
	state = State.WINDUP
	charge_timer.start(windup_time)

func end_charge() -> void:
	state = State.RETREATING

func _on_charge_timer_timeout() -> void:
	if state == State.WINDUP:
		state = State.CHARGING
	elif state == State.COOLDOWN:
		state = State.IDLE

# =========================
# DAMAGE
# =========================
func take_damage(amount: int) -> void:
	if damage_node != null:
		var dmg = damage_node.instantiate()
		var label = dmg.get_node_or_null("Label")
		if label:
			label.text = str(amount)
		dmg.global_position = global_position
		get_parent().add_child(dmg)

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
	queue_free()

# =========================
# STATUS EFFECTS
# =========================
func _on_burn_tick(damage: int) -> void:
	take_damage(damage)

func _on_effect_started(effect_type) -> void:
	match effect_type:
		StatusEffectManager.EffectType.STUN:
			current_speed = 0
		StatusEffectManager.EffectType.SLOW:
			current_speed = patrol_speed * 0.5

func _on_effect_ended(effect_type) -> void:
	if effect_type in [StatusEffectManager.EffectType.STUN, StatusEffectManager.EffectType.SLOW]:
		current_speed = patrol_speed

# =========================
# PATROL HELPER
# =========================
func _pick_new_patrol_target() -> void:
	var angle = randf() * TAU
	var distance = randf() * patrol_radius
	patrol_target = start_position + Vector2(cos(angle), sin(angle)) * distance

# =========================
# PLAYER DETECTION / STATUS EFFECT APPLICATION
# =========================
func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("take_armor_damage"):
			body.take_armor_damage(damage)

		if has_status_effect and damage > 0:
			# Apply effect to the player
			if body.has_node("status_effects"):
				body.get_node("status_effects").add_effect(effect_type, effect_duration, effect_value)

		# Enemy reacts to hitting player
		take_damage(1)