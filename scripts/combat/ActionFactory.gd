class_name ActionFactory
extends RefCounted

# Factory class for creating combat actions

static func create_attack_action(attack_name: String) -> AttackAction:
	return AttackAction.new(attack_name)

static func create_move_forward_action() -> MoveAction:
	return MoveAction.new(MoveAction.MoveDirection.FORWARD)

static func create_move_backward_action() -> MoveAction:
	return MoveAction.new(MoveAction.MoveDirection.BACKWARD)

static func create_move_toward_target_action() -> MoveAction:
	return MoveAction.new(MoveAction.MoveDirection.TOWARD_TARGET)

static func create_move_away_from_target_action() -> MoveAction:
	return MoveAction.new(MoveAction.MoveDirection.AWAY_FROM_TARGET)

static func create_run_action() -> SpecialAction:
	return SpecialAction.new(SpecialAction.SpecialActionType.RUN, 0.7)  # 70% success chance

static func create_defend_action() -> SpecialAction:
	return SpecialAction.new(SpecialAction.SpecialActionType.DEFEND)

static func create_wait_action() -> SpecialAction:
	return SpecialAction.new(SpecialAction.SpecialActionType.WAIT)

static func create_use_item_action() -> SpecialAction:
	return SpecialAction.new(SpecialAction.SpecialActionType.USE_ITEM)

# Create all available main actions for a player
static func create_main_actions() -> Array[CombatAction]:
	return [
		create_attack_menu_action(),  # Simple menu option, not detailed attack
		create_move_forward_action(),
		create_move_backward_action(),
		create_run_action()
	]

# Create a simple "Attack" menu option that opens the attack submenu
static func create_attack_menu_action() -> SpecialAction:
	var action = SpecialAction.new(SpecialAction.SpecialActionType.MENU_ACTION, 1.0, func(controller): 
		controller.open_attack_menu()
		return true
	)
	action.action_name = "Attack"  # Set the display name to "Attack"
	return action

# Create attack actions from player's equipped attacks
static func create_attack_actions(player: Player, cooldowns: Dictionary = {}) -> Array[CombatAction]:
	var actions: Array[CombatAction] = []
	
	if player.equipped_attacks.size() > 0:
		for attack_name in player.equipped_attacks:
			# Check if attack is on cooldown
			var cooldown_remaining = cooldowns.get(attack_name, 0)
			if cooldown_remaining <= 0:
				# Attack is available, create action
				actions.append(create_attack_action(attack_name))
			else:
				# Attack is on cooldown, create disabled action
				var disabled_action = create_disabled_attack_action(attack_name, cooldown_remaining)
				actions.append(disabled_action)
	else:
		# Fallback to basic attack
		actions.append(create_attack_action("Basic Attack"))
	
	return actions

# Create a disabled attack action (on cooldown)
static func create_disabled_attack_action(attack_name: String, cooldown_remaining: int) -> SpecialAction:
	var action = SpecialAction.new(SpecialAction.SpecialActionType.WAIT, 0.0, func(controller): 
		controller.log_combat_message("%s is on cooldown for %d more turns!" % [attack_name, cooldown_remaining])
		return false  # Don't end turn
	)
	action.action_name = "%s (CD: %d)" % [attack_name, cooldown_remaining]
	action.description = "This attack is on cooldown"
	return action

# Create a custom action with a custom execution function
static func create_custom_action(name: String, description: String, execution_func: Callable) -> SpecialAction:
	var action = SpecialAction.new(SpecialAction.SpecialActionType.WAIT, 1.0, execution_func)
	action.action_name = name
	action.description = description
	return action 