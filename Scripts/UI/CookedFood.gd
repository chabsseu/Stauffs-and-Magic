extends Area2D

var food_data: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(data: Dictionary) -> void:
	food_data = data

	if data.has("icon") and data["icon"] != null:
		sprite.texture = data["icon"]
		sprite.modulate = Color(1, 1, 1)

		# 🔥 AUTO SCALE SYSTEM
		var target_size: float = 16.0

		var tex_size: Vector2 = sprite.texture.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			var scale_factor: float = target_size / max(tex_size.x, tex_size.y)
			sprite.scale = Vector2(scale_factor, scale_factor)
	else:
		sprite.texture = null
		sprite.scale = Vector2.ONE  # 🔥 reset scale so old scale doesn't stay

		match data.get("buff", ""):
			"speed":
				sprite.modulate = Color(0.2, 0.8, 1.0)
			"heal":
				sprite.modulate = Color(0.2, 1.0, 0.2)  # ✅ green for heal (better)
			"both":
				sprite.modulate = Color(1.0, 0.8, 0.2)
			_:
				sprite.modulate = Color(1, 1, 1)  # fallback

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if IngredientBag and IngredientBag.add_food(food_data):
			queue_free()