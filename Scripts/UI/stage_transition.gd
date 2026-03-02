extends CanvasLayer

@onready var fade_rect : ColorRect = $ColorRect
@onready var floor_label : Label = $Label

# --------------------------------------------------
# READY
# --------------------------------------------------
func _ready():
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Full screen
	fade_rect.anchor_left = 0.0
	fade_rect.anchor_top = 0.0
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.offset_left = 0
	fade_rect.offset_top = 0
	fade_rect.offset_right = 0
	fade_rect.offset_bottom = 0
	
	# Center the label
	floor_label.anchor_left = 0.0
	floor_label.anchor_top = 0.0
	floor_label.anchor_right = 1.0
	floor_label.anchor_bottom = 1.0
	floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	floor_label.visible = false

# --------------------------------------------------
# CALLED WHEN PLAYER ENTERS PORTAL
# --------------------------------------------------
func start_transition():
	print("Starting transition to floor ", GameData.floor)
	
	# Block input during transition
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Step 1: Fade to black
	await _fade(0.0, 1.0, 0.6)
	
	# Step 2: Show floor number
	floor_label.text = "Floor " + str(GameData.floor)
	floor_label.visible = true
	
	# Step 3: Wait a moment
	await get_tree().create_timer(1.2).timeout
	
	# Step 4: Reload dungeon scene fresh
	get_tree().reload_current_scene()

# --------------------------------------------------
# CALLED ON _ready OF DUNGEON AFTER RELOAD
# --------------------------------------------------
func fade_in_on_start():
	print("Fading in on floor ", GameData.floor)
	
	# Start black
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Show floor label briefly
	floor_label.text = "Floor " + str(GameData.floor)
	floor_label.visible = true
	
	await get_tree().create_timer(0.8).timeout
	
	# Hide label then fade in
	floor_label.visible = false
	await _fade(1.0, 0.0, 0.6)
	
	# Allow input again
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

# --------------------------------------------------
# FADE HELPER
# --------------------------------------------------
func _fade(from: float, to: float, duration: float):
	var tween = create_tween()
	tween.tween_method(
		func(v): fade_rect.color = Color(0, 0, 0, v),
		from, to, duration
	)
	await tween.finished