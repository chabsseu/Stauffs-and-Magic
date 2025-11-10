extends CharacterBody2D

@export var speed = 300
@export var max_health = 5
@export var damage_node : PackedScene
var current_health = max_health

var player_in_range = false
var attacking = false

@onready var spear = $Spear
@onready var animation_player = spear.get_node_or_null("AnimationPlayer")
@onready var attack_area = $AttackArea
@onready var attack_cooldown = $AttackCooldown

func _ready():
	if animation_player == null:
		push_error("⚠️ AnimationPlayer not found inside Spear scene!")

	attack_area.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	attack_area.connect("body_exited", Callable(self, "_on_attack_area_body_exited"))

func _process(delta):
	if player_in_range and not attacking and not attack_cooldown.is_stopped():
		# cooldown still running, skip attack
		return

	if player_in_range and not attacking:
		attack()

func attack():
	if animation_player == null:
		return

	attacking = true
	animation_player.play("attack")

	await animation_player.animation_finished

	attacking = false
	attack_cooldown.start(2.5)  # start cooldown after attack


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


func _on_attack_area_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true

func _on_attack_area_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
