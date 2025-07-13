class_name EnemyAttackAction
extends RefCounted

var attack_name: String
var damage: int
var hit_chance: float
var target_position: int

func _init(enemy_attack_name: String, attack_damage: int, accuracy: float, target_pos: int):
	attack_name = enemy_attack_name
	damage = attack_damage
	hit_chance = accuracy
	target_position = target_pos

func execute(controller: CombatController) -> bool:
	# Determine if attack hits
	if randf() < hit_chance:
		# Attack hits
		controller.player.take_damage(damage)
		controller.log_combat_message("%s uses %s for %d damage!" % [controller.enemy.name, attack_name, damage])
		
		# Show damage number
		if controller.damage_number_manager:
			controller.damage_number_manager.show_damage(damage, target_position)
		
		return true
	else:
		# Attack misses
		controller.log_combat_message("%s's %s misses!" % [controller.enemy.name, attack_name])
		
		# Show miss indicator
		if controller.damage_number_manager:
			controller.damage_number_manager.show_miss(target_position)
		
		return true  # Still counts as executed, just missed 