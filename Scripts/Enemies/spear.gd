extends Area2D

@export var damage = 2
@onready var anim = $AnimationPlayer

func _ready() -> void:
	anim.play("attack")

func _physics_process(delta):
	if get_tree().has_group("Player"):
		var player = get_tree().get_nodes_in_group("Player")[0]
		look_at(player.global_position)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.take_armor_damage(damage)
