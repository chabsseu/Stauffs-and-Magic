extends Control

@onready var title: Label = $Panel/title
@onready var weapon_name: Label = $Panel/weapon_name
@onready var level_label: Label = $Panel/level_label
@onready var cooldown_label: Label = $Panel/cooldown_label
@onready var upgrade_button: Button = $Panel/upgrade_button
@onready var close_button: Button = $Panel/close_button

var player: CharacterBody2D = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
	visible = false

func open():
	var slot = player.current_slot
	if slot == -1:
		return
	var data = player.hotbar_data[slot]
	if data["scene"] == null:
		return
	title.text = "FORGE"
	weapon_name.text = "Weapon Slot: %d" % (slot + 1)
	level_label.text = "Level: %d" % data["level"]
	cooldown_label.text = "Skill Cooldown: %.1f sec" % data["skill_cooldown"]
	visible = true

func _on_upgrade_button_pressed():
	player.upgrade_weapon(player.current_slot)
	open()
	visible = false
func _on_close_button_pressed():
	visible = false
