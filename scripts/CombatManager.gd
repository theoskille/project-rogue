class_name CombatManager
extends Control

var player: Player  # Will be set by GameManager
var game_manager: Node

# New modular components
var combat_controller: CombatController
var combat_ui: CombatUI
var combat_input_handler: CombatInputHandler
var damage_number_manager: DamageNumberManager

# Animation overlay
@onready var animation_overlay: CombatAnimationOverlay = $AnimationOverlay

# Timer for enemy turn delay
var enemy_turn_timer: Timer

# UI elements - direct children of CombatManager
@onready var combat_info: Label = $HeaderContainer/CombatInfo
@onready var battlefield_container: HBoxContainer = $BattlefieldContainer/Battlefield
@onready var actions_menu: VBoxContainer = $MenuContainer/MenuMargin/ActionsMenu
@onready var status_display: Label = $StatsContainer/StatsMargin/StatusDisplay
@onready var combat_log_panel: PanelContainer = $LogContainer
@onready var combat_log_center: MarginContainer = $LogContainer/LogMargin
@onready var combat_log_scroll: ScrollContainer = $LogContainer/LogMargin/ScrollContainer
@onready var combat_log_vbox: VBoxContainer = $LogContainer/LogMargin/ScrollContainer/VBoxContainer
@onready var damage_number_container: Control = $DamageNumberContainer

func _ready():
	game_manager = get_parent()
	
	# Set up enemy turn timer
	enemy_turn_timer = Timer.new()
	enemy_turn_timer.wait_time = 1.0
	enemy_turn_timer.one_shot = true
	enemy_turn_timer.timeout.connect(_on_enemy_turn_timer_timeout)
	add_child(enemy_turn_timer)
	
	# Note: player will be set by GameManager via set_player()

# New method to set the player reference from GameManager
func set_player(p: Player):
	player = p
	# Initialize the modular components
	combat_controller = CombatController.new(player)
	combat_ui = CombatUI.new(combat_controller)
	combat_input_handler = CombatInputHandler.new(combat_controller)
	damage_number_manager = DamageNumberManager.new(damage_number_container, battlefield_container)
	
	# Connect animation overlay
	if animation_overlay:
		combat_controller.set_animation_overlay(animation_overlay)
	
	# Set up damage number manager
	combat_controller.set_damage_number_manager(damage_number_manager)
	
	# Set up the UI references
	setup_ui()
	
	# Connect combat end signal to game manager
	combat_controller.combat_ended.connect(_on_combat_ended)
	
	# Connect enemy turn delay signal
	combat_controller.enemy_turn_delay_started.connect(_on_enemy_turn_delay_started)

func setup_ui():
	# Set UI references for CombatUI
	combat_ui.set_ui_references(
		combat_info,
		battlefield_container,
		actions_menu,
		status_display,
		combat_log_panel,
		combat_log_center,
		combat_log_scroll,
		combat_log_vbox
	)
	
	# Set up the UI components
	combat_ui.setup_battlefield()
	combat_ui.setup_actions_menu()

func handle_input(event: InputEvent):
	# Delegate input handling to the input handler
	combat_input_handler.handle_input(event)

func initialize_combat(enemy_data: Enemy):
	# Delegate combat initialization to the controller
	combat_controller.initialize_combat(enemy_data)
	combat_ui.clear_combat_log()

func _on_combat_ended(player_won: bool):
	# Handle combat end by notifying game manager
	if player_won:
		# Mark room as cleared
		var exploration_manager = game_manager.get_node("ExplorationManager")
		if exploration_manager:
			exploration_manager.room_cleared()
	
	game_manager.end_combat(player_won)

func _on_enemy_turn_delay_started():
	# Start the 1-second delay timer
	enemy_turn_timer.start()

func _on_enemy_turn_timer_timeout():
	# Timer finished, enemy can take their turn
	combat_controller.take_enemy_turn()
