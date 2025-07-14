class_name CombatStateMachine
extends RefCounted

# Combat state enum - moved from CombatController
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
var current_turn: String = ""  # "player" or "enemy"
var combat_active: bool = false

# Signals for state changes
signal state_changed(old_state: CombatState, new_state: CombatState)
signal turn_changed(new_turn: String)
signal combat_started
signal combat_ended

func start_combat(player_speed: int, enemy_speed: int):
	combat_active = true
	current_state = CombatState.PLAYER_TURN
	
	# Determine who goes first based on speed
	if player_speed >= enemy_speed:
		current_turn = "player"
	else:
		current_turn = "enemy"
	
	combat_started.emit()

func end_combat():
	combat_active = false
	combat_ended.emit()

func transition_to(new_state: CombatState):
	var old_state = current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)

func change_turn(new_turn: String):
	current_turn = new_turn
	turn_changed.emit(new_turn)

# Convenience methods for common state transitions
func start_player_turn():
	change_turn("player")
	transition_to(CombatState.PLAYER_TURN)

func start_enemy_turn():
	change_turn("enemy")
	transition_to(CombatState.ENEMY_TURN)

func start_animation():
	transition_to(CombatState.PLAYING_ANIMATION)

func start_enemy_animation():
	transition_to(CombatState.ENEMY_ANIMATION)

func start_resolving_action():
	transition_to(CombatState.RESOLVING_ACTION)

func start_resolving_enemy_action():
	transition_to(CombatState.RESOLVING_ENEMY_ACTION)

func start_enemy_turn_delay():
	transition_to(CombatState.ENEMY_TURN_DELAY)

# State checking methods
func is_player_turn() -> bool:
	return current_state == CombatState.PLAYER_TURN and current_turn == "player"

func is_enemy_turn() -> bool:
	return current_state == CombatState.ENEMY_TURN and current_turn == "enemy"

func is_animation_playing() -> bool:
	return current_state == CombatState.PLAYING_ANIMATION or current_state == CombatState.ENEMY_ANIMATION

func is_resolving_action() -> bool:
	return current_state == CombatState.RESOLVING_ACTION or current_state == CombatState.RESOLVING_ENEMY_ACTION

func is_enemy_turn_delay() -> bool:
	return current_state == CombatState.ENEMY_TURN_DELAY

# Get current state as string for debugging
func get_state_name() -> String:
	return CombatState.keys()[current_state]

func get_turn_name() -> String:
	return current_turn 