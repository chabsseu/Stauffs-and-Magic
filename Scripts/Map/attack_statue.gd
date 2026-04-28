extends CharacterBody2D

@onready var prompt_label: Label = $Detection_area/Label
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

var player_nearby: bool = false
var forge_ui: Node = null
var used: bool = false
var cached_cost: int = 0

func _ready():
	prompt_label.visible = false
	animation.play("active")
	cached_cost = calculate_forge_cost()

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact") and not used:
		open_forge()

func open_forge():
	forge_ui = get_tree().get_first_node_in_group("forge_ui")
	if forge_ui == null:
		push_error("ForgeUI not found")
		return

	# Prevent opening if already open
	if forge_ui.visible:
		return

	if not forge_ui.is_connected("upgrade_confirmed", Callable(self, "_on_upgrade_confirmed")):
		forge_ui.connect("upgrade_confirmed", Callable(self, "_on_upgrade_confirmed"))

	forge_ui.open("damage", cached_cost)

	# Prevent player from firing while forge is open
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_fire = false

func calculate_forge_cost() -> int:
	var floor_number = GameData.floor
	var base_cost = 10
	var scale_per_floor = 8
	var random_variance = randi_range(-3, 5)
	var cost = base_cost + (floor_number - 1) * scale_per_floor + random_variance
	return max(5, cost)

func _on_upgrade_confirmed():
	used = true
	animation.play("idle")
	prompt_label.visible = false
	# Restore firing after upgrade
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_fire = true

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not used:
		player_nearby = true
		prompt_label.visible = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = false
		prompt_label.visible = false
		if forge_ui != null:
			forge_ui.close()
		# Restore firing when player walks away
		body.can_fire = true