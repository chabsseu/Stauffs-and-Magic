extends Node
class_name StatusEffectManager

enum EffectType { STUN, BURN, SLOW, POISON }

signal effect_started(type)
signal effect_ended(type)
signal burn_tick(damage)

var active_effects = {}

func _process(delta: float):
	for type in active_effects.keys():
		var data = active_effects[type]

		data.time_left -= delta

		# END EFFECT
		if data.time_left <= 0:
			effect_ended.emit(type)
			active_effects.erase(type)


func add_effect(type: EffectType, duration: float, value := 0.0):
	# refresh effect if already exists
	if active_effects.has(type):
		active_effects[type].time_left = duration
		active_effects[type].value = value
		return

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