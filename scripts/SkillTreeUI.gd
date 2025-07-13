class_name SkillTreeUI
extends Control

# UI References
@onready var skill_points_label: Label = $"../SkillPointsLabel"  # Go up one level to find the label

# Visual settings
var node_size: Vector2 = Vector2(50, 50)  # Square nodes
var node_spacing: Vector2 = Vector2(80, 80)  # Grid spacing
var connection_width: float = 3.0
var node_color_unlocked: Color = Color.GREEN
var node_color_locked: Color = Color.GRAY
var node_color_unlockable: Color = Color.YELLOW
var node_color_selected: Color = Color.CYAN

# State
var player: Player
var skill_tree_database: SkillTreeDatabase
var selected_node_id: String = ""
var node_data: Dictionary = {}  # node_id -> {position, size, state, color, name}

# Store calculated positioning data
var calculated_center: Vector2 = Vector2.ZERO
var calculated_scale: float = 1.0
var calculated_spacing: Vector2 = Vector2.ZERO

func _ready():
	setup_ui()

func setup_ui():
	# Enable input processing for this control
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_player(p: Player):
	player = p
	skill_tree_database = p.skill_tree_database
	refresh_display()

func refresh_display():
	if not player or not skill_tree_database:
		print("SkillTreeUI: refresh_display - missing player or database")
		return
	
	print("SkillTreeUI: refresh_display called")
	update_skill_points_display()
	update_skill_tree_visual()

func update_skill_points_display():
	if not player or not skill_points_label:
		print("SkillTreeUI: update_skill_points_display - missing player or label")
		return
	
	skill_points_label.text = "Skill Points: %d" % player.skill_points
	print("SkillTreeUI: Updated skill points display")

func update_skill_tree_visual():
	if not player or not skill_tree_database:
		print("SkillTreeUI: Missing required references")
		return
	
	print("SkillTreeUI: update_skill_tree_visual called")
	
	# Clear existing node data
	node_data.clear()
	
	# Get tree bounds for positioning
	var bounds = skill_tree_database.get_tree_bounds()
	var tree_size = bounds.size
	
	# Get container size (our own size)
	var container_size = size
	print("SkillTreeUI: Container size = ", container_size, " Tree size = ", tree_size)
	
	# If container size is 0, try to get the parent's size as fallback
	if container_size.x <= 0 or container_size.y <= 0:
		container_size = get_parent().size
		print("SkillTreeUI: Using parent size as fallback: ", container_size)
		
		if container_size.x <= 0 or container_size.y <= 0:
			print("SkillTreeUI: Container still not ready, using default size")
			container_size = Vector2(600, 400)  # Taller default for branching layout
	
	# Calculate scaling to fit the tree in the container
	var scale_factor_x = (container_size.x * 0.8) / max(tree_size.x * node_spacing.x, 1.0)  # 80% of container width
	var scale_factor_y = (container_size.y * 0.8) / max(tree_size.y * node_spacing.y, 1.0)  # 80% of container height
	var scale_factor = min(scale_factor_x, scale_factor_y, 1.0)  # Don't scale up, only down
	
	# Set a minimum scale to prevent nodes from being too small
	scale_factor = max(scale_factor, 0.4)  # Minimum 40% scale
	
	# Store the calculated values for use in _draw()
	calculated_scale = scale_factor
	calculated_spacing = node_spacing * scale_factor
	
	print("SkillTreeUI: Scale factors - X: ", scale_factor_x, " Y: ", scale_factor_y, " Final: ", scale_factor)
	
	# Calculate adjusted spacing and node size
	var adjusted_spacing = node_spacing * scale_factor
	var adjusted_node_size = node_size * scale_factor
	
	# Calculate center position - properly center the tree
	var tree_width = tree_size.x * adjusted_spacing.x
	var tree_height = tree_size.y * adjusted_spacing.y
	var center_pos = Vector2(
		container_size.x / 2,
		container_size.y / 2
	)
	
	# Store the calculated center for use in _draw()
	calculated_center = center_pos
	
	print("SkillTreeUI: Creating nodes at center: ", center_pos, " Tree dimensions: ", Vector2(tree_width, tree_height))
	
	# Create node data for all skills
	var node_count = 0
	for node_id in skill_tree_database.get_all_node_ids():
		create_node_data(node_id, center_pos, adjusted_spacing, adjusted_node_size)
		node_count += 1
	
	print("SkillTreeUI: Created ", node_count, " nodes")
	
	# Force a redraw to show everything
	queue_redraw()

func create_node_data(node_id: String, center_pos: Vector2, adjusted_spacing: Vector2, adjusted_node_size: Vector2):
	var node_info = skill_tree_database.get_node(node_id)
	if node_info.is_empty():
		print("SkillTreeUI: Cannot create node ", node_id, " - missing data")
		return
	
	# Calculate position
	var relative_pos = node_info.position
	var world_pos = center_pos + (relative_pos * adjusted_spacing)
	var node_rect_pos = world_pos - (adjusted_node_size / 2)  # Center the rectangle
	
	print("SkillTreeUI: Node '", node_info.name, "' - relative_pos: ", relative_pos, " world_pos: ", world_pos, " rect_pos: ", node_rect_pos, " center: ", world_pos)
	
	# Determine node state and color
	var state = "locked"
	var color = node_color_locked
	
	if node_id in player.unlocked_skill_nodes:
		state = "unlocked"
		color = node_color_unlocked
	elif skill_tree_database.can_unlock_node(node_id, player.unlocked_skill_nodes) and player.skill_points >= node_info.cost:
		state = "unlockable"
		color = node_color_unlockable
	
	# Store node data
	node_data[node_id] = {
		"position": node_rect_pos,
		"size": adjusted_node_size,
		"state": state,
		"color": color,
		"name": node_info.name,
		"description": node_info.description,
		"cost": node_info.cost,
		"center": world_pos  # Store the center position for comparison
	}

func _gui_input(event):
	if not player or not skill_tree_database:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = event.position
		var clicked_node = get_node_at_position(mouse_pos)
		if clicked_node:
			_on_node_clicked(clicked_node)

func get_node_at_position(pos: Vector2) -> String:
	for node_id in node_data:
		var data = node_data[node_id]
		var rect = Rect2(data.position, data.size)
		if rect.has_point(pos):
			return node_id
	return ""

func _on_node_clicked(node_id: String):
	if not player:
		return
	
	var data = node_data[node_id]
	
	# Only allow clicking on unlockable nodes
	if data.state == "unlockable":
		# Try to unlock the node
		if player.unlock_skill_node(node_id):
			selected_node_id = ""
			refresh_display()
			print("Successfully unlocked: %s" % data.name)
		else:
			print("Cannot unlock: %s" % data.name)
			selected_node_id = node_id
			refresh_display()
	else:
		print("Node %s is not unlockable (state: %s)" % [data.name, data.state])

# Draw everything in _draw
func _draw():
	if not skill_tree_database:
		return
	
	print("SkillTreeUI: Drawing with stored scale: ", calculated_scale, " center: ", calculated_center)
	
	# Draw connections between nodes first (so they appear behind nodes)
	draw_connections(calculated_center, calculated_spacing, calculated_scale)
	
	# Draw all nodes as rectangles
	draw_nodes()

func draw_connections(center_pos: Vector2, adjusted_spacing: Vector2, scale_factor: float):
	# Draw connections between nodes
	for node_id in skill_tree_database.get_all_node_ids():
		var node_data = skill_tree_database.get_node(node_id)
		for prereq_id in node_data.prerequisites:
			draw_connection(prereq_id, node_id, center_pos, adjusted_spacing, scale_factor)

func draw_connection(from_node_id: String, to_node_id: String, center_pos: Vector2, adjusted_spacing: Vector2, scale_factor: float):
	var from_data = skill_tree_database.get_node(from_node_id)
	var to_data = skill_tree_database.get_node(to_node_id)
	
	if from_data.is_empty() or to_data.is_empty():
		return
	
	# Calculate positions - use the EXACT SAME logic as node positioning
	var from_pos = center_pos + (from_data.position * adjusted_spacing)
	var to_pos = center_pos + (to_data.position * adjusted_spacing)
	
	# Draw line with a thicker width for better visibility
	var line_width = max(connection_width * scale_factor, 2.0)  # Minimum 2px width
	draw_line(from_pos, to_pos, Color.WHITE, line_width)
	
	# Debug: Draw circles at the exact connection points
	draw_circle(from_pos, 5, Color.RED)
	draw_circle(to_pos, 5, Color.RED)
	
	print("SkillTreeUI: Line from '", from_data.name, "' to '", to_data.name, "' - from_pos: ", from_pos, " to_pos: ", to_pos)
	
	# Compare with node centers
	if from_node_id in node_data and to_node_id in node_data:
		var from_node_center = node_data[from_node_id].center
		var to_node_center = node_data[to_node_id].center
		print("SkillTreeUI: Node centers - from: ", from_node_center, " to: ", to_node_center)
		print("SkillTreeUI: Line positions - from: ", from_pos, " to: ", to_pos)
		print("SkillTreeUI: Differences - from: ", from_pos - from_node_center, " to: ", to_pos - to_node_center)

func draw_nodes():
	# Draw all nodes as rectangles
	for node_id in node_data:
		var data = node_data[node_id]
		var rect = Rect2(data.position, data.size)
		
		# Draw the main rectangle
		draw_rect(rect, data.color)
		
		# Draw a border
		draw_rect(rect, Color.WHITE, false, 2.0)  # false = not filled, 2.0 = border width
		
		# Highlight selected node
		if node_id == selected_node_id:
			draw_rect(rect, node_color_selected, false, 3.0)
		
		# Debug: Draw a small circle at the center of each node
		var node_center = data.center
		draw_circle(node_center, 3, Color.BLUE)
		
		print("SkillTreeUI: Drew node '", data.name, "' at ", data.position, " center: ", data.center, " with color ", data.color) 
