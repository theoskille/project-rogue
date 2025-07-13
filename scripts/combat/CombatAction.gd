class_name CombatAction
extends RefCounted

# Base class for all combat actions
var action_name: String
var description: String
var cost: int = 1  # Action points or similar resource

func _init(name: String, desc: String = "", action_cost: int = 1):
	action_name = name
	description = desc
	cost = action_cost

# Abstract method - must be implemented by subclasses
func execute(controller: CombatController) -> bool:
	# Return true if action was successful, false if it failed
	push_error("execute() method must be implemented by subclass")
	return false

# Virtual method - can be overridden by subclasses
func can_execute(controller: CombatController) -> bool:
	# Check if this action can be executed
	return true

# Virtual method - can be overridden by subclasses
func get_description() -> String:
	return description

# Virtual method - can be overridden by subclasses
func get_display_name() -> String:
	return action_name 