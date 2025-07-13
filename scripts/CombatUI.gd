class_name CombatUI
extends Control

# UI elements - will be set by CombatManager
var combat_info: Label
var battlefield_container: HBoxContainer
var actions_menu: VBoxContainer
var status_display: Label
var combat_log_panel: PanelContainer
var combat_log_center: MarginContainer
var combat_log_scroll: ScrollContainer
var combat_log_vbox: VBoxContainer

var combat_controller: CombatController

# Combat log settings
var max_log_messages: int = 20  # Limit messages to prevent memory issues

func _init(controller: CombatController):
	combat_controller = controller
	connect_controller_signals()

func connect_controller_signals():
	combat_controller.combat_state_changed.connect(_on_combat_state_changed)
	combat_controller.player_turn_started.connect(_on_player_turn_started)
	combat_controller.enemy_turn_started.connect(_on_enemy_turn_started)
	combat_controller.combat_ended.connect(_on_combat_ended)
	combat_controller.combat_log_message.connect(_on_combat_log_message)
	combat_controller.battlefield_updated.connect(_on_battlefield_updated)
	combat_controller.actions_menu_updated.connect(_on_actions_menu_updated)

# Method to set UI references from CombatManager
func set_ui_references(info: Label, battlefield: HBoxContainer, menu: VBoxContainer, status: Label, log_panel: PanelContainer, log_center: MarginContainer, log_scroll: ScrollContainer, log_vbox: VBoxContainer):
	combat_info = info
	battlefield_container = battlefield
	actions_menu = menu
	status_display = status
	combat_log_panel = log_panel
	combat_log_center = log_center
	combat_log_scroll = log_scroll
	combat_log_vbox = log_vbox

func setup_battlefield():
	# Create 8 battlefield tiles - static size that won't stretch
	for i in range(8):
		var tile = ColorRect.new()
		tile.custom_minimum_size = Vector2(80, 80)
		tile.size = Vector2(80, 80)  # Set explicit size
		tile.color = Color.DARK_GRAY
		
		# Prevent the tile from expanding
		tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		battlefield_container.add_child(tile)

func setup_actions_menu():
	# Create action buttons - now using action objects
	var main_actions = combat_controller.get_current_actions()
	for i in range(main_actions.size()):
		var action_label = Label.new()
		action_label.text = main_actions[i].get_display_name()
		actions_menu.add_child(action_label)
	
	update_actions_menu()

func update_actions_menu():
	if not actions_menu:
		return
		
	var current_actions = combat_controller.get_current_actions()
	
	# Clear existing labels
	for child in actions_menu.get_children():
		child.queue_free()
	
	# Create new labels for current menu
	for i in range(current_actions.size()):
		var label = Label.new()
		var action = current_actions[i]
		
		if i == combat_controller.selected_action:
			label.modulate = Color.YELLOW
			label.text = "> " + action.get_display_name() + " <"
		else:
			label.modulate = Color.WHITE
			label.text = "  " + action.get_display_name()
		
		actions_menu.add_child(label)

func update_battlefield():
	if not battlefield_container:
		return
		
	# Update battlefield tiles
	for i in range(battlefield_container.get_child_count()):
		var tile = battlefield_container.get_child(i) as ColorRect
		
		# Reset tile
		tile.color = Color.DARK_GRAY
		
		# Clear any existing children (sprites will go here later)
		for child in tile.get_children():
			child.queue_free()
		
		# Add markers for player and enemy positions
		if i == combat_controller.player_position:
			tile.color = Color.BLUE
			var player_marker = Label.new()
			player_marker.text = "P"
			player_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			player_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			player_marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			tile.add_child(player_marker)
		elif i == combat_controller.enemy_position:
			tile.color = Color.RED
			var enemy_marker = Label.new()
			enemy_marker.text = "E"
			enemy_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			enemy_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			enemy_marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			tile.add_child(enemy_marker)

func update_combat_info():
	if not combat_info:
		return
		
	combat_info.text = combat_controller.get_combat_info()
	combat_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func update_status_display():
	if not status_display:
		return
		
	# Enhanced status display with enemy name and stats
	var player_status = combat_controller.get_player_status_text()
	var enemy_status = combat_controller.get_enemy_status_text()
	
	# Format player stats
	var player_stats_text = combat_controller.get_player_stats_text()
	
	# Format enemy stats
	var enemy_stats_text = combat_controller.get_enemy_stats_text()
	
	status_display.text = "=== PLAYER ===\nHP: %d/%d\nStats: %s\n%s\n=== %s ===\nHP: %d/%d\nStats: %s\n%s" % [
		combat_controller.player.current_hp, combat_controller.player.max_hp,
		player_stats_text,
		player_status if player_status != "" else "No status effects",
		combat_controller.enemy.name.to_upper(),
		combat_controller.enemy.current_hp, combat_controller.enemy.max_hp,
		enemy_stats_text,
		enemy_status if enemy_status != "" else "No status effects"
	]

func log_combat_message(message: String):
	if not combat_log_vbox:
		print("ERROR VBOX")
		return
		
	print(message)
	# Create a new label for this message
	var log_label = Label.new()
	log_label.modulate = Color.WHITE
	log_label.text = message
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.custom_minimum_size.x = 200  # Set minimum width for proper wrapping
	
	# Add the label to the VBox
	combat_log_vbox.add_child(log_label)
	print("DEBUG: VBox child count after: ", combat_log_vbox.get_child_count())
	print("DEBUG: VBox size: ", combat_log_vbox.size)
	print("DEBUG: VBox visible: ", combat_log_vbox.visible)
	print("DEBUG: ScrollContainer size: ", combat_log_scroll.size if combat_log_scroll else "null")
	print("DEBUG: Panel size: ", combat_log_panel.size if combat_log_panel else "null")
	
	# Limit the number of messages (remove oldest if too many)
	if combat_log_vbox.get_child_count() > max_log_messages:
		var oldest_message = combat_log_vbox.get_child(0)
		oldest_message.queue_free()
	
	# Auto-scroll to the bottom to show the latest message
	call_deferred("scroll_to_bottom")

func scroll_to_bottom():
	if combat_log_scroll:
		combat_log_scroll.scroll_vertical = combat_log_scroll.get_v_scroll_bar().max_value

func clear_combat_log():
	if combat_log_vbox:
		# Remove all existing log messages
		for child in combat_log_vbox.get_children():
			child.queue_free()

func update_display():
	update_combat_info()
	update_battlefield()
	update_actions_menu()
	update_status_display()

# Signal handlers
func _on_combat_state_changed():
	update_display()

func _on_player_turn_started():
	update_display()

func _on_enemy_turn_started():
	update_display()

func _on_combat_ended(player_won: bool):
	update_display()

func _on_combat_log_message(message: String):
	log_combat_message(message)

func _on_battlefield_updated():
	update_battlefield()

func _on_actions_menu_updated():
	update_actions_menu() 
