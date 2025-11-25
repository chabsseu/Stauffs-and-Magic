extends Node

signal healthChanged
signal armorChanged

@export var max_health = 5
var current_health = max_health

@export var max_armor = 5
var current_armor = max_armor

@export var armor_regen_interval: float = 3.0

func _ready() -> void:
	# Start the repeating timer
	var timer = Timer.new()
	timer.wait_time = armor_regen_interval
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_on_armor_regen_timer_timeout)

func _on_armor_regen_timer_timeout() -> void:
	# Regenerate 1 armor every tick
	if current_armor < max_armor:
		armorChanged.emit()
		armor_regen(1)
		

func take_damage(amount: int) -> void:
	current_health = max(current_health - amount, 0)
	healthChanged.emit()
	print("Player Health:", current_health)


func take_armor_damage(amount: int) -> void:
	if current_armor > 0:
		var damage_to_armor = min(amount, current_armor)
		current_armor -= damage_to_armor
		
		# leftover damage continues to the health
		var leftover = amount - damage_to_armor
		if leftover > 0:
			take_damage(leftover)

		armorChanged.emit()
		print("Armor:", current_armor)
	else:
		take_damage(amount)


func armor_regen(amount: int) -> void:
	current_armor = min(current_armor + amount, max_armor)
	armorChanged.emit()
	print("Armor Healed:", current_armor)