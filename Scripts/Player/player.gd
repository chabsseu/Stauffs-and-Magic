extends CharacterBody2D


@export var speed = 300.0
@onready var staff = $test_staff
func get_input():
	var input_direction = Input.get_vector("A", "D", "W", "S")
	velocity = input_direction * speed
	
func _physics_process(delta: float=) -> void:
	# Make staff look toward the mouse
	var direction = get_global_mouse_position() - global_position
	staff.rotation = direction.angle()
	
	get_input()
	move_and_slide()
