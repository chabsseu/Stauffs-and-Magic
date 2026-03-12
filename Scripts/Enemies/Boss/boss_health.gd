extends TextureProgressBar

@export var Boss: CharacterBody2D

func _ready() -> void:
	Boss.healthChanged.connect(update_health)
	call_deferred("update_health") 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func update_health():
	value = Boss.current_health * 50 / Boss.max_health
