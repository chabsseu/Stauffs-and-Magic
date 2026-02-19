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
#--------------------------
# Dash
#--------------------------
@export var dash_distance: float = 200.0
@export var dash_speed: float = 1500.0
@export var dash_cooldown: float = 1.0

var is_dashing: bool = false
var dash_dir: Vector2 = Vector2.ZERO
var dash_remaining = 0.0
# -------------------------
# Nodes
# -------------------------
@onready var weapon_socket: Node2D = $WeaponSocket
@onready var player_state = $"/root/PlayerState"

# -------------------------
# Constants & State
# -------------------------
const HOTBAR_SIZE := 5

var hotbar: Array[PackedScene] = [null, null, null, null, null]
var hotbar_icons: Array[Texture2D] = [null, null, null, null, null]

# Skill cooldown only
var cooldown := [0.0, 0.0, 0.0, 0.0, 0.0]
var max_cooldown := [0.0, 0.0, 0.0, 0.0, 0.0]

var current_slot := -1
var current_weapon: Node2D = null
var pickup_weapon: Area2D = null
var can_fire := true

# -------------------------
# Movement + Cooldown Tick
# -------------------------
func _physics_process(delta: float) -> void:
	

	for i in range(HOTBAR_SIZE):
		if cooldown[i] > 0.0:
			cooldown[i] -= delta

	update_hotbar_ui()

	if is_dashing:
		velocity = dash_dir * dash_speed  # assign velocity first
		dash_remaining -= velocity.length() * delta
		move_and_slide()
		if dash_remaining <= 0:
			is_dashing = false

	else:
		var input_direction = Input.get_vector("A", "D", "W", "S")
		velocity = input_direction * player_state.speed
		move_and_slide()
# -------------------------
# Input
# -------------------------
func _input(event):
	if event.is_action_pressed("interact"):
		try_pickup()

	for i in range(HOTBAR_SIZE):
		if event.is_action_pressed("hotbar%d" % (i + 1)):
			equip(i)

	if current_weapon == null or current_slot == -1 or not can_fire:
		return

	# -------------------------
	# Normal attack (NO cooldown)
	# -------------------------
	if event.is_action_pressed("fire"):
		current_weapon.attack()

	# -------------------------
	# Skill (WITH cooldown)
	# -------------------------
	if event.is_action_pressed("skill"):
		if cooldown[current_slot] <= 0.0:
			current_weapon.skill()
			cooldown[current_slot] = max_cooldown[current_slot]

# -------------------------
# Pickup
# -------------------------
func try_pickup():
	if pickup_weapon == null:
		return

	for i in range(HOTBAR_SIZE):
		if hotbar[i] == null:
			store_weapon_in_slot(i)
			return

	if current_slot != -1:
		swap_current_weapon()

func store_weapon_in_slot(slot: int):
	hotbar[slot] = pickup_weapon.weapon_scene

	var temp = hotbar[slot].instantiate()
	if temp.has_node("Sprite2D"):
		hotbar_icons[slot] = temp.get_node("Sprite2D").texture
	max_cooldown[slot] = temp.skill_cooldown
	temp.queue_free()

	pickup_weapon.queue_free()
	pickup_weapon = null

	if current_weapon == null:
		equip(slot)

	update_hotbar_ui()

func swap_current_weapon():
	if current_weapon == null or pickup_weapon == null:
		return

	var pickup_scene = preload("res://Scenes/Weapon/weapon_pickup.tscn")
	var dropped = pickup_scene.instantiate()
	dropped.weapon_scene = hotbar[current_slot]
	dropped.global_position = global_position
	get_parent().add_child(dropped)

	current_weapon.queue_free()

	hotbar[current_slot] = pickup_weapon.weapon_scene
	cooldown[current_slot] = 0.0

	var temp = hotbar[current_slot].instantiate()
	if temp.has_node("Sprite2D"):
		hotbar_icons[current_slot] = temp.get_node("Sprite2D").texture
	max_cooldown[current_slot] = temp.skill_cooldown
	temp.queue_free()

	equip(current_slot)

	pickup_weapon.queue_free()
	pickup_weapon = null

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

	can_fire = false
	await get_tree().process_frame
	can_fire = true

	update_hotbar_ui()

# -------------------------
# UI (Radial skill cooldown)
# -------------------------
func update_hotbar_ui():
	for i in range(HOTBAR_SIZE):
		var slot = hotbar_ui_slots[i]

		slot.texture = hotbar_icons[i]
		slot.modulate = Color(1, 1, 0) if i == current_slot else Color(1, 1, 1)

		var cd_bar := slot.get_node_or_null("Cooldown") as TextureProgressBar
		if cd_bar == null:
			continue

		if hotbar[i] != null and cooldown[i] > 0.0:
			cd_bar.visible = true
			cd_bar.value = clamp(cooldown[i] / max_cooldown[i], 0.0, 1.0)
		else:
			cd_bar.visible = false
			cd_bar.value = 0.0

# -------------------------
# Pickup Area
# -------------------------
func _on_pickup_area_area_entered(area: Area2D) -> void:
	if area.get("weapon_scene"):
		pickup_weapon = area

func _on_pickup_area_area_exited(area: Area2D) -> void:
	if pickup_weapon == area:
		pickup_weapon = null

# -------------------------
# Damage
# -------------------------
func take_armor_damage(amount: int) -> void:
	PlayerState.take_armor_damage(amount)

	$Camera2D.shake(randf_range(5.0, 8.0))

	if PlayerState.current_health <= 0:
		die()

#_------------------------
# Dash function
#-------------------------
func dash (direction: Vector2):
	if is_dashing:
		return
	is_dashing = true
	dash_dir = direction.normalized()
	dash_remaining = dash_distance

func die():
	queue_free()
