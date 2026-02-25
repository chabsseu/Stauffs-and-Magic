extends CharacterBody2D

@onready var prompt_label: Label = $Detection_area/Label
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

var player_nearby: bool = false
var forge_ui: Node = null
var used: bool = false

func _ready():
	prompt_label.visible = false
	animation.play("active")

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact") and not used:
		open_forge()

func open_forge():
	forge_ui = get_tree().get_first_node_in_group("forge_ui")
	if forge_ui == null:
		push_error("ForgeUI not found")
		return
	
	if not forge_ui.is_connected("buff_confirmed", Callable(self, "_on_buff_confirmed")):
		forge_ui.connect("buff_confirmed", Callable(self, "_on_buff_confirmed"))
	
	if not forge_ui.is_connected("closed", Callable(self, "_on_forge_closed")):
		forge_ui.connect("closed", Callable(self, "_on_forge_closed"))

	forge_ui.open("damage")

func _on_buff_confirmed(buff_type):
	used = true
	animation.play("idle")
	prompt_label.visible = false

func _on_forge_closed():
	pass

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not used:
		player_nearby = true
		prompt_label.visible = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = false
		prompt_label.visible = false