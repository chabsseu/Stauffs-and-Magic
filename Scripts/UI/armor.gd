extends TextureProgressBar

@export var player: PlayerState

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerState.armorChanged.connect(update_armor)
	update_armor()

func update_armor():
	value = PlayerState.current_armor * 5 / PlayerState.max_armor
