extends Node
signal healthChanged
signal armorChanged
signal manaChanged
@export var max_health := 5
var current_health := 5
@export var max_armor := 5
var current_armor := 5
@export var armor_regen_interval: float = 3.0
@export var base_speed := 300.0
var speed := 300.0
var current_mana: int = 100
var max_mana: int = 100
var status_effects: StatusEffectManager

func _ready() -> void:
	current_health = max_health
	current_armor = max_armor
	speed = base_speed
	status_effects = StatusEffectManager.new()
	add_child(status_effects)
	status_effects.burn_tick.connect(_on_burn_tick)
	status_effects.effect_started.connect(_on_effect_started)
	status_effects.effect_ended.connect(_on_effect_ended)
	var timer = Timer.new()
	timer.wait_time = armor_regen_interval
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_on_armor_regen_timer_timeout)

# ----------------------------
# CORE SYSTEM
# ----------------------------
func _on_armor_regen_timer_timeout() -> void:
	if current_armor < max_armor:
		armor_regen(1)

func take_damage(amount: int) -> void:
	current_health = max(current_health - amount, 0)
	healthChanged.emit()

func take_armor_damage(amount: int) -> void:
	if current_armor > 0:
		var damage_to_armor = min(amount, current_armor)
		current_armor -= damage_to_armor
		var leftover = amount - damage_to_armor
		if leftover > 0:
			take_damage(leftover)
		armorChanged.emit()
	else:
		take_damage(amount)

func armor_regen(amount: int) -> void:
	current_armor = min(current_armor + amount, max_armor)
	armorChanged.emit()

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	healthChanged.emit()

func use_mana(amount: int) -> bool:
	if current_mana < amount:
		return false
	current_mana -= amount
	manaChanged.emit()
	return true

func add_mana(amount: int) -> bool:
	if current_mana >= max_mana:
		return false
	current_mana = min(current_mana + amount, max_mana)
	manaChanged.emit()
	return true

# ----------------------------
# STATUS EFFECTS
# ----------------------------
func _on_burn_tick(damage):
	take_damage(damage)

func _on_effect_started(type):
	print("Effect started:", type)
	match type:
		StatusEffectManager.EffectType.STUN:
			speed = 0
		StatusEffectManager.EffectType.SLOW:
			speed = base_speed * 0.5
		StatusEffectManager.EffectType.POISON:
			print("Poison applied")
		StatusEffectManager.EffectType.BURN:
			print("Burn applied")

func _on_effect_ended(type):
	print("Effect ended:", type)
	match type:
		StatusEffectManager.EffectType.STUN:
			if status_effects.has_effect(StatusEffectManager.EffectType.SLOW):
				speed = base_speed * 0.5  # still slowed
			else:
				speed = base_speed
		StatusEffectManager.EffectType.SLOW:
			if not status_effects.has_effect(StatusEffectManager.EffectType.STUN):
				speed = base_speed  # only restore if not stunned
		StatusEffectManager.EffectType.POISON:
			print("Poison ended")
		StatusEffectManager.EffectType.BURN:
			print("Burn applied")