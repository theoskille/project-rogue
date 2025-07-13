class_name Entity
extends Resource

# Base stats that all entities have
var stats: Dictionary = {
	"STR": 5,
	"INT": 4, 
	"SPD": 5,
	"DEX": 5,
	"CON": 6,
	"DEF": 4,
	"LCK": 3
}

# Health system
var current_hp: int
var max_hp: int

# Attack system - using AttackDatabase
var available_attacks: Array[String] = ["Arcane Bolt"]
var equipped_attacks: Array[String] = ["Arcane Bolt"]

func _init():
	max_hp = stats["CON"] * 2
	current_hp = max_hp

# Health management
func is_alive() -> bool:
	return current_hp > 0

func take_damage(damage: int):
	current_hp = max(0, current_hp - damage)

func heal(amount: int):
	current_hp = min(max_hp, current_hp + amount)

# Attack system methods
func get_attack_damage(attack_name: String, weapon_bonus: int = 0) -> int:
	return AttackDatabase.calculate_attack_damage(attack_name, stats, weapon_bonus)

func get_speed() -> int:
	return stats["SPD"]

func get_random_attack() -> String:
	if equipped_attacks.size() > 0:
		return equipped_attacks[randi() % equipped_attacks.size()]
	return "Arcane Bolt"  # Fallback attack

# Attack management
func equip_attack(attack_name: String) -> bool:
	if attack_name in available_attacks and attack_name not in equipped_attacks:
		equipped_attacks.append(attack_name)
		return true
	return false

func unequip_attack(attack_name: String) -> bool:
	if attack_name in equipped_attacks:
		equipped_attacks.erase(attack_name)
		return true
	return false

# Get methods for UI and other systems
func get_attack_info(attack_name: String) -> Dictionary:
	return AttackDatabase.get_attack_data(attack_name)

func get_attack_description(attack_name: String) -> String:
	var attack_data = AttackDatabase.get_attack_data(attack_name)
	return attack_data.get("description", "No description available")

# Get all attack names with their info (for AI and UI)
func get_available_attacks_info() -> Array[Dictionary]:
	var attack_info: Array[Dictionary] = []
	
	for attack_name in equipped_attacks:
		var info = AttackDatabase.get_attack_data(attack_name)
		info["name"] = attack_name
		info["damage"] = get_attack_damage(attack_name)
		attack_info.append(info)
	
	return attack_info

# Virtual methods that can be overridden by subclasses
func get_weapon_damage_bonus() -> int:
	return 0  # Base entities have no weapon bonus

func get_armor_defense_bonus() -> int:
	return 0  # Base entities have no armor bonus

func get_accessory_bonus() -> Dictionary:
	return {}  # Base entities have no accessory bonus 
