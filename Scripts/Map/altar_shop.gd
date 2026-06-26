extends CharacterBody2D
class_name AltarShop

@onready var icon: Sprite2D = $Icon
@onready var detection_area = $Detection_area

var prompt_label: Label = null

@export var possible_weapons: Array[PackedScene] = []
@export var base_cost: int = 10
@export var cost_per_level: int = 3

var player_nearby: bool = false
var weapon_offered: PackedScene = null
var weapon_level: int = 1
var weapon_cost: int = 0
var used: bool = false
var shop_ui: Node = null

func _ready():
	# Try to find prompt_label
	prompt_label = detection_area.get_node_or_null("Label")
	
	if prompt_label != null:
		prompt_label.visible = false
	
	# Auto-setup icon if needed
	if icon != null:
		icon.visible = true
		icon.scale = Vector2(2, 2)
	
	# Pick random weapon for this altar
	if possible_weapons.size() > 0:
		weapon_offered = possible_weapons[randi() % possible_weapons.size()]
		weapon_level = randi_range(1, 3)
		weapon_cost = calculate_cost()
		_update_icon()
		if prompt_label != null:
			prompt_label.text = "Press E to interact"
	else:
		push_error("No weapons assigned to altar!")
	
	# Connect detection area signals
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact") and not used:
		open_shop_ui()

func calculate_cost() -> int:
	return base_cost + ((weapon_level - 1) * cost_per_level)

func _update_icon():
	"""Display the weapon icon"""
	if weapon_offered == null:
		return
	
	var temp_weapon = weapon_offered.instantiate()
	var sprite = temp_weapon.get_node_or_null("Sprite2D")
	if icon != null and sprite != null:
		icon.texture = sprite.texture
	temp_weapon.queue_free()

func open_shop_ui():
	shop_ui = get_tree().get_first_node_in_group("altar_shop_ui")
	if shop_ui == null:
		push_error("AltarShopUI not found!")
		return

	# Prevent opening twice
	if shop_ui.visible:
		return

	# Connect signals once
	if not shop_ui.purchase_confirmed.is_connected(_on_purchase_confirmed):
		shop_ui.purchase_confirmed.connect(_on_purchase_confirmed)

	if not shop_ui.purchase_cancelled.is_connected(_on_purchase_cancelled):
		shop_ui.purchase_cancelled.connect(_on_purchase_cancelled)

	shop_ui.open(
		weapon_offered,
		weapon_level,
		weapon_cost
	)

func _on_purchase_confirmed():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	# Check coins
	if GameData.coins < weapon_cost:
		print("Not enough coins!")
		return

	# Find an empty slot
	var empty_slot := -1

	for i in range(player.HOTBAR_SIZE):
		if player.hotbar_data[i]["scene"] == null:
			empty_slot = i
			break

	if empty_slot == -1:
		print("Inventory Full!")
		return

	# Take coins
	GameData.coins -= weapon_cost

	# Create the weapon data
	player.hotbar_data[empty_slot] = player.create_weapon_data(
		weapon_offered,
		weapon_level
	)

	player.max_cooldown[empty_slot] = player.hotbar_data[empty_slot]["skill_cooldown"]

	# Equip automatically if no weapon equipped
	if player.current_weapon == null:
		player.equip(empty_slot)

	player.update_hotbar_ui()

	used = true

	if prompt_label:
		prompt_label.visible = false

	if shop_ui:
		shop_ui.close()

	print("Purchased weapon!")
	icon.queue_free()
func _on_purchase_cancelled():
	"""Called when player cancels the purchase"""
	print("Purchase cancelled")
	if shop_ui != null:
		shop_ui.close()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not used:
		player_nearby = true
		if prompt_label != null:
			prompt_label.visible = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = false
		if prompt_label != null:
			prompt_label.visible = false
		if shop_ui != null:
			shop_ui.close()
