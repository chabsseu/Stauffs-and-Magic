extends Control

# Exchange rate: how many coins = 1 food
const COINS_PER_FOOD: int = 5

@onready var coins_label: Label = %coins_label
@onready var food_label: Label = %food_label
@onready var amount_label: Label = %amount_label
@onready var convert_button: Button = %convert_button
@onready var increase_button: Button = %increase_button
@onready var decrease_button: Button = %decrease_button
@onready var close_button: Button = %close_button
@onready var rate_label: Label = %rate_label

var amount: int = 1  # how many food to convert to

func _ready():
    visible = false

func open():
    amount = 1
    refresh_ui()
    visible = true

func close():
    visible = false

func refresh_ui():
    coins_label.text = "Coins: %d" % GameData.coins
    food_label.text = "Food: %d" % GameData.food
    rate_label.text = "Rate: %d= 1" % COINS_PER_FOOD
    amount_label.text = "x%d  (costs %d)" % [amount, amount * COINS_PER_FOOD]

    # Disable convert if can't afford
    var can_afford = GameData.coins >= amount * COINS_PER_FOOD
    convert_button.disabled = not can_afford
    convert_button.text = "CONVERT" if can_afford else "CONVERT"

    # Disable increase if next amount would be unaffordable
    increase_button.disabled = GameData.coins < (amount + 1) * COINS_PER_FOOD

    # Disable decrease if already at 1
    decrease_button.disabled = amount <= 1

func _on_increase_button_pressed():
    amount += 1
    refresh_ui()

func _on_decrease_button_pressed():
    amount = max(1, amount - 1)
    refresh_ui()

func _on_convert_button_pressed():
    var total_cost = amount * COINS_PER_FOOD
    if GameData.coins >= total_cost:
        GameData.coins -= total_cost
        GameData.food += amount
        refresh_ui()

func _on_close_button_pressed():
    visible = false