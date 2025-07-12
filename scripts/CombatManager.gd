class_name CombatManager
extends Control

var player: Player  # Will be set by GameManager
var enemy: Enemy
var game_manager: Node
var status_manager: StatusEffectManager  # Handles DOT and other ongoing effects

# Combat state
var player_position: int = 2  # 0-7 on battlefield
var enemy_position: int = 5   # Start 2 tiles apart
var current_turn: String = ""  # "player" or "enemy"
var combat_active: bool = false

# Menu state
var selected_action: int = 0
var current_menu: String = "main"  # "main" or "attack"
var main_action_options: Array[String] = ["Attack", "Move Forward", "Move Back", "Run"]
var attack_options: Array[String] = []  # Will be populated from player's equipped attacks

# No longer need attack_data - using AttackDatabase instead

# UI elements - direct children of CombatManager
@onready var combat_info: Label = $HeaderContainer/CombatInfo
@onready var battlefield_container: HBoxContainer = $BattlefieldContainer/Battlefield
@onready var actions_menu: VBoxContainer = $MenuContainer/MenuMargin/ActionsMenu
@onready var status_display: Label = $StatsContainer/StatsMargin/StatusDisplay
@onready var combat_log_panel: PanelContainer = $LogContainer
@onready var combat_log_center: MarginContainer = $LogContainer/LogMargin
@onready var combat_log_scroll: ScrollContainer = $LogContainer/LogMargin/ScrollContainer
@onready var combat_log_vbox: VBoxContainer = $LogContainer/LogMargin/ScrollContainer/VBoxContainer

func _ready():
	game_manager = get_parent()
	status_manager = StatusEffectManager.new()
	# Note: player will be set by GameManager via set_player()
	setup_battlefield()
	setup_actions_menu()

# New method to set the player reference from GameManager
func set_player(p: Player):
	player = p

func setup_battlefield():
	# Create 8 battlefield tiles - static size that won't stretch
	for i in range(8):
		var tile = ColorRect.new()
		tile.custom_minimum_size = Vector2(80, 80)
		tile.size = Vector2(80, 80)  # Set explicit size
		tile.color = Color.DARK_GRAY
		
		# Prevent the tile from expanding
		tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		battlefield_container.add_child(tile)

func setup_actions_menu():
	# Create action buttons
	for i in range(main_action_options.size()):
		var action_label = Label.new()
		action_label.text = main_action_options[i]
		actions_menu.add_child(action_label)
	
	update_actions_menu()

func get_current_options() -> Array[String]:
	if current_menu == "main":
		return main_action_options
	else:
		return attack_options

func update_attack_options():
	# Build attack menu from player's equipped attacks + Back option
	attack_options.clear()
	
	if player and player.equipped_attacks.size() > 0:
		for attack in player.equipped_attacks:
			attack_options.append(attack)
	else:
		# Fallback if no attacks equipped
		attack_options.append("Basic Attack")
	
	# Always add Back option
	attack_options.append("Back")

func initialize_combat(enemy_data: Enemy):
	# Ensure we have a player reference
	if not player:
		print("ERROR: CombatManager has no player reference!")
		return
	
	clear_combat_log()
	
	enemy = enemy_data
	player_position = 2
	enemy_position = 5
	combat_active = true
	current_menu = "main"
	selected_action = 0
	
	# Clear any previous status effects
	status_manager.clear_all_effects()
	
	# Update attack options from player's equipped attacks
	update_attack_options()
	
	# Determine who goes first based on speed
	if player.get_speed() >= enemy.get_speed():
		current_turn = "player"
	else:
		current_turn = "enemy"
	
	log_combat_message("Combat begins!")
	update_display()
	
	# If enemy goes first, take enemy turn
	if current_turn == "enemy":
		call_deferred("take_enemy_turn")

func handle_input(event: InputEvent):
	if not combat_active:
		return
		
	if not event.is_pressed():
		return
		
	if event is InputEventKey:
		if current_turn == "player":
			match event.keycode:
				KEY_W, KEY_UP:
					navigate_menu(-1)
				KEY_S, KEY_DOWN:
					navigate_menu(1)
				KEY_SPACE:
					execute_selected_action()

func navigate_menu(direction: int):
	var current_options = get_current_options()
	selected_action = (selected_action + direction) % current_options.size()
	if selected_action < 0:
		selected_action = current_options.size() - 1
	update_actions_menu()

func update_actions_menu():
	var current_options = get_current_options()
	
	# Clear existing labels
	for child in actions_menu.get_children():
		child.queue_free()
	
	# Create new labels for current menu
	for i in range(current_options.size()):
		var label = Label.new()
		
		if i == selected_action:
			label.modulate = Color.YELLOW
			if current_menu == "attack" and current_options[i] != "Back":
				# Show attack details from AttackDatabase
				var attack_data = AttackDatabase.get_attack_data(current_options[i])
				var damage = AttackDatabase.calculate_attack_damage(current_options[i], player.stats, player.get_weapon_damage_bonus())
				label.text = "> %s (DMG:%d RNG:%d ACC:%d%%) <" % [
					current_options[i], 
					damage, 
					attack_data["range"], 
					int(attack_data["accuracy"] * 100)
				]
			else:
				label.text = "> " + current_options[i] + " <"
		else:
			label.modulate = Color.WHITE
			if current_menu == "attack" and current_options[i] != "Back":
				# Show attack details from AttackDatabase
				var attack_data = AttackDatabase.get_attack_data(current_options[i])
				var damage = AttackDatabase.calculate_attack_damage(current_options[i], player.stats, player.get_weapon_damage_bonus())
				label.text = "  %s (DMG:%d RNG:%d ACC:%d%%)" % [
					current_options[i], 
					damage, 
					attack_data["range"], 
					int(attack_data["accuracy"] * 100)
				]
			else:
				label.text = "  " + current_options[i]
		
		actions_menu.add_child(label)

func execute_selected_action():
	if current_menu == "main":
		match selected_action:
			0: # Attack
				open_attack_menu()
			1: # Move Forward
				player_move(1)
			2: # Move Back
				player_move(-1)
			3: # Run
				player_run()
	elif current_menu == "attack":
		var attack_name = attack_options[selected_action]
		if attack_name == "Back":
			close_attack_menu()
		else:
			player_attack(attack_name)

func open_attack_menu():
	current_menu = "attack"
	selected_action = 0
	update_actions_menu()
	update_combat_info()

func close_attack_menu():
	current_menu = "main"
	selected_action = 0
	update_actions_menu()
	update_combat_info()

func player_attack(attack_name: String):
	# Handle special case attacks first
	if attack_name == "Basic Attack":
		# Fallback attack if no attacks equipped
		var damage = 5
		enemy.take_damage(damage)
		log_combat_message("Player uses Basic Attack for %d damage!" % damage)
		current_menu = "main"
		selected_action = 0
		end_player_turn()
		return
	
	# Get attack data from AttackDatabase
	var attack_data = AttackDatabase.get_attack_data(attack_name)
	var damage = AttackDatabase.calculate_attack_damage(attack_name, player.stats, player.get_weapon_damage_bonus())
	var range = attack_data["range"]
	var accuracy = attack_data["accuracy"]
	
	var distance = abs(player_position - enemy_position)
	
	# Check range
	if distance > range:
		log_combat_message("Too far to use %s! (Distance: %d, Range: %d)" % [attack_name, distance, range])
		return
	
	# Execute special effects BEFORE damage (for movement attacks)
	var effects = AttackDatabase.get_special_effects(attack_name)
	if effects.size() > 0:
		SpecialEffectsHandler.execute_special_effects(attack_name, self)
		# Recalculate distance after potential movement
		distance = abs(player_position - enemy_position)
		
		# Check range again after movement
		if distance > range:
			log_combat_message("%s moved player out of range!" % attack_name)
			current_menu = "main"
			selected_action = 0
			end_player_turn()
			return
	
	# Apply damage
	if randf() < accuracy:
		enemy.take_damage(damage)
		log_combat_message("Player uses %s for %d damage!" % [attack_name, damage])
	else:
		log_combat_message("Player's %s misses!" % attack_name)
	
	# Close attack menu and end turn
	current_menu = "main"
	selected_action = 0
	end_player_turn()

func player_move(direction: int):
	var new_position = player_position + direction
	
	# Check bounds and enemy collision
	if new_position < 0 or new_position > 7:
		log_combat_message("Can't move there - out of bounds!")
		return
	
	if new_position == enemy_position:
		log_combat_message("Can't move there - enemy is blocking!")
		return
	
	player_position = new_position
	log_combat_message("Player moves to position %d" % player_position)
	end_player_turn()

func player_run():
	var run_chance = 0.7  # 70% chance to run
	if randf() < run_chance:
		log_combat_message("Successfully ran away!")
		end_combat(false)
	else:
		log_combat_message("Failed to run away!")
		end_player_turn()

func end_player_turn():
	update_display()
	
	if not enemy.is_alive():
		log_combat_message("Enemy defeated!")
		end_combat(true)
		return
	
	# Apply status effects to enemy at end of player turn
	var enemy_status_messages = status_manager.apply_enemy_effects(enemy, self)
	for message in enemy_status_messages:
		log_combat_message(message)
	
	# Check if enemy died from status effects
	if not enemy.is_alive():
		log_combat_message("Enemy defeated by status effects!")
		end_combat(true)
		return
	
	current_turn = "enemy"
	call_deferred("take_enemy_turn")

func take_enemy_turn():
	if not combat_active:
		return
		
	# Simple AI: move closer if far, attack if close
	var distance = abs(player_position - enemy_position)
	
	if distance <= 1:
		# Attack
		var damage = enemy.get_attack_damage(enemy.get_random_attack())
		var hit_chance = 0.7
		
		if randf() < hit_chance:
			player.take_damage(damage)
			log_combat_message("Enemy hits for %d damage!" % damage)
		else:
			log_combat_message("Enemy misses!")
	else:
		# Move closer
		var direction = 1 if player_position > enemy_position else -1
		var new_position = enemy_position + direction
		
		if new_position != player_position and new_position >= 0 and new_position <= 7:
			enemy_position = new_position
			log_combat_message("Enemy moves to position %d" % enemy_position)
		else:
			log_combat_message("Enemy can't move closer!")
	
	end_enemy_turn()

func end_enemy_turn():
	update_display()
	
	if not player.is_alive():
		log_combat_message("Player defeated!")
		end_combat(false)
		return
	
	# Apply status effects to player at end of enemy turn  
	var player_status_messages = status_manager.apply_player_effects(player, self)
	for message in player_status_messages:
		log_combat_message(message)
	
	# Check if player died from status effects
	if not player.is_alive():
		log_combat_message("Player defeated by status effects!")
		end_combat(false)
		return
	
	current_turn = "player"

func end_combat(player_won: bool):
	combat_active = false
	
	if player_won:
		# Mark room as cleared
		var exploration_manager = game_manager.get_node("ExplorationManager")
		if exploration_manager:
			exploration_manager.room_cleared()
	
	game_manager.end_combat(player_won)

func update_display():
	update_combat_info()
	update_battlefield()
	update_actions_menu()
	
	# Status display with status effects
	var player_status = status_manager.get_player_status_text()
	var enemy_status = status_manager.get_enemy_status_text()
	
	status_display.text = "Player HP: %d/%d\n%sEnemy HP: %d/%d\n%s" % [
		player.current_hp, player.max_hp,
		player_status + "\n" if player_status != "" else "",
		enemy.current_hp, enemy.max_hp,
		enemy_status + "\n" if enemy_status != "" else ""
	]

func update_combat_info():
	# Combat info
	if current_turn == "player":
		if current_menu == "main":
			combat_info.text = "Your Turn - Use W/S to select, SPACE to confirm"
		else:
			combat_info.text = "Select Attack - Use W/S to select, SPACE to confirm"
	else:
		combat_info.text = "Enemy Turn..."
	
	combat_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func update_battlefield():
	# Update battlefield tiles
	for i in range(battlefield_container.get_child_count()):
		var tile = battlefield_container.get_child(i) as ColorRect
		
		# Reset tile
		tile.color = Color.DARK_GRAY
		
		# Clear any existing children (sprites will go here later)
		for child in tile.get_children():
			child.queue_free()
		
		# Add markers for player and enemy positions
		if i == player_position:
			tile.color = Color.BLUE
			var player_marker = Label.new()
			player_marker.text = "P"
			player_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			player_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			player_marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			tile.add_child(player_marker)
		elif i == enemy_position:
			tile.color = Color.RED
			var enemy_marker = Label.new()
			enemy_marker.text = "E"
			enemy_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			enemy_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			enemy_marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			tile.add_child(enemy_marker)
			
# Combat log settings
var max_log_messages: int = 20  # Limit messages to prevent memory issues

func log_combat_message(message: String):
	if not combat_log_vbox:
		print("ERROR VBOX")
	print(message)
	# Create a new label for this message
	var log_label = Label.new()
	log_label.modulate = Color.WHITE
	log_label.text = message
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.custom_minimum_size.x = 200  # Set minimum width for proper wrapping
	
	# Add the label to the VBox
	combat_log_vbox.add_child(log_label)
	print("DEBUG: VBox child count after: ", combat_log_vbox.get_child_count())
	print("DEBUG: VBox size: ", combat_log_vbox.size)
	print("DEBUG: VBox visible: ", combat_log_vbox.visible)
	print("DEBUG: ScrollContainer size: ", combat_log_scroll.size if combat_log_scroll else "null")
	print("DEBUG: Panel size: ", combat_log_panel.size if combat_log_panel else "null")
	
	# Limit the number of messages (remove oldest if too many)
	if combat_log_vbox.get_child_count() > max_log_messages:
		var oldest_message = combat_log_vbox.get_child(0)
		oldest_message.queue_free()
	
	# Auto-scroll to the bottom to show the latest message
	call_deferred("scroll_to_bottom")

func scroll_to_bottom():
	if combat_log_scroll:
		combat_log_scroll.scroll_vertical = combat_log_scroll.get_v_scroll_bar().max_value

func clear_combat_log():
	if combat_log_vbox:
		# Remove all existing log messages
		for child in combat_log_vbox.get_children():
			child.queue_free()
