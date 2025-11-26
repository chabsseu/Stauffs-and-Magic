extends Node


@export var base_speed: float = 150.0

var speed: float
var status_effects: StatusEffectManager  # declared for parser

func _ready() -> void:
	speed = base_speed
	# Initialize status_effects at runtime
	status_effects = StatusEffectManager.new()
	add_child(status_effects)

	# Connect signals
	status_effects.burn_tick.connect(_on_burn_tick)
	status_effects.effect_started.connect(_on_effect_started)
	status_effects.effect_ended.connect(_on_effect_ended)

func _process(delta: float) -> void:
	status_effects.update(delta)

func take_damage(amount: int) -> void:
	pass

# --- Status effect handlers ---
func _on_burn_tick(damage: int) -> void:
	take_damage(damage)

func _on_effect_started(effect_type) -> void:
	print("Effect started:", effect_type)
	if effect_type == StatusEffectManager.EffectType.STUN:
		speed = 0
	elif effect_type == StatusEffectManager.EffectType.SLOW:
		speed = base_speed * 0.5
		print("Speed reduced to:", speed)

func _on_effect_ended(effect_type) -> void:
	print("Effect ended:", effect_type)
	if effect_type in [StatusEffectManager.EffectType.STUN, StatusEffectManager.EffectType.SLOW]:
		speed = base_speed
		print("Speed restored to:", speed)
