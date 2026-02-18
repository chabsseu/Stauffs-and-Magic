extends Node
class_name StatusEffectManager

enum EffectType { STUN, BURN, SLOW }

signal effect_started(type)
signal effect_ended(type)
signal burn_tick(damage)

var active_effects = {}

func add_effect(type: EffectType, duration: float, value := 0.0):
	if active_effects.has(type):
		return
	
	active_effects[type] = {
		"time_left": duration,
		"value": value,
		"tick_timer": 0.5
	}
	effect_started.emit(type)

func has_effect(type: EffectType) -> bool:
	return active_effects.has(type)

func remove_effect(type: EffectType):
	if active_effects.has(type):
		effect_ended.emit(type)
		active_effects.erase(type)

func update(delta: float):
	var to_remove = []

	for type in active_effects.keys():
		var data = active_effects[type]
		data.time_left -= delta
		
		if type == EffectType.BURN:
			data.tick_timer -= delta
			if data.tick_timer <= 0:
				data.tick_timer = 0.5
				burn_tick.emit(data.value)

		if data.time_left <= 0:
			to_remove.append(type)

	for type in to_remove:
		effect_ended.emit(type)
		active_effects.erase(type)