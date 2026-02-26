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
# Dash
# -------------------------
@export var dash_distance: float = 200.0
@export var dash_speed: float = 1500.0
@export var dash_cooldown: float = 1.0

var is_dashing: bool = false
var dash_dir: Vector2 = Vector2.ZERO
var dash_remaining: float = 0.0
var dash_cooldown_remaining: float = 0.0

# -------------------------
# Nodes
# -------------------------
@onready var weapon_socket: Node2D = $WeaponSocket
@onready var player_state = $"/root/PlayerState"

# -------------------------
# Constants & State
# -------------------------
const HOTBAR_SIZE := 5

var hotbar_data: Array = []
var cooldown := [0.0, 0.0, 0.0, 0.0, 0.0]
var max_cooldown := [0.0, 0.0, 0.0, 0.0, 0.0]

var current_slot := -1
var current_weapon: Node2D = null
var pickup_weapon: Area2D = null
var can_fire := true

# -------------------------
# Ready
# -------------------------
func _ready():
	add_to_group("player")
	for i in range(HOTBAR_SIZE):
		hotbar_data.append({
			"scene": null,
			"level": 1,
			"icon": null,
			"skill_cooldown": 0.0,
			"attack_damage": 0.0,
			"skill_damage": 0.0
		})

# -------------------------
# Physics
# -------------------------
func _physics_process(delta: float) -> void:
	for i in range(HOTBAR_SIZE):
		if cooldown[i] > 0.0:
			cooldown[i] -= delta
			update_hotbar_ui()

	if dash_cooldown_remaining > 0:
		dash_cooldown_remaining -= delta

	if is_dashing:
		velocity = dash_dir * dash_speed
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

	if event.is_action_pressed("fire"):
		current_weapon.attack()

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
		if hotbar_data[i]["scene"] == null:
			store_weapon_in_slot(i)
			return

	if current_slot != -1:
		swap_current_weapon()

func store_weapon_in_slot(slot: int):
	var temp = pickup_weapon.weapon_scene.instantiate()

	# Upgrade increments (safe check)
	var atk_inc = temp.get_upgrade_damage_increase() if temp.has_method("get_upgrade_damage_increase") else 0.0
	var skill_inc = temp.get_upgrade_skill_damage_increase() if temp.has_method("get_upgrade_skill_damage_increase") else 0.0

	# Get base stats safely using get()
	var base_attack  = temp.get("attack_damage") if temp.get("attack_damage") != null else 0.0
	var base_skill   = temp.get("skill_damage")  if temp.get("skill_damage")  != null else 0.0
	var base_cd      = temp.get("skill_cooldown") if temp.get("skill_cooldown") != null else 1.0

	hotbar_data[slot]["scene"] = pickup_weapon.weapon_scene
	hotbar_data[slot]["level"] = pickup_weapon.weapon_level
	hotbar_data[slot]["icon"] = temp.get_node("Sprite2D").texture if temp.has_node("Sprite2D") else null
	hotbar_data[slot]["skill_cooldown"] = max(1.0, base_cd - (pickup_weapon.weapon_level - 1))
	hotbar_data[slot]["attack_damage"]  = base_attack + ((pickup_weapon.weapon_level - 1) * atk_inc)
	hotbar_data[slot]["skill_damage"]   = base_skill + ((pickup_weapon.weapon_level - 1) * skill_inc)

	max_cooldown[slot] = hotbar_data[slot]["skill_cooldown"]

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
	dropped.weapon_scene = hotbar_data[current_slot]["scene"]
	dropped.weapon_level = hotbar_data[current_slot]["level"]
	dropped.global_position = global_position
	get_parent().add_child(dropped)

	current_weapon.queue_free()

	var temp = pickup_weapon.weapon_scene.instantiate()

	var atk_inc = temp.get_upgrade_damage_increase() if temp.has_method("get_upgrade_damage_increase") else 0.0
	var skill_inc = temp.get_upgrade_skill_damage_increase() if temp.has_method("get_upgrade_skill_damage_increase") else 0.0

	var base_attack  = temp.get("attack_damage") if temp.get("attack_damage") != null else 0.0
	var base_skill   = temp.get("skill_damage")  if temp.get("skill_damage")  != null else 0.0
	var base_cd      = temp.get("skill_cooldown") if temp.get("skill_cooldown") != null else 1.0

	hotbar_data[current_slot]["scene"] = pickup_weapon.weapon_scene
	hotbar_data[current_slot]["level"] = pickup_weapon.weapon_level
	hotbar_data[current_slot]["icon"] = temp.get_node("Sprite2D").texture if temp.has_node("Sprite2D") else null
	hotbar_data[current_slot]["skill_cooldown"] = max(1.0, base_cd - (pickup_weapon.weapon_level - 1))
	hotbar_data[current_slot]["attack_damage"]  = base_attack + ((pickup_weapon.weapon_level - 1) * atk_inc)
	hotbar_data[current_slot]["skill_damage"]   = base_skill + ((pickup_weapon.weapon_level - 1) * skill_inc)

	max_cooldown[current_slot] = hotbar_data[current_slot]["skill_cooldown"]
	cooldown[current_slot] = 0.0
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
	if hotbar_data[slot]["scene"] == null:
		return

	if current_weapon:
		current_weapon.queue_free()

	current_slot = slot
	current_weapon = hotbar_data[slot]["scene"].instantiate()
	current_weapon.weapon_level = hotbar_data[slot]["level"]
	current_weapon.skill_cooldown = hotbar_data[slot]["skill_cooldown"]

	if current_weapon.get("attack_damage") != null:
		current_weapon.attack_damage = hotbar_data[slot]["attack_damage"]
	if current_weapon.get("skill_damage") != null:
		current_weapon.skill_damage = hotbar_data[slot]["skill_damage"]

	weapon_socket.add_child(current_weapon)

	can_fire = false
	await get_tree().process_frame
	can_fire = true

	update_hotbar_ui()

# -------------------------
# Upgrade
# -------------------------
func upgrade_weapon_cooldown(slot: int):
	if hotbar_data[slot]["scene"] == null:
		return
	var temp = hotbar_data[slot]["scene"].instantiate()
	var reduction = temp.get_upgrade_cooldown_reduction() if temp.has_method("get_upgrade_cooldown_reduction") else 0.0
	temp.queue_free()

	hotbar_data[slot]["level"] += 1
	hotbar_data[slot]["skill_cooldown"] = max(1.0, hotbar_data[slot]["skill_cooldown"] - reduction)
	max_cooldown[slot] = hotbar_data[slot]["skill_cooldown"]

	if current_slot == slot and current_weapon != null:
		current_weapon.skill_cooldown = hotbar_data[slot]["skill_cooldown"]

func upgrade_weapon_damage(slot: int):
	if hotbar_data[slot]["scene"] == null:
		return
	var temp = hotbar_data[slot]["scene"].instantiate()

	var atk_inc = temp.get_upgrade_damage_increase() if temp.has_method("get_upgrade_damage_increase") else 0.0
	var skill_inc = temp.get_upgrade_skill_damage_increase() if temp.has_method("get_upgrade_skill_damage_increase") else 0.0
	temp.queue_free()

	hotbar_data[slot]["level"] += 1
	hotbar_data[slot]["attack_damage"] += atk_inc
	hotbar_data[slot]["skill_damage"]  += skill_inc

	if current_slot == slot and current_weapon != null:
		if current_weapon.get("attack_damage") != null:
			current_weapon.attack_damage = hotbar_data[slot]["attack_damage"]
		if current_weapon.get("skill_damage") != null:
			current_weapon.skill_damage = hotbar_data[slot]["skill_damage"]

# -------------------------
# UI
# -------------------------
func update_hotbar_ui():
	for i in range(HOTBAR_SIZE):
		var slot = hotbar_ui_slots[i]
		slot.texture = hotbar_data[i]["icon"]
		slot.modulate = Color(1, 1, 0) if i == current_slot else Color(1, 1, 1)

		var cd_bar := slot.get_node_or_null("Cooldown") as TextureProgressBar
		if cd_bar == null:
			continue

		if hotbar_data[i]["scene"] != null and cooldown[i] > 0.0:
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

# -------------------------
# Dash
# -------------------------
func dash(direction: Vector2):
	if is_dashing or dash_cooldown_remaining > 0:
		return
	is_dashing = true
	dash_dir = direction.normalized()
	dash_remaining = dash_distance
	dash_cooldown_remaining = dash_cooldown

func die():
	queue_free()
