class_name AttackAction
extends CombatAction

var attack_name: String
var accuracy: float
var base_damage: int
var damage_scaling: String

func _init(attack: String, attack_accuracy: float = 0.8, damage: int = 5, scaling: String = "STR"):
	attack_name = attack
	accuracy = attack_accuracy
	base_damage = damage
	damage_scaling = scaling
	
	# Get attack data from database if available
	var attack_data = AttackDatabase.get_attack_data(attack)
	if attack_data.has("description"):
		description = attack_data["description"]
	else:
		description = "A basic attack"
	
	super._init(attack, description)

func execute(controller: CombatController) -> bool:
	# Check if we can execute this attack
	if not can_execute(controller):
		return false
	
	# Handle special case attacks first
	if attack_name == "Basic Attack":
		return execute_basic_attack(controller)
	
	# Get attack data from AttackDatabase
	var attack_data = AttackDatabase.get_attack_data(attack_name)
	var attack_accuracy = attack_data["accuracy"]
	
	# Execute special effects BEFORE damage (for movement attacks)
	var effects = AttackDatabase.get_special_effects(attack_name)
	if effects.size() > 0:
		execute_special_effects(controller)
		# Recalculate distance after potential movement
		var distance = abs(controller.player_position - controller.enemy_position)
		var min_range = attack_data["min_range"]
		var max_range = attack_data["max_range"]
		
		# Check range again after movement
		if distance < min_range:
			controller.log_combat_message("%s moved player too close!" % attack_name)
			return false
		elif distance > max_range:
			controller.log_combat_message("%s moved player too far!" % attack_name)
			return false
	
	# Apply damage only if the attack actually has damage
	var has_damage = attack_data["base_damage"] > 0 or attack_data["damage_scaling"].size() > 0
	
	if has_damage:
		var damage = AttackDatabase.calculate_attack_damage(attack_name, controller.player.stats, controller.player.get_weapon_damage_bonus())
		
		if randf() < attack_accuracy:
			controller.enemy.take_damage(damage)
			controller.log_combat_message("Player uses %s for %d damage!" % [attack_name, damage])
			
			# Show damage number
			if controller.damage_number_manager:
				controller.damage_number_manager.show_damage(damage, controller.enemy_position)
		else:
			controller.log_combat_message("Player's %s misses!" % [attack_name])
			
			# Show miss indicator
			if controller.damage_number_manager:
				controller.damage_number_manager.show_miss(controller.enemy_position)
	else:
		# Utility ability - no damage, just log the use
		controller.log_combat_message("Player uses %s!" % [attack_name])
	
	# Set cooldown if attack has one
	var cooldown = attack_data.get("cooldown", 0)
	if cooldown > 0:
		controller.set_attack_cooldown(attack_name, cooldown)
	
	return true

func execute_basic_attack(controller: CombatController) -> bool:
	# Fallback attack if no attacks equipped
	var damage = AttackDatabase.calculate_attack_damage("Arcane Bolt", controller.player.stats, controller.player.get_weapon_damage_bonus())
	controller.enemy.take_damage(damage)
	controller.log_combat_message("Player uses Arcane Bolt for %d damage!" % damage)
	return true

func execute_special_effects(controller: CombatController):
	# Pass the CombatController directly to SpecialEffectsHandler
	SpecialEffectsHandler.execute_special_effects(attack_name, controller)

func can_execute(controller: CombatController) -> bool:
	# Check if player has this attack equipped
	if attack_name == "Basic Attack":
		return true  # Basic attack is always available
	
	if attack_name not in controller.player.equipped_attacks:
		controller.log_combat_message("You don't have %s equipped!" % attack_name)
		return false
	
	# Check if attack is on cooldown
	var cooldown_remaining = controller.get_attack_cooldown(attack_name)
	if cooldown_remaining > 0:
		controller.log_combat_message("%s is on cooldown for %d more turns!" % [attack_name, cooldown_remaining])
		return false
	
	# Check range
	var attack_data = AttackDatabase.get_attack_data(attack_name)
	var min_range = attack_data["min_range"]
	var max_range = attack_data["max_range"]
	var distance = abs(controller.player_position - controller.enemy_position)
	
	if distance < min_range:
		controller.log_combat_message("Too close to use %s! (Distance: %d, Min Range: %d)" % [attack_name, distance, min_range])
		return false
	elif distance > max_range:
		controller.log_combat_message("Too far to use %s! (Distance: %d, Max Range: %d)" % [attack_name, distance, max_range])
		return false
	
	return true

func get_display_name() -> String:
	if attack_name == "Basic Attack":
		return "Basic Attack"
	
	# Get attack data for display
	var attack_data = AttackDatabase.get_attack_data(attack_name)
	
	# Use base damage for display (without player stats) to avoid errors
	var base_damage = attack_data["base_damage"]
	
	# Format range display
	var min_range = attack_data["min_range"]
	var max_range = attack_data["max_range"]
	var range_text = ""
	if min_range == max_range:
		range_text = "RNG:%d" % min_range
	else:
		range_text = "RNG:%d-%d" % [min_range, max_range]
	
	# Add cooldown info if available
	var cooldown = attack_data.get("cooldown", 0)
	var cooldown_text = ""
	if cooldown > 0:
		cooldown_text = " CD:%d" % cooldown
	
	# Add scaling info for display
	var scaling = attack_data["damage_scaling"]
	var scaling_text = ""
	if scaling.size() > 0:
		var scaling_parts: Array[String] = []
		for stat_name in scaling.keys():
			var factor = scaling[stat_name]
			scaling_parts.append("%s:%.1f" % [stat_name, factor])
		scaling_text = " SCALING:" + ",".join(scaling_parts)
	
	return "%s (DMG:%d %s ACC:%d%%%s%s)" % [
		attack_name, 
		base_damage, 
		range_text,
		int(attack_data["accuracy"] * 100),
		cooldown_text,
		scaling_text
	]

func get_detailed_info(controller: CombatController) -> Dictionary:
	var attack_data = AttackDatabase.get_attack_data(attack_name)
	var damage = AttackDatabase.calculate_attack_damage(attack_name, controller.player.stats, controller.player.get_weapon_damage_bonus())
	
	return {
		"name": attack_name,
		"damage": damage,
		"min_range": attack_data["min_range"],
		"max_range": attack_data["max_range"],
		"accuracy": attack_data["accuracy"],
		"description": attack_data["description"],
		"special_effects": attack_data["special_effects"]
	} 
