extends CanvasLayer
class_name AltarShopUI

signal purchase_confirmed
signal purchase_cancelled

@onready var panel: Panel = $Panel
@onready var weapon_icon: Sprite2D = $Panel/WeaponIcon
@onready var weapon_name_label: Label = $Panel/WeaponName
@onready var weapon_level_label: Label = $Panel/WeaponLevel
@onready var weapon_cost_label: Label = $Panel/CostLabel
@onready var confirm_button: Button = $Panel/ConfirmButton
@onready var cancel_button: Button = $Panel/CancelButton

var current_weapon_scene: PackedScene = null
var current_level: int = 1
var current_cost: int = 0

func _ready():
	add_to_group("altar_shop_ui")

	# Hide the whole UI
	visible = false

	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

func open(weapon_scene: PackedScene, level: int, cost: int):
	current_weapon_scene = weapon_scene
	current_level = level
	current_cost = cost

	var weapon = weapon_scene.instantiate()

	# Weapon name
	if weapon.get("weapon_name") != null:
		weapon_name_label.text = str(weapon.weapon_name)
	else:
		weapon_name_label.text = weapon.name

	# Weapon level
	weapon_level_label.text = "Level: %d" % level

	# Cost
	weapon_cost_label.text = "Cost: %d Coins" % cost

	# Icon
	if weapon.has_node("Sprite2D"):
		var sprite: Sprite2D = weapon.get_node("Sprite2D")
		weapon_icon.texture = sprite.texture
		weapon_icon.scale = Vector2(2, 2)

	weapon.queue_free()

	# Can afford?
	if GameData.coins >= current_cost:
		weapon_cost_label.modulate = Color.WHITE
		confirm_button.disabled = false
	else:
		weapon_cost_label.modulate = Color.RED
		confirm_button.disabled = true

	confirm_button.text = "BUY"

	# Show the whole UI
	visible = true

func close():
	visible = false

func _on_confirm_pressed():
	if GameData.coins < current_cost:
		return

	close()
	purchase_confirmed.emit()

func _on_cancel_pressed():
	close()
	purchase_cancelled.emit()
