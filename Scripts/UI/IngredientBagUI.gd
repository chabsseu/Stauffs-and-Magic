extends CanvasLayer

@onready var panel = $Panel
@onready var slime_label = $Panel/VBoxContainer/HBoxContainer/Count
@onready var apple_label = $Panel/VBoxContainer/HBoxContainer2/Count
@onready var cookie_label = $Panel/VBoxContainer/HBoxContainer3/Count

var is_open = false

func _ready() -> void:
	print("panel: ", panel)
	print("slime_label: ", slime_label)
	print("apple_label: ", apple_label)
	print("cookie_label: ", cookie_label)
	panel.visible = false
	IngredientBag.bag_changed.connect(_update_ui)
	_update_ui()

func _input(event) -> void:
	if event.is_action_pressed("ingredient_bag"):
		is_open = !is_open
		panel.visible = is_open
		_update_ui()

func _update_ui() -> void:
	slime_label.text = "x" + str(IngredientBag.get_count("slime"))
	apple_label.text = "x" + str(IngredientBag.get_count("apple"))
	cookie_label.text = "x" + str(IngredientBag.get_count("cookie_crumble"))
