extends Node2D

@export var tilemap : TileMapLayer
@export var player : CharacterBody2D
@export var weapon : Node2D
@export var enemy_scenes : Array[PackedScene]
@export var statue_scenes : Array[PackedScene]
@export var chest_scenes : Array[PackedScene] = []
@export var portal : Node2D
@export var floor_transition : CanvasLayer
@export var minimap : Control
@export var boss_scenes : Array[PackedScene] = []
@export var box_scenes : Array[PackedScene] = []
@export var min_boxes_per_room : int = 3
@export var max_boxes_per_room : int = 8
@export var campfire_scene : PackedScene
@export var slime_scene : PackedScene
@export var apple_scene : PackedScene
@export var cookie_crumble_scene : PackedScene
@export var altar_shop_scene : PackedScene

const DUNGEON_WIDTH = 800
const DUNGEON_HEIGHT = 800
const MIN_CORRIDOR_LENGTH = 18
const MAX_CORRIDOR_LENGTH = 64

enum TileType { EMPTY, FLOOR, WALL }
enum RoomSize { SMALL_START, MEDIUM_LARGE, LARGE_BOSS }

var dungeon_grid = []
var all_rooms : Array[Rect2] = []
var end_room : Rect2
var room_wave_data = {}
var room_barriers = {}
var boss_ref : Node = null
var statue_room_index : int = -1
var campfire_room_index : int = -1
var altar_shop_room_index : int = -1

# --------------------------------------------------
# READY
# --------------------------------------------------
func _ready():
	if portal:
		portal.visible = false
	create_dungeon()

	if GameData.floor >= 1:
		GameData.restore_to_player_state(player.get_node("/root/PlayerState"), player)

	if floor_transition:
		floor_transition.fade_in_on_start()

# --------------------------------------------------
# PROCESS
# --------------------------------------------------
func _process(_delta):
	for room_index in room_wave_data.keys().duplicate():
		check_wave_complete(room_index)

# --------------------------------------------------
# CREATE ROOM TRIGGER
# --------------------------------------------------
func create_room_trigger(room: Rect2, room_index: int):
	if room_index == statue_room_index:
		print("Skipping room trigger for statue room ", room_index)
		return
	if room_index == campfire_room_index:
		print("Skipping room trigger for campfire room ", room_index)
		return
	if room_index == altar_shop_room_index:
		print("Skipping room trigger for altar shop room ", room_index)
		return

	var area = Area2D.new()
	area.name = "RoomTrigger_" + str(room_index)

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(room.size.x * 16 * 0.5, room.size.y * 16 * 0.5)
	collision.shape = shape
	area.position = room.get_center() * 16
	area.collision_layer = 0
	area.collision_mask = 2

	var callable = func(body):
		if body == player:
			var is_boss_room = (room_index == all_rooms.size() - 1 and GameData.floor % 5 == 0)

			if is_boss_room:
				if not room_wave_data.has(room_index):
					room_wave_data[room_index] = {
						"room": end_room,
						"total_waves": 1,
						"current_wave": 1,
						"enemies_per_wave": 1,
						"active_enemies": [],
						"is_spawning": true
					}
					close_room_exits(room, room_index)
					_spawn_boss(room_index)
					print("Boss room entered — spawning boss and closing exits")
			else:
				spawn_enemies_in_room(room, room_index)
				close_room_exits(room, room_index)

			if minimap:
				minimap.visit_room(room_index)
			area.queue_free()

	area.body_entered.connect(callable, CONNECT_ONE_SHOT)
	collision.set_deferred("disabled", false)
	area.add_child(collision)
	add_child(area)

# --------------------------------------------------
# SPAWN BOSS
# --------------------------------------------------
func _spawn_boss(room_index: int):
	if boss_scenes.is_empty():
		if room_wave_data.has(room_index):
			room_wave_data[room_index].is_spawning = false
		return

	var scene = boss_scenes[randi() % boss_scenes.size()]
	var boss = scene.instantiate()
	var spawn_pos = end_room.get_center() * 16
	boss.position = spawn_pos
	boss.visible = false
	add_child(boss)
	boss_ref = boss
	create_spawn_effect(spawn_pos)
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(boss) and room_wave_data.has(room_index):
		boss.visible = true
		room_wave_data[room_index].active_enemies.append(boss)
		room_wave_data[room_index].is_spawning = false
		print("Boss added to active_enemies for room ", room_index)

# --------------------------------------------------
# ROOM EXIT BLOCKING
# --------------------------------------------------
func close_room_exits(room: Rect2, room_index: int):
	if room_barriers.has(room_index):
		return

	var barrier_positions = []
	var barrier_tile = Vector2i(3, 2)

	for x in range(room.position.x - 1, room.end.x + 1):
		var top_y = int(room.position.y) - 1
		if is_in_bounds(x, top_y) and dungeon_grid[top_y][x] == TileType.FLOOR:
			var barrier_pos = Vector2i(x, top_y)
			barrier_positions.append(barrier_pos)
			tilemap.set_cell(barrier_pos, 0, barrier_tile)

		var bottom_y = int(room.end.y)
		if is_in_bounds(x, bottom_y) and dungeon_grid[bottom_y][x] == TileType.FLOOR:
			var barrier_pos = Vector2i(x, bottom_y)
			barrier_positions.append(barrier_pos)
			tilemap.set_cell(barrier_pos, 0, barrier_tile)

	for y in range(room.position.y - 1, room.end.y + 1):
		var left_x = int(room.position.x) - 1
		if is_in_bounds(left_x, y) and dungeon_grid[y][left_x] == TileType.FLOOR:
			var barrier_pos = Vector2i(left_x, y)
			barrier_positions.append(barrier_pos)
			tilemap.set_cell(barrier_pos, 0, barrier_tile)

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
		tilemap.set_cell(barrier_pos, 0, floor_tiles[randi() % floor_tiles.size()])

	print("Room ", room_index, " exits opened!")
	room_barriers.erase(room_index)

# --------------------------------------------------
# WAVE COMPLETION CHECK PER ROOM
# --------------------------------------------------
func check_wave_complete(room_index: int):
	if not room_wave_data.has(room_index):
		return
	if room_index >= all_rooms.size():
		return

	var data = room_wave_data[room_index]
	if data.is_spawning:
		return

	data.active_enemies = data.active_enemies.filter(func(enemy): return is_instance_valid(enemy))

	if not data.active_enemies.is_empty():
		return

	if data.current_wave < data.total_waves:
		print("Room ", room_index, " - Wave ", data.current_wave, " complete! Spawning wave ", data.current_wave + 1, "...")
		data.current_wave += 1
		spawn_wave(data.room, data.enemies_per_wave, data.current_wave, room_index)
		return

	print("Room ", room_index, " - All waves complete!")
	open_room_exits(room_index)

	if room_index < all_rooms.size() and all_rooms[room_index] == end_room:
		activate_portal()
	else:
		spawn_chest_in_room(all_rooms[room_index])

	room_wave_data.erase(room_index)

# --------------------------------------------------
# SPAWN CHEST AFTER WAVE CLEAR
# --------------------------------------------------
func spawn_chest_in_room(room: Rect2):
	if chest_scenes.is_empty():
		return
	var scene = chest_scenes[randi() % chest_scenes.size()]
	var chest = scene.instantiate()
	chest.position = room.get_center() * 16
	add_child(chest)
	print("Chest spawned after wave clear!")

# --------------------------------------------------
# SPAWN ENEMIES IN A SPECIFIC ROOM
# --------------------------------------------------
func spawn_enemies_in_room(room: Rect2, room_index: int):
	print("Room ", room_index, " triggered!")
	var total_waves = randi_range(2, 4)
	var enemies_per_wave = randi_range(2, 4)

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

	create_spawn_effect(spawn_pos)

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

	if minimap:
		minimap.portal_active = true

	portal.body_entered.connect(_on_portal_entered, CONNECT_ONE_SHOT)

func _on_portal_entered(body):
	if body != player:
		return

	print("Saving and transitioning to floor ", GameData.floor + 1)
	GameData.save_from_player_state(player.get_node("/root/PlayerState"), player)
	GameData.floor += 1

	if floor_transition:
		floor_transition.start_transition()
	else:
		print("ERROR: floor_transition is null!")

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

	var first_room = _create_spawn_room_corner()
	rooms.append(first_room)
	_carve_room(first_room)

	while rooms.size() < target_room_count and tries < max_attempts:
		var base_room = rooms.pick_random()
		var direction = randi() % 4
		var corridor_length = randi_range(MIN_CORRIDOR_LENGTH, MAX_CORRIDOR_LENGTH)
		var new_room = _create_room_with_corridor(base_room, direction, corridor_length)

		if new_room.has_area() and _can_place_room(new_room, rooms):
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
# ROOM COUNT (5-8)
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
		RoomSize.SMALL_START:  return Vector2i(randi_range(14,18), randi_range(12,16))
		RoomSize.MEDIUM_LARGE: return Vector2i(randi_range(22,30), randi_range(20,26))
		RoomSize.LARGE_BOSS:   return Vector2i(randi_range(30,42), randi_range(26,34))
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
	var wall_tiles  = [Vector2i(3,2), Vector2i(2,2), Vector2i(4,2)]

	for y in range(DUNGEON_HEIGHT):
		for x in range(DUNGEON_WIDTH):
			match dungeon_grid[y][x]:
				TileType.FLOOR:
					tilemap.set_cell(Vector2i(x, y), 0, floor_tiles[randi() % floor_tiles.size()])
				TileType.WALL:
					tilemap.set_cell(Vector2i(x, y), 0, wall_tiles[randi() % wall_tiles.size()])

# --------------------------------------------------
# BOXES
# --------------------------------------------------
func place_boxes(rooms: Array[Rect2]):
	if box_scenes.is_empty():
		return

	for i in range(1, rooms.size() - 1):
		if i == statue_room_index:
			continue
		if i == campfire_room_index:
			continue
		if i == altar_shop_room_index:
			continue

		var room = rooms[i]
		var box_count = randi_range(min_boxes_per_room, max_boxes_per_room)

		var cluster_count = randi_range(1, 2)
		var clusters = []
		var margin = 4
		for c in range(cluster_count):
			clusters.append(Vector2(
				randi_range(int(room.position.x) + margin, int(room.end.x) - margin),
				randi_range(int(room.position.y) + margin, int(room.end.y) - margin)
			))

		var placed_positions : Array = []
		var min_distance = 16.0
		var spread = 2
		var max_attempts = 20

		for j in range(box_count):
			var cluster = clusters[randi() % clusters.size()]
			var placed = false

			for attempt in range(max_attempts):
				var tx = clamp(
					cluster.x + randi_range(-spread, spread),
					int(room.position.x) + 2,
					int(room.end.x) - 2
				)
				var ty = clamp(
					cluster.y + randi_range(-spread, spread),
					int(room.position.y) + 2,
					int(room.end.y) - 2
				)
				var candidate = Vector2(tx, ty) * 16

				var too_close = false
				for existing in placed_positions:
					if candidate.distance_to(existing) < min_distance:
						too_close = true
						break

				if not too_close:
					placed_positions.append(candidate)
					var box_scene = _roll_box_type()
					var box = box_scene.instantiate()
					box.position = candidate
					add_child(box)
					placed = true
					break

func _roll_box_type() -> PackedScene:
	if box_scenes.size() == 1:
		return box_scenes[0]
	var roll = randf()
	if roll < 0.70:
		return box_scenes[0]
	elif roll < 0.85:
		return box_scenes[1]
	else:
		return box_scenes[2]

# --------------------------------------------------
# CAMPFIRE
# --------------------------------------------------
func place_campfire(rooms: Array[Rect2]):
	if randf() > 0.5:
		print("No campfire this floor!")
		return
	if campfire_scene == null:
		print("No campfire scene assigned!")
		return

	var eligible_rooms = rooms.slice(1, rooms.size() - 1)
	if eligible_rooms.is_empty():
		return

	var available = eligible_rooms.filter(func(r):
		return rooms.find(r) != statue_room_index
	)
	if available.is_empty():
		return

	var chosen_room = available[randi() % available.size()]
	campfire_room_index = rooms.find(chosen_room)

	var campfire = campfire_scene.instantiate()
	campfire.position = chosen_room.get_center() * 16
	add_child(campfire)

	if minimap:
		minimap.set_campfire_room(campfire_room_index)

	print("Campfire spawned in room index: ", campfire_room_index)
	_spawn_campfire_ingredients(chosen_room)

func _spawn_campfire_ingredients(room: Rect2):
	var ingredient_scenes = [slime_scene, apple_scene, cookie_crumble_scene]
	for scene in ingredient_scenes:
		if scene == null:
			continue
		var count = randi_range(1, 2)
		for i in range(count):
			var item = scene.instantiate()
			var margin = 3
			var x = randi_range(int(room.position.x) + margin, int(room.end.x) - margin) * 16
			var y = randi_range(int(room.position.y) + margin, int(room.end.y) - margin) * 16
			item.position = Vector2(x, y)
			add_child(item)

# --------------------------------------------------
# ALTAR SHOP
# --------------------------------------------------
func place_altar_shop(rooms: Array[Rect2]):
	if altar_shop_scene == null:
		print("No altar shop scene assigned!")
		return
	if randf() > 0.6:
		print("No altar shop this floor!")
		return

	var eligible_rooms = rooms.slice(1, rooms.size() - 1)
	if eligible_rooms.is_empty():
		return

	var available = eligible_rooms.filter(func(r):
		var idx = rooms.find(r)
		return idx != statue_room_index and idx != campfire_room_index
	)
	if available.is_empty():
		return

	var chosen_room = available[randi() % available.size()]
	altar_shop_room_index = rooms.find(chosen_room)

	# Spawn 3 altars in the room
	var num_altars = 3
	var positions = _get_altar_positions(chosen_room, num_altars)
	
	for pos in positions:
		var altar = altar_shop_scene.instantiate()
		altar.position = pos
		add_child(altar)

	print("Altar shop spawned in room index: ", altar_shop_room_index, " with ", num_altars, " altars")

	if minimap:
		minimap.set_altar_shop_room(altar_shop_room_index)

func _get_altar_positions(room: Rect2, count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var room_center = room.get_center() * 16
	var spread = 100.0  # Distance between altars
	
	match count:
		1:
			positions.append(room_center)
		2:
			positions.append(room_center + Vector2(-spread/2, 0))
			positions.append(room_center + Vector2(spread/2, 0))
		3:
			positions.append(room_center + Vector2(-spread, 0))
			positions.append(room_center)
			positions.append(room_center + Vector2(spread, 0))
		_:
			# Default: spread around room
			for i in range(count):
				var angle = (TAU / count) * i
				var offset = Vector2(cos(angle), sin(angle)) * spread
				positions.append(room_center + offset)
	
	return positions

# --------------------------------------------------
# STATUES
# --------------------------------------------------
func place_statues(rooms: Array[Rect2]):
	if statue_scenes.is_empty():
		return
	if randf() > 0.5:
		print("No statue this floor!")
		return
	var eligible_rooms = rooms.slice(1, rooms.size() - 1)
	if eligible_rooms.is_empty():
		return
	var chosen_room = eligible_rooms[randi() % eligible_rooms.size()]
	var statue_index = rooms.find(chosen_room)
	statue_room_index = statue_index
	var scene = statue_scenes[randi() % statue_scenes.size()]
	var statue = scene.instantiate()
	statue.position = chosen_room.get_center() * 16
	add_child(statue)
	if minimap:
		minimap.set_statue_room(statue_index)
	print("Statue spawned in room index: ", statue_index)

# --------------------------------------------------
# SPAWN EFFECT
# --------------------------------------------------
func create_spawn_effect(pos: Vector2):
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
	particles.color = Color(0.55, 0.35, 0.75, 1.0)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.15, 0.0, 0.25, 1.0))
	gradient.add_point(0.5, Color(0.35, 0.1, 0.5, 0.8))
	gradient.add_point(1.0, Color(0.5, 0.3, 0.7, 0.0))
	particles.color_ramp = gradient
	particles.texture = null
	particles.emitting = true

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
	particles2.color = Color(0.2, 0.05, 0.3, 1.0)
	var gradient2 = Gradient.new()
	gradient2.add_point(0.0, Color(0.15, 0.0, 0.25, 1.0))
	gradient2.add_point(0.5, Color(0.35, 0.1, 0.5, 0.8))
	gradient2.add_point(1.0, Color(0.5, 0.3, 0.7, 0.0))
	particles2.color_ramp = gradient2
	particles2.texture = null
	particles2.emitting = true

	var cleanup_timer = get_tree().create_timer(1.2)
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(particles):  particles.queue_free()
		if is_instance_valid(particles2): particles2.queue_free()
	)

# --------------------------------------------------
# PLAYER SPAWN
# --------------------------------------------------
func place_player(rooms: Array[Rect2]):
	if rooms.is_empty():
		return
	var spawn_room = rooms[0]
	player.position = spawn_room.get_center() * 16

# --------------------------------------------------
# CREATE
# --------------------------------------------------
func create_dungeon():
	all_rooms = generate_dungeon()
	end_room = all_rooms[all_rooms.size()-1]
	place_player(all_rooms)
	add_walls()
	render_dungeon()
	place_statues(all_rooms)
	place_campfire(all_rooms)
	place_altar_shop(all_rooms)
	place_boxes(all_rooms)

	if minimap:
		minimap.dungeon_grid   = dungeon_grid
		minimap.all_rooms      = all_rooms
		minimap.end_room       = end_room
		minimap.player_ref     = player
		minimap.portal_ref     = portal
		minimap.dungeon_width  = DUNGEON_WIDTH
		minimap.dungeon_height = DUNGEON_HEIGHT
		minimap.setup_minimap()
		minimap.visit_room(0)

	for i in range(1, all_rooms.size()):
		create_room_trigger(all_rooms[i], i)