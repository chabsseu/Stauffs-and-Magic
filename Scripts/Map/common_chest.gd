extends CharacterBody2D

@onready var label = $Detection_Area/Label
@onready var animate = $AnimatedSprite2D

@export var reward_weapons : Array[PackedScene] = []
@export var reward_mana : int = 30

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
	await animate.animation_finished
	give_rewards()

func give_rewards():
	# Give mana
	PlayerState.add_mana(reward_mana)
	print("Gave ", reward_mana, " mana!")
	
	# Spawn ONE random weapon from the array
	if reward_weapons.is_empty():
		return
	
	var chosen = reward_weapons[randi() % reward_weapons.size()]
	if chosen == null:
		return
	
	var pickup_scene = preload("res://Scenes/Weapon/weapon_pickup.tscn")
	var pickup = pickup_scene.instantiate()
	pickup.weapon_scene = chosen
	pickup.global_position = global_position + Vector2(0, 40)
	get_parent().add_child(pickup)
	print("Spawned weapon: ", chosen.resource_path)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = true
		if not is_open:
			label.visible = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = false
		label.visible = false