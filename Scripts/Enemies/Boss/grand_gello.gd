extends CharacterBody2D

signal healthChanged

# --------------------------------------------------
# EXPORTS
# --------------------------------------------------
@export var max_health : int = 50
@export var phase_two_threshold : float = 0.5
@export var projectile_scene : PackedScene
@export var puddle_scene : PackedScene
@export var enemy_scenes : Array[PackedScene] = []

@export var phase1_attack_cooldown : float = 2.5
@export var phase2_speed : float = 220.0
@export var phase2_attack_cooldown : float = 1.5
@export var phase2_consecutive_attacks : int = 2
@export var all_directions_range : float = 200
@export var pattern_range : float = 200

# --------------------------------------------------
# STATE
# --------------------------------------------------
enum Phase { ONE, TWO }
enum Attack { ARC_PROJECTILE, SPAWN_ENEMIES, ALL_DIRECTIONS, PATTERN }

var current_phase : Phase = Phase.ONE
var current_health : int
var player_ref : Node2D = null
var is_attacking : bool = false
var attack_timer : float = 0.0
var phase_two_triggered : bool = false

var _random_move_dir : Vector2 = Vector2.ZERO
var _random_move_timer : float = 0.0

# --------------------------------------------------
# READY
# --------------------------------------------------
func _ready():
	current_health = max_health

# --------------------------------------------------
# PHYSICS PROCESS
# --------------------------------------------------
func _physics_process(delta: float):
	if player_ref == null:
		return

	if not phase_two_triggered and current_health <= max_health * phase_two_threshold:
		_trigger_phase_two()

	var cooldown = phase1_attack_cooldown if current_phase == Phase.ONE else phase2_attack_cooldown
	if not is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = cooldown
			if current_phase == Phase.ONE:
				phase_one()
			else:
				phase_two()

	if current_phase == Phase.TWO:
		_random_move_timer -= delta
		if _random_move_timer <= 0.0:
			_random_move_timer = randf_range(0.8, 2.0)
			var random_angle = randf_range(0.0, TAU)
			_random_move_dir = Vector2(cos(random_angle), sin(random_angle))
		velocity = _random_move_dir * phase2_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

# --------------------------------------------------
# PHASE ONE
# --------------------------------------------------
func phase_one():
	var attack = _pick_random_attack()
	_execute_attack(attack)

# --------------------------------------------------
# PHASE TWO
# --------------------------------------------------
func phase_two():
	_execute_consecutive_attacks(phase2_consecutive_attacks)

func _trigger_phase_two():
	phase_two_triggered = true
	current_phase = Phase.TWO
	print("BOSS PHASE 2!")
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 0.3, 0.3), 0.15)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.15)
	tween.set_loops(4)

# --------------------------------------------------
# PICK RANDOM ATTACK
# --------------------------------------------------
func _pick_random_attack() -> Attack:
	var attacks = [Attack.ARC_PROJECTILE, Attack.SPAWN_ENEMIES, Attack.ALL_DIRECTIONS, Attack.PATTERN]
	return attacks[randi() % attacks.size()]

# --------------------------------------------------
# EXECUTE CONSECUTIVE ATTACKS
# --------------------------------------------------
func _execute_consecutive_attacks(count: int):
	is_attacking = true
	for i in range(count):
		var attack = _pick_random_attack()
		_execute_attack(attack)
		await get_tree().create_timer(0.8).timeout
	is_attacking = false

# --------------------------------------------------
# EXECUTE ATTACK
# --------------------------------------------------
func _execute_attack(attack: Attack):
	match attack:
		Attack.ARC_PROJECTILE:
			_attack_arc_projectile()
		Attack.SPAWN_ENEMIES:
			_attack_spawn_enemies()
		Attack.ALL_DIRECTIONS:
			_attack_all_directions()
		Attack.PATTERN:
			_attack_pattern()

# --------------------------------------------------
# ATTACK 1 — Arc projectile
# --------------------------------------------------
func _attack_arc_projectile():
	if not projectile_scene or not player_ref:
		return
	print("Boss: Arc projectile!")
	var proj = projectile_scene.instantiate()
	proj.global_position = global_position
	proj.land_position = player_ref.global_position
	proj.puddle_scene = puddle_scene
	get_parent().add_child(proj)

# --------------------------------------------------
# ATTACK 2 — Spawn enemies
# --------------------------------------------------
func _attack_spawn_enemies():
	if enemy_scenes.is_empty():
		return
	print("Boss: Spawning enemies!")
	var count = randi_range(1, 2)
	for i in range(count):
		var scene = enemy_scenes[randi() % enemy_scenes.size()]
		var enemy = scene.instantiate()
		var angle = (TAU / count) * i
		var offset = Vector2(cos(angle), sin(angle)) * 80.0
		enemy.global_position = global_position + offset
		get_parent().add_child(enemy)

# --------------------------------------------------
# ATTACK 3 — 8 directions
# --------------------------------------------------
func _attack_all_directions():
	if not projectile_scene:
		return
	print("Boss: 8 direction burst!")
	for i in range(16):
		var angle = (TAU / 16.0) * i
		var proj = projectile_scene.instantiate()
		proj.global_position = global_position
		proj.land_position = global_position + Vector2(cos(angle), sin(angle)) * all_directions_range
		proj.puddle_scene = puddle_scene
		proj.arc_height = 0.0
		get_parent().add_child(proj)

# --------------------------------------------------
# ATTACK 4 — Spread pattern toward player
# --------------------------------------------------
func _attack_pattern():
	if not projectile_scene or not player_ref:
		return
	print("Boss: Pattern attack!")
	var base_angle = global_position.angle_to_point(player_ref.global_position)
	var spread_angles = [-0.3, 0.0, 0.3]
	for offset_angle in spread_angles:
		var proj = projectile_scene.instantiate()
		proj.global_position = global_position
		var dir = Vector2(cos(base_angle + offset_angle), sin(base_angle + offset_angle))
		proj.land_position = global_position + dir * pattern_range
		proj.puddle_scene = puddle_scene
		proj.arc_height = randf_range(40.0, 80.0)
		get_parent().add_child(proj)

# --------------------------------------------------
# TAKE DAMAGE
# --------------------------------------------------
func take_damage(amount: int):
	current_health -= amount
	current_health = max(current_health, 0)
	healthChanged.emit()
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(2, 2, 2), 0.05)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
	if current_health <= 0:
		die()

	# Camera shake
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(randf_range(2.5, 4.0))

func die():
	print("Boss defeated!")
	queue_free()

# --------------------------------------------------
# DETECTION
# --------------------------------------------------
func _on_detection_area_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		player_ref = body
		_attack_all_directions()

func _on_detection_area_body_exited(body: Node2D):
	if body.is_in_group("Player"):
		_attack_all_directions()
		player_ref = null