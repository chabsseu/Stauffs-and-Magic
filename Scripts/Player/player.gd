extends CharacterBody2D

@onready var staff = $test_staff
@onready var player_state = $"/root/PlayerState"

func get_input():
	var input_direction = Input.get_vector("A", "D", "W", "S")
	velocity = input_direction * player_state.speed
	
func _physics_process(delta: float) -> void:
	var direction = get_global_mouse_position() - global_position
	staff.rotation = direction.angle()
	get_input()
	move_and_slide()

func take_armor_damage(amount: int) -> void:
	PlayerState.take_armor_damage(amount)
	if PlayerState.current_health <= 0:
		die()

func die():
	print("Player has died")
	queue_free()

func status():
	PlayerState.status
