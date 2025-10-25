extends CharacterBody2D


@export var speed = 300.0

func get_input():
	var input_direction = Input.get_vector("A", "D", "W", "S")
	velocity = input_direction * speed
	
func _physics_process(delta: float) -> void:
	get_input()
	move_and_slide()
