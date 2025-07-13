class_name InventoryManager
extends Control

# Database references
var attack_database: AttackDatabase

# UI References - Left Panel (Player Stats)
@onready var player_stats_label: Label = $HBoxContainer/LeftPanel/PlayerStatsPanel/PlayerStatsLabel

# UI References - Left Panel (Equipped Items)
@onready var weapon_slot: Label = $HBoxContainer/LeftPanel/EquippedItemsPanel/EquippedItemsContainer/WeaponSlot
@onready var armor_slot: Label = $HBoxContainer/LeftPanel/EquippedItemsPanel/EquippedItemsContainer/ArmorSlot
@onready var accessory_slot: Label = $HBoxContainer/LeftPanel/EquippedItemsPanel/EquippedItemsContainer/AccessorySlot

# UI References - Left Panel (Equipped Attacks)
@onready var attack_slot1: Label = $HBoxContainer/LeftPanel/EquippedAttacksPanel/EquippedAttacksContainer/AttackSlot1
@onready var attack_slot2: Label = $HBoxContainer/LeftPanel/EquippedAttacksPanel/EquippedAttacksContainer/AttackSlot2
@onready var attack_slot3: Label = $HBoxContainer/LeftPanel/EquippedAttacksPanel/EquippedAttacksContainer/AttackSlot3
@onready var attack_slot4: Label = $HBoxContainer/LeftPanel/EquippedAttacksPanel/EquippedAttacksContainer/AttackSlot4

# UI References - Right Panel (Item Selection)
@onready var tab_container: TabContainer = $HBoxContainer/RightPanel/ItemSelectionPanel/TabContainer
@onready var weapons_list: ItemList = $HBoxContainer/RightPanel/ItemSelectionPanel/TabContainer/WeaponsTab/WeaponsList
@onready var armor_list: ItemList = $HBoxContainer/RightPanel/ItemSelectionPanel/TabContainer/ArmorTab/ArmorList
@onready var accessories_list: ItemList = $HBoxContainer/RightPanel/ItemSelectionPanel/TabContainer/AccessoriesTab/AccessoriesList
@onready var instructions_label: Label = $HBoxContainer/RightPanel/ItemSelectionPanel/InstructionsLabel

# UI References - Right Panel (Attacks)
@onready var attacks_list: ItemList = $HBoxContainer/RightPanel/AttacksPanel/AttacksList
@onready var attack_instructions: Label = $HBoxContainer/RightPanel/AttacksPanel/AttackInstructions

# UI References - Center Panel (Skill Tree)
@onready var skill_tree_ui: Control = $HBoxContainer/CenterPanel/SkillTreePanel/SkillTreeUI

# State variables
var current_focus: String = "items"  # "items" or "attacks"
var player: Player

func _ready():
	# Initialize database references
	attack_database = AttackDatabase.new()
	
	setup_ui()
	connect_signals()

func setup_ui():
	instructions_label.text = "WASD: Navigate | Space: Equip | Tab: Switch Panel | E: Exit"
	attack_instructions.text = "Space: Equip | Delete: Unequip | Tab: Switch Panel | N: Toggle Dev Mode"
	
	# Set up attack slot placeholders
	attack_slot1.text = "Attack Slot 1: Empty"
	attack_slot2.text = "Attack Slot 2: Empty"
	attack_slot3.text = "Attack Slot 3: Empty"
	attack_slot4.text = "Attack Slot 4: Empty"

func connect_signals():
	# Connect ItemList selection signals
	if weapons_list:
		weapons_list.item_selected.connect(_on_weapons_list_item_selected)
	if armor_list:
		armor_list.item_selected.connect(_on_armor_list_item_selected)
	if accessories_list:
		accessories_list.item_selected.connect(_on_accessories_list_item_selected)
	if attacks_list:
		attacks_list.item_selected.connect(_on_attacks_list_item_selected)

func set_player(p: Player):
	player = p
	print("InventoryManager: Setting player")
	refresh_display()
	
	# Set up skill tree UI if it exists and has the script attached
	if skill_tree_ui and skill_tree_ui.has_method("set_player"):
		print("InventoryManager: Setting up skill tree UI")
		skill_tree_ui.set_player(p)
	else:
		print("InventoryManager: Skill tree UI not found or missing set_player method")

func refresh_display():
	if not player:
		print("InventoryManager: No player to refresh")
		return
	
	print("InventoryManager: Refreshing display")
	update_player_stats_display()
	update_equipped_items_display()
	update_equipped_attacks_display()
	update_available_items_lists()
	update_available_attacks_list()
	
	# Refresh skill tree if it exists and has the script attached
	if skill_tree_ui and skill_tree_ui.has_method("refresh_display"):
		print("InventoryManager: Refreshing skill tree")
		skill_tree_ui.refresh_display()
	else:
		print("InventoryManager: Skill tree UI not found or missing refresh_display method")

func update_player_stats_display():
	if not player:
		return
	
	var stats_text = "=== PLAYER STATS ===\n"
	stats_text += "Level: %d\n" % player.level
	stats_text += "XP: %d/%d\n" % [player.experience, player.experience_to_next_level]
	stats_text += "HP: %d/%d\n" % [player.current_hp, player.max_hp]
	stats_text += "\n=== STATS ===\n"
	stats_text += "STR: %d\n" % player.stats["STR"]
	stats_text += "DEX: %d\n" % player.stats["DEX"]
	stats_text += "CON: %d\n" % player.stats["CON"]
	stats_text += "INT: %d\n" % player.stats["INT"]
	stats_text += "SPD: %d\n" % player.stats["SPD"]
	stats_text += "DEF: %d\n" % player.stats["DEF"]
	stats_text += "LCK: %d\n" % player.stats["LCK"]
	
	player_stats_label.text = stats_text

func update_equipped_items_display():
	if not player:
		return
	
	# Update equipped item slots
	weapon_slot.text = "Weapon: " + (player.equipped_weapon if player.equipped_weapon else "None")
	armor_slot.text = "Armor: " + (player.equipped_armor if player.equipped_armor else "None")
	accessory_slot.text = "Accessory: " + (player.equipped_accessory if player.equipped_accessory else "None")

func update_equipped_attacks_display():
	if not player:
		return
	
	var attack_slots = [attack_slot1, attack_slot2, attack_slot3, attack_slot4]
	
	for i in range(attack_slots.size()):
		if i < player.equipped_attacks.size():
			attack_slots[i].text = "Attack Slot " + str(i + 1) + ": " + player.equipped_attacks[i]
		else:
			attack_slots[i].text = "Attack Slot " + str(i + 1) + ": Empty"

func update_available_items_lists():
	if not player:
		return
	
	var available = player.get_available_items()
	
	# Update weapons list
	weapons_list.clear()
	for weapon in available.weapons:
		var text = weapon
		if player.equipped_weapon == weapon:
			text += " [EQUIPPED]"
		weapons_list.add_item(text)
	
	# Update armor list
	armor_list.clear()
	for armor in available.armor:
		var text = armor
		if player.equipped_armor == armor:
			text += " [EQUIPPED]"
		armor_list.add_item(text)
	
	# Update accessories list
	accessories_list.clear()
	for accessory in available.accessories:
		var text = accessory
		if player.equipped_accessory == accessory:
			text += " [EQUIPPED]"
		accessories_list.add_item(text)

func update_available_attacks_list():
	if not player:
		return
	
	attacks_list.clear()
	
	# Get all attacks from AttackDatabase
	var all_attacks = []
	if attack_database:
		all_attacks = attack_database.get_all_attack_names()
	
	# Show dev mode status
	if player.is_dev_mode():
		attacks_list.add_item("=== DEV MODE ENABLED - ALL ATTACKS UNLOCKED ===")
		attacks_list.add_item("Press N to disable dev mode")
		attacks_list.add_item("")  # Empty line for spacing
	else:
		attacks_list.add_item("=== NORMAL MODE - SKILL TREE UNLOCKED ATTACKS ===")
		attacks_list.add_item("Press N to enable dev mode")
		attacks_list.add_item("")  # Empty line for spacing
	
	# Show all attacks, but mark which ones are unlocked/equipped
	for attack in all_attacks:
		var text = attack
		
		if player.is_dev_mode():
			# In dev mode, all attacks are available
			text += " [AVAILABLE]"
		else:
			# In normal mode, show unlock status
			if player.is_attack_unlocked(attack):
				text += " [UNLOCKED]"
			else:
				text += " [LOCKED]"
		
		# Show equipped status
		if attack in player.equipped_attacks:
			text += " [EQUIPPED]"
		
		attacks_list.add_item(text)

func handle_input(event: InputEvent):
	if not event.is_pressed() or not event is InputEventKey:
		return
	
	match event.keycode:
		KEY_W:
			navigate_selection(-1)
		KEY_S:
			navigate_selection(1)
		KEY_A:
			if current_focus == "items":
				change_tab(-1)
		KEY_D:
			if current_focus == "items":
				change_tab(1)
		KEY_N:
			toggle_dev_mode()
		KEY_SPACE:
			equip_selected_item()
		KEY_TAB:
			switch_focus()
		KEY_DELETE, KEY_BACKSPACE:
			if current_focus == "attacks":
				unequip_selected_attack()

# Dev mode functions
func toggle_dev_mode():
	if not player:
		return
	
	player.toggle_dev_mode()
	refresh_display()

# Removed update_dev_mode_button_text()

func navigate_selection(direction: int):
	var current_list = get_current_item_list()
	if not current_list:
		return
	
	var current_selection = current_list.get_selected_items()
	var new_index = 0
	
	if current_selection.size() > 0:
		new_index = current_selection[0] + direction
	
	# Wrap around selection
	if new_index < 0:
		new_index = current_list.get_item_count() - 1
	elif new_index >= current_list.get_item_count():
		new_index = 0
	
	if current_list.get_item_count() > 0:
		current_list.select(new_index)

func change_tab(direction: int):
	if current_focus != "items":
		return
	
	var current_tab = tab_container.current_tab
	var new_tab = current_tab + direction
	
	# Wrap around tabs
	if new_tab < 0:
		new_tab = tab_container.get_tab_count() - 1
	elif new_tab >= tab_container.get_tab_count():
		new_tab = 0
	
	tab_container.current_tab = new_tab

func switch_focus():
	if current_focus == "items":
		current_focus = "attacks"
		highlight_attacks_panel()
	else:
		current_focus = "items"
		highlight_items_panel()

func highlight_attacks_panel():
	# Visual feedback for focus (you can enhance this with colors/styling)
	attack_instructions.text = "[FOCUSED] Space: Equip | Delete: Unequip | Tab: Switch Panel"
	instructions_label.text = "WASD: Navigate | Space: Equip | Tab: Switch Panel | E: Exit"

func highlight_items_panel():
	# Visual feedback for focus
	instructions_label.text = "[FOCUSED] WASD: Navigate | Space: Equip | A/D: Change Tab | Tab: Switch Panel | E: Exit"
	attack_instructions.text = "Space: Equip | Delete: Unequip | Tab: Switch Panel"

func get_current_item_list() -> ItemList:
	if current_focus == "attacks":
		return attacks_list
	
	# For items panel, get the list from current tab
	match tab_container.current_tab:
		0:  # Weapons tab
			return weapons_list
		1:  # Armor tab
			return armor_list
		2:  # Accessories tab
			return accessories_list
		_:
			return null

func equip_selected_item():
	if not player:
		return
	
	var current_list = get_current_item_list()
	if not current_list:
		return
	
	var selected = current_list.get_selected_items()
	if selected.size() == 0:
		return
	
	var selected_index = selected[0]
	var success = false
	
	if current_focus == "attacks":
		# Skip header items in attacks list
		var header_offset = 3  # 3 header items (status line, instruction line, empty line)
		if selected_index < header_offset:
			return  # Don't equip header items
		
		# Adjust index to account for header items
		var actual_index = selected_index - header_offset
		var all_attacks = attack_database.get_all_attack_names()
		
		if actual_index >= 0 and actual_index < all_attacks.size():
			var attack_name = all_attacks[actual_index]
			
			# In dev mode, all attacks are available
			# In normal mode, only unlocked attacks can be equipped
			if player.is_dev_mode() or player.is_attack_unlocked(attack_name):
				if attack_name in player.equipped_attacks:
					success = player.unequip_attack(attack_name)
				else:
					success = player.equip_attack(attack_name)
			else:
				print("Cannot equip locked attack: %s" % attack_name)
	else:
		# Handle item equipment based on current tab
		match tab_container.current_tab:
			0:  # Weapons
				var weapon_name = player.available_weapons[selected_index]
				success = player.equip_weapon(weapon_name)
			1:  # Armor
				var armor_name = player.available_armor[selected_index]
				success = player.equip_armor(armor_name)
			2:  # Accessories
				var accessory_name = player.available_accessories[selected_index]
				success = player.equip_accessory(accessory_name)
	
	if success:
		refresh_display()
	elif current_focus == "attacks" and not player.can_equip_more_attacks():
		print("Cannot equip more attacks! Maximum is " + str(player.max_equipped_attacks))

func unequip_selected_attack():
	if current_focus != "attacks" or not player:
		return
	
	var selected = attacks_list.get_selected_items()
	if selected.size() == 0:
		return
	
	var selected_index = selected[0]
	
	# Skip header items in attacks list
	var header_offset = 3  # 3 header items (status line, instruction line, empty line)
	if selected_index < header_offset:
		return  # Don't unequip header items
	
	# Adjust index to account for header items
	var actual_index = selected_index - header_offset
	var all_attacks = attack_database.get_all_attack_names()
	
	if actual_index >= 0 and actual_index < all_attacks.size():
		var attack_name = all_attacks[actual_index]
		if player.unequip_attack(attack_name):
			refresh_display()

# Signal handlers for ItemList selections
func _on_weapons_list_item_selected(index: int):
	# Optional: Add preview or description functionality
	pass

func _on_armor_list_item_selected(index: int):
	# Optional: Add preview or description functionality
	pass

func _on_accessories_list_item_selected(index: int):
	# Optional: Add preview or description functionality
	pass

func _on_attacks_list_item_selected(index: int):
	# Optional: Add preview or description functionality
	pass

# External methods for adding/removing items
func add_item(item_type: String, item_name: String):
	if not player:
		return
		
	match item_type:
		"weapon":
			if item_name not in player.available_weapons:
				player.available_weapons.append(item_name)
		"armor":
			if item_name not in player.available_armor:
				player.available_armor.append(item_name)
		"accessory":
			if item_name not in player.available_accessories:
				player.available_accessories.append(item_name)
		"attack":
			if item_name not in player.available_attacks:
				player.available_attacks.append(item_name)
	
	refresh_display()

func remove_item(item_type: String, item_name: String):
	if not player:
		return
		
	match item_type:
		"weapon":
			player.available_weapons.erase(item_name)
		"armor":
			player.available_armor.erase(item_name)
		"accessory":
			player.available_accessories.erase(item_name)
		"attack":
			player.available_attacks.erase(item_name)
			player.equipped_attacks.erase(item_name)
	
	refresh_display()
