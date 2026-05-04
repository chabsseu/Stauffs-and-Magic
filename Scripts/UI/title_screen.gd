extends Node2D


func _on_start_pressed():
	PlayerState.reset()
	get_tree().change_scene_to_file("res://Scenes/Floors/starting_room.tscn")


func _on_quit_pressed():
	get_tree().quit()
