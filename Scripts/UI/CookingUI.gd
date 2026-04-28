extends Control

const RECIPES = {
	"apple+slime": {
		"buff": "speed",
		"duration": 30.0,
		"value": 1.5,
		"icon": preload("res://icon.svg"),
		"cook_time": 3.0
	},
	"cookie_crumble+slime": {
		"buff": "heal",
		"duration": .5,
		"value": 2,
		"icon": preload("res://Assets/Stats/apple_heal.png"),
		"cook_time": 6.0
	},
	"apple+cookie_crumble": {
		"buff": "both",
		"duration": 20.0,
		"value": 1.3,
		"icon": preload("res://icon.svg"),
		"cook_time": 9.0
	}
}

@export var cooked_food_scene: PackedScene
@export var campfire_position: Vector2 = Vector2.ZERO

var selected_ingredients: Array = []
var is_cooking: bool = false
var cook_timer: float = 0.0
var cook_duration: float = 0.0
var pending_recipe: Dictionary = {}

@onready var slot1_btn = $Panel/VBoxContainer/Slots/Slot1
@onready var slot2_btn = $Panel/VBoxContainer/Slots/Slot2
@onready var cook_btn = $Panel/VBoxContainer/CookButton
@onready var result_label = $Panel/VBoxContainer/ResultPanel/ResultLabel
@onready var result_icon = $Panel/VBoxContainer/ResultPanel/ResultIcon
@onready var result_panel = $Panel/VBoxContainer/ResultPanel
@onready var undo_btn = $Panel/VBoxContainer/UndoButton
@onready var slime_btn = $Panel/VBoxContainer/Ingredients/SlimeBtn
@onready var apple_btn = $Panel/VBoxContainer/Ingredients/AppleBtn
@onready var cookie_btn = $Panel/VBoxContainer/Ingredients/CookieBtn
@onready var cook_progress = $Panel/VBoxContainer/CookProgressBar
@onready var cook_timer_label = $Panel/VBoxContainer/CookTimerLabel

func _ready() -> void:
	cook_btn.pressed.connect(_on_cook_pressed)
	undo_btn.pressed.connect(_on_undo_pressed)
	slime_btn.pressed.connect(func(): _select_ingredient("slime"))
	apple_btn.pressed.connect(func(): _select_ingredient("apple"))
	cookie_btn.pressed.connect(func(): _select_ingredient("cookie_crumble"))
	cook_progress.visible = false
	cook_timer_label.visible = false
	result_panel.visible = false
	undo_btn.text = "Undo"
	undo_btn.disabled = true
	visible = false
	refresh()

func _process(delta: float) -> void:
	if not is_cooking:
		return
	cook_timer -= delta
	cook_progress.value = (1.0 - cook_timer / cook_duration) * 100.0
	cook_timer_label.text = "Cooking... %.1fs" % max(cook_timer, 0.0)
	if cook_timer <= 0.0:
		_finish_cooking()

func refresh(campfire_pos: Vector2 = Vector2.ZERO) -> void:
	campfire_position = campfire_pos
	selected_ingredients.clear()
	result_panel.visible = false
	_update_slots()
	_update_ingredient_buttons()

# --------------------------------------------------
# SELECT INGREDIENT
# --------------------------------------------------
func _select_ingredient(type: String) -> void:
	if is_cooking:
		return
	if not IngredientBag.has_ingredient(type):
		return
	if type in selected_ingredients:
		return
	if selected_ingredients.size() >= 2:
		return
	selected_ingredients.append(type)
	_update_slots()
	_update_undo_button()

	# Show preview when 2 ingredients selected
	if selected_ingredients.size() == 2:
		_show_recipe_preview()
	else:
		result_panel.visible = false

# --------------------------------------------------
# RECIPE PREVIEW
# --------------------------------------------------
func _show_recipe_preview() -> void:
	var sorted = selected_ingredients.duplicate()
	sorted.sort()
	var key = "+".join(sorted)
	var recipe = RECIPES.get(key, null)
	if recipe == null:
		result_icon.texture = null
		result_label.text = "No recipe found!"
	else:
		result_icon.texture = recipe.get("icon", null)
		result_label.text = _get_buff_description(recipe)
	result_panel.visible = true

# -------------------------------------------------- 
# UNDO
# --------------------------------------------------
func _on_undo_pressed() -> void:
	if selected_ingredients.is_empty() or is_cooking:
		return
	var last = selected_ingredients.pop_back()
	IngredientBag.add_ingredient(last)
	result_panel.visible = false
	_update_slots()
	_update_ingredient_buttons()
	_update_undo_button()

func _update_undo_button() -> void:
	undo_btn.disabled = selected_ingredients.is_empty() or is_cooking

# --------------------------------------------------
# SLOTS
# --------------------------------------------------
func _update_slots() -> void:
	slot1_btn.text = selected_ingredients[0] if selected_ingredients.size() > 0 else "Empty"
	slot2_btn.text = selected_ingredients[1] if selected_ingredients.size() > 1 else "Empty"
	cook_btn.disabled = selected_ingredients.size() < 2 or is_cooking

func _update_ingredient_buttons() -> void:
	slime_btn.text = "Slime x" + str(IngredientBag.get_count("slime"))
	apple_btn.text = "Apple x" + str(IngredientBag.get_count("apple"))
	cookie_btn.text = "Cookie x" + str(IngredientBag.get_count("cookie_crumble"))
	slime_btn.disabled = not IngredientBag.has_ingredient("slime") or is_cooking
	apple_btn.disabled = not IngredientBag.has_ingredient("apple") or is_cooking
	cookie_btn.disabled = not IngredientBag.has_ingredient("cookie_crumble") or is_cooking

# --------------------------------------------------
# COOK
# --------------------------------------------------
func _on_cook_pressed() -> void:
	if selected_ingredients.size() < 2 or is_cooking:
		return
	var sorted = selected_ingredients.duplicate()
	sorted.sort()
	var key = "+".join(sorted)
	var recipe = RECIPES.get(key, null)
	if recipe == null:
		result_label.text = "No recipe found!"
		result_icon.texture = null
		result_panel.visible = true
		selected_ingredients.clear()
		_update_slots()
		return

	# Remove ingredients
	for ing in selected_ingredients:
		IngredientBag.remove_ingredient(ing)

	# Start cooking
	pending_recipe = recipe
	cook_duration = recipe.get("cook_time", 3.0)
	cook_timer = cook_duration
	is_cooking = true

	cook_progress.visible = true
	cook_progress.value = 0.0
	cook_timer_label.visible = true
	cook_timer_label.text = "Cooking... %.1fs" % cook_duration

	# Hide preview while cooking
	result_panel.visible = false
	cook_btn.disabled = true
	undo_btn.disabled = true
	_update_ingredient_buttons()

# --------------------------------------------------
# FINISH COOKING
# --------------------------------------------------
func _finish_cooking() -> void:
	is_cooking = false
	cook_progress.visible = false
	cook_timer_label.visible = false

	if cooked_food_scene and not pending_recipe.is_empty():
		var food = cooked_food_scene.instantiate()
		food.global_position = campfire_position + Vector2(40, 0)
		get_tree().current_scene.add_child(food)
		food.setup(pending_recipe)
		result_icon.texture = pending_recipe.get("icon", null)
		result_label.text = "Done! " + _get_buff_description(pending_recipe)
		result_panel.visible = true
	else:
		result_label.text = "No food scene assigned!"
		result_panel.visible = true

	pending_recipe = {}
	selected_ingredients.clear()
	_update_slots()
	_update_ingredient_buttons()
	_update_undo_button()

# --------------------------------------------------
# BUFF DESCRIPTION
# --------------------------------------------------
func _get_buff_description(recipe: Dictionary) -> String:
	var buff = recipe.get("buff", "")
	var duration = recipe.get("duration", 0.0)
	var value = recipe.get("value", 0.0)
	match buff:
		"speed":
			return "Speed x%.1f for %ds" % [value, int(duration)]
		"heal":
			return "Healed +%d HP" % [int(value)]
		"both":
			return "Speed x%.1f + Heal for %ds" % [value, int(duration)]
	return "Unknown buff"
