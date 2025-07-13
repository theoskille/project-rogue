class_name EnemyDatabase
extends Resource

# Enemy data structure:
# {
#   "enemy_name": {
#     "display_name": String,       # Friendly display name
#     "stats": Dictionary,          # Base stats (STR, INT, SPD, etc.)
#     "attacks": Array[String],     # Available attacks (from AttackDatabase)
#     "rarity": String,             # "common", "uncommon", "rare", "boss"
#     "description": String,        # Enemy description
#     "special_abilities": Array[String]  # Special enemy abilities
#   }
# }

static var enemies: Dictionary = {
	"goblin": {
		"display_name": "Goblin",
		"stats": {"STR": 8, "INT": 4, "SPD": 12, "DEX": 10, "CON": 10, "DEF": 6, "LCK": 5},
		"attacks": ["Slash", "Quick Attack"] as Array[String],
		"rarity": "common",
		"description": "A small, agile creature with sharp claws",
		"special_abilities": [] as Array[String]
	},
	
	"orc": {
		"display_name": "Orc",
		"stats": {"STR": 14, "INT": 6, "SPD": 8, "DEX": 7, "CON": 16, "DEF": 10, "LCK": 4},
		"attacks": ["Power Strike", "Slash"] as Array[String],
		"rarity": "common",
		"description": "A brutal warrior with immense strength",
		"special_abilities": [] as Array[String]
	},
	
	"skeleton": {
		"display_name": "Skeleton",
		"stats": {"STR": 10, "INT": 3, "SPD": 6, "DEX": 8, "CON": 12, "DEF": 12, "LCK": 2},
		"attacks": ["Block", "Slash"] as Array[String],
		"rarity": "common",
		"description": "Animated bones held together by dark magic",
		"special_abilities": [] as Array[String]
	},
	
	"spider": {
		"display_name": "Giant Spider",
		"stats": {"STR": 6, "INT": 5, "SPD": 14, "DEX": 12, "CON": 8, "DEF": 4, "LCK": 6},
		"attacks": ["Quick Attack", "Poison Blade"] as Array[String],
		"rarity": "uncommon",
		"description": "A venomous spider with lightning-fast strikes",
		"special_abilities": [] as Array[String]
	},
	
	"wolf": {
		"display_name": "Dire Wolf",
		"stats": {"STR": 12, "INT": 6, "SPD": 16, "DEX": 11, "CON": 14, "DEF": 8, "LCK": 7},
		"attacks": ["Quick Attack", "Lunge Strike"] as Array[String],
		"rarity": "uncommon",
		"description": "A fierce predator that hunts in packs",
		"special_abilities": [] as Array[String]
	},
	
	"bandit": {
		"display_name": "Bandit",
		"stats": {"STR": 10, "INT": 8, "SPD": 11, "DEX": 13, "CON": 12, "DEF": 7, "LCK": 9},
		"attacks": ["Slash", "Backstep Slash", "Quick Attack"] as Array[String],
		"rarity": "uncommon",
		"description": "A cunning thief with dirty fighting tactics",
		"special_abilities": [] as Array[String]
	},
	
	"fire_elemental": {
		"display_name": "Fire Elemental",
		"stats": {"STR": 8, "INT": 15, "SPD": 10, "DEX": 9, "CON": 16, "DEF": 12, "LCK": 8},
		"attacks": ["Fire Blast", "Magic Bolt"] as Array[String],
		"rarity": "rare",
		"description": "A being of pure flame and magical energy",
		"special_abilities": [] as Array[String]
	},
	
	# Boss enemies
	"orc_chieftain": {
		"display_name": "Orc Chieftain",
		"stats": {"STR": 18, "INT": 8, "SPD": 10, "DEX": 9, "CON": 20, "DEF": 14, "LCK": 6},
		"attacks": ["Power Strike", "Lunge Strike", "Slash"] as Array[String],
		"rarity": "boss",
		"description": "The mighty leader of an orc war band",
		"special_abilities": [] as Array[String]
	},
	
	"lich": {
		"display_name": "Lich",
		"stats": {"STR": 6, "INT": 20, "SPD": 8, "DEX": 12, "CON": 18, "DEF": 16, "LCK": 15},
		"attacks": ["Magic Bolt", "Fire Blast", "Poison Blade"] as Array[String],
		"rarity": "boss",
		"description": "An undead sorcerer of immense magical power",
		"special_abilities": [] as Array[String]
	}
}

# Get enemy data by ID
static func get_enemy_data(enemy_id: String) -> Dictionary:
	if enemies.has(enemy_id):
		return enemies[enemy_id]
	else:
		# Return default enemy data
		return {
			"display_name": "Unknown Enemy",
			"stats": {"STR": 8, "INT": 4, "SPD": 8, "DEX": 8, "CON": 10, "DEF": 6, "LCK": 3},
			"attacks": ["Slash"] as Array[String],
			"rarity": "common",
			"description": "A mysterious creature",
			"special_abilities": [] as Array[String]
		}

# Create an Enemy instance from database
static func create_enemy(enemy_id: String) -> Enemy:
	var enemy_data = get_enemy_data(enemy_id)
	var enemy = Enemy.new()
	
	enemy.name = enemy_data["display_name"]
	enemy.stats = enemy_data["stats"].duplicate()
	enemy.attacks = enemy_data["attacks"].duplicate()
	enemy.max_hp = enemy.stats["CON"] * 2
	enemy.current_hp = enemy.max_hp
	
	return enemy

# Get enemies by rarity
static func get_enemies_by_rarity(rarity: String) -> Array[String]:
	var filtered_enemies: Array[String] = []
	
	for enemy_id in enemies.keys():
		if enemies[enemy_id]["rarity"] == rarity:
			filtered_enemies.append(enemy_id)
	
	return filtered_enemies

# Get random enemy by rarity
static func get_random_enemy_by_rarity(rarity: String) -> String:
	var rarity_enemies = get_enemies_by_rarity(rarity)
	
	if rarity_enemies.size() > 0:
		return rarity_enemies[randi() % rarity_enemies.size()]
	else:
		# Fallback to any common enemy
		var common_enemies = get_enemies_by_rarity("common")
		if common_enemies.size() > 0:
			return common_enemies[randi() % common_enemies.size()]
		else:
			return "goblin"  # Ultimate fallback

# Get all enemy IDs
static func get_all_enemy_ids() -> Array[String]:
	var ids: Array[String] = []
	for enemy_id in enemies.keys():
		ids.append(enemy_id)
	return ids

# Get random enemy of any rarity (weighted by rarity)
static func get_random_enemy() -> String:
	var rand_value = randf()
	
	# Weighted selection: common 60%, uncommon 25%, rare 15%
	if rand_value < 0.60:
		return get_random_enemy_by_rarity("common")
	elif rand_value < 0.85:
		return get_random_enemy_by_rarity("uncommon")
	else:
		return get_random_enemy_by_rarity("rare")

# Get random boss enemy
static func get_random_boss() -> String:
	return get_random_enemy_by_rarity("boss")

# Helper: Get enemy description
static func get_enemy_description(enemy_id: String) -> String:
	var enemy_data = get_enemy_data(enemy_id)
	return enemy_data.get("description", "No description available")

# Helper: Check if enemy exists
static func enemy_exists(enemy_id: String) -> bool:
	return enemies.has(enemy_id)
