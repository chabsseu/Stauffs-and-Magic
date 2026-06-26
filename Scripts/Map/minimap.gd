extends Control

# --------------------------------------------------
# SETTINGS
# --------------------------------------------------
const MINIMAP_SIZE = Vector2(180, 180)
const MINIMAP_MARGIN = Vector2(10, 10)
const PADDING = 20.0

const COLOR_BACKGROUND    = Color(0.08, 0.05, 0.15, 0.9)
const COLOR_VISITED_FLOOR = Color(0.75, 0.5, 1.0, 1.0)
const COLOR_CORRIDOR      = Color(0.65, 0.4, 0.9, 0.8)
const COLOR_FOG           = Color(0.2, 0.1, 0.3, 0.7)
const COLOR_PLAYER        = Color(1.0, 1.0, 0.3, 1.0)
const COLOR_PORTAL        = Color(0.4, 1.0, 0.9, 1.0)
const COLOR_BORDER        = Color(0.6, 0.35, 0.9, 1.0)
const COLOR_END_ROOM      = Color(1.0, 0.4, 0.4, 0.8)
const COLOR_STATUE_ROOM   = Color(1.0, 0.85, 0.2, 0.95)
const COLOR_BOSS_ROOM     = Color(1.0, 0.5, 0.0, 0.9)
const COLOR_CAMPFIRE_ROOM = Color(1.0, 0.6, 0.1, 0.95)
const COLOR_ALTARSHOP_ROOM = Color (1.0, 0.9, 0.5, 1)

# --------------------------------------------------
# DATA
# --------------------------------------------------
var dungeon_grid = []
var all_rooms : Array[Rect2] = []
var end_room : Rect2
var statue_room_index : int = -1
var campfire_room_index : int = -1
var altar_shop_room_index : int = -1
var player_ref : CharacterBody2D
var portal_ref : Node2D
var portal_active := false

var visited_rooms : Array[int] = []

var dungeon_width := 800
var dungeon_height := 800

var _scale := Vector2.ONE
var _offset := Vector2.ZERO

var _all_corridor_rects : Array[Rect2] = []
var _all_room_tiles : Dictionary = {}
var _visited_corridor_rects : Array[Rect2] = []
var _corridors_dirty := false

# --------------------------------------------------
# READY
# --------------------------------------------------
func _ready():
	anchor_left   = 1.0
	anchor_top    = 0.0
	anchor_right  = 1.0
	anchor_bottom = 0.0
	offset_left   = -MINIMAP_SIZE.x - MINIMAP_MARGIN.x
	offset_top    = MINIMAP_MARGIN.y
	offset_right  = -MINIMAP_MARGIN.x
	offset_bottom = MINIMAP_SIZE.y + MINIMAP_MARGIN.y
	custom_minimum_size = MINIMAP_SIZE

# --------------------------------------------------
# PROCESS
# --------------------------------------------------
func _process(_delta):
	if is_instance_valid(player_ref) and statue_room_index != -1:
		var current_room = _get_room_from_world(player_ref.position)
		if current_room == statue_room_index:
			visit_room(statue_room_index)

	if is_instance_valid(player_ref) and campfire_room_index != -1:
		var current_room = _get_room_from_world(player_ref.position)
		if current_room == campfire_room_index:
			visit_room(campfire_room_index)

	if is_instance_valid(player_ref) and altar_shop_room_index != -1:
		var current_room = _get_room_from_world(player_ref.position)
		if current_room == altar_shop_room_index:
			visit_room(altar_shop_room_index)
			
	if _corridors_dirty:
		_rebuild_visited_corridors()
		_corridors_dirty = false

	queue_redraw()

# --------------------------------------------------
# SETUP
# --------------------------------------------------
func setup_minimap():
	if all_rooms.is_empty() or dungeon_grid.is_empty():
		return
	_recalculate_bounds()
	_build_all_corridors()
	_rebuild_visited_corridors()

# --------------------------------------------------
# VISIT ROOM
# --------------------------------------------------
func visit_room(room_index: int):
	if room_index == -1:
		return
	if not visited_rooms.has(room_index):
		visited_rooms.append(room_index)
	_corridors_dirty = true

# --------------------------------------------------
# SET STATUE ROOM
# --------------------------------------------------
func set_statue_room(room_index: int):
	statue_room_index = room_index

# --------------------------------------------------
# SET CAMPFIRE ROOM
# --------------------------------------------------
func set_campfire_room(room_index: int):
	campfire_room_index = room_index

# -------------------------------------------------
# SET ALTAR SHOP
# -------------------------------------------------
func set_altar_shop_room(room_index: int):
	altar_shop_room_index = room_index
	
# --------------------------------------------------
# ROOM FROM PLAYER WORLD POSITION
# --------------------------------------------------
func _get_room_from_world(world_pos: Vector2) -> int:
	var tile_pos = world_pos / 16.0
	for i in range(all_rooms.size()):
		if all_rooms[i].has_point(tile_pos):
			return i
	return -1

# --------------------------------------------------
# RECALCULATE BOUNDS
# --------------------------------------------------
func _recalculate_bounds():
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF

	for room in all_rooms:
		min_x = min(min_x, room.position.x)
		min_y = min(min_y, room.position.y)
		max_x = max(max_x, room.end.x)
		max_y = max(max_y, room.end.y)

	var content_width  = max_x - min_x + PADDING * 2
	var content_height = max_y - min_y + PADDING * 2

	var scale_x = MINIMAP_SIZE.x / content_width
	var scale_y = MINIMAP_SIZE.y / content_height
	var uniform_scale = min(scale_x, scale_y)
	_scale = Vector2(uniform_scale, uniform_scale)

	var scaled_width  = content_width * uniform_scale
	var scaled_height = content_height * uniform_scale

	_offset = Vector2(
		(MINIMAP_SIZE.x - scaled_width) / 2.0 - (min_x - PADDING) * uniform_scale,
		(MINIMAP_SIZE.y - scaled_height) / 2.0 - (min_y - PADDING) * uniform_scale
	)

# --------------------------------------------------
# BUILD CORRIDORS
# --------------------------------------------------
func _build_all_corridors():
	_all_corridor_rects.clear()
	_all_room_tiles.clear()

	for i in range(all_rooms.size()):
		var room = all_rooms[i]
		for y in range(int(room.position.y), int(room.end.y)):
			for x in range(int(room.position.x), int(room.end.x)):
				_all_room_tiles[Vector2i(x, y)] = i

	var step = 2
	var tile_size = Vector2(max(1.5, _scale.x * step), max(1.5, _scale.y * step))

	for y in range(0, dungeon_height, step):
		for x in range(0, dungeon_width, step):
			if dungeon_grid[y][x] != 1:
				continue
			if _all_room_tiles.has(Vector2i(x, y)):
				continue

			var map_pos = _to_map(Vector2(x, y))
			if map_pos.x < 0 or map_pos.y < 0 or map_pos.x > MINIMAP_SIZE.x or map_pos.y > MINIMAP_SIZE.y:
				continue

			_all_corridor_rects.append(Rect2(map_pos, tile_size))

# --------------------------------------------------
# VISITED CORRIDORS
# --------------------------------------------------
func _rebuild_visited_corridors():
	_visited_corridor_rects.clear()

	for rect in _all_corridor_rects:
		var world_pos = (rect.position - _offset) / _scale
		var cx = int(world_pos.x)
		var cy = int(world_pos.y)

		if _corridor_connects_visited(cx, cy):
			_visited_corridor_rects.append(rect)

func _corridor_connects_visited(cx: int, cy: int) -> bool:
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]

	for dir in dirs:
		var x = cx
		var y = cy

		for _i in range(120):
			x += dir.x
			y += dir.y

			if x < 0 or y < 0 or x >= dungeon_width or y >= dungeon_height:
				break
			if dungeon_grid[y][x] != 1:
				break

			var room_idx = _all_room_tiles.get(Vector2i(x, y), -1)
			if room_idx != -1 and visited_rooms.has(room_idx):
				return true

	return false

# --------------------------------------------------
# WORLD → MAP
# --------------------------------------------------
func _to_map(world_pos: Vector2) -> Vector2:
	return world_pos * _scale + _offset

# --------------------------------------------------
# DRAW
# --------------------------------------------------
func _draw():
	if dungeon_grid.is_empty() or all_rooms.is_empty():
		return

	draw_rect(Rect2(Vector2.ZERO, MINIMAP_SIZE), COLOR_BACKGROUND)

	# Fog rooms
	for room in all_rooms:
		draw_rect(Rect2(_to_map(room.position), room.size * _scale), COLOR_FOG)

	# Fog corridors
	for rect in _all_corridor_rects:
		draw_rect(rect, COLOR_FOG)

	# Revealed corridors
	for rect in _visited_corridor_rects:
		draw_rect(rect, COLOR_CORRIDOR)

	# Draw visited rooms
	for i in range(all_rooms.size()):
		if not visited_rooms.has(i):
			continue

		var room = all_rooms[i]
		var rect = Rect2(_to_map(room.position), room.size * _scale)
		var color_to_draw : Color = COLOR_VISITED_FLOOR

		if i == statue_room_index:
			color_to_draw = COLOR_STATUE_ROOM
		elif i == campfire_room_index:
			color_to_draw = COLOR_CAMPFIRE_ROOM
		elif i == altar_shop_room_index:
			color_to_draw = COLOR_ALTARSHOP_ROOM
		elif all_rooms[i] == end_room:
			color_to_draw = COLOR_END_ROOM

		draw_rect(rect, color_to_draw)
		draw_rect(rect, COLOR_BORDER, false, 1.5)

	# Player
	if is_instance_valid(player_ref):
		var player_map_pos = _to_map(player_ref.position / 16.0)
		draw_circle(player_map_pos, 3.5, COLOR_PLAYER)

	draw_rect(Rect2(Vector2.ZERO, MINIMAP_SIZE), COLOR_BORDER, false, 2.5)
