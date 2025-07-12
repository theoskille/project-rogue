class_name InventoryManager
extends Control

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

# State variables
var current_focus: String = "items"  # "items" or "attacks"
var player: Player

func _ready():
	setup_ui()
	connect_signals()

func setup_ui():
	instructions_label.text = "WASD: Navigate | Space: Equip | Tab: Switch Panel | E: Exit"
	attack_instructions.text = "Space: Equip | Delete: Unequip | Tab: Switch Panel"
	
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
	refresh_display()

func refresh_display():
	if not player:
		return
	
	update_equipped_items_display()
	update_equipped_attacks_display()
	update_available_items_lists()
	update_available_attacks_list()

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
	for attack in player.available_attacks:
		var text = attack
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
		KEY_SPACE:
			equip_selected_item()
		KEY_TAB:
			switch_focus()
		KEY_DELETE, KEY_BACKSPACE:
			if current_focus == "attacks":
				unequip_selected_attack()

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
		var attack_name = player.available_attacks[selected_index]
		if attack_name in player.equipped_attacks:
			success = player.unequip_attack(attack_name)
		else:
			success = player.equip_attack(attack_name)
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
	
	var attack_name = player.available_attacks[selected[0]]
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
