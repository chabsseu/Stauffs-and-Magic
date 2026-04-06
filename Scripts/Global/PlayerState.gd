
extends Node

signal healthChanged
signal armorChanged
signal manaChanged

@export var max_health = 5
var current_health = max_health
@export var max_armor = 5
var current_armor = max_armor
@export var armor_regen_interval: float = 3.0
@export var base_speed = 300.0
var speed = base_speed
var current_mana: int = 100
var max_mana: int = 100

var status_effects: StatusEffectManager  # Own instance

func _ready() -> void:
	# Create own status effect instance
	status_effects = StatusEffectManager.new()
	add_child(status_effects)
	
	# Connect signals
	status_effects.burn_tick.connect(_on_burn_tick)
	status_effects.effect_started.connect(_on_effect_started)
	status_effects.effect_ended.connect(_on_effect_ended)
	
	# Armor regen timer
	var timer = Timer.new()
	timer.wait_time = armor_regen_interval
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_on_armor_regen_timer_timeout)

# func _process(delta):
# 	status_effects.update(delta)

func _on_armor_regen_timer_timeout() -> void:
	if current_armor < max_armor:
		armor_regen(1)
		armorChanged.emit()

func take_damage(amount: int) -> void:
	current_health = max(current_health - amount, 0)
	healthChanged.emit()
	print("Player Health:", current_health)

func take_armor_damage(amount: int) -> void:
	if current_armor > 0:
		var damage_to_armor = min(amount, current_armor)
		current_armor -= damage_to_armor
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

func heal(amount: int) -> void:
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	healthChanged.emit()  # Also emit signal to notify UI or others
	print("Healed! Current health:", current_health)
	
func use_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		manaChanged.emit()
		return true   # Skill can be used
	else:
		return false  # Not enough mana

func add_mana(amount: int) -> bool:
	if current_mana >= max_mana:
		return false  # No mana added

	var old_mana = current_mana
	current_mana = min(current_mana + amount, max_mana)

	if current_mana != old_mana:
		manaChanged.emit()
		print("Mana regenerated:", current_mana)
		return true

	return false


func _on_burn_tick(damage):
	take_damage(damage)

func _on_effect_started(type):
	print("Effect started:", type)
	if type == StatusEffectManager.EffectType.STUN:
		speed = 0
	if type == StatusEffectManager.EffectType.SLOW:
		speed = base_speed * 0.5
		print("Speed reduced to:", speed)

func _on_effect_ended(type):
	print("Effect ended:", type)
	if type == StatusEffectManager.EffectType.STUN or type == StatusEffectManager.EffectType.SLOW:
		speed = base_speed
		print("Speed restored to:", speed)
