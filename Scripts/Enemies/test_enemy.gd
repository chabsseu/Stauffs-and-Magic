extends CharacterBody2D


@export var speed = 150.0
@export var  max_health : int
@export var damage_node : PackedScene
var current_health : int

var chase = false
var player: Node2D = null

func _ready():
	current_health = max_health

func _physics_process(delta: float) -> void:
	if chase:
		position += (player.position - position).normalized() * speed * delta
	
	move_and_slide()

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
	
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body
		chase = true
	
	if body.has_method("take_armor_damage"):
		body.take_armor_damage(2)
