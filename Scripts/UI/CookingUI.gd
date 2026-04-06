extends Control

const RECIPES = {
	"apple+slime": {
		"buff": "speed",
		"duration": 30.0,
		"value": 1.5,
		"icon": preload("res://icon.svg") # change this to the official sprite
	},
	"cookie_crumble+slime": {
		"buff": "heal",
		"duration": 1,
		"value": 2,
		"icon": preload("res://icon.svg") # change this to the official sprite 
	},
	"apple+cookie_crumble": {
		"buff": "both",
		"duration": 20.0,
		"value": 1.3,
		"icon": preload("res://icon.svg") # change this to the official sprite
	}
}

@export var cooked_food_scene: PackedScene
@export var campfire_position: Vector2 = Vector2.ZERO

var selected_ingredients: Array = []

@onready var slot1_btn = $Panel/VBoxContainer/Slots/Slot1
@onready var slot2_btn = $Panel/VBoxContainer/Slots/Slot2
@onready var cook_btn = $Panel/VBoxContainer/CookButton
@onready var result_label = $Panel/VBoxContainer/ResultLabel
@onready var slime_btn = $Panel/VBoxContainer/Ingredients/SlimeBtn
@onready var apple_btn = $Panel/VBoxContainer/Ingredients/AppleBtn
@onready var cookie_btn = $Panel/VBoxContainer/Ingredients/CookieBtn

func _ready() -> void:
	cook_btn.pressed.connect(_on_cook_pressed)
	slime_btn.pressed.connect(func(): _select_ingredient("slime"))
	apple_btn.pressed.connect(func(): _select_ingredient("apple"))
	cookie_btn.pressed.connect(func(): _select_ingredient("cookie_crumble"))
	visible = false
	refresh()

func refresh(campfire_pos: Vector2 = Vector2.ZERO) -> void:
	campfire_position = campfire_pos
	selected_ingredients.clear()
	result_label.text = ""
	_update_slots()
	_update_ingredient_buttons()

func _select_ingredient(type: String) -> void:
	if not IngredientBag.has_ingredient(type):
		return
	if type in selected_ingredients:
		return
	if selected_ingredients.size() >= 2:
		return
	selected_ingredients.append(type)
	_update_slots()

func _update_slots() -> void:
	slot1_btn.text = selected_ingredients[0] if selected_ingredients.size() > 0 else "Empty"
	slot2_btn.text = selected_ingredients[1] if selected_ingredients.size() > 1 else "Empty"
	cook_btn.disabled = selected_ingredients.size() < 2

func _update_ingredient_buttons() -> void:
	slime_btn.text = "Slime x" + str(IngredientBag.get_count("slime"))
	apple_btn.text = "Apple x" + str(IngredientBag.get_count("apple"))
	cookie_btn.text = "Cookie x" + str(IngredientBag.get_count("cookie_crumble"))

	slime_btn.disabled = not IngredientBag.has_ingredient("slime")
	apple_btn.disabled = not IngredientBag.has_ingredient("apple")
	cookie_btn.disabled = not IngredientBag.has_ingredient("cookie_crumble")

func _on_cook_pressed() -> void:
	if selected_ingredients.size() < 2:
		return

	var sorted = selected_ingredients.duplicate()
	sorted.sort()
	var key = "+".join(sorted)
	var recipe = RECIPES.get(key, null)

	if recipe == null:
		result_label.text = "No recipe found!"
		selected_ingredients.clear()
		_update_slots()
		return

	for ing in selected_ingredients:
		IngredientBag.remove_ingredient(ing)

	if cooked_food_scene:
		var food = cooked_food_scene.instantiate()
		food.global_position = campfire_position + Vector2(40, 0)
		get_tree().current_scene.add_child(food)
		food.setup(recipe)
		result_label.text = "Cooked! Pick it up!"
	else:
		result_label.text = "No food scene assigned!"

	selected_ingredients.clear()
	_update_slots()
	_update_ingredient_buttons()
