class_name SpecialAction
extends CombatAction

enum SpecialActionType {
	RUN,
	DEFEND,
	WAIT,
	USE_ITEM,
	MENU_ACTION
}

var action_type: SpecialActionType
var success_chance: float = 1.0
var custom_execution: Callable

func _init(special_type: SpecialActionType, chance: float = 1.0, custom_func: Callable = Callable()):
	action_type = special_type
	success_chance = chance
	custom_execution = custom_func
	
	var type_name = ""
	match action_type:
		SpecialActionType.RUN:
			type_name = "Run"
			description = "Attempt to run away from combat"
		SpecialActionType.DEFEND:
			type_name = "Defend"
			description = "Take a defensive stance"
		SpecialActionType.WAIT:
			type_name = "Wait"
			description = "Wait and do nothing"
		SpecialActionType.USE_ITEM:
			type_name = "Use Item"
			description = "Use an item"
		_:
			type_name = "Menu Action"
			description = "Navigate the combat menu"
	
	super._init(type_name, description)

func execute(controller: CombatController) -> bool:
	if not can_execute(controller):
		return false
	
	# If we have a custom execution function, use it
	if custom_execution.is_valid():
		return custom_execution.call(controller)
	
	# Otherwise, use default behavior
	match action_type:
		SpecialActionType.RUN:
			return execute_run(controller)
		SpecialActionType.DEFEND:
			return execute_defend(controller)
		SpecialActionType.WAIT:
			return execute_wait(controller)
		SpecialActionType.USE_ITEM:
			return execute_use_item(controller)
		_:
			return false

func execute_run(controller: CombatController) -> bool:
	if randf() < success_chance:
		controller.log_combat_message("Successfully ran away!")
		controller.end_combat(false)  # Player ran away, so they didn't win
		return true
	else:
		controller.log_combat_message("Failed to run away!")
		return true  # Still counts as executed, just failed

func execute_defend(controller: CombatController) -> bool:
	controller.log_combat_message("Player takes a defensive stance!")
	# Could add defense bonus logic here
	return true

func execute_wait(controller: CombatController) -> bool:
	controller.log_combat_message("Player waits...")
	return true

func execute_use_item(controller: CombatController) -> bool:
	controller.log_combat_message("No items available to use!")
	return false

func can_execute(controller: CombatController) -> bool:
	match action_type:
		SpecialActionType.RUN:
			return true  # Can always try to run
		SpecialActionType.DEFEND:
			return true  # Can always defend
		SpecialActionType.WAIT:
			return true  # Can always wait
		SpecialActionType.USE_ITEM:
			return false  # No items implemented yet
		_:
			return false

# Override to handle custom display names
func get_display_name() -> String:
	# If this is a custom action (has custom execution), use the action name
	if custom_execution.is_valid():
		return action_name
	
	# Otherwise use the default behavior
	match action_type:
		SpecialActionType.RUN:
			return "Run"
		SpecialActionType.DEFEND:
			return "Defend"
		SpecialActionType.WAIT:
			return "Wait"
		SpecialActionType.USE_ITEM:
			return "Use Item"
		SpecialActionType.MENU_ACTION:
			return action_name  # Use the custom action name for menu actions
		_:
			return action_name 