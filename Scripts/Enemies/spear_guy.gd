extends CharacterBody2D

# =========================
# EXPORTS
# =========================
@export var damage_node: PackedScene
@export var max_health: int = 10

# Patrol
@export var patrol_radius: float = 200.0
@export var patrol_speed: float = 100.0
@export var stop_duration: float = 1.5

# Backoff
@export var backoff_distance: float = 100.0
@export var backoff_speed: float = 100.0

# Attack
@export var attack_cooldown_time: float = 2.0

# =========================
# VARIABLES
# =========================
var current_health: int
var player_in_range: bool = false
var attacking: bool = false
var chase: bool = false
var player: Node2D = null

# Patrol
var patrol_target: Vector2
var is_stopping: bool = false
var stop_timer: float = 0.0
var start_position: Vector2

# Backoff
var is_backing_off: bool = false
var backoff_target: Vector2

# Movement speed affected by status effects
var current_speed: float

# Status effects
var status_effects: StatusEffectManager

# =========================
# NODES
# =========================
@onready var spear = $Spear
@onready var animation_player: AnimationPlayer = spear.get_node_or_null("AnimationPlayer")
@onready var attack_area: Area2D = $AttackArea
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var detection_area: Area2D = $DetectionArea

# =========================
# READY
# =========================
func _ready() -> void:
	current_health = max_health
	start_position = global_position
	current_speed = patrol_speed

	if animation_player == null:
		push_error("⚠️ AnimationPlayer not found inside Spear scene!")

	# Initialize StatusEffectManager
	status_effects = StatusEffectManager.new()
	status_effects.name = "status_effects"
	add_child(status_effects)
	status_effects.burn_tick.connect(_on_burn_tick)
	status_effects.effect_started.connect(_on_effect_started)
	status_effects.effect_ended.connect(_on_effect_ended)

	# Connect signals
	# attack_area.body_entered.connect(_on_attack_area_body_entered)
	# attack_area.body_exited.connect(_on_attack_area_body_exited)
	# detection_area.body_entered.connect(_on_detection_area_body_entered)
	# detection_area.body_exited.connect(_on_detection_area_body_exited)

	_pick_new_patrol_target()

# =========================
# MAIN LOOP
# =========================
func _physics_process(delta: float) -> void:
	# Update status effects
	#status_effects.update(delta)

	# Movement
	if attacking:
		velocity = Vector2.ZERO
	elif is_backing_off:
		var dir = (backoff_target - global_position)
		if dir.length() > 0:
			velocity = dir.normalized() * current_speed
		else:
			velocity = Vector2.ZERO
		if global_position.distance_to(backoff_target) < 5.0:
			is_backing_off = false
			velocity = Vector2.ZERO
	elif chase and player != null:
		var dir = (player.global_position - global_position)
		velocity = dir.normalized() * current_speed
	else:
		# Patrol
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

	# Attack
	if player_in_range and not attacking and not is_backing_off and attack_cooldown.time_left == 0:
		attack()

# =========================
# ATTACK
# =========================
func attack() -> void:
	if animation_player == null or player == null:
		return

	attacking = true
	animation_player.play("attack")
	await animation_player.animation_finished
	attacking = false
	_start_backoff()
	attack_cooldown.start(attack_cooldown_time)

func _start_backoff() -> void:
	if player == null:
		return
	is_backing_off = true
	var move_dir = (global_position - player.global_position).normalized()
	backoff_target = global_position + move_dir * backoff_distance

# =========================
# PATROL
# =========================
func _pick_new_patrol_target() -> void:
	var angle = randf() * TAU
	var distance = randf() * patrol_radius
	patrol_target = start_position + Vector2(cos(angle), sin(angle)) * distance

# =========================
# DAMAGE SYSTEM
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

	# Camera shake
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
# STATUS EFFECT SIGNALS
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
	current_speed = patrol_speed

# =========================
# STATUS EFFECT GETTER
# =========================
func get_status_effects() -> StatusEffectManager:
	# This allows projectiles to access the enemy's status effects
	return status_effects

# =========================
# DETECTION
# =========================
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
