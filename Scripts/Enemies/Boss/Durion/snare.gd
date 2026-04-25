extends Area2D

var damage : int = 1
var stun_duration : float = 2.0
var warning_duration : float = 1.2
var active_duration : float = 2.0
var is_active : bool = false

@onready var color_rect = $ColorRect

func _ready():
	# Center the ColorRect
	color_rect.position = -color_rect.size / 2
	
	color_rect.color = Color(1, 0.5, 0, 0.5)
	_blink_warning()
	
	await get_tree().create_timer(warning_duration).timeout
	_activate()
	
	await get_tree().create_timer(active_duration).timeout
	queue_free()

func _blink_warning():
	var tween = create_tween()
	tween.set_loops(4)
	tween.tween_property(color_rect, "modulate", Color(1, 1, 1, 0.2), 0.15)
	tween.tween_property(color_rect, "modulate", Color(1, 1, 1, 1.0), 0.15)

func _activate():
	is_active = true
	color_rect.color = Color(1, 0, 0, 0.8)
	
	# Check if player is ALREADY standing on it when it activates
	await get_tree().process_frame
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Player"):
			_apply_snare(body)
			return

func _apply_snare(body: Node2D):
	var state = get_node_or_null("/root/PlayerState")
	if state and state.status_effects:
		state.status_effects.add_effect(
			StatusEffectManager.EffectType.STUN,
			stun_duration
		)
	if body.has_method("take_armor_damage"):
		body.take_armor_damage(damage)
	queue_free()

func _on_body_entered(body: Node2D):
	if body.is_in_group("Player") and is_active:
		_apply_snare(body)
