extends CharacterBody2D


@export var speed = 150.0
var chase = false
var player: Node2D = null

func _physics_process(delta: float) -> void:
	if chase:
		position += (player.position - position).normalized() * speed * delta
	
	move_and_slide()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body
		chase = true
