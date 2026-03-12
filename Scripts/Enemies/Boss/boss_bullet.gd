extends Area2D

var land_position : Vector2 = Vector2.ZERO
var puddle_scene : PackedScene = null
var arc_height : float = 80.0
var speed : float = 2.5
var _start_position : Vector2
var _time : float = 0.0
var _arrived : bool = false

@export var damage : int = 1

func _ready():
	_start_position = global_position
	body_entered.connect(_on_body_entered)

func _process(delta: float):
	if _arrived:
		return
	_time += delta
	var t = min(_time / speed, 1.0)
	var flat_pos = _start_position.lerp(land_position, t)
	var arc_offset = sin(t * PI) * arc_height
	global_position = Vector2(flat_pos.x, flat_pos.y - arc_offset)
	var scale_val = lerp(1.0, 0.6, t)
	scale = Vector2(scale_val, scale_val)
	if t >= 1.0:
		_land(land_position)

func _land(spawn_pos: Vector2):
	if _arrived:
		return
	_arrived = true
	if puddle_scene:
		var puddle = puddle_scene.instantiate()
		puddle.global_position = spawn_pos  # ← spawns at whatever position is passed
		get_parent().add_child(puddle)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("take_armor_damage"):
			body.take_armor_damage(damage)
		_land(body.global_position)  # ← spawns puddle at player's current position