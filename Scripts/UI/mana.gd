extends TextureProgressBar


@onready var player: PlayerState

func _ready():
	PlayerState.manaChanged.connect(update_mana)
	update_mana()

func update_mana():
	value = PlayerState.current_mana * 100 / PlayerState.max_mana
