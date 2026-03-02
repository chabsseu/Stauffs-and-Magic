extends CharacterBody2D

@onready var label = $Detection_Area/Label
@onready var animate = $AnimatedSprite2D

var player_nearby := false
var is_open := false

func _ready() -> void:
	label.visible = false
	animate.play("Idle")

func _process(_delta: float) -> void:
	if player_nearby and not is_open:
		if Input.is_action_just_pressed("interact"):
			open()

func open():
	is_open = true
	label.visible = false
	animate.play("Open")

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = true
		if not is_open:
			label.visible = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = false
		label.visible = false