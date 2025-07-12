class_name ExplorationManager
extends Control

var dungeon_data: Dictionary
var current_room_id: int = 0
var game_manager: Node

# UI elements
@onready var room_info_label: Label = $VBoxContainer/RoomInfo
@onready var connections_label: Label = $VBoxContainer/Connections
@onready var instructions_label: Label = $VBoxContainer/Instructions
@onready var dungeon_map: Control = $VBoxContainer/DungeonMap

# Map visualization
var room_nodes: Dictionary = {}
var room_size: Vector2 = Vector2(50, 50)
var room_spacing: Vector2 = Vector2(60, 60)
var player_icon: Control
var connection_lines: Array = []

func _ready():
	game_manager = get_parent()
	generate_new_dungeon()
	create_visual_map()
	update_ui()
	
	# Set up instructions
	instructions_label.text = "WASD: Navigate, SPACE: Enter room, E: Inventory, R: Regenerate dungeon"

func generate_new_dungeon():
	# You can change the number of rooms here
	dungeon_data = DungeonGenerator.generate_dungeon(12)
	current_room_id = dungeon_data["start_room"]

func create_visual_map():
	# Clear existing map
	clear_map()
	
	# Calculate room positions for display
	var room_positions = calculate_room_positions()
	
	# Create visual nodes for each room
	for room_id in dungeon_data["rooms"].keys():
		var room = dungeon_data["rooms"][room_id]
		var room_node = create_room_node(room_id, room, room_positions[room_id])
		room_nodes[room_id] = room_node
		dungeon_map.add_child(room_node)
	
	# Draw connections between rooms
	draw_room_connections()
	
	# Create player icon
	create_player_icon()

func clear_map():
	# Remove existing room nodes
	for room_node in room_nodes.values():
		if room_node and is_instance_valid(room_node):
			room_node.queue_free()
	room_nodes.clear()
	
	# Clear connection lines
	for line in connection_lines:
		if line and is_instance_valid(line):
			line.queue_free()
	connection_lines.clear()
	
	# Remove player icon
	if player_icon and is_instance_valid(player_icon):
		player_icon.queue_free()
	player_icon = null

func calculate_room_positions() -> Dictionary:
	var positions = {}
	
	# Use the grid positions from the Room objects, scaled for display
	var scale_factor = room_spacing
	var offset = Vector2(50, 50)
	
	for room_id in dungeon_data["rooms"].keys():
		var room = dungeon_data["rooms"][room_id]
		positions[room_id] = offset + (room.position * scale_factor)
	
	return positions

func create_room_node(room_id: int, room_data, position: Vector2) -> Control:
	var room_node = ColorRect.new()
	room_node.size = room_size
	room_node.position = position
	
	# Set color based on room type
	match room_data.type:
		DungeonGenerator.RoomType.EMPTY:
			room_node.color = Color.LIGHT_GRAY
		DungeonGenerator.RoomType.COMBAT:
			room_node.color = Color.RED if not room_data.cleared else Color.DARK_RED
		DungeonGenerator.RoomType.BOSS:
			room_node.color = Color.PURPLE if not room_data.cleared else Color.DIM_GRAY
	
	# Add room ID label
	var label = Label.new()
	label.text = str(room_id)
	label.position = Vector2(5, 5)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 12)
	room_node.add_child(label)
	
	# Add room type indicator
	var type_label = Label.new()
	type_label.text = get_room_type_short_name(room_data.type)
	type_label.position = Vector2(5, 25)
	type_label.add_theme_color_override("font_color", Color.WHITE)
	type_label.add_theme_font_size_override("font_size", 10)
	room_node.add_child(type_label)
	
	# Add visited indicator
	if room_data.visited:
		var visited_indicator = ColorRect.new()
		visited_indicator.size = Vector2(8, 8)
		visited_indicator.position = Vector2(room_size.x - 12, 4)
		visited_indicator.color = Color.GREEN
		room_node.add_child(visited_indicator)
	
	return room_node

func get_room_type_short_name(room_type: DungeonGenerator.RoomType) -> String:
	match room_type:
		DungeonGenerator.RoomType.EMPTY:
			return "Start"
		DungeonGenerator.RoomType.COMBAT:
			return "Combat"
		DungeonGenerator.RoomType.BOSS:
			return "Boss"
		_:
			return "?"

func draw_room_connections():
	# Draw lines between connected rooms
	for room_id in dungeon_data["rooms"].keys():
		var room = dungeon_data["rooms"][room_id]
		var room_node = room_nodes[room_id]
		
		for connected_id in room.connections:
			# Only draw each connection once (avoid duplicate lines)
			if connected_id > room_id and connected_id in room_nodes:
				var connected_node = room_nodes[connected_id]
				var line = create_connection_line(room_node, connected_node)
				dungeon_map.add_child(line)
				connection_lines.append(line)

func create_connection_line(from_node: Control, to_node: Control) -> Line2D:
	var line = Line2D.new()
	var from_center = from_node.position + from_node.size / 2
	var to_center = to_node.position + to_node.size / 2
	
	line.add_point(from_center)
	line.add_point(to_center)
	line.width = 2
	line.default_color = Color.WHITE
	line.z_index = -1  # Behind room nodes
	
	return line

func create_player_icon():
	player_icon = ColorRect.new()
	player_icon.size = Vector2(20, 20)
	player_icon.color = Color.YELLOW
	player_icon.z_index = 1  # Above room nodes
	
	# Add a simple player symbol
	var player_label = Label.new()
	player_label.text = "P"
	player_label.position = Vector2(6, 2)
	player_label.add_theme_color_override("font_color", Color.BLACK)
	player_icon.add_child(player_label)
	
	dungeon_map.add_child(player_icon)
	update_player_icon_position()

func update_player_icon_position():
	if player_icon and current_room_id in room_nodes:
		var room_node = room_nodes[current_room_id]
		var room_center = room_node.position + room_node.size / 2
		player_icon.position = room_center - player_icon.size / 2

func handle_input(event: InputEvent):
	if not event.is_pressed():
		return
		
	if event is InputEventKey:
		match event.keycode:
			KEY_W, KEY_UP:
				try_move_direction(Vector2(0, -1))  # Up
			KEY_S, KEY_DOWN:
				try_move_direction(Vector2(0, 1))   # Down
			KEY_A, KEY_LEFT:
				try_move_direction(Vector2(-1, 0))  # Left
			KEY_D, KEY_RIGHT:
				try_move_direction(Vector2(1, 0))   # Right
			KEY_SPACE:
				enter_current_room()
			KEY_R:
				regenerate_dungeon()

func try_move_direction(direction: Vector2):
	var current_room = dungeon_data["rooms"][current_room_id]
	var target_position = current_room.position + direction
	
	# Find room at target position
	for connection_id in current_room.connections:
		var connected_room = dungeon_data["rooms"][connection_id]
		if connected_room.position == target_position:
			move_to_room(connection_id)
			return
	
	# No room found in that direction
	print("No room in that direction")

func move_to_room(room_id: int):
	current_room_id = room_id
	var room = dungeon_data["rooms"][room_id]
	room.visited = true
	
	# Update visual representation
	update_room_visual(room_id)
	update_player_icon_position()
	update_ui()

func update_room_visual(room_id: int):
	if room_id in room_nodes:
		var room_node = room_nodes[room_id]
		var room = dungeon_data["rooms"][room_id]
		
		# Update room color if cleared
		if room.cleared:
			match room.type:
				DungeonGenerator.RoomType.COMBAT:
					room_node.color = Color.DARK_RED
				DungeonGenerator.RoomType.BOSS:
					room_node.color = Color.DIM_GRAY
		
		# Add visited indicator if not already present
		if room.visited and not has_visited_indicator(room_node):
			var visited_indicator = ColorRect.new()
			visited_indicator.size = Vector2(8, 8)
			visited_indicator.position = Vector2(room_size.x - 12, 4)
			visited_indicator.color = Color.GREEN
			room_node.add_child(visited_indicator)

func has_visited_indicator(room_node: Control) -> bool:
	for child in room_node.get_children():
		if child is ColorRect and child.color == Color.GREEN:
			return true
	return false

func regenerate_dungeon():
	generate_new_dungeon()
	create_visual_map()
	update_ui()
	print("New maze dungeon generated!")

func enter_current_room():
	var current_room = dungeon_data["rooms"][current_room_id]
	
	match current_room.type:
		DungeonGenerator.RoomType.EMPTY:
			print("Starting room - safe area")
			current_room.cleared = true
		DungeonGenerator.RoomType.COMBAT:
			if not current_room.cleared:
				start_combat()
			else:
				print("Room already cleared")
		DungeonGenerator.RoomType.BOSS:
			if not current_room.cleared:
				start_boss_fight()
			else:
				print("Boss already defeated!")
	
	update_room_visual(current_room_id)
	update_ui()

func start_combat():
	var enemy = DungeonGenerator.get_enemy_for_room()
	game_manager.start_combat(enemy)

func start_boss_fight():
	var boss = Enemy.new("Boss Orc")
	boss.stats = {"STR": 18, "INT": 8, "SPD": 6, "DEX": 10, "CON": 25, "DEF": 14, "LCK": 8}
	boss.max_hp = boss.stats["CON"] * 3
	boss.current_hp = boss.max_hp
	boss.attacks = ["Mighty Swing", "Roar", "Charge"]
	game_manager.start_combat(boss)

func room_cleared():
	# Called when returning from successful combat
	var current_room = dungeon_data["rooms"][current_room_id]
	current_room.cleared = true
	update_room_visual(current_room_id)
	update_ui()

func update_ui():
	var current_room = dungeon_data["rooms"][current_room_id]
	
	# Room info
	var room_type_text = DungeonGenerator.get_room_type_name(current_room.type)
	if current_room.cleared:
		room_type_text += " (Cleared)"
	
	room_info_label.text = "Current Room: %d - %s" % [current_room_id, room_type_text]
	
	# Show available directions
	var directions_text = "Available directions: "
	var available_directions = []
	
	var current_pos = current_room.position
	for connection_id in current_room.connections:
		var connected_room = dungeon_data["rooms"][connection_id]
		var direction_vector = connected_room.position - current_pos
		
		if direction_vector == Vector2(0, -1):
			available_directions.append("W(Up)")
		elif direction_vector == Vector2(0, 1):
			available_directions.append("S(Down)")
		elif direction_vector == Vector2(-1, 0):
			available_directions.append("A(Left)")
		elif direction_vector == Vector2(1, 0):
			available_directions.append("D(Right)")
	
	if available_directions.size() > 0:
		directions_text += ", ".join(available_directions)
	else:
		directions_text += "None"
	
	connections_label.text = directions_text
