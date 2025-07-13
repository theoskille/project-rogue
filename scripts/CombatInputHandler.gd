class_name CombatInputHandler
extends RefCounted

var combat_controller: CombatController

func _init(controller: CombatController):
	combat_controller = controller

func handle_input(event: InputEvent):
	if not combat_controller.combat_active:
		return
		
	if not event.is_pressed():
		return
		
	if event is InputEventKey:
		# Check if animation is playing
		if combat_controller.current_state == CombatController.CombatState.PLAYING_ANIMATION or combat_controller.current_state == CombatController.CombatState.ENEMY_ANIMATION:
			# Allow skipping animation with ESC key
			if event.keycode == KEY_ESCAPE:
				if combat_controller.animation_overlay:
					combat_controller.animation_overlay.skip_animation()
			return
		
		# Normal input handling
		if combat_controller.current_turn == "player":
			match event.keycode:
				KEY_W, KEY_UP:
					combat_controller.navigate_menu(-1)
				KEY_S, KEY_DOWN:
					combat_controller.navigate_menu(1)
				KEY_SPACE:
					combat_controller.execute_selected_action() 