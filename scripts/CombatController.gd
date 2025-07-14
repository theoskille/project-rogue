class_name CombatController
extends RefCounted

# Combat state
var player: Player
var enemy: Enemy
var status_manager: StatusEffectManager
var cooldown_manager: CooldownManager
var animation_overlay: CombatAnimationOverlay
var damage_number_manager: DamageNumberManager

# NEW: State machine
var state_machine: CombatStateMachine

# Combat state - simplified, state machine handles the rest
var player_position: int = 2  # 0-7 on battlefield
var enemy_position: int = 5   # Start 2 tiles apart

# Menu state
var selected_action: int = 0
var current_menu: String = "main"  # "main" or "attack"
var main_actions: Array[CombatAction] = []  # Will be populated by ActionFactory
var attack_actions: Array[CombatAction] = []  # Will be populated from player's equipped attacks

# Pending action to resolve after animation
var pending_action: CombatAction
var pending_enemy_action: EnemyAttackAction

# Signals for UI updates
signal combat_state_changed
signal player_turn_started
signal enemy_turn_started
signal combat_ended(player_won: bool)
signal combat_log_message(message: String)
signal battlefield_updated
signal actions_menu_updated
signal enemy_turn_delay_started

func _init(p: Player):
	player = p
	status_manager = StatusEffectManager.new()
	cooldown_manager = CooldownManager.new()
	
	# NEW: Initialize state machine
	state_machine = CombatStateMachine.new()
	state_machine.state_changed.connect(_on_state_changed)
	state_machine.turn_changed.connect(_on_turn_changed)
	state_machine.combat_started.connect(_on_combat_started)
	state_machine.combat_ended.connect(_on_combat_ended)
	
	update_actions()

func set_animation_overlay(overlay: CombatAnimationOverlay):
	animation_overlay = overlay
	if animation_overlay:
		animation_overlay.animation_completed.connect(_on_animation_completed)
		animation_overlay.enemy_animation_completed.connect(_on_enemy_animation_completed)

func set_damage_number_manager(manager: DamageNumberManager):
	damage_number_manager = manager

func initialize_combat(enemy_data: Enemy):
	enemy = enemy_data
	player_position = 2
	enemy_position = 5
	current_menu = "main"
	selected_action = 0
	
	# Clear any previous status effects
	status_manager.clear_all_effects()
	
	# Update actions from player's equipped attacks
	update_actions()
	
	# NEW: Use state machine to start combat
	state_machine.start_combat(player.get_speed(), enemy.get_speed())
	
	log_combat_message("Combat begins against %s!" % enemy.name)
	
	# If enemy goes first, take enemy turn
	if state_machine.current_turn == "enemy":
		emit_signal("enemy_turn_delay_started")

# NEW: State machine event handlers
func _on_state_changed(old_state: CombatStateMachine.CombatState, new_state: CombatStateMachine.CombatState):
	emit_signal("combat_state_changed")

func _on_turn_changed(new_turn: String):
	if new_turn == "player":
		emit_signal("player_turn_started")
	elif new_turn == "enemy":
		emit_signal("enemy_turn_started")

func _on_combat_started():
	# Combat started - trigger UI update
	emit_signal("combat_state_changed")

func _on_combat_ended():
	# Combat ended - trigger UI update
	emit_signal("combat_state_changed")

func update_actions():
	# Update main actions
	main_actions = ActionFactory.create_main_actions()
	
	# Update attack actions from player's equipped attacks (filter out cooldowns)
	attack_actions = ActionFactory.create_attack_actions(player, cooldown_manager.get_all_cooldowns())
	
	# Add "Back" action to attack menu
	var back_action = ActionFactory.create_custom_action("Back", "Return to main menu", func(controller): 
		controller.close_attack_menu()
		return true
	)
	attack_actions.append(back_action)

# Cooldown management methods
func get_attack_cooldown(attack_name: String) -> int:
	return cooldown_manager.get_cooldown(attack_name)

func set_attack_cooldown(attack_name: String, turns: int):
	cooldown_manager.add_cooldown(attack_name, turns)

func decrement_cooldowns():
	cooldown_manager.tick_cooldowns()

func get_current_actions() -> Array[CombatAction]:
	if current_menu == "main":
		return main_actions
	else:
		return attack_actions

func get_current_action_names() -> Array[String]:
	var actions = get_current_actions()
	var names: Array[String] = []
	
	for action in actions:
		if action is AttackAction:
			# For attack actions, get detailed display name
			names.append(action.get_display_name())
		else:
			# For other actions, use simple display name
			names.append(action.get_display_name())
	
	return names

func navigate_menu(direction: int):
	var current_actions = get_current_actions()
	selected_action = (selected_action + direction) % current_actions.size()
	if selected_action < 0:
		selected_action = current_actions.size() - 1
	emit_signal("actions_menu_updated")

func execute_selected_action():
	var current_actions = get_current_actions()
	if selected_action >= current_actions.size():
		return
	
	var action = current_actions[selected_action]
	
	if current_menu == "main":
		match selected_action:
			0: # Attack
				open_attack_menu()
			_:
				# Execute non-attack actions immediately
				if action.execute(self):
					end_player_turn()
	elif current_menu == "attack":
		if action.action_name == "Back":
			close_attack_menu()
		else:
			# Execute attack actions with animation
			execute_attack_with_animation(action)

func execute_attack_with_animation(action: CombatAction):
	if not animation_overlay:
		# Fallback: execute immediately if no animation overlay
		if action.execute(self):
			close_attack_menu()
			end_player_turn()
		return
	
	# Pre-execution check for attack actions
	if action is AttackAction:
		var attack_action = action as AttackAction
		
		# Check if attack can be executed before starting animation
		if not attack_action.can_execute(self):
			# Attack cannot be executed, don't start animation
			# The can_execute method will log the appropriate message
			return
	
	# Store the action to resolve after animation
	pending_action = action
	
	# NEW: Use state machine to start animation
	state_machine.start_animation()
	
	# Start animation
	animation_overlay.play_attack_animation(action)
	
	# Close attack menu
	close_attack_menu()

func _on_animation_completed(action: CombatAction):
	# Animation finished, now resolve the action
	state_machine.start_resolving_action()
	
	if pending_action and pending_action == action:
		# Execute the actual game logic
		if action.execute(self):
			end_player_turn()
		
		pending_action = null
		state_machine.start_enemy_turn()

func _on_enemy_animation_completed(attack_name: String):
	# Enemy animation finished, now resolve the action
	state_machine.start_resolving_enemy_action()
	
	if pending_enemy_action and pending_enemy_action.attack_name == attack_name:
		# Execute the actual game logic
		pending_enemy_action.execute(self)
		
		pending_enemy_action = null
		state_machine.start_player_turn()
		
		# End enemy turn after action is resolved
		end_enemy_turn()

func open_attack_menu():
	current_menu = "attack"
	selected_action = 0
	emit_signal("actions_menu_updated")

func close_attack_menu():
	current_menu = "main"
	selected_action = 0
	emit_signal("actions_menu_updated")

func end_player_turn():
	emit_signal("combat_state_changed")
	
	if not enemy.is_alive():
		log_combat_message("%s defeated!" % enemy.name)
		end_combat(true)
		return
	
	# Apply status effects to enemy at end of player turn
	var enemy_status_messages = status_manager.apply_enemy_effects(enemy, self)
	for message in enemy_status_messages:
		log_combat_message(message)
	
	# Check if enemy died from status effects
	if not enemy.is_alive():
		log_combat_message("%s defeated by status effects!" % enemy.name)
		end_combat(true)
		return
	
	# Decrement attack cooldowns at end of player turn
	decrement_cooldowns()
	
	state_machine.start_enemy_turn()
	emit_signal("enemy_turn_delay_started")


func take_enemy_turn():
	if not state_machine.combat_active:
		return
		
	# Simple AI: move closer if far, attack if close
	var distance = abs(player_position - enemy_position)
	
	if distance <= 1:
		# Attack - use animation system
		var attack_name = enemy.get_random_attack()
		var damage = enemy.get_attack_damage(attack_name)
		var hit_chance = 0.7
		
		# Create enemy attack action
		pending_enemy_action = EnemyAttackAction.new(attack_name, damage, hit_chance, player_position)
		
		# Start enemy attack animation
		if animation_overlay:
			state_machine.start_enemy_animation()
			animation_overlay.play_enemy_attack_animation(attack_name)
		else:
			# Fallback: execute immediately if no animation overlay
			pending_enemy_action.execute(self)
			pending_enemy_action = null
			end_enemy_turn()
	else:
		# Check if enemy is paralyzed
		if status_manager.enemy_has_effect("paralysis"):
			log_combat_message("%s is paralyzed and cannot move!" % enemy.name)
			end_enemy_turn()
			return
		
		# Move closer
		var direction = 1 if player_position > enemy_position else -1
		var new_position = enemy_position + direction
		
		if new_position != player_position and new_position >= 0 and new_position <= 7:
			enemy_position = new_position
			log_combat_message("%s moves to position %d" % [enemy.name, enemy_position])
		else:
			log_combat_message("%s can't move closer!" % enemy.name)
		
		end_enemy_turn()

func end_enemy_turn():
	emit_signal("combat_state_changed")
	
	if not player.is_alive():
		log_combat_message("Player defeated!")
		end_combat(false)
		return
	
	# Apply status effects to player at end of enemy turn (including cooldowns)
	var player_status_messages = status_manager.apply_player_effects(player, self)
	for message in player_status_messages:
		log_combat_message(message)
	
	# Check if player died from status effects
	if not player.is_alive():
		log_combat_message("Player defeated by status effects!")
		end_combat(false)
		return
	
	state_machine.start_player_turn()

func end_combat(player_won: bool):
	state_machine.end_combat()
	cooldown_manager.clear_all_cooldowns()
	
	if player_won and enemy:
		# Award XP for defeating the enemy
		var xp_gained = enemy.get_xp_reward()
		player.gain_experience(xp_gained)
		log_combat_message("Gained %d experience points!" % xp_gained)
	
	emit_signal("combat_ended", player_won)

func log_combat_message(message: String):
	emit_signal("combat_log_message", message)

# Getter methods for UI - updated to use state machine
func get_combat_info() -> String:
	if state_machine.is_player_turn():
		if current_menu == "main":
			return "Player Turn - Use W/S to select, SPACE to confirm"
		else:
			return "Select Attack - Use W/S to select, SPACE to confirm"
	else:
		return "%s's Turn..." % enemy.name

func get_player_status_text() -> String:
	return status_manager.get_player_status_text()

func get_enemy_status_text() -> String:
	return status_manager.get_enemy_status_text()

func get_player_stats_text() -> String:
	return "STR:%d INT:%d SPD:%d DEX:%d CON:%d DEF:%d LCK:%d" % [
		player.stats["STR"], player.stats["INT"], player.stats["SPD"], 
		player.stats["DEX"], player.stats["CON"], player.stats["DEF"], player.stats["LCK"]
	]

func get_enemy_stats_text() -> String:
	return "STR:%d INT:%d SPD:%d DEX:%d CON:%d DEF:%d LCK:%d" % [
		enemy.stats["STR"], enemy.stats["INT"], enemy.stats["SPD"], 
		enemy.stats["DEX"], enemy.stats["CON"], enemy.stats["DEF"], enemy.stats["LCK"]
	]

func get_player_level_info() -> Dictionary:
	return player.get_level_info()

func get_player_level_text() -> String:
	var level_info = player.get_level_info()
	return "Level %d - XP: %d/%d (%.1f%%)" % [
		level_info["level"],
		level_info["experience"],
		level_info["experience_to_next"],
		level_info["progress"] * 100
	]

# NEW: Convenience getters for state machine properties
func get_current_state() -> CombatStateMachine.CombatState:
	return state_machine.current_state

func get_current_turn() -> String:
	return state_machine.current_turn

func is_combat_active() -> bool:
	return state_machine.combat_active 
