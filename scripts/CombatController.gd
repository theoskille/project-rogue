class_name CombatController
extends RefCounted

# Combat state
var player: Player
var enemy: Enemy
var status_manager: StatusEffectManager
var cooldown_manager: CooldownManager
var animation_overlay: CombatAnimationOverlay
var damage_number_manager: DamageNumberManager

# Combat state
var player_position: int = 2  # 0-7 on battlefield
var enemy_position: int = 5   # Start 2 tiles apart
var current_turn: String = ""  # "player" or "enemy"
var combat_active: bool = false

# Animation state
enum CombatState {
	PLAYER_TURN,
	ENEMY_TURN,
	PLAYING_ANIMATION,
	RESOLVING_ACTION,
	ENEMY_ANIMATION,
	RESOLVING_ENEMY_ACTION,
	ENEMY_TURN_DELAY
}
var current_state: CombatState = CombatState.PLAYER_TURN

# Menu state
var selected_action: int = 0
var current_menu: String = "main"  # "main" or "attack"
var main_actions: Array[CombatAction] = []  # Will be populated by ActionFactory
var attack_actions: Array[CombatAction] = []  # Will be populated from player's equipped attacks

# Pending action to resolve after animation
var pending_action: CombatAction
var pending_enemy_action: EnemyAttackAction

# Cooldowns are now handled by StatusEffectManager

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
	combat_active = true
	current_menu = "main"
	selected_action = 0
	
	# Clear any previous status effects
	status_manager.clear_all_effects()
	
	# Update actions from player's equipped attacks
	update_actions()
	
	# Determine who goes first based on speed
	if player.get_speed() >= enemy.get_speed():
		current_turn = "player"
	else:
		current_turn = "enemy"
	
	log_combat_message("Combat begins against %s!" % enemy.name)
	emit_signal("combat_state_changed")
	
	# If enemy goes first, take enemy turn
	if current_turn == "enemy":
		emit_signal("enemy_turn_delay_started")

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
	
	# Store the action to resolve after animation
	pending_action = action
	
	# Change to animation state
	current_state = CombatState.PLAYING_ANIMATION
	
	# Start animation
	animation_overlay.play_attack_animation(action)
	
	# Close attack menu
	close_attack_menu()

func _on_animation_completed(action: CombatAction):
	# Animation finished, now resolve the action
	current_state = CombatState.RESOLVING_ACTION
	
	if pending_action and pending_action == action:
		# Execute the actual game logic
		if action.execute(self):
			end_player_turn()
		
		pending_action = null
		current_state = CombatState.ENEMY_TURN

func _on_enemy_animation_completed(attack_name: String):
	# Enemy animation finished, now resolve the action
	current_state = CombatState.RESOLVING_ENEMY_ACTION
	
	if pending_enemy_action and pending_enemy_action.attack_name == attack_name:
		# Execute the actual game logic
		pending_enemy_action.execute(self)
		
		pending_enemy_action = null
		current_state = CombatState.PLAYER_TURN
		
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
	
	current_turn = "enemy"
	emit_signal("enemy_turn_started")
	emit_signal("enemy_turn_delay_started")


func take_enemy_turn():
	if not combat_active:
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
			current_state = CombatState.ENEMY_ANIMATION
			animation_overlay.play_enemy_attack_animation(attack_name)
		else:
			# Fallback: execute immediately if no animation overlay
			pending_enemy_action.execute(self)
			pending_enemy_action = null
			end_enemy_turn()
	else:
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
	
	current_turn = "player"
	emit_signal("player_turn_started")

func end_combat(player_won: bool):
	combat_active = false
	cooldown_manager.clear_all_cooldowns()
	
	if player_won and enemy:
		# Award XP for defeating the enemy
		var xp_gained = enemy.get_xp_reward()
		player.gain_experience(xp_gained)
		log_combat_message("Gained %d experience points!" % xp_gained)
	
	emit_signal("combat_ended", player_won)

func log_combat_message(message: String):
	emit_signal("combat_log_message", message)

# Getter methods for UI
func get_combat_info() -> String:
	if current_turn == "player":
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
