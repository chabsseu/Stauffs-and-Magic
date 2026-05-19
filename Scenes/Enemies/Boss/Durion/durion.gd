extends CharacterBody2D

signal healthChanged

# --------------------------------------------------
# EXPORTS
# --------------------------------------------------
@export var max_health : int = 80
@export var phase_two_threshold : float = 0.5
@export var wave_scene : PackedScene
@export var snare_scene : PackedScene
@export var deflect_projectile_scene : PackedScene
@export var health_bar : Control
@export var label : Control

@export var phase1_attack_cooldown : float = 3.0
@export var phase2_attack_cooldown : float = 1.0
@export var hit: PackedScene

@onready var deflect_indicator = $DeflectIndicator

# --------------------------------------------------
# STATE
# --------------------------------------------------
enum Phase { ONE, TWO }
enum Attack { GROUND_SMASH, SNARE, SPIKE_SHELL }

var current_phase : Phase = Phase.ONE
var current_health : int
var player_ref : Node2D = null
var is_attacking : bool = false
var attack_timer : float = 0.0
var phase_two_triggered : bool = false

# Spike shell state
var is_deflecting : bool = false
var deflect_timer : float = 0.0
var deflect_duration : float = 3.0
var pulse_tween : Tween = null

# --------------------------------------------------
# READY
# --------------------------------------------------
func _ready():
	current_health = max_health
	deflect_indicator.visible = false
	print("Durion ready!")

# --------------------------------------------------
# PHYSICS PROCESS
# --------------------------------------------------
func _physics_process(delta: float):
	if player_ref == null:
		return

	if not phase_two_triggered and current_health <= max_health * phase_two_threshold:
		_trigger_phase_two()

	_process_spike_shell(delta)

	var cooldown = phase1_attack_cooldown if current_phase == Phase.ONE else phase2_attack_cooldown
	if not is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = cooldown
			if current_phase == Phase.ONE:
				phase_one()
			else:
				phase_two()

	velocity = Vector2.ZERO
	move_and_slide()

# --------------------------------------------------
# PHASE ONE
# --------------------------------------------------
func phase_one():
	var attacks = [Attack.GROUND_SMASH, Attack.SNARE, Attack.SPIKE_SHELL]
	var attack = attacks[randi() % attacks.size()]
	_execute_attack(attack)

# --------------------------------------------------
# PHASE TWO
# --------------------------------------------------
func phase_two():
	is_attacking = true
	_execute_attack(_pick_phase_two_attack())
	await get_tree().create_timer(0.8).timeout
	_execute_attack(_pick_phase_two_attack())
	is_attacking = false

func _pick_phase_two_attack() -> Attack:
	var attacks = [Attack.GROUND_SMASH, Attack.SNARE, Attack.SPIKE_SHELL]
	return attacks[randi() % attacks.size()]

# --------------------------------------------------
# PHASE TWO TRIGGER
# --------------------------------------------------
func _trigger_phase_two():
	phase_two_triggered = true
	current_phase = Phase.TWO
	print("DURION PHASE 2!")
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 0.3, 0.3), 0.15)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.15)
	tween.set_loops(4)

# --------------------------------------------------
# EXECUTE ATTACK
# --------------------------------------------------
func _execute_attack(attack: Attack):
	match attack:
		Attack.GROUND_SMASH:
			_attack_ground_smash()
		Attack.SNARE:
			_attack_snare()
		Attack.SPIKE_SHELL:
			_attack_spike_shell()

# --------------------------------------------------
# ATTACK 1 — Ground Smash Wave
# --------------------------------------------------
func _attack_ground_smash():
	if not wave_scene:
		print("wave_scene is not assigned!")
		return
	print("Durion: Ground Smash!")

	var direction_count = 8 if current_phase == Phase.ONE else 16
	is_attacking = true

	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 1.0, 0.3), 0.3)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
	await get_tree().create_timer(0.4).timeout

	for i in range(direction_count):
		var angle = (TAU / direction_count) * i
		var wave = wave_scene.instantiate()
		wave.global_position = global_position
		wave.direction = Vector2(cos(angle), sin(angle))
		wave.speed = 200.0 if current_phase == Phase.ONE else 280.0
		get_parent().add_child(wave)

	is_attacking = false

# --------------------------------------------------
# ATTACK 2 — Underground Snare
# --------------------------------------------------
func _attack_snare():
	if not snare_scene or not player_ref:
		print("snare_scene is not assigned!")
		return
	print("Durion: Underground Snare!")

	is_attacking = true

	var snare_count = 1 if current_phase == Phase.ONE else 3
	var snare_duration = 2.0 if current_phase == Phase.ONE else 3.0

	for i in range(snare_count):
		var snare = snare_scene.instantiate()
		snare.stun_duration = snare_duration

		if i == 0:
			snare.global_position = player_ref.global_position
		else:
			var random_offset = Vector2(
				randf_range(-80, 80),
				randf_range(-80, 80)
			)
			snare.global_position = player_ref.global_position + random_offset

		get_parent().add_child(snare)

	is_attacking = false

# --------------------------------------------------
# ATTACK 3 — Spinning Spike Shell
# --------------------------------------------------
func _attack_spike_shell():
	if is_deflecting:
		return
	print("Durion: Spinning Spike Shell!")
	is_attacking = true

	# Telegraph flash
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.8, 0.3, 1.5), 0.2)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
	tween.set_loops(3)
	await get_tree().create_timer(0.8).timeout

	# Activate deflect
	is_deflecting = true
	deflect_duration = 3.0 if current_phase == Phase.ONE else 5.0
	deflect_timer = deflect_duration
	modulate = Color(0.8, 0.5, 1.5)

	# Show circle indicator
	deflect_indicator.visible = true
	deflect_indicator.set_color(Color(0.8, 0.3, 1.5, 0.4))

	# Kill old pulse tween if exists
	if pulse_tween:
		pulse_tween.kill()

	# Start pulse
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_method(
		func(a): deflect_indicator.set_color(Color(0.8, 0.3, 1.5, a)),
		0.1, 0.6, 0.4
	)

	is_attacking = false

func _process_spike_shell(delta: float):
	if not is_deflecting:
		return

	deflect_timer -= delta
	if deflect_timer <= 0.0:
		is_deflecting = false
		modulate = Color(1, 1, 1)

		# Stop pulse and hide indicator
		if pulse_tween:
			pulse_tween.kill()
			pulse_tween = null
		deflect_indicator.visible = false
		deflect_indicator.set_color(Color(0.8, 0.3, 1.5, 0.0))

		print("Durion: Spike Shell ended!")
		return

	# Check for player projectiles in range
	var projectiles = get_tree().get_nodes_in_group("Projectile")
	for proj in projectiles:
		var dist = global_position.distance_to(proj.global_position)
		if dist < 50.0:
			_deflect_projectile(proj)

func _deflect_projectile(proj: Node2D):
	if not "direction" in proj:
		return
	proj.direction = (player_ref.global_position - proj.global_position).normalized()
	proj.remove_from_group("Projectile")
	proj.add_to_group("EnemyProjectile")
	print("Deflected toward player!")

# --------------------------------------------------
# TAKE DAMAGE
# --------------------------------------------------
func take_damage(amount: int, hit_direction: Vector2 = Vector2.ZERO):
	current_health -= amount
	current_health = max(current_health, 0)
	healthChanged.emit()
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(2, 2, 2), 0.05)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
	if current_health <= 0:
		die()

	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(randf_range(2.5, 4.0))

func die():
	print("Durion defeated!")
	queue_free()

# --------------------------------------------------
# DETECTION
# --------------------------------------------------
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_ref = body
		print("Player detected!")
		health_bar.visible = true
		label.visible = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_ref = null
		health_bar.visible = false
		label.visible = false