extends CharacterBody2D

# =========================
# EXPORTS
# =========================
@export var projectile_scene: PackedScene
@export var damage_node: PackedScene

@export var max_health: int = 10

# Patrol
@export var patrol_radius: float = 200.0
@export var patrol_speed: float = 100.0
@export var stop_duration: float = 1.0

# Reposition
@export var reposition_radius: float = 100.0
@export var reposition_speed: float = 200.0

# Combat
@export var safe_distance: float = 200.0
@export var shoot_interval: float = 0.5
@export var base_speed: float = 150.0  # used for movement affected by status

# =========================
# VARIABLES
# =========================
var current_health: int
var current_speed: float
var player: CharacterBody2D
var can_shoot: bool = false

var patrol_target: Vector2
var reposition_target: Vector2

var is_stopping: bool = false
var stop_timer: float = 0.0
var start_position: Vector2

# States
enum State { PATROL, COMBAT, REPOSITION }
var state = State.PATROL

# =========================
# NODES
# =========================
@onready var shooting_area = $ShootingArea
@onready var timer = $Timer

# Status effect manager
var status_effects: StatusEffectManager

# =========================
# READY
# =========================
func _ready() -> void:
	current_health = max_health
	start_position = global_position
	current_speed = base_speed

	# Initialize status effects per enemy
	status_effects = StatusEffectManager.new()
	add_child(status_effects)
	status_effects.burn_tick.connect(_on_burn_tick)
	status_effects.effect_started.connect(_on_effect_started)
	status_effects.effect_ended.connect(_on_effect_ended)

	# Timer for shooting
	timer.wait_time = shoot_interval
	timer.timeout.connect(_on_timer_timeout)

	_pick_new_patrol_target()

# =========================
# MAIN LOOP
# =========================
func _physics_process(delta: float) -> void:
	match state:
		State.PATROL:
			_handle_patrol(delta)
		State.COMBAT:
			_handle_combat()
		State.REPOSITION:
			_handle_reposition()

	# Move the enemy
	move_and_slide()

	# Update status effects
	status_effects.update(delta)

# =========================
# PATROL
# =========================
func _handle_patrol(delta):
	if player:
		state = State.COMBAT
		return

	if is_stopping:
		stop_timer -= delta
		velocity = Vector2.ZERO
		if stop_timer <= 0:
			is_stopping = false
			_pick_new_patrol_target()
	else:
		var dir = (patrol_target - global_position).normalized()
		velocity = dir * patrol_speed
		if global_position.distance_to(patrol_target) < 5.0:
			is_stopping = true
			stop_timer = stop_duration

func _pick_new_patrol_target():
	var angle = randf() * TAU
	var distance = randf() * patrol_radius
	patrol_target = start_position + Vector2(cos(angle), sin(angle)) * distance

# =========================
# COMBAT
# =========================
func _handle_combat():
	if not player:
		state = State.PATROL
		return

	var distance = global_position.distance_to(player.global_position)

	if distance < safe_distance:
		var move_dir = (global_position - player.global_position).normalized()
		velocity = move_dir * current_speed
	else:
		velocity = Vector2.ZERO

# =========================
# SHOOTING
# =========================
func _on_timer_timeout():
	if not can_shoot or not player or projectile_scene == null:
		return

	var bullet = projectile_scene.instantiate()
	bullet.global_position = global_position

	var direction = (player.global_position - global_position).normalized()

	if bullet.has_method("set_direction"):
		bullet.set_direction(direction)
	elif "velocity" in bullet:
		bullet.velocity = direction * bullet.speed

	get_tree().current_scene.add_child(bullet)

	# Reposition after shooting
	_pick_reposition_target()
	state = State.REPOSITION

# =========================
# REPOSITION
# =========================
func _pick_reposition_target():
	if not player:
		return
	var angle = randf() * TAU
	var offset = Vector2(cos(angle), sin(angle)) * reposition_radius
	reposition_target = player.global_position + offset

func _handle_reposition():
	if not player:
		state = State.PATROL
		return

	var dir = (reposition_target - global_position)
	if dir.length() < 10.0:
		state = State.COMBAT
		timer.start()
		return

	velocity = dir.normalized() * reposition_speed

# =========================
# DETECTION
# =========================
func _on_shooting_area_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		player = body
		can_shoot = true
		timer.start()
		state = State.COMBAT

func _on_shooting_area_body_exited(body: Node2D):
	if body.is_in_group("Player"):
		player = null
		can_shoot = false
		timer.stop()
		state = State.PATROL

# =========================
# DAMAGE + STATUS EFFECT HANDLERS
# =========================
func take_damage(amount: int):
	# Spawn damage label
	if damage_node:
		var dmg = damage_node.instantiate()
		var label = dmg.find_child("Label")
		if label:
			label.text = str(amount)
		dmg.global_position = global_position
		get_parent().add_child(dmg)

	# Apply damage
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

# =========================
# STATUS EFFECT SIGNALS
# =========================
func _on_burn_tick(damage: int):
	take_damage(damage)

func _on_effect_started(effect_type):
	match effect_type:
		StatusEffectManager.EffectType.STUN:
			current_speed = 0
		StatusEffectManager.EffectType.SLOW:
			current_speed = base_speed * 0.5

func _on_effect_ended(effect_type):
	if effect_type in [StatusEffectManager.EffectType.STUN, StatusEffectManager.EffectType.SLOW]:
		current_speed = base_speed

# =========================
# DEATH
# =========================
func die():
	queue_free()
