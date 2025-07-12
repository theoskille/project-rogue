class_name PoisonEffect
extends StatusEffect

var damage_per_turn: int

func _init(turns: int = 3, damage: int = 2, source: String = "Poison"):
	super("poison", turns, source)
	damage_per_turn = damage

func apply_effect(target, combat_manager) -> String:
	target.take_damage(damage_per_turn)
	
	# Better way to determine if target is player or enemy
	var target_name = "Enemy"
	if target == combat_manager.player:
		target_name = "Player"
	
	return "%s takes %d poison damage! (%d turns left)" % [
		target_name, 
		damage_per_turn, 
		duration
	]

func get_description() -> String:
	return "Poison (%d damage/turn, %d turns left)" % [damage_per_turn, duration]
