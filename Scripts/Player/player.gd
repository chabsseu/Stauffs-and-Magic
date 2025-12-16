extends CharacterBody2D

# -------------------------
# UI
# -------------------------
@onready var hotbar_ui_slots := [
	$Hotbar_UI/HotbarSlots/Slot0,
	$Hotbar_UI/HotbarSlots/Slot1,
	$Hotbar_UI/HotbarSlots/Slot2,
	$Hotbar_UI/HotbarSlots/Slot3,
	$Hotbar_UI/HotbarSlots/Slot4
]

# -------------------------
# Nodes
# -------------------------
@onready var weapon_socket: Node2D = $WeaponSocket
@onready var player_state = $"/root/PlayerState"

# -------------------------
# Constants & State
# -------------------------
const HOTBAR_SIZE := 5

var hotbar := [null, null, null, null, null]        # Stores weapon scenes
var hotbar_icons := [null, null, null, null, null]  # Stores UI textures

var current_slot := -1
var current_weapon: Node2D = null
var pickup_weapon: Area2D = null

var can_fire := true

# -------------------------
# Movement
# -------------------------
func _physics_process(delta: float) -> void:
	var input_direction = Input.get_vector("A", "D", "W", "S")
	velocity = input_direction * player_state.speed
	move_and_slide()

# -------------------------
# Input
# -------------------------
func _input(event):
	# Pickup
	if event.is_action_pressed("interact"):
		try_pickup()

	# Hotbar selection
	for i in range(HOTBAR_SIZE):
		if event.is_action_pressed("hotbar%d" % (i + 1)):
			equip(i)

	# Weapon usage
	if current_weapon == null or not can_fire:
		return

	if event.is_action_pressed("fire"):
		current_weapon.attack()

	if event.is_action_pressed("skill"):
		current_weapon.skill() #should just be a skill

# -------------------------
# Pickup
# -------------------------
func try_pickup():
	if pickup_weapon == null:
		return

	# Try to find an empty slot first
	for i in range(HOTBAR_SIZE):
		if hotbar[i] == null:
			store_weapon_in_slot(i)
			return

	# Hotbar full → swap with current slot
	if current_slot != -1:
		swap_current_weapon()
	else:
		print("Hotbar full and no weapon equipped to swap")

func store_weapon_in_slot(slot: int):
	hotbar[slot] = pickup_weapon.weapon_scene

	# Get weapon icon
	var temp_instance = hotbar[slot].instantiate()
	if temp_instance.has_node("Sprite2D"):
		hotbar_icons[slot] = temp_instance.get_node("Sprite2D").texture
	temp_instance.queue_free()

	# Remove the weapon from the ground
	pickup_weapon.queue_free()
	pickup_weapon = null

	# Auto-equip if no weapon equipped
	if current_weapon == null:
		equip(slot)

	print("Weapon stored in slot", slot)
	update_hotbar_ui()

func swap_current_weapon():
	if current_weapon == null or pickup_weapon == null:
		return

	# 1. Spawn a pickup weapon for the currently equipped weapon
	var dropped_scene = hotbar[current_slot]
	var pickup_instance = preload("res://Scenes/Weapon/weapon_pickup.tscn").instantiate()  # Your pickup scene
	pickup_instance.weapon_scene = dropped_scene
	pickup_instance.global_position = global_position
	get_parent().add_child(pickup_instance)

	# 2. Remove current weapon from player
	current_weapon.queue_free()

	# 3. Put the new weapon in the hotbar
	hotbar[current_slot] = pickup_weapon.weapon_scene

	# 4. Update UI icon
	var temp_instance = hotbar[current_slot].instantiate()
	if temp_instance.has_node("Sprite2D"):
		hotbar_icons[current_slot] = temp_instance.get_node("Sprite2D").texture
	temp_instance.queue_free()

	# 5. Equip the new weapon
	equip(current_slot)

	# 6. Remove the pickup_weapon from the ground
	pickup_weapon.queue_free()
	pickup_weapon = null

	update_hotbar_ui()



# -------------------------
# Equip
# -------------------------
func equip(slot: int):
	if slot < 0 or slot >= HOTBAR_SIZE:
		return
	if hotbar[slot] == null:
		return

	if current_weapon:
		current_weapon.queue_free()

	current_slot = slot
	current_weapon = hotbar[slot].instantiate()
	weapon_socket.add_child(current_weapon)

	# 🔒 Prevent firing on the same frame
	can_fire = false
	await get_tree().process_frame
	can_fire = true

	print("Equipped slot", slot)
	update_hotbar_ui()

# -------------------------
# UI
# -------------------------
func update_hotbar_ui():
	for i in range(HOTBAR_SIZE):
		hotbar_ui_slots[i].texture = hotbar_icons[i]
		hotbar_ui_slots[i].modulate = Color(1, 1, 0) if i == current_slot else Color(1, 1, 1)

# -------------------------
# Pickup Area
# -------------------------
func _on_pickup_area_area_entered(area: Area2D) -> void:
	if area.get("weapon_scene"):
		pickup_weapon = area

func _on_pickup_area_area_exited(area: Area2D) -> void:
	if pickup_weapon == area:
		pickup_weapon = null

#take damage
func take_armor_damage(amount: int) -> void:
	PlayerState.take_armor_damage(amount)
	if PlayerState.current_health <= 0:
		die()

func die():
	print("Player has died")
	queue_free()
