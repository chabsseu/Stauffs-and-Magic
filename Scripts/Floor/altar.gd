extends CharacterBody2D
@onready var prompt_label: Label = $Detection_area/Label
var player_nearby: bool = false
var altar_ui: Node = null

func _ready():
	prompt_label.visible = false

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact"):
		open_altar()

func open_altar():
	altar_ui = get_tree().get_first_node_in_group("altar_ui")
	if altar_ui == null:
		push_error("AltarUI not found")
		return
	altar_ui.open()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = true
		prompt_label.visible = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = false
		prompt_label.visible = false
		if altar_ui != null:
			altar_ui.close()
