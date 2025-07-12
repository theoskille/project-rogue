class_name StatusEffectManager
extends Resource

var player_effects: Array[StatusEffect] = []
var enemy_effects: Array[StatusEffect] = []

# Add status effect to target
func add_effect_to_player(effect: StatusEffect):
	# Check if effect already exists and refresh/stack as needed
	for existing_effect in player_effects:
		if existing_effect.effect_id == effect.effect_id:
			# Refresh duration for same effect type
			existing_effect.duration = max(existing_effect.duration, effect.duration)
			return
	
	player_effects.append(effect)

func add_effect_to_enemy(effect: StatusEffect):
	for existing_effect in enemy_effects:
		if existing_effect.effect_id == effect.effect_id:
			existing_effect.duration = max(existing_effect.duration, effect.duration)
			return
	
	enemy_effects.append(effect)

# Apply all effects for a target
func apply_player_effects(player, combat_manager) -> Array[String]:
	var messages: Array[String] = []
	var effects_to_remove: Array[StatusEffect] = []
	
	for effect in player_effects:
		var message = effect.apply_effect(player, combat_manager)
		messages.append(message)
		
		effect.tick_duration()
		if effect.is_expired():
			effects_to_remove.append(effect)
	
	# Remove expired effects
	for effect in effects_to_remove:
		player_effects.erase(effect)
	
	return messages

func apply_enemy_effects(enemy, combat_manager) -> Array[String]:
	var messages: Array[String] = []
	var effects_to_remove: Array[StatusEffect] = []
	
	for effect in enemy_effects:
		var message = effect.apply_effect(enemy, combat_manager)
		messages.append(message)
		
		effect.tick_duration()
		if effect.is_expired():
			effects_to_remove.append(effect)
	
	# Remove expired effects
	for effect in effects_to_remove:
		enemy_effects.erase(effect)
	
	return messages

# Get status descriptions for UI
func get_player_status_text() -> String:
	if player_effects.size() == 0:
		return ""
	
	var status_text = "Status Effects: "
	for effect in player_effects:
		status_text += effect.get_description() + " "
	return status_text

func get_enemy_status_text() -> String:
	if enemy_effects.size() == 0:
		return ""
	
	var status_text = "Status Effects: "
	for effect in enemy_effects:
		status_text += effect.get_description() + " "
	return status_text

# Clear all effects (for when combat ends)
func clear_all_effects():
	player_effects.clear()
	enemy_effects.clear()

# Check if target has specific effect
func player_has_effect(effect_id: String) -> bool:
	for effect in player_effects:
		if effect.effect_id == effect_id:
			return true
	return false

func enemy_has_effect(effect_id: String) -> bool:
	for effect in enemy_effects:
		if effect.effect_id == effect_id:
			return true
	return false
