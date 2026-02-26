extends Node2D

@export var tilemap : TileMapLayer
@export var player : CharacterBody2D
@export var weapon : Node2D
@export var enemy_scenes : Array[PackedScene]
@export var statue_scenes : Array[PackedScene]
@export var portal : Node2D  # Portal node

const DUNGEON_WIDTH = 800
const DUNGEON_HEIGHT = 800
const MIN_CORRIDOR_LENGTH = 18
const MAX_CORRIDOR_LENGTH = 64

enum TileType { EMPTY, FLOOR, WALL }
enum RoomSize { SMALL_START, MEDIUM_LARGE, LARGE_BOSS }

var dungeon_grid = []
var all_rooms : Array[Rect2] = []
var end_room : Rect2
var room_wave_data = {}  # Track wave data per room index
var room_barriers = {}  # Track barrier positions per room index

# --------------------------------------------------
# READY / INPUT
# --------------------------------------------------
func _ready():
	if portal:
		portal.visible = false  # Hide portal initially
	create_dungeon()

func _process(_delta):
	# Check all active rooms for wave completion
	for room_index in room_wave_data.keys():
		check_wave_complete(room_index)

# --------------------------------------------------
# CREATE ROOM TRIGGER
# --------------------------------------------------
func create_room_trigger(room: Rect2, room_index: int):
	var area = Area2D.new()
	area.name = "RoomTrigger_" + str(room_index)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Trigger at entrance (30% of room size)
	shape.size = Vector2(room.size.x * 16 * 0.3, room.size.y * 16 * 0.3)
	collision.shape = shape
	area.position = room.get_center() * 16
	area.collision_layer = 0
	area.collision_mask = 1  # Player layer
	
	var callable = func(body):
		if body == player:
			spawn_enemies_in_room(room, room_index)
			close_room_exits(room, room_index)
			area.queue_free()
	
	area.body_entered.connect(callable, CONNECT_ONE_SHOT)
	collision.set_deferred("disabled", false)
	area.add_child(collision)
	add_child(area)

# --------------------------------------------------
# ROOM EXIT BLOCKING
# --------------------------------------------------
func close_room_exits(room: Rect2, room_index: int):
	var barrier_positions = []
	var barrier_tile = Vector2i(3, 2)  # Use a wall tile
	
	# Find corridor entrances around the room perimeter
	# Check all edges of the room
	for x in range(room.position.x - 1, room.end.x + 1):
		# Top edge
		var top_y = int(room.position.y) - 1
		if is_in_bounds(x, top_y) and dungeon_grid[top_y][x] == TileType.FLOOR:
			var barrier_pos = Vector2i(x, top_y)
			barrier_positions.append(barrier_pos)
			tilemap.set_cell(barrier_pos, 0, barrier_tile)
		
		# Bottom edge
		var bottom_y = int(room.end.y)
		if is_in_bounds(x, bottom_y) and dungeon_grid[bottom_y][x] == TileType.FLOOR:
			var barrier_pos = Vector2i(x, bottom_y)
			barrier_positions.append(barrier_pos)
			tilemap.set_cell(barrier_pos, 0, barrier_tile)
	
	for y in range(room.position.y - 1, room.end.y + 1):
		# Left edge
		var left_x = int(room.position.x) - 1
		if is_in_bounds(left_x, y) and dungeon_grid[y][left_x] == TileType.FLOOR:
			var barrier_pos = Vector2i(left_x, y)
			barrier_positions.append(barrier_pos)
			tilemap.set_cell(barrier_pos, 0, barrier_tile)
		
		# Right edge
		var right_x = int(room.end.x)
		if is_in_bounds(right_x, y) and dungeon_grid[y][right_x] == TileType.FLOOR:
			var barrier_pos = Vector2i(right_x, y)
			barrier_positions.append(barrier_pos)
			tilemap.set_cell(barrier_pos, 0, barrier_tile)
	
	room_barriers[room_index] = barrier_positions
	print("Room ", room_index, " exits closed! Barriers placed: ", barrier_positions.size())

func open_room_exits(room_index: int):
	if not room_barriers.has(room_index):
		return
	
	var floor_tiles = [Vector2i(1, 5), Vector2i(5, 5)]
	
	for barrier_pos in room_barriers[room_index]:
		# Replace barrier with floor tile
		tilemap.set_cell(barrier_pos, 0, floor_tiles[randi() % floor_tiles.size()])
	
	print("Room ", room_index, " exits opened!")
	room_barriers.erase(room_index)

# --------------------------------------------------
# WAVE COMPLETION CHECK PER ROOM
# --------------------------------------------------
func check_wave_complete(room_index: int):
	if not room_wave_data.has(room_index):
		return

	var data = room_wave_data[room_index]
	if data.is_spawning:
		return

	# Remove dead enemies from tracking
	data.active_enemies = data.active_enemies.filter(func(enemy): return is_instance_valid(enemy))

	# All waves complete
	if data.active_enemies.is_empty() and data.current_wave >= data.total_waves:
		print("Room ", room_index, " - All waves complete!")
		
		# Open room exits
		open_room_exits(room_index)
		
		# If this is the end room, activate portal
		if all_rooms[room_index] == end_room:
			activate_portal()
		
		room_wave_data.erase(room_index)
	# If there are more waves, spawn next wave
	elif data.active_enemies.is_empty() and data.current_wave < data.total_waves:
		print("Room ", room_index, " - Wave ", data.current_wave, " complete! Spawning wave ", data.current_wave + 1, "...")
		data.current_wave += 1
		spawn_wave(data.room, data.enemies_per_wave, data.current_wave, room_index)

# --------------------------------------------------
# SPAWN ENEMIES IN A SPECIFIC ROOM
# --------------------------------------------------
func spawn_enemies_in_room(room: Rect2, room_index: int):
	print("Room ", room_index, " triggered!")
	var total_waves = randi_range(2 , 4)
	var enemies_per_wave = randi_range(3, 6)
	
	room_wave_data[room_index] = {
		"room": room,
		"total_waves": total_waves,
		"current_wave": 1,
		"enemies_per_wave": enemies_per_wave,
		"active_enemies": [],
		"is_spawning": false
	}
	
	print("Room ", room_index, " - Spawning wave 1 of ", total_waves)
	spawn_wave(room, enemies_per_wave, 1, room_index)

func spawn_wave(room: Rect2, count: int, wave_num: int, room_index: int):
	if not room_wave_data.has(room_index):
		return

	room_wave_data[room_index].is_spawning = true

	for j in range(count):
		if enemy_scenes.is_empty():
			room_wave_data[room_index].is_spawning = false
			return

		var spawn_timer = Timer.new()
		spawn_timer.one_shot = true
		add_child(spawn_timer)

		var is_last = (j == count - 1)
		spawn_timer.timeout.connect(func():
			_spawn_single_enemy(room, spawn_timer, room_index)
			if is_last and room_wave_data.has(room_index):
				await get_tree().create_timer(0.5).timeout
				if room_wave_data.has(room_index):
					room_wave_data[room_index].is_spawning = false
		)
		spawn_timer.start(0.3 * j)

func _spawn_single_enemy(room: Rect2, timer: Timer, room_index: int):
	if enemy_scenes.is_empty():
		timer.queue_free()
		return
	
	var scene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy = scene.instantiate()
	var x = randi_range(room.position.x + 2, room.end.x - 2)
	var y = randi_range(room.position.y + 2, room.end.y - 2)
	var spawn_pos = Vector2(x, y) * 16
	enemy.position = spawn_pos
	
	# Spawn effect at the same position
	create_spawn_effect(spawn_pos)
	
	# Optional: brief delay before enemy becomes active
	enemy.visible = false
	add_child(enemy)
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(enemy):
		enemy.visible = true

	if room_wave_data.has(room_index):
		room_wave_data[room_index].active_enemies.append(enemy)

	timer.queue_free()

# --------------------------------------------------
# PORTAL ACTIVATION
# --------------------------------------------------
func activate_portal():
	if not portal:
		return
	portal.position = end_room.get_center() * 16
	portal.visible = true
	print("Portal activated in end room!")

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

	# First room
	var first_room = _create_spawn_room_corner()
	rooms.append(first_room)
	_carve_room(first_room)

	# Other rooms
	while rooms.size() < target_room_count and tries < max_attempts:
		var base_room = rooms.pick_random()
		var direction = randi() % 4
		var corridor_length = randi_range(MIN_CORRIDOR_LENGTH, MAX_CORRIDOR_LENGTH)
		var new_room = _create_room_with_corridor(base_room, direction, corridor_length)

		if new_room.has_area() and _can_place_room(new_room, rooms):
			# Last room = boss room
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
func _create_spawn_room_corner() -> Rect2:
	var dims = _get_room_dimensions(RoomSize.SMALL_START)
	var w = dims.x
	var h = dims.y
	var margin = 6
	var corner = randi() % 4
	var x = 0
	var y = 0

	match corner:
		0: x = margin; y = margin
		1: x = DUNGEON_WIDTH - w - margin; y = margin
		2: x = margin; y = DUNGEON_HEIGHT - h - margin
		3: x = DUNGEON_WIDTH - w - margin; y = DUNGEON_HEIGHT - h - margin

	return Rect2(x, y, w, h)

func _create_room_with_corridor(base_room: Rect2, direction: int, corridor_length: int) -> Rect2:
	var dims = _get_room_dimensions(RoomSize.MEDIUM_LARGE)
	var w = dims.x
	var h = dims.y
	var base_center = base_room.get_center()
	var x = 0
	var y = 0

	match direction:
		0: x = base_center.x - w / 2; y = base_room.position.y - corridor_length - h
		1: x = base_center.x - w / 2; y = base_room.end.y + corridor_length
		2: x = base_room.position.x - corridor_length - w; y = base_center.y - h / 2
		3: x = base_room.end.x + corridor_length; y = base_center.y - h / 2

	if x < 1 or y < 1 or x + w >= DUNGEON_WIDTH - 1 or y + h >= DUNGEON_HEIGHT - 1:
		return Rect2()
	
	return Rect2(x, y, w, h)

func _can_place_room(room: Rect2, existing_rooms: Array[Rect2]) -> bool:
	if room.position.x < 1 or room.position.y < 1:
		return false
	if room.end.x >= DUNGEON_WIDTH - 1 or room.end.y >= DUNGEON_HEIGHT - 1:
		return false

	for other in existing_rooms:
		if room.grow(6).intersects(other):
			return false
	return true

func _carve_room(room: Rect2):
	for y in range(room.position.y, room.position.y + room.size.y):
		for x in range(room.position.x, room.position.x + room.size.x):
			if is_in_bounds(x, y):
				dungeon_grid[y][x] = TileType.FLOOR

# --------------------------------------------------
# ROOM COUNT (5–8)
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
		RoomSize.SMALL_START: return Vector2i(randi_range(14,18), randi_range(12,16))
		RoomSize.MEDIUM_LARGE: return Vector2i(randi_range(22,30), randi_range(20,26))
		RoomSize.LARGE_BOSS: return Vector2i(randi_range(30,42), randi_range(26,34))
	return Vector2i(26,22)

# --------------------------------------------------
# CORRIDORS
# --------------------------------------------------
func carve_corridor(from: Vector2, to: Vector2, width: int = 6):
	var half_width = width / 2
	if randf() < 0.5:
		for x in range(min(from.x, to.x), max(from.x, to.x)+1):
			for offset in range(-half_width, half_width+1):
				var y = int(from.y + offset)
				if is_in_bounds(x, y):
					dungeon_grid[y][x] = TileType.FLOOR
		for y in range(min(from.y, to.y), max(from.y, to.y)+1):
			for offset in range(-half_width, half_width+1):
				var x = int(to.x + offset)
				if is_in_bounds(x, y):
					dungeon_grid[y][x] = TileType.FLOOR
	else:
		for y in range(min(from.y, to.y), max(from.y, to.y)+1):
			for offset in range(-half_width, half_width+1):
				var x = int(from.x + offset)
				if is_in_bounds(x, y):
					dungeon_grid[y][x] = TileType.FLOOR
		for x in range(min(from.x, to.x), max(from.x, to.x)+1):
			for offset in range(-half_width, half_width+1):
				var y = int(to.y + offset)
				if is_in_bounds(x, y):
					dungeon_grid[y][x] = TileType.FLOOR

# --------------------------------------------------
# BOUNDS
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
						if is_in_bounds(nx, ny) and dungeon_grid[ny][nx] == TileType.EMPTY:
							wall_positions.append(Vector2i(nx, ny))
	for pos in wall_positions:
		if dungeon_grid[pos.y][pos.x] == TileType.EMPTY:
			dungeon_grid[pos.y][pos.x] = TileType.WALL

# --------------------------------------------------
# RENDER
# --------------------------------------------------
func render_dungeon():
	tilemap.clear()
	var floor_tiles = [Vector2i(1,5), Vector2i(5,5)]
	var wall_tiles = [Vector2i(3,2), Vector2i(2,2), Vector2i(4,2)]

	for y in range(DUNGEON_HEIGHT):
		for x in range(DUNGEON_WIDTH):
			match dungeon_grid[y][x]:
				TileType.FLOOR:
					tilemap.set_cell(Vector2i(x, y), 0, floor_tiles[randi() % floor_tiles.size()])
				TileType.WALL:
					tilemap.set_cell(Vector2i(x, y), 0, wall_tiles[randi() % wall_tiles.size()])

# --------------------------------------------------
# CREATE
# --------------------------------------------------
func create_dungeon():
	all_rooms = generate_dungeon()
	end_room = all_rooms[all_rooms.size()-1]
	place_player(all_rooms)
	add_walls()
	render_dungeon()
	weapon_place(all_rooms)
	place_statues(all_rooms)
	
	for i in range(1, all_rooms.size()):
		create_room_trigger(all_rooms[i], i)

# --------------------------------------------------
# STATUES
# --------------------------------------------------
func place_statues(rooms: Array[Rect2]):
	if statue_scenes.is_empty():
		return
	
	# 50% chance a statue spawns this stage at all
	if randf() > 0.5:
		print("No statue this stage!")
		return
	
	# Pick a random room, skip room 0 (spawn) and last room (boss)
	var eligible_rooms = rooms.slice(1, rooms.size() - 1)
	if eligible_rooms.is_empty():
		return
	
	var chosen_room = eligible_rooms[randi() % eligible_rooms.size()]
	
	# Pick a random statue scene from your array
	var scene = statue_scenes[randi() % statue_scenes.size()]
	var statue = scene.instantiate()
	
	statue.position = chosen_room.get_center() * 16
	add_child(statue)
	
	print("Statue spawned in room at: ", chosen_room.get_center())

# --------------------------------------------------
# SPAWN EFFECT
# --------------------------------------------------
func create_spawn_effect(pos: Vector2):
	# --- Main burst ---
	var particles = CPUParticles2D.new()
	add_child(particles)
	particles.position = pos
	
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 8.0
	
	particles.amount = 28
	particles.lifetime = 0.9
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 90.0
	particles.gravity = Vector2(0, 150)
	
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 5.0
	
	particles.color = Color(0.55, 0.35, 0.75, 1.0)  # Mid purple matching floor
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.15, 0.0, 0.25, 1.0))  # Very dark purple core
	gradient.add_point(0.5, Color(0.35, 0.1, 0.5, 0.8))   # Mid dark purple
	gradient.add_point(1.0, Color(0.5, 0.3, 0.7, 0.0))    # Fade out to lighter
	particles.color_ramp = gradient
	
	particles.color_ramp = gradient
	particles.texture = null
	particles.emitting = true
	
	# --- Secondary burst ---
	var particles2 = CPUParticles2D.new()
	add_child(particles2)
	particles2.position = pos
	particles2.amount = 10
	particles2.lifetime = 0.5
	particles2.one_shot = true
	particles2.explosiveness = 1.0
	particles2.spread = 180.0
	particles2.initial_velocity_min = 20.0
	particles2.initial_velocity_max = 35.0
	particles2.scale_amount_min = 4.0
	particles2.scale_amount_max = 8.0
	particles2.gravity = Vector2(0, 200)
	
	particles2.color = Color(0.2, 0.05, 0.3, 1.0)  # Lighter purple accent
	
	var gradient2 = Gradient.new()
	gradient2.add_point(0.0, Color(0.8, 0.6, 1.0, 1.0))   # Light lavender burst
	gradient2.add_point(0.3, Color(0.45, 0.25, 0.65, 0.9)) # Deep dungeon purple
	gradient2.add_point(1.0, Color(0.2, 0.1, 0.3, 0.0))
	particles2.color_ramp = gradient2
	particles2.texture = null
	particles2.emitting = true
	
	# Cleanup
	var cleanup_timer = get_tree().create_timer(1.2)
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(particles): particles.queue_free()
		if is_instance_valid(particles2): particles2.queue_free()
	)
# --------------------------------------------------
# Weapon 
# --------------------------------------------------
func weapon_place(rooms : Array[Rect2]):
	if rooms.is_empty():
		return
	var spawn_room = rooms[0]
	var base_pos = spawn_room.get_center() * 16
	var offset = Vector2(50, 25)
	weapon.position = base_pos + offset

# --------------------------------------------------
# PLAYER SPAWN
# --------------------------------------------------
func place_player(rooms : Array[Rect2]):
	if rooms.is_empty():
		return
	var spawn_room = rooms[0]
	player.position = spawn_room.get_center() * 16
