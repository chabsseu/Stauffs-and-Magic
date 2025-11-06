extends Area2D

@export var damage_per_tick: int = 1
@export var tick_rate: float = 1.0
@export var life_time: float = 5.0

var overlapping_players: Array = []
@onready var tick_timer: Timer = Timer.new()
@onready var life_timer: Timer = Timer.new()

func _ready() -> void:
	add_child(tick_timer)
	add_child(life_timer)

	tick_timer.wait_time = tick_rate
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()

	life_timer.wait_time = life_time
	life_timer.timeout.connect(queue_free)
	life_timer.start()

	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		overlapping_players.append(body)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		overlapping_players.erase(body)


func _on_tick() -> void:
	for player in overlapping_players:
		if player and player.is_inside_tree():
			player.take_armor_damage(damage_per_tick)
