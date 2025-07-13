class_name Enemy
extends Entity

var name: String
var xp_reward: int = 50  # Base XP reward

func _init():
	# Default values - will be set by EnemyDatabase.create_enemy()
	name = "Unknown Enemy"
	stats = {"STR": 4, "INT": 2, "SPD": 4, "DEX": 4, "CON": 5, "DEF": 3, "LCK": 2}
	attacks = ["Slash"]
	
	# Call parent constructor to set up health
	super._init()

# Override to use enemy's attack list instead of equipped attacks
func get_random_attack() -> String:
	if attacks.size() > 0:
		return attacks[randi() % attacks.size()]
	return "Slash"  # Fallback attack

# Enemy-specific attack list (different from equipped_attacks)
var attacks: Array[String] = ["Slash"]

# Override to use enemy's attack list for info
func get_available_attacks_info() -> Array[Dictionary]:
	var attack_info: Array[Dictionary] = []
	
	for attack_name in attacks:
		var info = AttackDatabase.get_attack_data(attack_name)
		info["name"] = attack_name
		info["damage"] = get_attack_damage(attack_name)
		attack_info.append(info)
	
	return attack_info

# Get XP reward for defeating this enemy
func get_xp_reward() -> int:
	return xp_reward
