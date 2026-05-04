extends Control

func _ready():
    add_to_group("game_over_menu")
    hide()

func show_menu():
    show()

func _on_try_again_pressed():
    get_tree().paused = false
    PlayerState.reset()
    get_tree().reload_current_scene()

func _on_exit_pressed():
    get_tree().paused = false
    get_tree().change_scene_to_file("res://Scenes/UI/title_screen.tscn")