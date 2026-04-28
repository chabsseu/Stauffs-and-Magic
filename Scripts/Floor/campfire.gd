extends CharacterBody2D

@onready var prompt_label: Label = $Detection_Area/Label
@onready var cook_world_bar: TextureProgressBar = $CookWorldBar

@export var cooking_ui: NodePath
var player_nearby: bool = false
var ui: Node = null

func _ready() -> void:
	ui = get_node(cooking_ui)
	prompt_label.visible = false
	cook_world_bar.visible = false
	cook_world_bar.min_value = 0.0
	cook_world_bar.max_value = 100.0
	cook_world_bar.value = 0.0
	if ui:
		ui.visible = false

func _process(_delta) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		if ui:
			ui.visible = !ui.visible
			if ui.visible:
				var screen_size = get_viewport().get_visible_rect().size
				ui.global_position = screen_size / 2 - ui.size / 2
				ui.refresh(global_position)
				var player = get_tree().get_first_node_in_group("player")
				if player:
					player.can_fire = false
			else:
				var player = get_tree().get_first_node_in_group("player")
				if player:
					player.can_fire = true

	# Sync world progress bar with cooking UI
	if ui and ui.is_cooking:
		cook_world_bar.visible = true
		cook_world_bar.value = ui.cook_progress.value
	else:
		cook_world_bar.visible = false

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = true
		prompt_label.visible = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = false
		prompt_label.visible = false
		if ui:
			ui.visible = false
		body.can_fire = true
