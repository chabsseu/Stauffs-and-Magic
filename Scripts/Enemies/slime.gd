extends CharacterBody2D

@onready var enemy_state = EnemyState
@export var projectile_scene: PackedScene
@export var safe_distance: float = 200.0
@export var shoot_interval: float = 3.0
@export var damage_node: PackedScene
@export var max_health: int
@export var patrol_radius: float = 200.0    # max distance for patrol from starting point
@export var patrol_speed: float = 100.0
@export var stop_duration: float = 1.5      # seconds to stop after reaching destination

var current_health: int
var player: CharacterBody2D
var can_shoot: bool = false

var patrol_target: Vector2
var is_stopping: bool = false
var stop_timer: float = 0.0

@onready var shooting_area = $ShootingArea
@onready var timer = $Timer
var start_position: Vector2


func _ready() -> void:
	timer.wait_time = shoot_interval
	timer.timeout.connect(_on_timer_timeout)
	shooting_area.body_entered.connect(_on_shooting_area_body_entered)
	shooting_area.body_exited.connect(_on_shooting_area_body_exited)
	current_health = max_health
	start_position = global_position
	_pick_new_patrol_target()


func _physics_process(delta: float) -> void:
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance < safe_distance:
			# Move away from player if too close
			var move_dir = (global_position - player.global_position).normalized()
			velocity = move_dir * enemy_state.speed
		else:
			velocity = Vector2.ZERO
	else:
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


func _pick_new_patrol_target() -> void:
	# Pick a random point within patrol_radius from start_position
	var angle = randf() * TAU
	var distance = randf() * patrol_radius
	patrol_target = start_position + Vector2(cos(angle), sin(angle)) * distance


func _on_timer_timeout() -> void:
	if not can_shoot or not player or projectile_scene == null:
		return

	var bullet = projectile_scene.instantiate()
	bullet.global_position = global_position
	get_tree().current_scene.add_child(bullet)
	bullet.launch(global_position, player.global_position)


func _on_shooting_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body
		can_shoot = true
		timer.start()


func _on_shooting_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = null
		can_shoot = false
		timer.stop()


func take_damage(amount: int):
	var damage = damage_node.instantiate()
	damage.find_child("Label").text = str(amount)
	damage.position = position
	get_parent().add_child(damage)
	current_health -= amount
	print("Enemy Health: %d" % current_health)
	if current_health <= 0:
		die()


func die():
	queue_free()