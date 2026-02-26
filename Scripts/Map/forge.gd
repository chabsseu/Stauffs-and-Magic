extends Control

signal upgrade_confirmed

@onready var title: Label = %title
@onready var weapon_name: Label = %weapon_name
@onready var level_label: Label = %level_label
@onready var stat_label: Label = %stat_label
@onready var stat_label2: Label = %stat_label2
@onready var upgrade_button: Button = %upgrade_button
@onready var close_button: Button = %close_button

var player: CharacterBody2D = null
var upgrade_type: String = "cooldown"

var title_map = {
	"cooldown": "Donut Sugar rush FORGE",
	"damage": "Chilli Pepper FORGE",
}

func _ready():
	player = get_tree().get_first_node_in_group("player")
	visible = false

func open(type: String):
	upgrade_type = type
	title.text = title_map.get(upgrade_type, "FORGE")

	var slot = player.current_slot
	if slot == -1:
		return
	var data = player.hotbar_data[slot]
	if data["scene"] == null:
		return

	var temp = data["scene"].instantiate()
	weapon_name.text = temp.weapon_name
	level_label.text = "Level: %d" % data["level"]

	match upgrade_type:
		"cooldown":
			var reduction = 0.0
			if temp.has_method("get_upgrade_cooldown_reduction"):
				reduction = temp.get_upgrade_cooldown_reduction()

			stat_label.text = "Skill Cooldown: %.1f sec" % (data.get("skill_cooldown", 0.0))
			stat_label2.text = "After Upgrade: %.1f sec" % max(1.0, (data.get("skill_cooldown", 0.0) - reduction))

		"damage":
			# Safe attack upgrade
			var atk_increase = temp.get_upgrade_damage_increase() if temp.has_method("get_upgrade_damage_increase") else 0.0
			# Safe skill upgrade
			var skill_increase = temp.get_upgrade_skill_damage_increase() if temp.has_method("get_upgrade_skill_damage_increase") else 0.0

			var atk = data.get("attack_damage", 0.0)
			var skill = data.get("skill_damage", 0.0)

			if skill <= 0.0:
				# Weapon has no skill → hide skill damage
				stat_label.text = "ATK: %.1f" % atk
				stat_label2.text = "After: ATK %.1f" % (atk + atk_increase)
			else:
				stat_label.text = "ATK: %.1f | SKILL: %.1f" % [atk, skill]
				stat_label2.text = "After: ATK %.1f | SKILL %.1f" % [atk + atk_increase, skill + skill_increase]

	temp.queue_free()
	visible = true

func close():
	visible = false

func _on_upgrade_button_pressed():
	match upgrade_type:
		"cooldown":
			player.upgrade_weapon_cooldown(player.current_slot)
		"damage":
			player.upgrade_weapon_damage(player.current_slot)
	emit_signal("upgrade_confirmed")
	visible = false

func _on_close_button_pressed():
	visible = false
