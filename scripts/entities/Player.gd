class_name Player
extends Resource

# Base stats
var stats = {
	"STR": 12,
	"INT": 8, 
	"SPD": 10,
	"DEX": 11,
	"CON": 15,
	"DEF": 9,
	"LCK": 6
}

# Health system
var current_hp: int
var max_hp: int

# Equipment system
var equipped_weapon: String = ""
var equipped_armor: String = ""
var equipped_accessory: String = ""

# Available items (inventory)
var available_weapons: Array[String] = ["Basic Sword", "Iron Blade", "Magic Staff"]
var available_armor: Array[String] = ["Cloth Robe", "Leather Armor", "Chain Mail"]
var available_accessories: Array[String] = ["Lucky Charm", "Power Ring", "Speed Boots"]

# Attack system
var available_attacks: Array[String] = ["Slash", "Block", "Defend", "Power Strike", "Quick Attack", "Magic Bolt"]
var equipped_attacks: Array[String] = ["Slash", "Block", "Defend"]  # Max 3-4 equipped attacks
var max_equipped_attacks: int = 4

func _init():
	max_hp = stats["CON"] * 2
	current_hp = max_hp
	
	# Start with basic equipment
	equipped_weapon = "Basic Sword"
	equipped_armor = "Cloth Robe"

# Existing combat methods (unchanged interface)
func is_alive() -> bool:
	return current_hp > 0

func take_damage(damage: int):
	current_hp = max(0, current_hp - damage)

func heal(amount: int):
	current_hp = min(max_hp, current_hp + amount)

func get_attack_damage(attack_name: String) -> int:
	var base_damage = 0
	
	# Base attack calculations
	match attack_name:
		"Slash":
			base_damage = stats["STR"] + stats["DEX"]
		"Block":
			base_damage = stats["STR"] / 2
		"Defend":
			base_damage = 0
		"Power Strike":
			base_damage = stats["STR"] * 2
		"Quick Attack":
			base_damage = stats["DEX"] + stats["SPD"] / 2
		"Magic Bolt":
			base_damage = stats["INT"] + stats["LCK"]
		_:
			base_damage = stats["STR"]
	
	# Add weapon bonus
	base_damage += get_weapon_damage_bonus()
	
	return base_damage

func get_speed() -> int:
	var base_speed = stats["SPD"]
	
	# Add equipment bonuses
	if equipped_accessory == "Speed Boots":
		base_speed += 5
	
	return base_speed

# New equipment methods
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

# Attack management
func equip_attack(attack_name: String) -> bool:
	if attack_name in available_attacks and attack_name not in equipped_attacks:
		if equipped_attacks.size() < max_equipped_attacks:
			equipped_attacks.append(attack_name)
			return true
	return false

func unequip_attack(attack_name: String) -> bool:
	if attack_name in equipped_attacks:
		equipped_attacks.erase(attack_name)
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
