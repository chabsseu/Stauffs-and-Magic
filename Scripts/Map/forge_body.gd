extends CharacterBody2D

@onready var prompt_label: Label = $Detection_area/Label
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

var player_nearby: bool = false
var forge_ui: Node = null
var used: bool = false   # <-- NEW

func _ready():
	prompt_label.visible = false
	animation.play("active")   # your default forge animation

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact") and not used:
		open_forge()

func open_forge():
	# Give buff here OR open UI
	forge_ui = get_tree().get_first_node_in_group("forge_ui")
	if forge_ui != null and forge_ui.has_method("open"):
		forge_ui.open()

	# mark as used
	used = true
	
	# change animation to altar (used state)
	animation.play("idle")   # <-- your altar animation name
	
	# remove prompt so player can't interact again
	prompt_label.visible = false

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not used:
		player_nearby = true
		prompt_label.visible = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = false
		prompt_label.visible = false
