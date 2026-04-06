extends Area2D

@export var ingredient_type: String = "slime"  # "slime", "apple", "cookie_crumble"
@export var ingredient_color: Color = Color(0.2, 1.0, 0.2)

func _ready() -> void:
    $Sprite2D.modulate = ingredient_color
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("Player"):
        if IngredientBag.add_ingredient(ingredient_type):
            queue_free()