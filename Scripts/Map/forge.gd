extends Control

@onready var title: Label = %title
@onready var weapon_name: Label = %weapon_name
@onready var level_label: Label = %level_label
@onready var stat_label: Label = %stat_label
@onready var stat_label2: Label = %stat_label2
@onready var upgrade_button: Button = %upgrade_button
@onready var close_button: Button = %close_button

var player: CharacterBody2D = null
var upgrade_type: String = "cooldown"

func _ready():
	player = get_tree().get_first_node_in_group("player")
	visible = false

func open(type: String):
	upgrade_type = type
	var slot = player.current_slot
	if slot == -1:
		return
	var data = player.hotbar_data[slot]
	if data["scene"] == null:
		return

	var temp = data["scene"].instantiate()

	title.text = "FORGE"
	weapon_name.text = "Weapon Slot: %d" % (slot + 1)
	level_label.text = "Level: %d" % data["level"]

	match upgrade_type:
		"cooldown":
			var reduction = temp.get_upgrade_cooldown_reduction()
			stat_label.text = "Skill Cooldown: %.1f sec" % data["skill_cooldown"]
			stat_label2.text = "After Upgrade: %.1f sec" % max(1.0, data["skill_cooldown"] - reduction)
		"damage":
			var increase = temp.get_upgrade_damage_increase()
			stat_label.text = "Attack Damage: %.1f" % data["attack_damage"]
			stat_label2.text = "After Upgrade: %.1f" % (data["attack_damage"] + increase)

	temp.queue_free()
	visible = true

func _on_upgrade_button_pressed():
	match upgrade_type:
		"cooldown":
			player.upgrade_weapon_cooldown(player.current_slot)
		"damage":
			player.upgrade_weapon_damage(player.current_slot)
	visible = false

func _on_close_button_pressed():
	visible = false