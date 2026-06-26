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
	panel.visible = false
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

func open(weapon_scene: PackedScene, level: int, cost: int):
	"""Display the shop UI with weapon details"""
	current_weapon_scene = weapon_scene
	current_level = level
	current_cost = cost
	
	# Get weapon name from the scene
	var temp_weapon = weapon_scene.instantiate()
	var weapon_name = temp_weapon.name if temp_weapon.name != "" else "Unknown Weapon"
	var sprite = temp_weapon.get_node_or_null("Sprite2D")
	
	# Update UI labels
	weapon_name_label.text = "Weapon: " + weapon_name
	weapon_level_label.text = "Level: " + str(level)
	weapon_cost_label.text = "Cost: " + str(cost) + " coins"
	
	# Update icon
	if sprite != null and weapon_icon != null:
		weapon_icon.texture = sprite.texture
		weapon_icon.scale = Vector2(2,2)
	
	temp_weapon.queue_free()
	
	# Show panel
	panel.visible = true
	print("Shop UI opened - showing weapon: ", weapon_name, " (Level ", level, ", Cost: ", cost, ")")

func close():
	"""Close the shop UI"""
	panel.visible = false

func _on_confirm_pressed():
	"""Handle purchase confirmation"""
	close()
	purchase_confirmed.emit()

func _on_cancel_pressed():
	"""Handle purchase cancellation"""
	close()
	purchase_cancelled.emit()
