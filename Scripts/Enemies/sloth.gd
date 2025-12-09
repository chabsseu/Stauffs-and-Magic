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

enum State { IDLE, WINDUP, CHARGING, RETREATING, COOLDOWN }

var current_health = max_health 
var player: Node2D = null
var state = State.IDLE
var charge_direction: Vector2 = Vector2.ZERO  # Lock direction when charging
var charge_start_pos: Vector2 = Vector2.ZERO  # Track where charge started

@onready var charge_timer = $ChargeTimer

func _ready():
	current_health = max_health
	set_process(true)

func _draw():
	if not show_trajectory:
		return
	
	# Only show trajectory during windup (before charging)
	if state == State.WINDUP and charge_direction != Vector2.ZERO:
		var charge_distance = charge_speed * charge_duration
		var end_point = charge_direction * charge_distance
		
		# Draw single thick line
		draw_line(Vector2.ZERO, end_point, trajectory_color, 5.0)

func _physics_process(delta: float) -> void:
	if player == null: 
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Request redraw each frame to update trajectory
	queue_redraw()
	
	match state:
		State.IDLE:
			move_toward_player()
			if distance_to_player <= charge_range:
				start_charge()
		
		State.WINDUP:
			# Stay still during windup, show trajectory
			velocity = Vector2.ZERO
			move_and_slide()
		
		State.CHARGING:
			charge_at_player()
			# Stop charging if hit player, hit anything, traveled too far, or timer expires
			if distance_to_player <= min_attack_distance:
				end_charge()
			elif global_position.distance_to(charge_start_pos) >= charge_speed * charge_duration:
				end_charge()
			# Check if collided with anything during charge
			elif get_slide_collision_count() > 0:
				end_charge()
		
		State.RETREATING:
			retreat_from_player()
			if distance_to_player >= retreat_distance:
				state = State.COOLDOWN
				charge_timer.start(0.5)  # Brief cooldown before next attack
		
		State.COOLDOWN:
			velocity = Vector2.ZERO
			move_and_slide()

func move_toward_player():
	var dir := (player.global_position - global_position).normalized()
	velocity = dir * enemy_state.speed
	move_and_slide()

func charge_at_player():
	# Use locked direction instead of tracking player
	velocity = charge_direction * charge_speed
	move_and_slide()

func retreat_from_player():
	var dir := (global_position - player.global_position).normalized()
	velocity = dir * enemy_state.speed * 1.2  # Slightly faster retreat
	move_and_slide()

func start_charge():
	# Lock the charge direction at the moment of charging
	charge_direction = (player.global_position - global_position).normalized()
	charge_start_pos = global_position  # Remember where we started
	state = State.WINDUP  # Start with windup state
	charge_timer.start(windup_time)
	queue_redraw()  # Show trajectory visualization

func end_charge():
	state = State.RETREATING
	queue_redraw()  # Clear trajectory

func _on_charge_timer_timeout() -> void:
	if state == State.WINDUP:
		# Windup finished, start actual charge
		state = State.CHARGING
		queue_redraw()  # Hide trajectory
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
		body.take_armor_damage(damage)
		take_damage(1)
	
	if has_status_effect:
			print("Applying effect:", effect_type, "for", effect_duration, "seconds")
			# Access PlayerState directly if it's a global autoload
			PlayerState.status_effects.add_effect(effect_type, effect_duration, effect_value)
			print("Effect applied to PlayerState global!")
