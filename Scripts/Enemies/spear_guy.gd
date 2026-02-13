extends CharacterBody2D

@onready var enemy_state = EnemyState
@export var damage_node: PackedScene
@export var max_health: int
@export var patrol_radius: float = 200.0    # max distance to patrol from start
@export var patrol_speed: float = 100.0
@export var stop_duration: float = 1.5      # seconds to stop after reaching patrol target
@export var backoff_distance: float = 100.0 # distance to move back after attacking
@export var backoff_speed: float = 100.0    # speed during backoff

var current_health: int
var player_in_range: bool = false
var attacking: bool = false
var chase: bool = false
var player: Node2D = null

# Patrol variables
var patrol_target: Vector2
var is_stopping: bool = false
var stop_timer: float = 0.0
var start_position: Vector2

# Backoff variables
var is_backing_off: bool = false
var backoff_target: Vector2

@onready var spear = $Spear
@onready var animation_player: AnimationPlayer = spear.get_node_or_null("AnimationPlayer")
@onready var attack_area: Area2D = $AttackArea
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var detection_area: Area2D = $DetectionArea  # Add this node in the scene


func _ready() -> void:
	current_health = max_health
	start_position = global_position

	if animation_player == null:
		push_error("⚠️ AnimationPlayer not found inside Spear scene!")

	# Connect signals
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	_pick_new_patrol_target()


func _physics_process(delta: float) -> void:
	# Stop movement while attacking
	if attacking:
		velocity = Vector2.ZERO
	elif is_backing_off:
		var direction = (backoff_target - global_position).normalized()
		velocity = direction * backoff_speed

		# Check if reached backoff target
		if global_position.distance_to(backoff_target) < 5.0:
			is_backing_off = false
			velocity = Vector2.ZERO
	else:
		if chase and player != null:
			# Chase player
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * enemy_state.speed
		else:
			# Patrol when not chasing or attacking
			if is_stopping:
				stop_timer -= delta
				velocity = Vector2.ZERO
				if stop_timer <= 0:
					is_stopping = false
					_pick_new_patrol_target()
			else:
				var direction = (patrol_target - global_position).normalized()
				velocity = direction * patrol_speed

				# Check if reached patrol target
				if global_position.distance_to(patrol_target) < 5.0:
					is_stopping = true
					stop_timer = stop_duration

	move_and_slide()

	# Attack if player is in range and not on cooldown or backing off
	if player_in_range and not attacking and not is_backing_off and attack_cooldown.time_left == 0:
		attack()


func attack() -> void:
	if animation_player == null or player == null:
		return

	attacking = true
	animation_player.play("attack")

	# Wait for attack animation to finish
	await animation_player.animation_finished

	attacking = false
	# Start backoff after attack
	_start_backoff()
	attack_cooldown.start(2.0)  # cooldown after attack


func _start_backoff() -> void:
	if player == null:
		return
	is_backing_off = true
	var move_dir = (global_position - player.global_position).normalized()
	backoff_target = global_position + move_dir * backoff_distance


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


func _on_attack_area_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		player = body


func _on_attack_area_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_range = false


func _on_detection_area_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player = body
		chase = true


func _on_detection_area_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player = null
		chase = false


# ----------------------
# Patrol helper
func _pick_new_patrol_target() -> void:
	var angle = randf() * TAU
	var distance = randf() * patrol_radius
	patrol_target = start_position + Vector2(cos(angle), sin(angle)) * distance