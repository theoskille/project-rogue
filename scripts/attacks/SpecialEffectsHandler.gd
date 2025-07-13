class_name SpecialEffectsHandler
extends Resource

# Special effects handler for combat
# This class handles all special attack effects in a modular way

# Execute special effects for an attack
static func execute_special_effects(attack_name: String, combat_controller: CombatController, effect_context: Dictionary = {}):
	var effects = AttackDatabase.get_special_effects(attack_name)
	var attack_data = AttackDatabase.get_attack_data(attack_name)
	var effect_parameters = attack_data.get("effect_parameters", {})
	
	for effect_id in effects:
		var params = effect_parameters.get(effect_id, {})
		execute_effect(effect_id, combat_controller, params)

# Execute a single special effect
static func execute_effect(effect_id: String, combat_controller: CombatController, context: Dictionary = {}):
	match effect_id:
		"move_toward_target":
			handle_move_toward_target(combat_controller, context)
		"move_backward":
			handle_move_backward(combat_controller, context)
		"move_forward":
			handle_move_forward(combat_controller, context)
		"apply_poison":
			handle_apply_poison(combat_controller, context)
		"apply_burn":
			handle_apply_burn(combat_controller, context)
		"push_back":
			handle_push_back(combat_controller, context)
		# Add more effects here as needed
		_:
			print("Unknown special effect: ", effect_id)

# Effect: Move player toward the target
static func handle_move_toward_target(combat_controller: CombatController, context: Dictionary):
	var player_pos = combat_controller.player_position
	var enemy_pos = combat_controller.enemy_position
	var distance = context.get("distance", 1) # Default distance is 1
	
	# Calculate direction toward enemy
	var direction = 1 if enemy_pos > player_pos else -1
	var new_position = player_pos + (direction * distance)
	
	# Check if movement is valid
	if new_position >= 0 and new_position <= 7 and new_position != enemy_pos:
		combat_controller.player_position = new_position
		if distance == 1:
			combat_controller.log_combat_message("Player lunges forward to position %d!" % new_position)
		else:
			combat_controller.log_combat_message("Player lunges forward %d positions!" % distance)
		combat_controller.emit_signal("battlefield_updated")  # Update visual
	else:
		if distance == 1:
			combat_controller.log_combat_message("Cannot move closer to target!")
		else:
			combat_controller.log_combat_message("Cannot move closer to target by %d positions!" % distance)

# Effect: Move player backward (away from target)
static func handle_move_backward(combat_controller: CombatController, context: Dictionary):
	var player_pos = combat_controller.player_position
	var enemy_pos = combat_controller.enemy_position
	var distance = context.get("distance", 1) # Default distance is 1
	
	# Calculate direction away from enemy
	var direction = -1 if enemy_pos > player_pos else 1
	var new_position = player_pos + (direction * distance)
	
	# Check if movement is valid
	if new_position >= 0 and new_position <= 7 and new_position != enemy_pos:
		combat_controller.player_position = new_position
		if distance == 1:
			combat_controller.log_combat_message("Player steps back to position %d!" % new_position)
		else:
			combat_controller.log_combat_message("Player steps back %d positions!" % distance)
		combat_controller.emit_signal("battlefield_updated")  # Update visual
	else:
		if distance == 1:
			combat_controller.log_combat_message("Cannot step backward!")
		else:
			combat_controller.log_combat_message("Cannot step backward by %d positions!" % distance)

# Effect: Move player forward (toward higher position numbers)
static func handle_move_forward(combat_controller: CombatController, context: Dictionary):
	var player_pos = combat_controller.player_position
	var enemy_pos = combat_controller.enemy_position
	var distance = context.get("distance", 1) # Default distance is 1
	var new_position = player_pos + distance
	
	# Check if movement is valid
	if new_position >= 0 and new_position <= 7 and new_position != enemy_pos:
		combat_controller.player_position = new_position
		if distance == 1:
			combat_controller.log_combat_message("Player moves forward to position %d!" % new_position)
		else:
			combat_controller.log_combat_message("Player moves forward %d positions!" % distance)
		combat_controller.emit_signal("battlefield_updated")  # Update visual
	else:
		if distance == 1:
			combat_controller.log_combat_message("Cannot move forward!")
		else:
			combat_controller.log_combat_message("Cannot move forward by %d positions!" % distance)

# Effect: Apply poison to enemy
static func handle_apply_poison(combat_controller: CombatController, context: Dictionary):
	var duration = context.get("duration", 3)  # Default 3 turns
	var damage = context.get("damage", 2)      # Default 2 damage per turn
	
	var poison_effect = PoisonEffect.new(duration, damage, "Player Attack")
	combat_controller.status_manager.add_effect_to_enemy(poison_effect)
	combat_controller.log_combat_message("Enemy is poisoned for %d turns!" % duration)

# Effect: Apply burn to enemy  
static func handle_apply_burn(combat_controller: CombatController, context: Dictionary):
	var duration = context.get("duration", 2)  # Default 2 turns
	var damage = context.get("damage", 3)      # Default 3 damage per turn
	
	var burn_effect = BurnEffect.new(duration, damage, "Player Attack")
	combat_controller.status_manager.add_effect_to_enemy(burn_effect)
	combat_controller.log_combat_message("Enemy is burning for %d turns!" % duration)

# Effect: Push enemy back
static func handle_push_back(combat_controller: CombatController, context: Dictionary):
	var player_pos = combat_controller.player_position
	var enemy_pos = combat_controller.enemy_position
	
	# Calculate direction away from player
	var direction = 1 if enemy_pos > player_pos else -1
	var new_position = enemy_pos + direction
	
	# Check if movement is valid
	if new_position >= 0 and new_position <= 7 and new_position != player_pos:
		combat_controller.enemy_position = new_position
		combat_controller.log_combat_message("Enemy is pushed back to position %d!" % new_position)
		combat_controller.emit_signal("battlefield_updated")  # Update visual
	else:
		combat_controller.log_combat_message("Cannot push enemy back!")

# Helper: Check if effect modifies movement
static func is_movement_effect(effect_id: String) -> bool:
	return effect_id in ["move_toward_target", "move_backward", "move_forward", "push_back"]

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
		"push_back":
			return "Push back"
		_:
			return "Unknown effect"
