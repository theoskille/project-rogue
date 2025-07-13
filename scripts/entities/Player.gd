class_name Player
extends Entity

# Signals
signal level_up(new_level: int, old_max_hp: int, new_max_hp: int)

# Player-specific stats (override base stats)
func _init():
	# Override base stats with player-specific values
	stats = {
		"STR": 12,
		"INT": 8, 
		"SPD": 10,
		"DEX": 11,
		"CON": 15,
		"DEF": 9,
		"LCK": 6
	}
	
	# Call parent constructor to set up health
	super._init()
	
	# Initialize skill tree system
	skill_tree_database = SkillTreeDatabase.new()
	initialize_skill_tree()
	
	# Player-specific attack setup - now based on skill tree
	available_attacks = get_unlocked_attacks()
	equipped_attacks = ["Arcane Bolt"]  # Start with basic wizard spell
	
	# Start with basic equipment
	equipped_weapon = "Magic Staff"
	equipped_armor = "Cloth Robe"

# Equipment system (Player-specific)
var equipped_weapon: String = "Rusty Sword"
var equipped_armor: String = "Leather Armor"
var equipped_accessory: String = "None"

# Available items (inventory)
var available_weapons: Array[String] = ["Basic Sword", "Iron Blade", "Magic Staff"]
var available_armor: Array[String] = ["Cloth Robe", "Leather Armor", "Chain Mail"]
var available_accessories: Array[String] = ["Lucky Charm", "Power Ring", "Speed Boots"]

var max_equipped_attacks: int = 4

# Leveling system
var level: int = 1
var experience: int = 0
var experience_to_next_level: int = 100  # Base XP requirement

# Skill tree system
var skill_points: int = 0
var unlocked_skill_nodes: Array[String] = []
var skill_tree_database: SkillTreeDatabase

# Development flag to unlock all attacks for testing
var dev_mode: bool = false  # Set to true to unlock all attacks

# Initialize skill tree with starting abilities
func initialize_skill_tree():
	# Start with the starting nodes (nodes with no prerequisites)
	var starting_nodes = skill_tree_database.get_starting_nodes()
	for node_id in starting_nodes:
		unlock_skill_node(node_id)

# Unlock a skill tree node
func unlock_skill_node(node_id: String) -> bool:
	# Check if we can unlock this node
	if not skill_tree_database.can_unlock_node(node_id, unlocked_skill_nodes):
		return false
	
	# Check if we have enough skill points
	var cost = skill_tree_database.get_node_cost(node_id)
	if skill_points < cost:
		return false
	
	# Unlock the node
	unlocked_skill_nodes.append(node_id)
	skill_points -= cost
	
	# Update available attacks
	available_attacks = get_unlocked_attacks()
	
	print("Unlocked skill: %s" % skill_tree_database.get_node(node_id).name)
	return true

# Get all attacks that are unlocked through the skill tree
func get_unlocked_attacks() -> Array[String]:
	if dev_mode:
		# Dev mode: return all attacks from the database
		return AttackDatabase.get_all_attack_names()
	
	# Normal mode: return only skill tree unlocked attacks
	var unlocked_attacks: Array[String] = []
	
	for node_id in unlocked_skill_nodes:
		var node_data = skill_tree_database.get_node(node_id)
		if node_data.has("attack_name"):
			unlocked_attacks.append(node_data.attack_name)
	
	return unlocked_attacks

# Get skill tree information for UI
func get_skill_tree_info() -> Dictionary:
	return {
		"skill_points": skill_points,
		"unlocked_nodes": unlocked_skill_nodes,
		"unlockable_nodes": skill_tree_database.get_unlockable_nodes(unlocked_skill_nodes),
		"all_nodes": skill_tree_database.get_all_node_ids(),
		"dev_mode": dev_mode
	}

# Development mode methods
func toggle_dev_mode():
	dev_mode = !dev_mode
	# Update available attacks when dev mode changes
	available_attacks = get_unlocked_attacks()
	print("Dev mode %s" % ("enabled" if dev_mode else "disabled"))

func set_dev_mode(enabled: bool):
	dev_mode = enabled
	# Update available attacks when dev mode changes
	available_attacks = get_unlocked_attacks()
	print("Dev mode %s" % ("enabled" if dev_mode else "disabled"))

func is_dev_mode() -> bool:
	return dev_mode

# Check if a specific attack is unlocked
func is_attack_unlocked(attack_name: String) -> bool:
	return attack_name in get_unlocked_attacks()

# XP requirements scale with level
func get_xp_for_next_level() -> int:
	return level * 100  # Simple scaling: level 1->2 = 100 XP, level 2->3 = 200 XP, etc.

func gain_experience(amount: int):
	experience += amount
	check_level_up()

func check_level_up():
	while experience >= experience_to_next_level:
		perform_level_up()

func perform_level_up():
	# Increase level
	level += 1
	
	# Award skill point
	skill_points += 1
	
	# Increase all stats by 1
	for stat_name in stats.keys():
		stats[stat_name] += 1
	
	# Recalculate health based on new CON
	var old_max_hp = max_hp
	max_hp = stats["CON"] * 2
	current_hp = max_hp  # Full heal on level up
	
	# Calculate remaining XP
	experience -= experience_to_next_level
	experience_to_next_level = get_xp_for_next_level()
	
	# Emit signal for UI updates
	emit_signal("level_up", level, old_max_hp, max_hp)
	
	print("Level up! You gained a skill point. Total skill points: %d" % skill_points)

# Get level info for UI
func get_level_info() -> Dictionary:
	return {
		"level": level,
		"experience": experience,
		"experience_to_next": experience_to_next_level,
		"progress": float(experience) / float(experience_to_next_level)
	}

# Override base methods to add equipment bonuses
func get_speed() -> int:
	var base_speed = stats["SPD"]
	
	# Add equipment bonuses
	if equipped_accessory == "Speed Boots":
		base_speed += 5
	
	return base_speed

func get_attack_damage(attack_name: String, weapon_bonus: int = 0) -> int:
	return super.get_attack_damage(attack_name, get_weapon_damage_bonus())

# Equipment bonus methods
func get_weapon_damage_bonus() -> int:
	match equipped_weapon:
		"Basic Sword":
			return 2
		"Iron Blade":
			return 5
		"Magic Staff":
			return 3
		_:
			return 0

func get_armor_defense_bonus() -> int:
	match equipped_armor:
		"Cloth Robe":
			return 1
		"Leather Armor":
			return 3
		"Chain Mail":
			return 6
		_:
			return 0

func get_accessory_bonus() -> Dictionary:
	match equipped_accessory:
		"Lucky Charm":
			return {"LCK": 3}
		"Power Ring":
			return {"STR": 2}
		"Speed Boots":
			return {"SPD": 5}
		_:
			return {}

# Equipment management
func equip_weapon(weapon_name: String) -> bool:
	if weapon_name in available_weapons:
		equipped_weapon = weapon_name
		return true
	return false

func equip_armor(armor_name: String) -> bool:
	if armor_name in available_armor:
		equipped_armor = armor_name
		return true
	return false

func equip_accessory(accessory_name: String) -> bool:
	if accessory_name in available_accessories:
		equipped_accessory = accessory_name
		return true
	return false

# Attack management - now validates against AttackDatabase and respects max equipped limit
func equip_attack(attack_name: String) -> bool:
	# Check if attack exists in database and is available to player
	if attack_name in available_attacks and attack_name not in equipped_attacks:
		if equipped_attacks.size() < max_equipped_attacks:
			equipped_attacks.append(attack_name)
			return true
	return false

func can_equip_more_attacks() -> bool:
	return equipped_attacks.size() < max_equipped_attacks

# Get methods for UI
func get_equipped_items() -> Dictionary:
	return {
		"weapon": equipped_weapon,
		"armor": equipped_armor,
		"accessory": equipped_accessory
	}

func get_available_items() -> Dictionary:
	return {
		"weapons": available_weapons,
		"armor": available_armor,
		"accessories": available_accessories
	}
