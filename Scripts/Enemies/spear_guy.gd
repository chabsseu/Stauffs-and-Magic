extends CharacterBody2D

@export var speed: float = 300
@export var max_health: int = 5
@export var damage_node: PackedScene

var current_health: int
var player_in_range: bool = false
var attacking: bool = false
var chase: bool = false
var player: Node2D = null

@onready var spear = $Spear
@onready var animation_player: AnimationPlayer = spear.get_node_or_null("AnimationPlayer")
@onready var attack_area: Area2D = $AttackArea
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var detection_area: Area2D = $DetectionArea  # Add this node in the scene

func _ready() -> void:
	current_health = max_health

	if animation_player == null:
		push_error("⚠️ AnimationPlayer not found inside Spear scene!")

	# Connect signals
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta: float) -> void:
	# Stop movement while attacking
	if attacking:
		velocity = Vector2.ZERO
	elif chase and player != null:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Attack if player is in range and not on cooldown
	if player_in_range and not attacking and attack_cooldown.time_left == 0:
		attack()

func attack() -> void:
	if animation_player == null:
		return

	attacking = true
	animation_player.play("attack")

	# Wait for attack animation to finish
	await animation_player.animation_finished

	attacking = false
	attack_cooldown.start(2.5)  # cooldown after attack

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
