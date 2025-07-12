class_name StatusEffect
extends Resource

# Base class for all status effects
var effect_id: String
var duration: int  # Turns remaining
var source_name: String  # What caused this effect

func _init(id: String = "", turns: int = 0, source: String = "Unknown"):
	effect_id = id
	duration = turns
	source_name = source

# Override in subclasses
func apply_effect(target, combat_manager) -> String:
	return "No effect"

func get_description() -> String:
	return "Unknown effect"

# Reduce duration each turn
func tick_duration():
	duration -= 1

func is_expired() -> bool:
	return duration <= 0
