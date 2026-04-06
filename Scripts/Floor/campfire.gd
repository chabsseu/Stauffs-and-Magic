extends Area2D

@export var cooking_ui: NodePath

var player_nearby = false
var ui: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	ui = get_node(cooking_ui)
	if ui:
		ui.visible = false

func _input(event) -> void:
	if event.is_action_pressed("interact") and player_nearby:
		if ui:
			ui.visible = !ui.visible
			if ui.visible:
				var screen_size = get_viewport().get_visible_rect().size
				ui.global_position = screen_size / 2 - ui.size / 2
				ui.refresh(global_position)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = true
		print("Press E to cook!")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = false
		if ui:
			ui.visible = false
