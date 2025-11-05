extends Area2D

@export var player_spawn: Node
var player: CharacterBody2D
var last_spawn: Marker2D = null

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and player_spawn:
		player = body
		var spawn_points: Array = player_spawn.get_children()

		# Make sure we have spawn points
		if spawn_points.is_empty():
			push_error("No spawn points found inside player_spawn!")
			return

		var new_spawn: Marker2D = null

		# If more than one spawn exists, ensure it's not the same as the last one
		if spawn_points.size() > 1:
			while new_spawn == null or new_spawn == last_spawn:
				new_spawn = spawn_points.pick_random()
		else:
			new_spawn = spawn_points[0]  # only one spawn available

		player.global_position = new_spawn.global_position
		last_spawn = new_spawn
