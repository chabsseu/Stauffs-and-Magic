extends CharacterBody2D

@onready var enemy_state = EnemyState

@export var projectile_scene: PackedScene
@export var safe_distance: float = 200.0
@export var shoot_interval: float = 0.5
@export var damage_node: PackedScene
@export var max_health: int = 10

@export var patrol_radius: float = 200.0
@export var patrol_speed: float = 100.0
@export var stop_duration: float = 1.0

# reposition settings
@export var reposition_radius: float = 100.0
@export var reposition_speed: float = 200.0

var current_health: int
var player: CharacterBody2D
var can_shoot: bool = false

var patrol_target: Vector2
var reposition_target: Vector2

var is_stopping: bool = false
var stop_timer: float = 0.0

var start_position: Vector2

@onready var shooting_area = $ShootingArea
@onready var timer = $Timer

# =========================
# STATES
# =========================
enum State {
	PATROL,
	COMBAT,
	REPOSITION
}

var state = State.PATROL

# =========================
# READY
# =========================
func _ready() -> void:
	timer.wait_time = shoot_interval
	timer.timeout.connect(_on_timer_timeout)

	shooting_area.body_entered.connect(_on_shooting_area_body_entered)
	shooting_area.body_exited.connect(_on_shooting_area_body_exited)

	current_health = max_health
	start_position = global_position
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

	move_and_slide()

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
		var direction = (patrol_target - global_position).normalized()
		velocity = direction * patrol_speed

		if global_position.distance_to(patrol_target) < 5.0:
			is_stopping = true
			stop_timer = stop_duration

func _pick_new_patrol_target() -> void:
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
		velocity = move_dir * enemy_state.speed
	else:
		velocity = Vector2.ZERO

# =========================
# SHOOT THEN REPOSITION
# =========================
func _on_timer_timeout() -> void:
	if not can_shoot or not player or projectile_scene == null:
		return

	# Shoot
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
func _on_shooting_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body
		can_shoot = true
		timer.start()
		state = State.COMBAT

func _on_shooting_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = null
		can_shoot = false
		timer.stop()
		state = State.PATROL

# =========================
# DAMAGE SYSTEM + JUICE
# =========================
func take_damage(amount: int):
	# Spawn floating damage text
	if damage_node:
		var damage = damage_node.instantiate()
		var label = damage.find_child("Label")
		if label:
			label.text = str(amount)

		damage.global_position = global_position
		get_parent().add_child(damage)

	# Apply damage
	current_health -= amount
	print("Enemy Health: %d" % current_health)

	# Camera shake (light hit)
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(randf_range(2.5, 4.0))

	# Death
	if current_health <= 0:
		# Stronger shake on kill
		if cam and cam.has_method("shake"):
			cam.shake(randf_range(5.0, 8.0))

		die()

# =========================
# DEATH
# =========================
func die():
	queue_free()