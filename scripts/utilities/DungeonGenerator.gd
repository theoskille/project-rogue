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
	var enemy_id: String = ""  # ID from EnemyDatabase
	
	func _init(room_id: int, room_type: RoomType):
		id = room_id
		type = room_type

static func generate_dungeon(num_rooms: int = 12) -> Dictionary:
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
	
	# Generate maze using depth-first search with controlled branching
	var maze_positions = generate_organic_maze(start_pos, num_rooms, grid_size)
	
	# Create rooms for each maze position
	for i in range(1, min(maze_positions.size(), num_rooms)):
		var pos = maze_positions[i]
		var room_type = determine_room_type(i, maze_positions.size())
		
		var room = Room.new(room_id, room_type)
		room.position = pos
		
		# Assign enemy based on room type
		match room_type:
			RoomType.COMBAT:
				room.enemy_id = EnemyDatabase.get_random_enemy()
			RoomType.BOSS:
				room.enemy_id = EnemyDatabase.get_random_boss()
			RoomType.EMPTY:
				room.enemy_id = ""  # No enemy for empty rooms
		
		rooms[room_id] = room
		positions_used.append(pos)
		room_id += 1
	
	# Create minimal connections for maze-like feel
	create_minimal_connections(rooms)
	
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

static func generate_organic_maze(start_pos: Vector2, num_rooms: int, grid_size: int) -> Array[Vector2]:
	var positions: Array[Vector2] = [start_pos]
	var visited_positions = {start_pos: true}
	var stack: Array[Vector2] = [start_pos]
	
	# Directions: up, right, down, left
	var directions = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	
	while positions.size() < num_rooms and stack.size() > 0:
		var current_pos = stack[stack.size() - 1]
		var valid_directions: Array[Vector2] = []
		
		# Find valid directions from current position
		for direction in directions:
			var new_pos = current_pos + direction
			
			# Check if position is within grid bounds and not already used
			if is_valid_position(new_pos, grid_size) and new_pos not in visited_positions:
				valid_directions.append(new_pos)
		
		if valid_directions.size() > 0:
			# Choose a random valid direction (with bias towards continuing current path)
			var next_pos: Vector2
			if randf() < 0.7 and positions.size() < num_rooms * 0.8:  # 70% chance to continue path
				next_pos = valid_directions[randi() % valid_directions.size()]
			else:
				# Create a branch or dead end
				next_pos = valid_directions[randi() % valid_directions.size()]
			
			positions.append(next_pos)
			visited_positions[next_pos] = true
			stack.append(next_pos)
		else:
			# Backtrack
			stack.pop_back()
	
	# If we didn't generate enough rooms, add some dead ends and branches
	while positions.size() < num_rooms:
		var added_rooms = add_branches_and_dead_ends(positions, visited_positions, grid_size, num_rooms - positions.size())
		if added_rooms == 0:
			break
	
	return positions

static func add_branches_and_dead_ends(positions: Array[Vector2], visited_positions: Dictionary, grid_size: int, max_to_add: int) -> int:
	var added = 0
	var directions = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	
	# Try to add branches from existing rooms
	for pos in positions:
		if added >= max_to_add:
			break
			
		for direction in directions:
			if added >= max_to_add:
				break
				
			var new_pos = pos + direction
			if is_valid_position(new_pos, grid_size) and new_pos not in visited_positions:
				positions.append(new_pos)
				visited_positions[new_pos] = true
				added += 1
				
				# 50% chance to add another room in the same direction (creating longer branches)
				if randf() < 0.5:
					var branch_pos = new_pos + direction
					if is_valid_position(branch_pos, grid_size) and branch_pos not in visited_positions and added < max_to_add:
						positions.append(branch_pos)
						visited_positions[branch_pos] = true
						added += 1
	
	return added

static func determine_room_type(room_index: int, total_rooms: int) -> RoomType:
	# Create more variety in room types
	var ratio = float(room_index) / float(total_rooms)
	
	if ratio < 0.2:  # First 20% - mostly empty rooms
		return RoomType.EMPTY if randf() < 0.7 else RoomType.COMBAT
	elif ratio < 0.8:  # Middle 60% - mix of combat and empty
		return RoomType.COMBAT if randf() < 0.8 else RoomType.EMPTY
	else:  # Last 20% - mostly combat, with boss at the end
		return RoomType.BOSS if room_index == total_rooms - 1 else RoomType.COMBAT

static func create_minimal_connections(rooms: Dictionary):
	# Create a tree-like structure with minimal connections
	var directions = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	var connected_rooms = {0: true}  # Start with the starting room
	var unconnected_rooms = {}
	
	# Initialize unconnected rooms
	for room_id in rooms.keys():
		if room_id != 0:
			unconnected_rooms[room_id] = rooms[room_id]
	
	# Connect rooms one by one to create a tree
	while unconnected_rooms.size() > 0:
		var room_to_connect = -1
		var room_to_connect_to = -1
		var min_distance = INF
		
		# Find the closest unconnected room to any connected room
		for unconnected_id in unconnected_rooms.keys():
			var unconnected_room = unconnected_rooms[unconnected_id]
			
			for connected_id in connected_rooms.keys():
				var connected_room = rooms[connected_id]
				var distance = unconnected_room.position.distance_to(connected_room.position)
				
				# Prefer adjacent rooms, but allow some longer connections for variety
				if distance <= 1.5 and distance < min_distance:  # Allow diagonal-like connections
					min_distance = distance
					room_to_connect = unconnected_id
					room_to_connect_to = connected_id
		
		# If no adjacent room found, find the closest one
		if room_to_connect == -1:
			for unconnected_id in unconnected_rooms.keys():
				var unconnected_room = unconnected_rooms[unconnected_id]
				
				for connected_id in connected_rooms.keys():
					var connected_room = rooms[connected_id]
					var distance = unconnected_room.position.distance_to(connected_room.position)
					
					if distance < min_distance:
						min_distance = distance
						room_to_connect = unconnected_id
						room_to_connect_to = connected_id
		
		# Connect the room
		if room_to_connect != -1:
			rooms[room_to_connect].connections.append(room_to_connect_to)
			rooms[room_to_connect_to].connections.append(room_to_connect)
			connected_rooms[room_to_connect] = true
			unconnected_rooms.erase(room_to_connect)
		else:
			break  # Safety break

static func is_valid_position(pos: Vector2, grid_size: int) -> bool:
	return pos.x >= 0 and pos.x < grid_size and pos.y >= 0 and pos.y < grid_size

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

static func get_enemy_for_room(room_id: int, rooms: Dictionary) -> Enemy:
	if rooms.has(room_id):
		var room = rooms[room_id]
		if room.enemy_id != "":
			return EnemyDatabase.create_enemy(room.enemy_id)
	
	# Fallback to random enemy
	return EnemyDatabase.create_enemy(EnemyDatabase.get_random_enemy())

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

# Helper function to get enemy name for a room
static func get_room_enemy_name(room_id: int, rooms: Dictionary) -> String:
	if rooms.has(room_id):
		var room = rooms[room_id]
		if room.enemy_id != "":
			var enemy_data = EnemyDatabase.get_enemy_data(room.enemy_id)
			return enemy_data["display_name"]
	return "No Enemy"
