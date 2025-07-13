class_name SkillTreeDatabase
extends RefCounted

# Skill tree data structure
var skill_tree_data: Dictionary = {
	"slash": {
		"name": "Slash",
		"description": "Basic sword attack that deals moderate damage",
		"attack_name": "Slash",
		"prerequisites": [],  # Starting ability - no prerequisites
		"position": Vector2(0, 0),
		"cost": 0  # Free starting ability
	},
	"lunge_strike": {
		"name": "Lunge Strike",
		"description": "A powerful thrust attack that can hit from a distance",
		"attack_name": "Lunge Strike",
		"prerequisites": ["slash"],
		"position": Vector2(0, 1),  # Above Slash
		"cost": 1
	},
	"quick_attack": {
		"name": "Quick Attack",
		"description": "Fast, low damage attack that can be used frequently",
		"attack_name": "Quick Attack",
		"prerequisites": ["lunge_strike"],
		"position": Vector2(-1, 1),  # Left of Lunge Strike
		"cost": 1
	},
	"power_strike": {
		"name": "Power Strike",
		"description": "Heavy damage attack that deals massive damage but has a cooldown",
		"attack_name": "Power Strike", 
		"prerequisites": ["lunge_strike"],
		"position": Vector2(1, 1),  # Right of Lunge Strike
		"cost": 1
	},
	"poison_blade": {
		"name": "Poison Blade",
		"description": "Attack that applies poison damage over time",
		"attack_name": "Poison Blade",
		"prerequisites": ["quick_attack"],
		"position": Vector2(-1, 2),  # Above Quick Attack
		"cost": 1
	},
	"magic_bolt": {
		"name": "Magic Bolt",
		"description": "Basic magical attack that scales with intelligence",
		"attack_name": "Magic Bolt",
		"prerequisites": ["slash"],
		"position": Vector2(0, -1),  # Below Slash
		"cost": 1
	},
	"fire_blast": {
		"name": "Fire Blast",
		"description": "Magical fire attack that deals area damage",
		"attack_name": "Fire Blast",
		"prerequisites": ["magic_bolt"],
		"position": Vector2(1, -1),  # Right of Magic Bolt
		"cost": 1
	}
}

# Get all skill tree data
func get_skill_tree_data() -> Dictionary:
	return skill_tree_data

# Get a specific node by ID
func get_node(node_id: String) -> Dictionary:
	if node_id in skill_tree_data:
		return skill_tree_data[node_id]
	return {}

# Get all node IDs
func get_all_node_ids() -> Array[String]:
	var node_ids: Array[String] = []
	for node_id in skill_tree_data.keys():
		node_ids.append(node_id)
	return node_ids

# Check if a node can be unlocked given the currently unlocked nodes
func can_unlock_node(node_id: String, unlocked_nodes: Array[String]) -> bool:
	if not node_id in skill_tree_data:
		return false
	
	var node_data = skill_tree_data[node_id]
	
	# Check if already unlocked
	if node_id in unlocked_nodes:
		return false
	
	# Check prerequisites
	for prereq in node_data.prerequisites:
		if prereq not in unlocked_nodes:
			return false
	
	return true

# Get all nodes that can be unlocked given the currently unlocked nodes
func get_unlockable_nodes(unlocked_nodes: Array[String]) -> Array[String]:
	var unlockable: Array[String] = []
	
	for node_id in skill_tree_data.keys():
		if can_unlock_node(node_id, unlocked_nodes):
			unlockable.append(node_id)
	
	return unlockable

# Get the cost to unlock a specific node
func get_node_cost(node_id: String) -> int:
	if node_id in skill_tree_data:
		return skill_tree_data[node_id].cost
	return 999  # High cost for invalid nodes

# Get all starting nodes (nodes with no prerequisites)
func get_starting_nodes() -> Array[String]:
	var starting: Array[String] = []
	
	for node_id in skill_tree_data.keys():
		if skill_tree_data[node_id].prerequisites.is_empty():
			starting.append(node_id)
	
	return starting

# Validate that the skill tree structure is valid
func validate_skill_tree() -> bool:
	var all_nodes = skill_tree_data.keys()
	
	# Check that all prerequisites exist
	for node_id in all_nodes:
		var node_data = skill_tree_data[node_id]
		for prereq in node_data.prerequisites:
			if prereq not in all_nodes:
				print("ERROR: Node '%s' has invalid prerequisite '%s'" % [node_id, prereq])
				return false
	
	# Check that there's at least one starting node
	if get_starting_nodes().is_empty():
		print("ERROR: No starting nodes found in skill tree")
		return false
	
	return true

# Get the visual layout bounds for UI positioning
func get_tree_bounds() -> Dictionary:
	var min_pos = Vector2(INF, INF)
	var max_pos = Vector2(-INF, -INF)
	
	for node_data in skill_tree_data.values():
		var pos = node_data.position
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)
	
	return {
		"min": min_pos,
		"max": max_pos,
		"size": max_pos - min_pos
	} 
