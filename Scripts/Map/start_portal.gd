extends Area2D

@onready var label = $Label
var player_inside = false

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("Player"):
        player_inside = true
        label.visible = true

func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("Player"):
        player_inside = false
        label.visible = false

func _process(_delta):
    if player_inside and Input.is_action_just_pressed("interact"):
        var player = get_tree().get_first_node_in_group("Player")
        if player:
            GameData.save_from_player_state(player.get_node("/root/PlayerState"), player)
        get_tree().change_scene_to_file("res://Scenes/Map/dungeon_generation.tscn")