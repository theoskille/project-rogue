class_name Enemy
extends Resource

var name: String
var stats: Dictionary
var current_hp: int
var max_hp: int
var attacks: Array[String]

func _init():
	# Default values - will be set by EnemyDatabase.create_enemy()
	name = "Unknown Enemy"
	stats = {"STR": 8, "INT": 4, "SPD": 8, "DEX": 8, "CON": 10, "DEF": 6, "LCK": 3}
	attacks = ["Slash"]
	max_hp = stats["CON"] * 2
	current_hp = max_hp

func is_alive() -> bool:
	return current_hp > 0

func take_damage(damage: int):
	current_hp = max(0, current_hp - damage)

func heal(amount: int):
	current_hp = min(max_hp, current_hp + amount)

# Now uses AttackDatabase for consistent damage calculation
func get_attack_damage(attack_name: String) -> int:
	return AttackDatabase.calculate_attack_damage(attack_name, stats, 0)  # No weapon bonus for enemies

func get_speed() -> int:
	return stats["SPD"]

func get_random_attack() -> String:
	if attacks.size() > 0:
		return attacks[randi() % attacks.size()]
	return "Slash"  # Fallback attack

# Get attack info for AI decisions
func get_attack_info(attack_name: String) -> Dictionary:
	return AttackDatabase.get_attack_data(attack_name)

# Helper: Get all attack names with their info (for AI)
func get_available_attacks_info() -> Array[Dictionary]:
	var attack_info: Array[Dictionary] = []
	
	for attack_name in attacks:
		var info = AttackDatabase.get_attack_data(attack_name)
		info["name"] = attack_name
		info["damage"] = get_attack_damage(attack_name)
		attack_info.append(info)
	
	return attack_info
