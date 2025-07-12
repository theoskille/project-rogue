class_name DungeonGenerator
extends RefCounted

enum RoomType {
	EMPTY,
	COMBAT,
	BOSS
}

class Room:
	var id: int
	var type: RoomType
	var connections: Array[int] = []
	var visited: bool = false
	var cleared: bool = false
	var position: Vector2
	
	func _init(room_id: int, room_type: RoomType):
		id = room_id
		type = room_type

static func generate_dungeon(num_rooms: int = 8) -> Dictionary:
	var rooms: Dictionary = {}
	var room_id = 0
	var grid_size = calculate_grid_size(num_rooms)
	var positions_used: Array[Vector2] = []
	
	# Create starting room at center of grid
	var start_pos = Vector2(grid_size / 2, grid_size / 2)
	var start_room = Room.new(room_id, RoomType.EMPTY)
	start_room.position = start_pos
	start_room.visited = true
	rooms[room_id] = start_room
	positions_used.append(start_pos)
	room_id += 1
	
	# Generate maze using recursive backtracking
	var maze_positions = generate_maze_positions(start_pos, num_rooms, grid_size)
	
	# Create rooms for each maze position
	for i in range(1, min(maze_positions.size(), num_rooms)):
		var pos = maze_positions[i]
		var room_type = RoomType.COMBAT  # Only combat rooms for now
		
		# Make the last room a boss room
		if i == num_rooms - 1:
			room_type = RoomType.BOSS
		
		var room = Room.new(room_id, room_type)
		room.position = pos
		rooms[room_id] = room
		positions_used.append(pos)
		room_id += 1
	
	# Connect adjacent rooms (only orthogonal connections)
	connect_adjacent_rooms(rooms)
	
	# Ensure there's a guaranteed path to the boss
	var boss_id = find_boss_room(rooms)
	ensure_path_connectivity(rooms, 0, boss_id)
	
	return {
		"rooms": rooms,
		"start_room": 0,
		"boss_room": boss_id,
		"current_room": 0
	}

static func calculate_grid_size(num_rooms: int) -> int:
	# Calculate a grid size that can accommodate the rooms with some spacing
	return max(int(ceil(sqrt(num_rooms * 2))), 5)

static func generate_maze_positions(start_pos: Vector2, num_rooms: int, grid_size: int) -> Array[Vector2]:
	var positions: Array[Vector2] = [start_pos]
	var available_positions: Array[Vector2] = []
	var current_pos = start_pos
	var visited_positions = {start_pos: true}
	
	# Directions: up, right, down, left
	var directions = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	
	while positions.size() < num_rooms:
		var valid_directions: Array[Vector2] = []
		
		# Find valid directions from current position
		for direction in directions:
			var new_pos = current_pos + direction
			
			# Check if position is within grid bounds and not already used
			if is_valid_position(new_pos, grid_size) and new_pos not in visited_positions:
				valid_directions.append(new_pos)
		
		if valid_directions.size() > 0:
			# Choose a random valid direction
			var next_pos = valid_directions[randi() % valid_directions.size()]
			positions.append(next_pos)
			visited_positions[next_pos] = true
			current_pos = next_pos
		else:
			# Backtrack: choose a random previous position that has available directions
			var backtrack_candidates: Array[Vector2] = []
			
			for pos in positions:
				for direction in directions:
					var test_pos = pos + direction
					if is_valid_position(test_pos, grid_size) and test_pos not in visited_positions:
						backtrack_candidates.append(pos)
						break
			
			if backtrack_candidates.size() > 0:
				current_pos = backtrack_candidates[randi() % backtrack_candidates.size()]
			else:
				# No more valid positions, fill remaining with adjacent positions
				break
	
	return positions

static func is_valid_position(pos: Vector2, grid_size: int) -> bool:
	return pos.x >= 0 and pos.x < grid_size and pos.y >= 0 and pos.y < grid_size

static func connect_adjacent_rooms(rooms: Dictionary):
	# Only connect rooms that are orthogonally adjacent (no diagonals)
	var directions = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	
	for room_id in rooms.keys():
		var room = rooms[room_id]
		
		for direction in directions:
			var adjacent_pos = room.position + direction
			var adjacent_room_id = find_room_at_position(rooms, adjacent_pos)
			
			if adjacent_room_id != -1 and adjacent_room_id not in room.connections:
				# Create bidirectional connection
				room.connections.append(adjacent_room_id)
				rooms[adjacent_room_id].connections.append(room_id)

static func find_room_at_position(rooms: Dictionary, position: Vector2) -> int:
	for room_id in rooms.keys():
		if rooms[room_id].position == position:
			return room_id
	return -1

static func find_boss_room(rooms: Dictionary) -> int:
	for room_id in rooms.keys():
		if rooms[room_id].type == RoomType.BOSS:
			return room_id
	return 0  # Fallback to start room if no boss found

static func ensure_path_connectivity(rooms: Dictionary, start_room: int, target_room: int):
	# Use BFS to check if target is reachable from start
	if not is_reachable(rooms, start_room, target_room):
		# Find the closest room to target and connect them
		connect_to_nearest_room(rooms, target_room, start_room)

static func is_reachable(rooms: Dictionary, start: int, target: int) -> bool:
	var visited = {}
	var queue = [start]
	visited[start] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		if current == target:
			return true
		
		var room = rooms[current]
		for connection in room.connections:
			if connection not in visited:
				visited[connection] = true
				queue.append(connection)
	
	return false

static func connect_to_nearest_room(rooms: Dictionary, isolated_room: int, connected_component_start: int):
	# Find all rooms in the connected component
	var connected_rooms = get_connected_component(rooms, connected_component_start)
	
	# Find the nearest room in the connected component
	var isolated_pos = rooms[isolated_room].position
	var min_distance = INF
	var nearest_room = -1
	
	for room_id in connected_rooms:
		var distance = isolated_pos.distance_to(rooms[room_id].position)
		if distance < min_distance:
			min_distance = distance
			nearest_room = room_id
	
	# Connect the isolated room to the nearest connected room
	if nearest_room != -1:
		rooms[isolated_room].connections.append(nearest_room)
		rooms[nearest_room].connections.append(isolated_room)

static func get_connected_component(rooms: Dictionary, start_room: int) -> Array:
	var component = []
	var visited = {}
	var queue = [start_room]
	visited[start_room] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		component.append(current)
		
		var room = rooms[current]
		for connection in room.connections:
			if connection not in visited:
				visited[connection] = true
				queue.append(connection)
	
	return component

static func get_enemy_for_room() -> Enemy:
	var enemy_types = ["Goblin", "Orc", "Skeleton", "Spider", "Wolf", "Bandit"]
	var random_type = enemy_types[randi() % enemy_types.size()]
	return Enemy.new(random_type)

# Helper function to get room type display name
static func get_room_type_name(room_type: RoomType) -> String:
	match room_type:
		RoomType.EMPTY:
			return "Empty Room"
		RoomType.COMBAT:
			return "Combat Room"
		RoomType.BOSS:
			return "Boss Room"
		_:
			return "Unknown Room"
