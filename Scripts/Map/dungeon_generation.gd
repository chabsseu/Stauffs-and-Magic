extends Node2D

@export var tilemap : TileMapLayer
@export var player : CharacterBody2D

const DUNGEON_WIDTH = 800
const DUNGEON_HEIGHT = 800
const MIN_CORRIDOR_LENGTH = 18
const MAX_CORRIDOR_LENGTH = 64

enum TileType { EMPTY, FLOOR, WALL }
enum RoomSize { MEDIUM_LARGE, LARGE_BOSS }

var dungeon_grid = []

# --------------------------------------------------
# READY / INPUT
# --------------------------------------------------
func _ready():
	create_dungeon()

func _input(event):
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_1:
			create_dungeon()

# --------------------------------------------------
# MAIN GENERATION
# --------------------------------------------------
func generate_dungeon():
	dungeon_grid = []
	for y in range(DUNGEON_HEIGHT):
		dungeon_grid.append([])
		for x in range(DUNGEON_WIDTH):
			dungeon_grid[y].append(TileType.EMPTY)

	var rooms : Array[Rect2] = []
	var target_room_count := _roll_room_count()

	var max_attempts = 500
	var tries = 0

	# ---------- FIRST ROOM ----------
	var first_room = _create_random_room()
	if first_room.has_area():
		rooms.append(first_room)
		_carve_room(first_room)

	# ---------- OTHER ROOMS ----------
	while rooms.size() < target_room_count and tries < max_attempts:
		if rooms.is_empty():
			break

		var base_room = rooms.pick_random()

		var direction = randi() % 4
		var corridor_length = randi_range(MIN_CORRIDOR_LENGTH, MAX_CORRIDOR_LENGTH)

		var new_room = _create_room_with_corridor(base_room, direction, corridor_length)

		if new_room.has_area() and _can_place_room(new_room, rooms):

			# LAST ROOM = BOSS ROOM
			if rooms.size() == target_room_count - 1:
				var boss_size = _get_room_dimensions(RoomSize.LARGE_BOSS)
				new_room.size = Vector2(boss_size.x, boss_size.y)

			rooms.append(new_room)
			_carve_room(new_room)

			var corridor_width = randi_range(5, 7)
			carve_corridor(base_room.get_center(), new_room.get_center(), corridor_width)

		tries += 1

	return rooms

# --------------------------------------------------
# ROOM CREATION
# --------------------------------------------------
func _create_random_room() -> Rect2:
	var dims = _get_room_dimensions(RoomSize.MEDIUM_LARGE)
	var w = dims.x
	var h = dims.y
	var x = randi_range(5, DUNGEON_WIDTH - w - 5)
	var y = randi_range(5, DUNGEON_HEIGHT - h - 5)
	return Rect2(x, y, w, h)

func _create_room_with_corridor(base_room: Rect2, direction: int, corridor_length: int) -> Rect2:
	var dims = _get_room_dimensions(RoomSize.MEDIUM_LARGE)
	var w = dims.x
	var h = dims.y

	var base_center = base_room.get_center()
	var x = 0
	var y = 0

	match direction:
		0: # UP
			x = base_center.x - w / 2
			y = base_room.position.y - corridor_length - h
		1: # DOWN
			x = base_center.x - w / 2
			y = base_room.end.y + corridor_length
		2: # LEFT
			x = base_room.position.x - corridor_length - w
			y = base_center.y - h / 2
		3: # RIGHT
			x = base_room.end.x + corridor_length
			y = base_center.y - h / 2

	if x < 1 or y < 1 or x + w >= DUNGEON_WIDTH - 1 or y + h >= DUNGEON_HEIGHT - 1:
		return Rect2()

	return Rect2(x, y, w, h)

func _can_place_room(room: Rect2, existing_rooms: Array[Rect2]) -> bool:
	if room.position.x < 1 or room.position.y < 1:
		return false
	if room.end.x >= DUNGEON_WIDTH - 1 or room.end.y >= DUNGEON_HEIGHT - 1:
		return false

	for other in existing_rooms:
		if room.grow(6).intersects(other): # BIG spacing for big rooms
			return false

	return true

func _carve_room(room: Rect2):
	for y in range(room.position.y, room.position.y + room.size.y):
		for x in range(room.position.x, room.position.x + room.size.x):
			if is_in_bounds(x, y):
				dungeon_grid[y][x] = TileType.FLOOR

# --------------------------------------------------
# ROOM COUNT (5–8, avg ≈5)
# --------------------------------------------------
func _roll_room_count() -> int:
	var roll = randf()
	if roll < 0.30:
		return 5
	elif roll < 0.55:
		return 6
	elif roll < 0.80:
		return 7
	else:
		return 8

# --------------------------------------------------
# ROOM SIZE
# --------------------------------------------------
func _get_room_dimensions(size_type: RoomSize) -> Vector2i:
	match size_type:
		RoomSize.MEDIUM_LARGE:
			return Vector2i(
				randi_range(22, 30),
				randi_range(20, 26)
			)

		RoomSize.LARGE_BOSS:
			return Vector2i(
				randi_range(30, 42),
				randi_range(26, 34)
			)

	return Vector2i(26, 22)

# --------------------------------------------------
# CORRIDORS
# --------------------------------------------------
func carve_corridor(from: Vector2, to: Vector2, width: int = 6):
	var half_width = width / 2

	if randf() < 0.5:
		for x in range(min(from.x, to.x), max(from.x, to.x) + 1):
			for offset in range(-half_width, half_width + 1):
				var y = int(from.y + offset)
				if is_in_bounds(x, y):
					dungeon_grid[y][x] = TileType.FLOOR

		for y in range(min(from.y, to.y), max(from.y, to.y) + 1):
			for offset in range(-half_width, half_width + 1):
				var x = int(to.x + offset)
				if is_in_bounds(x, y):
					dungeon_grid[y][x] = TileType.FLOOR
	else:
		for y in range(min(from.y, to.y), max(from.y, to.y) + 1):
			for offset in range(-half_width, half_width + 1):
				var x = int(from.x + offset)
				if is_in_bounds(x, y):
					dungeon_grid[y][x] = TileType.FLOOR

		for x in range(min(from.x, to.x), max(from.x, to.x) + 1):
			for offset in range(-half_width, half_width + 1):
				var y = int(to.y + offset)
				if is_in_bounds(x, y):
					dungeon_grid[y][x] = TileType.FLOOR


# --------------------------------------------------
# BOUNDS CHECK
# --------------------------------------------------
func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < DUNGEON_WIDTH and y < DUNGEON_HEIGHT

# --------------------------------------------------
# WALLS
# --------------------------------------------------
func add_walls():
	var wall_positions = []

	for y in range(DUNGEON_HEIGHT):
		for x in range(DUNGEON_WIDTH):
			if dungeon_grid[y][x] == TileType.FLOOR:
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx = x + dx
						var ny = y + dy
						if is_in_bounds(nx, ny):
							if dungeon_grid[ny][nx] == TileType.EMPTY:
								wall_positions.append(Vector2i(nx, ny))

	for pos in wall_positions:
		if dungeon_grid[pos.y][pos.x] == TileType.EMPTY:
			dungeon_grid[pos.y][pos.x] = TileType.WALL

# --------------------------------------------------
# RENDER
# --------------------------------------------------
func render_dungeon():
	tilemap.clear()
	# Define your floor variants here (atlas coordinates in TileSet)
	var floor_tiles = [Vector2i(1,5), Vector2i(5,5)]
	
	for y in range(DUNGEON_HEIGHT):
		for x in range(DUNGEON_WIDTH):
			match dungeon_grid[y][x]:
				TileType.FLOOR:
					# Pick a random floor variant for each floor cell
					var chosen_tile = floor_tiles[randi() % floor_tiles.size()]
					tilemap.set_cell(Vector2i(x, y), 0, chosen_tile)
				TileType.WALL:
					tilemap.set_cell(Vector2i(x, y), 0, Vector2i(3,2))

# --------------------------------------------------
# CREATE
# --------------------------------------------------
func create_dungeon():
	var rooms = generate_dungeon()
	place_player(rooms)
	add_walls()
	render_dungeon()

# --------------------------------------------------
# PLAYER SPAWN
# --------------------------------------------------
func place_player(rooms : Array[Rect2]):
	if rooms.is_empty():
		return

	var spawn_room = rooms.pick_random()
	player.position = spawn_room.get_center() * 16
