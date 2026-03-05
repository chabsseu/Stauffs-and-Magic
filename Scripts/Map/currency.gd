extends Control

const UI_WIDTH = 180.0
const UI_MARGIN = Vector2(10, 10)
const MINIMAP_HEIGHT = 180.0

# Your existing theme colors
const COLOR_BACKGROUND = Color(0.08, 0.05, 0.15, 0.9)
const COLOR_BORDER     = Color(0.6, 0.35, 0.9, 1.0)

# Theme-matching text colors (purple family)
const COLOR_COIN = Color(0.85, 0.55, 1.0, 1.0)
const COLOR_FOOD = Color(0.65, 0.45, 0.95, 1.0)

@export var coin_icon : Texture2D
@export var food_icon : Texture2D

var _coin_label : Label
var _food_label : Label
var _coin_icon : TextureRect
var _food_icon : TextureRect


func _ready():
	anchor_left   = 1.0
	anchor_top    = 0.0
	anchor_right  = 1.0
	anchor_bottom = 0.0
	
	offset_left   = -UI_WIDTH - UI_MARGIN.x
	offset_top    = UI_MARGIN.y + MINIMAP_HEIGHT + 4
	offset_right  = -UI_MARGIN.x
	offset_bottom = UI_MARGIN.y + MINIMAP_HEIGHT + 4 + 52
	
	custom_minimum_size = Vector2(UI_WIDTH, 52)

	# Coin Icon
	_coin_icon = TextureRect.new()
	_coin_icon.texture = coin_icon
	_coin_icon.position = Vector2(6, 4)
	_coin_icon.size = Vector2(18, 18)
	_coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_coin_icon)

	# Coin Label
	_coin_label = Label.new()
	_coin_label.position = Vector2(28, 4)
	_coin_label.size = Vector2(UI_WIDTH - 36, 20)
	_coin_label.add_theme_color_override("font_color", COLOR_COIN)
	_coin_label.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.25))
	_coin_label.add_theme_constant_override("outline_size", 1)
	add_child(_coin_label)

	# Food Icon
	_food_icon = TextureRect.new()
	_food_icon.texture = food_icon
	_food_icon.position = Vector2(6, 28)
	_food_icon.size = Vector2(18, 18)
	_food_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_food_icon)

	# Food Label
	_food_label = Label.new()
	_food_label.position = Vector2(28, 28)
	_food_label.size = Vector2(UI_WIDTH - 36, 20)
	_food_label.add_theme_color_override("font_color", COLOR_FOOD)
	_food_label.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.25))
	_food_label.add_theme_constant_override("outline_size", 1)
	add_child(_food_label)


func _process(_delta):
	_coin_label.text = "Coins: " + str(GameData.coins)
	_food_label.text = "Food:  " + str(GameData.food)


func _draw():
	draw_rect(Rect2(Vector2.ZERO, Vector2(UI_WIDTH, 52)), COLOR_BACKGROUND)
	draw_line(Vector2(4, 0), Vector2(UI_WIDTH - 4, 0), Color(0.75, 0.5, 1.0, 0.4), 1.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(UI_WIDTH, 52)), COLOR_BORDER, false, 2.0)