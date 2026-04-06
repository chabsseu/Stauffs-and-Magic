extends CharacterBody2D

# =========================
# EXPORTS
# =========================
@export var max_health: int = 10
@export var damage_node: PackedScene
@export var hit: PackedScene
# Patrol
@export var patrol_radius: float = 200.0
@export var patrol_speed: float = 100.0
@export var stop_duration: float = 1.0

# Reposition / combat
@export var reposition_radius: float = 100.0
@export var reposition_speed: float = 200.0
@export var safe_distance: float = 200.0
@export var shoot_interval: float = 0.5

@export var projectile_scene: PackedScene

@export var reward_mana : PackedScene
@export var coin_drop_scene : PackedScene
@export var food_drop_scene : PackedScene
@export var coin_drop_chance : float = 0.8   # 80% chance
@export var food_drop_chance : float = 0.4   # 40% chance
@export var item_drop_scene: PackedScene
@export var item_drop_chance: float = 0.5 #50% chance
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

# Status Effect
var status_effects: StatusEffectManager

# =========================
# READY
# =========================
func _ready():
	current_health = max_health
	current_speed = patrol_speed
	start_position = global_position

	# Create StatusEffectManager dynamically
	status_effects = StatusEffectManager.new()
	status_effects.name = "status_effects"
	add_child(status_effects)

	# Connect signals
	status_effects.burn_tick.connect(_on_burn_tick)
	status_effects.effect_started.connect(_on_effect_started)
	status_effects.effect_ended.connect(_on_effect_ended)

	# Shooting timer
	timer.wait_time = shoot_interval
	# timer.timeout.connect(_on_timer_timeout)

	_pick_new_patrol_target()

# =========================
# MAIN LOOP
# =========================
func _physics_process(delta):
	# Update status effects
	#status_effects.update(delta)

	# If stunned, skip all movement and shooting
	if status_effects.has_effect(StatusEffectManager.EffectType.STUN):
		velocity = Vector2.ZERO
		return  # skip everything else while stunned

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
		var dir = (patrol_target - global_position).normalized()
		velocity = dir * current_speed
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
	# Don't shoot if stunned
	if status_effects.has_effect(StatusEffectManager.EffectType.STUN):
		return

	if not can_shoot or not player or projectile_scene == null:
		return

	var bullet = projectile_scene.instantiate()
	bullet.global_position = global_position

	if bullet.has_method("set_direction"):
		bullet.set_direction((player.global_position - global_position).normalized())
	elif "velocity" in bullet:
		bullet.velocity = (player.global_position - global_position).normalized() * bullet.speed

	get_tree().current_scene.add_child(bullet)

	_pick_reposition_target()
	state = State.REPOSITION

# =========================
# REPOSITION
# =========================
func _pick_reposition_target():
	if not player:
		return
	var angle = randf() * TAU
	reposition_target = player.global_position + Vector2(cos(angle), sin(angle)) * reposition_radius

func _handle_reposition():
	if not player:
		state = State.PATROL
		return

	var dir = reposition_target - global_position
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
func take_damage(amount: int, hit_direction: Vector2 = Vector2.ZERO):
	# Damage popup
	if damage_node:
		var dmg = damage_node.instantiate()
		var label = dmg.find_child("Label")
		if label:
			label.text = str(amount)
		dmg.global_position = global_position
		get_parent().add_child(dmg)

	# Hit particle — always spawns
	if hit:
		var hit_particle = hit.instantiate()
		hit_particle.global_position = global_position
		get_parent().add_child(hit_particle)
		
		hit_particle.emitting = true

	current_health -= amount
	print("Enemy Health: %d" % current_health)

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
func _on_burn_tick(damage):
	take_damage(damage)

func _on_effect_started(effect_type):
	match effect_type:
		StatusEffectManager.EffectType.STUN:
			current_speed = 0
		StatusEffectManager.EffectType.SLOW:
			current_speed = patrol_speed * 0.5

func _on_effect_ended(effect_type):
	current_speed = patrol_speed

# =========================
# STATUS EFFECT GETTER
# =========================
func get_status_effects() -> StatusEffectManager:
	return status_effects

# =========================
# DEATH
# =========================
func die():
	if reward_mana:
		var mana_count = randi_range(1, 3)
		for i in range(mana_count):
			var mana_drop = reward_mana.instantiate()
			# Scatter them randomly around the chest
			var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
			mana_drop.global_position = global_position + offset
			get_parent().add_child(mana_drop)
		print("Spawned ", mana_count, " mana drops!")
	
	# Drop coins
	if coin_drop_scene and randf() < coin_drop_chance:
		var drop = coin_drop_scene.instantiate()
		drop.global_position = global_position
		get_parent().add_child(drop)

	# Drop food
	if food_drop_scene and randf() < food_drop_chance:
		var drop = food_drop_scene.instantiate()
		drop.global_position = global_position
		get_parent().add_child(drop)
	
	#item drop
	if item_drop_scene and randf() < item_drop_chance:
		var drop = item_drop_scene.instantiate()
		drop.global_position = global_position
		get_parent().add_child(drop)

	queue_free()
