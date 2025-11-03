extends TextureProgressBar

@onready var player: PlayerState

func _ready():
	PlayerState.healthChanged.connect(update_health)
	update_health()

func update_health():
	value = PlayerState.current_health * 5 / PlayerState.max_health
