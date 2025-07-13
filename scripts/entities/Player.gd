class_name Player
extends Entity

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
	
	# Player-specific attack setup
	available_attacks = ["Slash", "Block", "Defend", "Power Strike", "Quick Attack", "Magic Bolt", "Lunge Strike", "Poison Blade", "Fire Blast"]
	equipped_attacks = ["Slash", "Block", "Defend"]  # Max 3-4 equipped attacks
	
	# Start with basic equipment
	equipped_weapon = "Basic Sword"
	equipped_armor = "Cloth Robe"

# Equipment system (Player-specific)
var equipped_weapon: String = ""
var equipped_armor: String = ""
var equipped_accessory: String = ""

# Available items (inventory)
var available_weapons: Array[String] = ["Basic Sword", "Iron Blade", "Magic Staff"]
var available_armor: Array[String] = ["Cloth Robe", "Leather Armor", "Chain Mail"]
var available_accessories: Array[String] = ["Lucky Charm", "Power Ring", "Speed Boots"]

var max_equipped_attacks: int = 4

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
