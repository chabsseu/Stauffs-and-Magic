extends Node
class_name StatusEffectManager

enum EffectType { STUN, BURN, SLOW }

signal effect_started(type)
signal effect_ended(type)
signal burn_tick(damage)

var active_effects = {}

func add_effect(type: EffectType, duration: float, value := 0.0):
	if active_effects.has(type):
		return # prevent stacking (optional)
	
	active_effects[type] = {
		"time_left": duration,
		"value": value
	}
	effect_started.emit(type)

func has_effect(type: EffectType) -> bool:
	return active_effects.has(type)

func remove_effect(type: EffectType):
	if active_effects.has(type):
		effect_ended.emit(type)
		active_effects.erase(type)

func update(delta: float):
	for type in active_effects.keys():
		var data = active_effects[type]
		data.time_left -= delta
		
		# Burn effect deals damage every half second
		if type == EffectType.BURN and data.time_left > 0:
			if int(data.time_left * 10) % 5 == 0:
				burn_tick.emit(data.value)
		
		# Effect ends
		if data.time_left <= 0:
			effect_ended.emit(type)
			active_effects.erase(type)
