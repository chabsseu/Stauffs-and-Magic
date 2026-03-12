extends Area2D

@export var damage_per_tick : int = 1
@export var slow_amount : float = 0.5
@export var tick_interval : float = 0.5
@export var lifetime : float = 5.0

var _tick_timer : float = 0.0
var _lifetime_timer : float = 0.0
var _players_inside : Array = []

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.8, 0.3)

func _process(delta: float):
	_lifetime_timer += delta
	_tick_timer += delta

	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		for player in _players_inside:
			if is_instance_valid(player):
				player.take_armor_damage(damage_per_tick)
				if player.has_method("apply_slow"):
					player.apply_slow(slow_amount, tick_interval + 0.1)

	if _lifetime_timer >= lifetime - 0.5:
		modulate.a = lerp(modulate.a, 0.0, delta * 3.0)

	if _lifetime_timer >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		_players_inside.append(body)

func _on_body_exited(body: Node2D):
	if body.is_in_group("Player"):
		_players_inside.erase(body)