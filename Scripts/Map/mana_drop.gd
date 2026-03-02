extends Area2D

@export var min_mana : int = 1
@export var max_mana : int = 5
@export var chase_speed : float = 200.0
@export var chase_range : float = 150.0  # Distance to start chasing

var player_ref : Node2D = null
var mana_amount : int = 0

func _ready():
	# Randomize mana amount on spawn
	mana_amount = randi_range(min_mana, max_mana)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if player_ref == null:
		return
	
	var distance = global_position.distance_to(player_ref.global_position)
	
	# Chase player if in range
	if distance < chase_range:
		var direction = (player_ref.global_position - global_position).normalized()
		global_position += direction * chase_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		PlayerState.add_mana(mana_amount)
		print("Picked up ", mana_amount, " mana!")
		queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_ref = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_ref = null