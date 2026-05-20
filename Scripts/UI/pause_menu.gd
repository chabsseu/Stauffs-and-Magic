extends Control

func _ready():
	# Hide pause menu at start
	hide()

func _input(event):
	if event.is_action_pressed("pause"):  # ESC key
		toggle_pause()

func toggle_pause():
	if visible:
		hide()
		get_tree().paused = false
	else:
		show()
		get_tree().paused = true

func _on_resume_pressed():
	hide()
	get_tree().paused = false

func _on_options_pressed():
	pass  # add options later

func _on_restart_pressed():
	get_tree().paused    = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/title_screen.tscn")
