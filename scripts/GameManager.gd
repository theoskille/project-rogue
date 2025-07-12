extends Control

enum GameState {
	MENU,
	EXPLORATION,
	COMBAT,
	INVENTORY,
	GAME_OVER
}

var current_state: GameState = GameState.MENU

# Manager references
var exploration_manager: ExplorationManager
var combat_manager: CombatManager
var inventory_manager: InventoryManager

# Player instance - accessible by all managers
var player: Player

func _ready():
	# Create player instance
	player = Player.new()
	
	# Get references to managers
	exploration_manager = $ExplorationManager
	combat_manager = $CombatManager
	inventory_manager = $InventoryManager
	
	# Set player reference in managers that need it
	if inventory_manager:
		inventory_manager.set_player(player)
	
	if combat_manager:
		combat_manager.set_player(player)
	
	# You can add player reference to other managers as needed
	# if exploration_manager:
	#     exploration_manager.set_player(player)
	
	# Start in menu state (for now just go to exploration)
	change_state(GameState.EXPLORATION)

func _input(event):
	# Handle global inventory toggle from exploration state
	if event.is_pressed() and event is InputEventKey and event.keycode == KEY_E:
		if current_state == GameState.EXPLORATION:
			change_state(GameState.INVENTORY)
			return
		elif current_state == GameState.INVENTORY:
			change_state(GameState.EXPLORATION)
			return
	
	# Route input to active manager
	match current_state:
		GameState.EXPLORATION:
			if exploration_manager:
				exploration_manager.handle_input(event)
		GameState.COMBAT:
			if combat_manager:
				combat_manager.handle_input(event)
		GameState.INVENTORY:
			if inventory_manager:
				inventory_manager.handle_input(event)

func change_state(new_state: GameState):
	var old_state = current_state
	current_state = new_state
	
	print("State changed from ", GameState.keys()[old_state], " to ", GameState.keys()[new_state])
	
	# Handle state transitions
	match new_state:
		GameState.EXPLORATION:
			show_exploration()
		GameState.COMBAT:
			show_combat()
		GameState.INVENTORY:
			show_inventory()
		GameState.GAME_OVER:
			show_game_over()

func show_exploration():
	if combat_manager:
		combat_manager.hide()
	if inventory_manager:
		inventory_manager.hide()
	if exploration_manager:
		exploration_manager.show()

func show_combat():
	if exploration_manager:
		exploration_manager.hide()
	if inventory_manager:
		inventory_manager.hide()
	if combat_manager:
		combat_manager.show()

func show_inventory():
	if exploration_manager:
		exploration_manager.hide()
	if combat_manager:
		combat_manager.hide()
	if inventory_manager:
		inventory_manager.show()
	# Refresh inventory display when entering
	if inventory_manager:
		inventory_manager.refresh_display()

func show_game_over():
	print("Game Over!")
	# For now just restart
	change_state(GameState.EXPLORATION)

# Called by ExplorationManager when entering combat room
func start_combat(enemy_data: Enemy):
	combat_manager.initialize_combat(enemy_data)
	change_state(GameState.COMBAT)

# Called by CombatManager when combat ends
func end_combat(player_won: bool):
	if player_won:
		change_state(GameState.EXPLORATION)
	else:
		change_state(GameState.GAME_OVER)

# Getter for player instance (for other managers to access)
func get_player() -> Player:
	return player
