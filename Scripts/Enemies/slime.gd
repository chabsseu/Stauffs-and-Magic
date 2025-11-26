extends CharacterBody2D

@onready var enemy_state = EnemyState
@export var projectile_scene: PackedScene
@export var safe_distance: float = 200.0   # how far it tries to stay away
@export var shoot_interval: float = 3.0    # seconds between shots
@export var damage_node : PackedScene
@export var  max_health : int
var current_health : int

var player: CharacterBody2D
var can_shoot: bool = false
@onready var shooting_area = $ShootingArea
@onready var timer = $Timer


func _ready() -> void:
	timer.wait_time = shoot_interval
	timer.timeout.connect(_on_timer_timeout)
	shooting_area.body_entered.connect(_on_shooting_area_body_entered)
	shooting_area.body_exited.connect(_on_shooting_area_body_exited)
	current_health = max_health


func _physics_process(delta: float) -> void:
	if not player:
		return

	var distance = global_position.distance_to(player.global_position)

	# If player is too close, move away
	if distance < safe_distance:
		var move_dir = (global_position - player.global_position).normalized()
		velocity = move_dir * enemy_state.speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func _on_timer_timeout() -> void:
	if not can_shoot or not player or projectile_scene == null:
		return

	var bullet = projectile_scene.instantiate()
	bullet.global_position = global_position
	get_tree().current_scene.add_child(bullet)

	# Launch toward player in an arc
	bullet.launch(global_position, player.global_position)


func _on_shooting_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body
		can_shoot = true
		timer.start()


func _on_shooting_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
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
