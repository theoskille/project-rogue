class_name CooldownManager
extends RefCounted

# Tracks cooldowns for player attacks
var player_cooldowns: Dictionary = {}  # attack_name -> turns_remaining

# Add a cooldown for an attack
func add_cooldown(attack_name: String, turns: int):
	if turns > 0:
		player_cooldowns[attack_name] = turns

# Get remaining cooldown for an attack
func get_cooldown(attack_name: String) -> int:
	return player_cooldowns.get(attack_name, 0)

# Check if an attack is on cooldown
func is_on_cooldown(attack_name: String) -> bool:
	return get_cooldown(attack_name) > 0

# Decrement all cooldowns by 1 turn
func tick_cooldowns():
	var expired_cooldowns: Array[String] = []
	
	for attack_name in player_cooldowns:
		player_cooldowns[attack_name] -= 1
		if player_cooldowns[attack_name] <= 0:
			expired_cooldowns.append(attack_name)
	
	# Remove expired cooldowns
	for attack_name in expired_cooldowns:
		player_cooldowns.erase(attack_name)

# Get all current cooldowns for UI display
func get_all_cooldowns() -> Dictionary:
	return player_cooldowns.duplicate()

# Clear all cooldowns (for when combat ends)
func clear_all_cooldowns():
	player_cooldowns.clear()

# Get cooldown description for UI
func get_cooldown_description(attack_name: String) -> String:
	var cooldown = get_cooldown(attack_name)
	if cooldown > 0:
		return "%s (CD: %d)" % [attack_name, cooldown]
	return attack_name 