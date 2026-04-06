extends CanvasLayer

@onready var slot1_icon = $FoodSlots/Slot1/Icon
@onready var slot2_icon = $FoodSlots/Slot2/Icon

func _ready() -> void:
	slot1_icon.visible = true
	slot2_icon.visible = true

	IngredientBag.food_changed.connect(_update_ui)
	_update_ui()

func _update_ui() -> void:
	var slots = IngredientBag.food_slots

	# SLOT 1
	if slots[0] != null:
		if slots[0].has("icon"):
			slot1_icon.texture = slots[0]["icon"]
		else:
			slot1_icon.texture = null
		
		slot1_icon.modulate = Color.WHITE
	else:
		slot1_icon.texture = null
		slot1_icon.modulate = Color(0.3, 0.3, 0.3)

	# SLOT 2
	if slots[1] != null:
		if slots[1].has("icon"):
			slot2_icon.texture = slots[1]["icon"]
		else:
			slot2_icon.texture = null
		
		slot2_icon.modulate = Color.WHITE
	else:
		slot2_icon.texture = null
		slot2_icon.modulate = Color(0.3, 0.3, 0.3)
