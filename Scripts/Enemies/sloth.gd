extends CharacterBody2D

@export var max_health: int
@export var damage_node: PackedScene
@onready var enemy_state = EnemyState
@export var charge_speed: float = 600.0
@export var charge_range: float = 200.0
@export var charge_duration: float = 1.0  # Max time to charge before stopping
@export var windup_time: float = 0.4
@export var show_trajectory: bool = true  # Toggle trajectory visualization
@export var trajectory_color: Color = Color(1, 0, 0, 0.5)  # Red with transparency
@export var min_attack_distance: float = 25.0  # Stop charging this close to player
@export var retreat_distance: float = 250.0  # Retreat to this distance after charge
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

enum State { IDLE, WINDUP, CHARGING, RETREATING, COOLDOWN }

var current_health = max_health 
var player: Node2D = null
var state = State.IDLE
var charge_direction: Vector2 = Vector2.ZERO  # Lock direction when charging
var charge_start_pos: Vector2 = Vector2.ZERO  # Track where charge started

# Patrol helpers
var patrol_target: Vector2
var is_stopping: bool = false
var stop_timer: float = 0.0
var start_position: Vector2

@onready var charge_timer = $ChargeTimer

func _ready():
	current_health = max_health
	start_position = global_position
	set_process(true)
	_pick_new_patrol_target()

func _draw():
	if not show_trajectory:
		return
	
	# Only show trajectory during windup (before charging)
	if state == State.WINDUP and charge_direction != Vector2.ZERO:
		var charge_distance = charge_speed * charge_duration
		var end_point = charge_direction * charge_distance
		draw_line(Vector2.ZERO, end_point, trajectory_color, 5.0)

func _physics_process(delta: float) -> void:
	var distance_to_player: float = 9999  # declare it first

	if player != null:
		distance_to_player = global_position.distance_to(player.global_position)

	# Request redraw each frame to update trajectory
	queue_redraw()
	
	match state:
		State.IDLE:
			if player != null and distance_to_player <= charge_range:
				start_charge()
			else:
				# Patrol logic
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
	velocity = dir * enemy_state.speed
	move_and_slide()

func charge_at_player():
	velocity = charge_direction * charge_speed
	move_and_slide()

func retreat_from_player():
	var dir := (global_position - player.global_position).normalized()
	velocity = dir * enemy_state.speed * 1.2
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

func take_damage(amount: int) -> void:
	if damage_node != null:
		var damage = damage_node.instantiate()
		var label = damage.get_node_or_null("Label")
		if label:
			label.text = str(amount)
		damage.global_position = global_position
		get_parent().add_child(damage)

	current_health -= amount
	print("Enemy Health: %d" % current_health)

	if current_health <= 0:
		die()

func die() -> void:
	queue_free()

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Apply actual damage first
		if body.has_method("take_armor_damage"):
			body.take_armor_damage(damage)
		
		# Only apply status effect if this enemy actually deals damage
		if has_status_effect and damage > 0:
			PlayerState.status_effects.add_effect(effect_type, effect_duration, effect_value)
		
		# Optional: Enemy reacts to being hit
		take_damage(1)

# ----------------------
# Patrol helper
func _pick_new_patrol_target() -> void:
	var angle = randf() * TAU
	var distance = randf() * patrol_radius
	patrol_target = start_position + Vector2(cos(angle), sin(angle)) * distance
