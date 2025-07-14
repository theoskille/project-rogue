class_name ParalysisEffect
extends StatusEffect

func _init(turns: int = 2, source: String = "Paralysis"):
	super("paralysis", turns, source)

func apply_effect(target, combat_manager) -> String:
	# Paralysis doesn't deal damage, just prevents movement
	# The actual movement prevention is handled in the combat system
	
	# Better way to determine if target is player or enemy
	var target_name = "Enemy"
	if target == combat_manager.player:
		target_name = "Player"
	
	return "%s is paralyzed! (%d turns left)" % [target_name, duration]

func get_description() -> String:
	return "Paralyzed (%d turns left)" % duration 