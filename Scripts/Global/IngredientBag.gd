extends Node

signal bag_changed
signal food_changed

const MAX_PER_INGREDIENT = 5

var ingredients = {
	"slime": 0,
	"apple": 0,
	"cookie_crumble": 0
}

var food_slots: Array = [null, null]  # max 2 food items

# --------------------------------------------------
# INGREDIENTS
# --------------------------------------------------
func add_ingredient(type: String) -> bool:
	if not ingredients.has(type):
		return false
	if ingredients[type] >= MAX_PER_INGREDIENT:
		print("Bag full for:", type)
		return false
	ingredients[type] += 1
	bag_changed.emit()
	return true

func remove_ingredient(type: String) -> bool:
	if not ingredients.has(type):
		return false
	if ingredients[type] <= 0:
		return false
	ingredients[type] -= 1
	bag_changed.emit()
	return true

func has_ingredient(type: String) -> bool:
	return ingredients.get(type, 0) > 0

func get_count(type: String) -> int:
	return ingredients.get(type, 0)

# --------------------------------------------------
# FOOD
# --------------------------------------------------
func add_food(food_data: Dictionary) -> bool:
	for i in range(food_slots.size()):
		if food_slots[i] == null:
			food_slots[i] = food_data
			food_changed.emit()
			print("Food added:", food_data)
			return true
	print("Food slots full!")
	return false

func consume_food() -> Dictionary:
	for i in range(food_slots.size()):
		if food_slots[i] != null:
			var food = food_slots[i]
			food_slots[i] = null
			food_changed.emit()
			return food
	return {}

func has_food() -> bool:
	for slot in food_slots:
		if slot != null:
			return true
	return false