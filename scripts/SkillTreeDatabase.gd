class_name SkillTreeDatabase
extends RefCounted

# Skill tree data structure
var skill_tree_data: Dictionary = {
	# Starting ability
	"arcane_bolt": {
		"name": "Arcane Bolt",
		"description": "A basic magical projectile that serves as your starting spell",
		"attack_name": "Arcane Bolt",
		"prerequisites": [],  # Starting ability - no prerequisites
		"position": Vector2(0, 0),
		"cost": 0  # Free starting ability
	},
	
	# Fire Elemental Path
	"fire_bolt": {
		"name": "Fire Bolt",
		"description": "A magical fire projectile that burns the enemy",
		"attack_name": "Fire Bolt",
		"prerequisites": ["arcane_bolt"],
		"position": Vector2(-2, 1),  # Left branch from Arcane Bolt
		"cost": 1
	},
	"fireball": {
		"name": "Fireball",
		"description": "A powerful fireball that explodes on impact",
		"attack_name": "Fireball",
		"prerequisites": ["fire_bolt"],
		"position": Vector2(-2, 2),  # Above Fire Bolt
		"cost": 2
	},
	"inferno": {
		"name": "Inferno",
		"description": "A devastating inferno that engulfs the enemy",
		"attack_name": "Inferno",
		"prerequisites": ["fireball"],
		"position": Vector2(-2, 3),  # Above Fireball
		"cost": 3
	},
	
	# Frost Elemental Path
	"frost_bolt": {
		"name": "Frost Bolt",
		"description": "A magical ice projectile that freezes the enemy",
		"attack_name": "Frost Bolt",
		"prerequisites": ["arcane_bolt"],
		"position": Vector2(0, 1),  # Directly above Arcane Bolt
		"cost": 1
	},
	"ice_storm": {
		"name": "Ice Storm",
		"description": "A storm of ice shards that pierces the enemy",
		"attack_name": "Ice Storm",
		"prerequisites": ["frost_bolt"],
		"position": Vector2(0, 2),  # Above Frost Bolt
		"cost": 2
	},
	"blizzard": {
		"name": "Blizzard",
		"description": "A devastating blizzard that freezes everything",
		"attack_name": "Blizzard",
		"prerequisites": ["ice_storm"],
		"position": Vector2(0, 3),  # Above Ice Storm
		"cost": 3
	},
	
	# Shock Elemental Path
	"lightning_bolt": {
		"name": "Lightning Bolt",
		"description": "A lightning bolt that requires distance",
		"attack_name": "Lightning Bolt",
		"prerequisites": ["arcane_bolt"],
		"position": Vector2(2, 1),  # Right branch from Arcane Bolt
		"cost": 1
	},
	"thunder_strike": {
		"name": "Thunder Strike",
		"description": "A powerful thunder strike that requires great distance",
		"attack_name": "Thunder Strike",
		"prerequisites": ["lightning_bolt"],
		"position": Vector2(2, 2),  # Above Lightning Bolt
		"cost": 2
	},
	"storm_call": {
		"name": "Storm Call",
		"description": "A devastating storm that calls down lightning from the sky",
		"attack_name": "Storm Call",
		"prerequisites": ["thunder_strike"],
		"position": Vector2(2, 3),  # Above Thunder Strike
		"cost": 3
	},
	
	# Alchemist Path
	"acid_splash": {
		"name": "Acid Splash",
		"description": "A corrosive acid that melts the enemy over time",
		"attack_name": "Acid Splash",
		"prerequisites": ["arcane_bolt"],
		"position": Vector2(-1, -1),  # Below-left of Arcane Bolt
		"cost": 1
	},
	"venomous_cloud": {
		"name": "Venomous Cloud",
		"description": "A deadly cloud of venom that poisons the enemy",
		"attack_name": "Venomous Cloud",
		"prerequisites": ["acid_splash"],
		"position": Vector2(-1, -2),  # Below Acid Splash
		"cost": 2
	},
	
	# Utility Abilities
	"blink": {
		"name": "Blink",
		"description": "Teleport away from the enemy",
		"attack_name": "Blink",
		"prerequisites": ["arcane_bolt"],
		"position": Vector2(1, -1),  # Below-right of Arcane Bolt
		"cost": 1
	},
	
	"force_palm": {
		"name": "Force Palm",
		"description": "A magical melee strike that pushes the enemy back",
		"attack_name": "Force Palm",
		"prerequisites": ["arcane_bolt"],
		"position": Vector2(0, -1),  # Directly below Arcane Bolt
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
