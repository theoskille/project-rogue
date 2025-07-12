class_name Enemy
extends Resource

var name: String
var stats: Dictionary
var current_hp: int
var max_hp: int
var attacks: Array[String]

func _init(enemy_name: String = "Goblin"):
	name = enemy_name
	
	# Set default stats based on enemy type
	match enemy_name:
		"Goblin":
			stats = {"STR": 8, "INT": 4, "SPD": 12, "DEX": 10, "CON": 10, "DEF": 6, "LCK": 5}
			attacks = ["Scratch", "Bite"]
		"Orc":
			stats = {"STR": 14, "INT": 6, "SPD": 8, "DEX": 7, "CON": 16, "DEF": 10, "LCK": 4}
			attacks = ["Club", "Charge"]
		"Skeleton":
			stats = {"STR": 10, "INT": 3, "SPD": 6, "DEX": 8, "CON": 12, "DEF": 12, "LCK": 2}
			attacks = ["Bone Strike", "Rattle"]
		_:
			# Default enemy
			stats = {"STR": 8, "INT": 4, "SPD": 8, "DEX": 8, "CON": 10, "DEF": 6, "LCK": 3}
			attacks = ["Attack"]
	
	max_hp = stats["CON"] * 2
	current_hp = max_hp

func is_alive() -> bool:
	return current_hp > 0

func take_damage(damage: int):
	current_hp = max(0, current_hp - damage)

func heal(amount: int):
	current_hp = min(max_hp, current_hp + amount)

func get_attack_damage(attack_name: String) -> int:
	# Simple damage calculation
	match attack_name:
		"Scratch", "Bite":
			return stats["STR"] + randi() % 4
		"Club":
			return stats["STR"] * 2
		"Charge":
			return stats["STR"] + stats["SPD"] / 2
		"Bone Strike":
			return stats["STR"] + stats["DEX"] / 2
		"Rattle":
			return stats["STR"] / 2
		_:
			return stats["STR"]

func get_speed() -> int:
	return stats["SPD"]

func get_random_attack() -> String:
	if attacks.size() > 0:
		return attacks[randi() % attacks.size()]
	return "Attack"
