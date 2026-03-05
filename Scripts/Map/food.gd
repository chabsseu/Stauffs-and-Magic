extends Area2D

@export var min_amount : int = 1
@export var max_amount : int = 3
@export var chase_speed : float = 130.0
@export var chase_range : float = 120.0

@onready var sprite = $Sprite2D

var player_ref : Node2D = null
var amount : int = 0

func _ready():
	amount = randi_range(min_amount, max_amount)
	body_entered.connect(_on_body_entered)

func _process(delta: float):
	if player_ref == null:
		return
	var distance = global_position.distance_to(player_ref.global_position)
	if distance < chase_range:
		var direction = (player_ref.global_position - global_position).normalized()
		global_position += direction * chase_speed * delta

func _on_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		GameData.add_foods(amount)
		queue_free()

func _on_detection_area_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		player_ref = body

func _on_detection_area_body_exited(body: Node2D):
	if body.is_in_group("Player"):
		player_ref = null
