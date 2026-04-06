extends Area2D

var food_data: Dictionary = {}

@onready var sprite = $Sprite2D  # Reference to the Sprite2D

func _ready() -> void:
    body_entered.connect(_on_body_entered)

# This is called when the food is spawned from cooking
func setup(data: Dictionary) -> void:
    food_data = data

    # 1️⃣ Set the sprite texture if it exists
    if data.has("icon") and data["icon"] != null:
        sprite.texture = data["icon"]
        sprite.modulate = Color(1, 1, 1)  # Reset color to normal
    else:
        # fallback to buff-based color if no texture is provided
        match data.get("buff", ""):
            "speed":
                sprite.texture = null
                sprite.modulate = Color(0.2, 0.8, 1.0)
            "damage":
                sprite.texture = null
                sprite.modulate = Color(1.0, 0.2, 0.2)
            "both":
                sprite.texture = null
                sprite.modulate = Color(1.0, 0.8, 0.2)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("Player"):
        if IngredientBag.add_food(food_data):
            queue_free()