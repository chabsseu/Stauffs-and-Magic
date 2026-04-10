extends HBoxContainer

var player = PlayerState

var effect_icons = {
	StatusEffectManager.EffectType.STUN: preload("res://Assets/UI/stun.png"),
	StatusEffectManager.EffectType.SLOW: preload("res://Assets/UI/slow.png"),
	StatusEffectManager.EffectType.POISON: preload("res://Assets/UI/poison.png"),
	StatusEffectManager.EffectType.BURN: preload("res://Assets/UI/fire.png"),
}

var active_icons = {}


func _ready():
	await get_tree().process_frame

	player.status_effects.effect_started.connect(_on_effect_started)
	player.status_effects.effect_ended.connect(_on_effect_ended)


func _on_effect_started(type):
	if type in effect_icons and not active_icons.has(type):
		var icon = TextureRect.new()
		icon.texture = effect_icons[type]
		icon.custom_minimum_size = Vector2(32, 32)

		add_child(icon)
		active_icons[type] = icon


func _on_effect_ended(type):
	if active_icons.has(type):
		active_icons[type].queue_free()
		active_icons.erase(type)
