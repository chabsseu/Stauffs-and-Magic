extends CharacterBody2D

@onready var label = $Detection_Area/Label
@onready var animate = $AnimatedSprite2D

@export var reward_weapons : Array[PackedScene] = []
@export var reward_mana : PackedScene

@export var coin_drop_scene : PackedScene
@export var food_drop_scene : PackedScene
@export var chest_coin_count : int = 3   # Guaranteed coins from chest
@export var chest_food_count : int = 2   # Guaranteed food from chest

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
	# Spawn mana drop
	if reward_mana:
		var mana_count = randi_range(5, 10)
		for i in range(mana_count):
			var mana_drop = reward_mana.instantiate()
			# Scatter them randomly around the chest
			var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
			mana_drop.global_position = global_position + offset
			get_parent().add_child(mana_drop)
		print("Spawned ", mana_count, " mana drops!")

	# Spawn coin drops
	if coin_drop_scene:
		for i in range(chest_coin_count):
			var drop = coin_drop_scene.instantiate()
			drop.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
			get_parent().add_child(drop)

	# Spawn food drops
	if food_drop_scene:
		for i in range(chest_food_count):
			var drop = food_drop_scene.instantiate()
			drop.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
			get_parent().add_child(drop)
			
	# Spawn ONE random weapon from the array
	if not reward_weapons.is_empty():
		var drop_chance = 30  # % chance to drop a weapon
		var roll = randi_range(1, 100)
		if roll <= drop_chance:
			# Pick a random weapon from the array
			var chosen_scene: PackedScene = reward_weapons[randi() % reward_weapons.size()]
			if chosen_scene != null:
				# Instantiate the pickup
				var pickup_scene = preload("res://Scenes/Weapon/weapon_pickup.tscn")
				var pickup = pickup_scene.instantiate()
				
				# Assign the weapon scene
				pickup.weapon_scene = chosen_scene
				
				# Scatter the pickup a bit
				var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
				pickup.global_position = global_position + Vector2(0, 40) + offset
				
				get_parent().add_child(pickup)
				print("Spawned weapon: ", chosen_scene.resource_path)
			else:
				print("Chosen weapon is null!")

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = true
		if not is_open:
			label.visible = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = false
		label.visible = false
