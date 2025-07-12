class_name SpecialEffectsHandler
extends Resource

# Special effects handler for combat
# This class handles all special attack effects in a modular way

# Execute special effects for an attack
static func execute_special_effects(attack_name: String, combat_manager: CombatManager, effect_context: Dictionary = {}):
	var effects = AttackDatabase.get_special_effects(attack_name)
	
	for effect_id in effects:
		execute_effect(effect_id, combat_manager, effect_context)

# Execute a single special effect
static func execute_effect(effect_id: String, combat_manager: CombatManager, context: Dictionary = {}):
	match effect_id:
		"move_toward_target":
			handle_move_toward_target(combat_manager, context)
		"move_backward":
			handle_move_backward(combat_manager, context)
		"move_forward":
			handle_move_forward(combat_manager, context)
		"apply_poison":
			handle_apply_poison(combat_manager, context)
		"apply_burn":
			handle_apply_burn(combat_manager, context)
		# Add more effects here as needed
		_:
			print("Unknown special effect: ", effect_id)

# Effect: Move player toward the target
static func handle_move_toward_target(combat_manager: CombatManager, context: Dictionary):
	var player_pos = combat_manager.player_position
	var enemy_pos = combat_manager.enemy_position
	
	# Calculate direction toward enemy
	var direction = 1 if enemy_pos > player_pos else -1
	var new_position = player_pos + direction
	
	# Check if movement is valid
	if new_position >= 0 and new_position <= 7 and new_position != enemy_pos:
		combat_manager.player_position = new_position
		combat_manager.log_combat_message("Player lunges forward to position %d!" % new_position)
		combat_manager.update_battlefield()  # Update visual
	else:
		combat_manager.log_combat_message("Cannot move closer to target!")

# Effect: Move player backward (away from target)
static func handle_move_backward(combat_manager: CombatManager, context: Dictionary):
	var player_pos = combat_manager.player_position
	var enemy_pos = combat_manager.enemy_position
	
	# Calculate direction away from enemy
	var direction = -1 if enemy_pos > player_pos else 1
	var new_position = player_pos + direction
	
	# Check if movement is valid
	if new_position >= 0 and new_position <= 7 and new_position != enemy_pos:
		combat_manager.player_position = new_position
		combat_manager.log_combat_message("Player steps back to position %d!" % new_position)
		combat_manager.update_battlefield()  # Update visual
	else:
		combat_manager.log_combat_message("Cannot step backward!")

# Effect: Move player forward (toward higher position numbers)
static func handle_move_forward(combat_manager: CombatManager, context: Dictionary):
	var player_pos = combat_manager.player_position
	var enemy_pos = combat_manager.enemy_position
	var new_position = player_pos + 1
	
	# Check if movement is valid
	if new_position >= 0 and new_position <= 7 and new_position != enemy_pos:
		combat_manager.player_position = new_position
		combat_manager.log_combat_message("Player moves forward to position %d!" % new_position)
		combat_manager.update_battlefield()  # Update visual
	else:
		combat_manager.log_combat_message("Cannot move forward!")

# Effect: Apply poison to enemy
static func handle_apply_poison(combat_manager: CombatManager, context: Dictionary):
	var duration = context.get("duration", 3)  # Default 3 turns
	var damage = context.get("damage", 2)      # Default 2 damage per turn
	
	var poison_effect = PoisonEffect.new(duration, damage, "Player Attack")
	combat_manager.status_manager.add_effect_to_enemy(poison_effect)
	combat_manager.log_combat_message("Enemy is poisoned for %d turns!" % duration)

# Effect: Apply burn to enemy  
static func handle_apply_burn(combat_manager: CombatManager, context: Dictionary):
	var duration = context.get("duration", 2)  # Default 2 turns
	var damage = context.get("damage", 3)      # Default 3 damage per turn
	
	var burn_effect = BurnEffect.new(duration, damage, "Player Attack")
	combat_manager.status_manager.add_effect_to_enemy(burn_effect)
	combat_manager.log_combat_message("Enemy is burning for %d turns!" % duration)

# Helper: Check if effect modifies movement
static func is_movement_effect(effect_id: String) -> bool:
	return effect_id in ["move_toward_target", "move_backward", "move_forward"]

# Helper: Check if effect applies status
static func is_status_effect(effect_id: String) -> bool:
	return effect_id in ["apply_poison", "apply_burn"]

# Helper: Get effect description for UI
static func get_effect_description(effect_id: String) -> String:
	match effect_id:
		"move_toward_target":
			return "Moves toward enemy"
		"move_backward":
			return "Steps backward"
		"move_forward":
			return "Moves forward"
		"apply_poison":
			return "Applies poison"
		"apply_burn":
			return "Applies burn"
		_:
			return "Unknown effect"
