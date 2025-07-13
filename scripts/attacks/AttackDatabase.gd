class_name AttackDatabase
extends Resource

# Attack data structure:
# {
#   "attack_name": {
#     "base_damage": int,           # Base damage before player stats
#     "damage_scaling": Dictionary, # How damage scales with player stats {"STR": 0.5, "DEX": 0.25}
#     "min_range": int,             # Minimum distance required for attack
#     "max_range": int,             # Maximum distance attack can reach
#     "accuracy": float,            # Hit chance (0.0 to 1.0)
#     "description": String,        # Attack description
#     "special_effects": Array[String]  # List of special effect IDs
#   }
# }

static var attacks: Dictionary = {
	# ===== ENEMY ATTACKS =====
	# These are attacks used by enemies, not the player wizard
	
	"Slash": {
		"base_damage": 3,
		"damage_scaling": {"STR": 0.4, "DEX": 0.1},  # Primarily strength-based with some dexterity
		"min_range": 1,
		"max_range": 1,
		"accuracy": 0.90,
		"description": "A basic melee attack",
		"special_effects": [] as Array[String]
	},
	
	"Block": {
		"base_damage": 1,
		"damage_scaling": {"STR": 0.2, "CON": 0.2},  # More defensive, uses constitution
		"min_range": 1,
		"max_range": 1,
		"accuracy": 0.95,
		"description": "A defensive strike",
		"special_effects": [] as Array[String]
	},
	
	"Defend": {
		"base_damage": 0,
		"damage_scaling": {},  # No damage scaling for pure defensive move
		"min_range": 0,
		"max_range": 0,
		"accuracy": 1.0,
		"description": "Pure defensive stance",
		"special_effects": [] as Array[String]
	},
	
	"Power Strike": {
		"base_damage": 4,
		"damage_scaling": {"STR": 0.8},  # High strength scaling for powerful attack
		"min_range": 1,
		"max_range": 1,
		"accuracy": 0.70,
		"description": "A powerful attack that sacrifices accuracy",
		"special_effects": [] as Array[String],
		"cooldown": 2
	},
	
	"Quick Attack": {
		"base_damage": 2,
		"damage_scaling": {"DEX": 0.3, "SPD": 0.15},  # Speed and dexterity focused
		"min_range": 1,
		"max_range": 2,
		"accuracy": 0.85,
		"description": "A fast attack with extended range",
		"special_effects": [] as Array[String],
		"cooldown": 1
	},
	
	"Lunge Strike": {
		"base_damage": 4,
		"damage_scaling": {"STR": 0.3, "DEX": 0.2},  # Balanced strength and dexterity
		"min_range": 2,
		"max_range": 3,
		"accuracy": 0.80,
		"description": "Strike forward while moving toward the enemy",
		"special_effects": ["move_toward_target"] as Array[String]
	},
	
	"Backstep Slash": {
		"base_damage": 3,
		"damage_scaling": {"DEX": 0.45},  # High dexterity scaling
		"min_range": 1,
		"max_range": 1,
		"accuracy": 0.85,
		"description": "Attack then step backward",
		"special_effects": ["move_backward"] as Array[String]
	},
	
	"Poison Blade": {
		"base_damage": 2,
		"damage_scaling": {"DEX": 0.35, "INT": 0.05},  # Primarily dexterity with some intelligence
		"min_range": 1,
		"max_range": 1,
		"accuracy": 0.90,
		"description": "Poisoned weapon that causes damage over time",
		"special_effects": ["apply_poison"] as Array[String]
	},
	
	"Close Quarters Strike": {
		"base_damage": 4,
		"damage_scaling": {"STR": 0.5, "DEX": 0.3},  # Balanced strength and dexterity
		"min_range": 1,
		"max_range": 1,
		"accuracy": 0.95,
		"description": "A precise strike that only works at point-blank range",
		"special_effects": [] as Array[String],
		"cooldown": 2
	},
	
	# ===== WIZARD ATTACKS =====
	# These are the player wizard's magical abilities
	
	# Starting ability
	"Arcane Bolt": {
		"base_damage": 3,
		"damage_scaling": {"INT": 0.4, "LCK": 0.1},  # Intelligence-based with luck
		"min_range": 2,
		"max_range": 4,
		"accuracy": 0.85,
		"description": "A basic magical projectile",
		"special_effects": [] as Array[String]
	},
	
	# Fire Elemental Path
	"Fire Bolt": {
		"base_damage": 4,
		"damage_scaling": {"INT": 0.5, "LCK": 0.05},  # High intelligence scaling
		"min_range": 2,
		"max_range": 4,
		"accuracy": 0.80,
		"description": "A magical fire projectile that burns the enemy",
		"special_effects": ["apply_burn"] as Array[String],
		"cooldown": 2
	},
	
	"Fireball": {
		"base_damage": 6,
		"damage_scaling": {"INT": 0.6, "LCK": 0.1},  # Very high intelligence scaling
		"min_range": 3,
		"max_range": 5,
		"accuracy": 0.75,
		"description": "A powerful fireball that explodes on impact",
		"special_effects": ["apply_burn"] as Array[String],
		"cooldown": 3
	},
	
	"Inferno": {
		"base_damage": 8,
		"damage_scaling": {"INT": 0.7, "LCK": 0.15},  # Maximum intelligence scaling
		"min_range": 4,
		"max_range": 6,
		"accuracy": 0.70,
		"description": "A devastating inferno that engulfs the enemy",
		"special_effects": ["apply_burn"] as Array[String],
		"cooldown": 4
	},
	
	# Frost Elemental Path
	"Frost Bolt": {
		"base_damage": 3,
		"damage_scaling": {"INT": 0.45, "LCK": 0.05},  # Intelligence-based
		"min_range": 2,
		"max_range": 4,
		"accuracy": 0.85,
		"description": "A magical ice projectile",
		"special_effects": [] as Array[String],
		"cooldown": 2
	},
	
	"Ice Storm": {
		"base_damage": 5,
		"damage_scaling": {"INT": 0.55, "LCK": 0.1},  # High intelligence scaling
		"min_range": 3,
		"max_range": 5,
		"accuracy": 0.80,
		"description": "A storm of ice shards that pierces the enemy",
		"special_effects": [] as Array[String],
		"cooldown": 3
	},
	
	"Blizzard": {
		"base_damage": 7,
		"damage_scaling": {"INT": 0.65, "LCK": 0.15},  # Very high intelligence scaling
		"min_range": 4,
		"max_range": 6,
		"accuracy": 0.75,
		"description": "A devastating blizzard",
		"special_effects": [] as Array[String],
		"cooldown": 4
	},
	
	# Shock Elemental Path
	"Lightning Bolt": {
		"base_damage": 4,
		"damage_scaling": {"INT": 0.5, "LCK": 0.1},  # Intelligence-based with luck
		"min_range": 3,
		"max_range": 5,
		"accuracy": 0.75,
		"description": "A lightning bolt that requires distance",
		"special_effects": [] as Array[String],
		"cooldown": 2
	},
	
	"Thunder Strike": {
		"base_damage": 6,
		"damage_scaling": {"INT": 0.6, "LCK": 0.15},  # High intelligence scaling
		"min_range": 4,
		"max_range": 6,
		"accuracy": 0.70,
		"description": "A powerful thunder strike that requires great distance",
		"special_effects": [] as Array[String],
		"cooldown": 3
	},
	
	"Storm Call": {
		"base_damage": 8,
		"damage_scaling": {"INT": 0.7, "LCK": 0.2},  # Maximum intelligence scaling
		"min_range": 5,
		"max_range": 7,
		"accuracy": 0.65,
		"description": "A devastating storm that calls down lightning from the sky",
		"special_effects": [] as Array[String],
		"cooldown": 4
	},
	
	# Alchemist Path
	"Acid Splash": {
		"base_damage": 2,
		"damage_scaling": {"INT": 0.3, "LCK": 0.05},  # Moderate intelligence scaling
		"min_range": 2,
		"max_range": 4,
		"accuracy": 0.90,
		"description": "A corrosive acid that melts the enemy",
		"special_effects": ["apply_poison"] as Array[String],
		"cooldown": 2
	},
	
	"Venomous Cloud": {
		"base_damage": 4,
		"damage_scaling": {"INT": 0.5, "LCK": 0.1},  # High intelligence scaling
		"min_range": 3,
		"max_range": 5,
		"accuracy": 0.80,
		"description": "A deadly cloud of venom that poisons the enemy",
		"special_effects": ["apply_poison"] as Array[String],
		"cooldown": 3
	},
	
	# Utility Abilities
	"Blink": {
		"base_damage": 0,
		"damage_scaling": {},  # No damage
		"min_range": 1,
		"max_range": 3,
		"accuracy": 1.0,
		"description": "Teleport away from the enemy",
		"special_effects": ["move_backward"] as Array[String],
		"effect_parameters": {
			"move_backward": {"distance": 3}
		},
		"cooldown": 3
	},
	
	"Force Palm": {
		"base_damage": 3,
		"damage_scaling": {"INT": 0.4, "STR": 0.2},  # Intelligence and strength
		"min_range": 1,
		"max_range": 1,
		"accuracy": 0.85,
		"description": "A magical melee strike that pushes the enemy back",
		"special_effects": ["push_back"] as Array[String],
		"cooldown": 2
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
			"min_range": 1,
			"max_range": 1,
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
	var attack_names: Array[String] = []
	for attack_name in attacks.keys():
		attack_names.append(attack_name)
	return attack_names

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

# Get range information for an attack
static func get_attack_range(attack_name: String) -> Dictionary:
	var attack_data = get_attack_data(attack_name)
	return {
		"min_range": attack_data["min_range"],
		"max_range": attack_data["max_range"]
	}

# Check if an attack can be used at a given distance
static func is_attack_in_range(attack_name: String, distance: int) -> bool:
	var attack_data = get_attack_data(attack_name)
	var min_range = attack_data["min_range"]
	var max_range = attack_data["max_range"]
	return distance >= min_range and distance <= max_range

# Get range display text for UI
static func get_range_display_text(attack_name: String) -> String:
	var attack_data = get_attack_data(attack_name)
	var min_range = attack_data["min_range"]
	var max_range = attack_data["max_range"]
	
	if min_range == max_range:
		return str(min_range)
	else:
		return "%d-%d" % [min_range, max_range]
