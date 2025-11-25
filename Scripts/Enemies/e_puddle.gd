extends Area2D

@export var damage_per_tick: int = 1
@export var tick_rate: float = 1.0
@export var life_time: float = 5.0
var overlapping_players: Array = []
@onready var tick_timer: Timer = Timer.new()
@onready var life_timer: Timer = Timer.new()

# Status effect
@export var has_status_effect: bool = true
@export var effect_type: StatusEffectManager.EffectType = StatusEffectManager.EffectType.SLOW
@export var effect_duration: float = 3.0
@export var effect_value: float = 0.0

func _ready() -> void:
	add_child(tick_timer)
	add_child(life_timer)
	
	tick_timer.wait_time = tick_rate
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()
	
	life_timer.wait_time = life_time
	life_timer.timeout.connect(queue_free)
	life_timer.start()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("Player entered area!")
		overlapping_players.append(body)
		
		if has_status_effect:
			print("Applying effect:", effect_type, "for", effect_duration, "seconds")
			# Access PlayerState directly if it's a global autoload
			PlayerState.status_effects.add_effect(effect_type, effect_duration, effect_value)
			print("Effect applied to PlayerState global!")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("Player exited area")
		overlapping_players.erase(body)

func _on_tick() -> void:
	for player in overlapping_players:
		if player and player.is_inside_tree():
			player.take_armor_damage(damage_per_tick)
