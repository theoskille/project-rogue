class_name MoveAction
extends CombatAction

enum MoveDirection {
	FORWARD,
	BACKWARD,
	TOWARD_TARGET,
	AWAY_FROM_TARGET
}

var direction: MoveDirection
var distance: int = 1

func _init(move_direction: MoveDirection, move_distance: int = 1):
	direction = move_direction
	distance = move_distance
	
	var direction_name = ""
	match direction:
		MoveDirection.FORWARD:
			direction_name = "Forward"
			description = "Move forward one position"
		MoveDirection.BACKWARD:
			direction_name = "Backward"
			description = "Move backward one position"
		MoveDirection.TOWARD_TARGET:
			direction_name = "Toward Target"
			description = "Move toward the enemy"
		MoveDirection.AWAY_FROM_TARGET:
			direction_name = "Away from Target"
			description = "Move away from the enemy"
	
	super._init("Move " + direction_name, description)

func execute(controller: CombatController) -> bool:
	if not can_execute(controller):
		return false
	
	var new_position = calculate_new_position(controller)
	
	# Check bounds and enemy collision
	if new_position < 0 or new_position > 7:
		controller.log_combat_message("Can't move there - out of bounds!")
		return false
	
	if new_position == controller.enemy_position:
		controller.log_combat_message("Can't move there - enemy is blocking!")
		return false
	
	controller.player_position = new_position
	controller.log_combat_message("Player moves to position %d" % controller.player_position)
	controller.emit_signal("battlefield_updated")
	return true

func calculate_new_position(controller: CombatController) -> int:
	match direction:
		MoveDirection.FORWARD:
			return controller.player_position + distance
		MoveDirection.BACKWARD:
			return controller.player_position - distance
		MoveDirection.TOWARD_TARGET:
			var direction_to_enemy = 1 if controller.enemy_position > controller.player_position else -1
			return controller.player_position + (direction_to_enemy * distance)
		MoveDirection.AWAY_FROM_TARGET:
			var direction_away_from_enemy = -1 if controller.enemy_position > controller.player_position else 1
			return controller.player_position + (direction_away_from_enemy * distance)
		_:
			return controller.player_position

func can_execute(controller: CombatController) -> bool:
	# Check if player is paralyzed
	if controller.status_manager.player_has_effect("paralysis"):
		controller.log_combat_message("Cannot move - you are paralyzed!")
		return false
	
	# Check if movement would be valid
	var new_position = calculate_new_position(controller)
	return new_position >= 0 and new_position <= 7 and new_position != controller.enemy_position

func get_display_name() -> String:
	match direction:
		MoveDirection.FORWARD:
			return "Move Forward"
		MoveDirection.BACKWARD:
			return "Move Back"
		MoveDirection.TOWARD_TARGET:
			return "Move Toward Target"
		MoveDirection.AWAY_FROM_TARGET:
			return "Move Away from Target"
		_:
			return action_name 