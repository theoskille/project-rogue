class_name AttackDatabase
extends Resource

# Attack data structure:
# {
#   "attack_name": {
#     "base_damage": int,           # Base damage before player stats
#     "damage_scaling": Dictionary, # How damage scales with player stats {"STR": 0.5, "DEX": 0.25}
#     "range": int,                 # Attack range
#     "accuracy": float,            # Hit chance (0.0 to 1.0)
#     "description": String,        # Attack description
#     "special_effects": Array[String]  # List of special effect IDs
#   }
# }

static var attacks: Dictionary = {
	"Slash": {
		"base_damage": 3,
		"damage_scaling": {"STR": 0.4, "DEX": 0.1},  # Primarily strength-based with some dexterity
		"range": 1,
		"accuracy": 0.90,
		"description": "A basic melee attack",
		"special_effects": [] as Array[String]
	},
	
	"Block": {
		"base_damage": 1,
		"damage_scaling": {"STR": 0.2, "CON": 0.2},  # More defensive, uses constitution
		"range": 1,
		"accuracy": 0.95,
		"description": "A defensive strike",
		"special_effects": [] as Array[String]
	},
	
	"Defend": {
		"base_damage": 0,
		"damage_scaling": {},  # No damage scaling for pure defensive move
		"range": 0,
		"accuracy": 1.0,
		"description": "Pure defensive stance",
		"special_effects": [] as Array[String]
	},
	
	"Power Strike": {
		"base_damage": 4,
		"damage_scaling": {"STR": 0.8},  # High strength scaling for powerful attack
		"range": 1,
		"accuracy": 0.70,
		"description": "A powerful attack that sacrifices accuracy",
		"special_effects": [] as Array[String],
		"cooldown": 2
	},
	
	"Quick Attack": {
		"base_damage": 2,
		"damage_scaling": {"DEX": 0.3, "SPD": 0.15},  # Speed and dexterity focused
		"range": 2,
		"accuracy": 0.85,
		"description": "A fast attack with extended range",
		"special_effects": [] as Array[String],
		"cooldown": 1
	},
	
	"Magic Bolt": {
		"base_damage": 3,
		"damage_scaling": {"INT": 0.4, "LCK": 0.1},  # Intelligence-based with luck
		"range": 3,
		"accuracy": 0.75,
		"description": "A magical projectile attack",
		"special_effects": [] as Array[String],
		"cooldown": 3
	},
	
	# Example of new attack with special movement effect
	"Lunge Strike": {
		"base_damage": 4,
		"damage_scaling": {"STR": 0.3, "DEX": 0.2},  # Balanced strength and dexterity
		"range": 2,
		"accuracy": 0.80,
		"description": "Strike forward while moving toward the enemy",
		"special_effects": ["move_toward_target"] as Array[String]
	},
	
	"Backstep Slash": {
		"base_damage": 3,
		"damage_scaling": {"DEX": 0.45},  # High dexterity scaling
		"range": 1,
		"accuracy": 0.85,
		"description": "Attack then step backward",
		"special_effects": ["move_backward"] as Array[String]
	},
	
	# DOT attacks
	"Poison Blade": {
		"base_damage": 2,
		"damage_scaling": {"DEX": 0.35, "INT": 0.05},  # Primarily dexterity with some intelligence
		"range": 1,
		"accuracy": 0.90,
		"description": "Poisoned weapon that causes damage over time",
		"special_effects": ["apply_poison"] as Array[String]
	},
	
	"Fire Blast": {
		"base_damage": 3,
		"damage_scaling": {"INT": 0.5, "LCK": 0.05},  # High intelligence scaling
		"range": 2,
		"accuracy": 0.80,
		"description": "Magical fire attack that burns the enemy",
		"special_effects": ["apply_burn"] as Array[String]
	}
}

# Get attack data by name
static func get_attack_data(attack_name: String) -> Dictionary:
	if attacks.has(attack_name):
		return attacks[attack_name]
	else:
		# Return default attack data
		return {
			"base_damage": 2,
			"damage_scaling": {"STR": 0.3},
			"range": 1,
			"accuracy": 0.70,
			"description": "Unknown attack",
			"special_effects": [] as Array[String]
		}

# Calculate damage for an attack using player stats
static func calculate_attack_damage(attack_name: String, player_stats: Dictionary, weapon_bonus: int = 0) -> int:
	var attack_data = get_attack_data(attack_name)
	var base_damage = attack_data["base_damage"]
	var scaling = attack_data["damage_scaling"]
	
	var stat_damage = 0
	
	# Apply damage scaling based on player stats
	for stat_name in scaling.keys():
		var stat_value = player_stats.get(stat_name, 0) # Get stat value, default to 0 if not found
		var scaling_factor = scaling[stat_name]
		stat_damage += stat_value * scaling_factor
	
	return base_damage + stat_damage + weapon_bonus

# Get all available attacks (for inventory/UI purposes)
static func get_all_attack_names() -> Array[String]:
	return attacks.keys()

# Check if attack has specific special effect
static func has_special_effect(attack_name: String, effect_id: String) -> bool:
	var attack_data = get_attack_data(attack_name)
	return effect_id in attack_data["special_effects"]

# Get all special effects for an attack
static func get_special_effects(attack_name: String) -> Array[String]:
	var attack_data = get_attack_data(attack_name)
	var effects = attack_data["special_effects"]
	
	# Convert generic Array to Array[String] to satisfy type checking
	var typed_effects: Array[String] = []
	for effect in effects:
		typed_effects.append(effect)
	return typed_effects
