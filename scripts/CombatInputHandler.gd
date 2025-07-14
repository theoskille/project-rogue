class_name CombatInputHandler
extends RefCounted

var combat_controller: CombatController

func _init(controller: CombatController):
	combat_controller = controller

func handle_input(event: InputEvent):
	if not combat_controller.is_combat_active():
		return
		
	if not event.is_pressed():
		return
		
	if event is InputEventKey:
		# Check if animation is playing using state machine
		if combat_controller.state_machine.is_animation_playing():
			# Allow skipping animation with ESC key
			if event.keycode == KEY_ESCAPE:
				if combat_controller.animation_overlay:
					combat_controller.animation_overlay.skip_animation()
			return
		
		# Normal input handling
		if combat_controller.state_machine.is_player_turn():
			match event.keycode:
				KEY_W, KEY_UP:
					combat_controller.navigate_menu(-1)
				KEY_S, KEY_DOWN:
					combat_controller.navigate_menu(1)
				KEY_SPACE:
					combat_controller.execute_selected_action() 