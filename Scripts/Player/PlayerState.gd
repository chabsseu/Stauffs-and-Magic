extends Node

signal healthChanged
signal armorChanged

@export var max_health = 5
var current_health = max_health

@export var max_armor = 5
var current_armor = max_armor

@export var armor_regen_interval: float = 5.0

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
		current_armor = max(current_armor - amount, 0)
		armorChanged.emit()
		print("Armor:", current_armor)
	else:
		# Armor already 0 — deal damage to health instead
		take_damage(amount)

func armor_regen(amount: int) -> void:
	current_armor = min(current_armor + amount, max_armor)
	armorChanged.emit()
	print("Armor Healed:", current_armor)