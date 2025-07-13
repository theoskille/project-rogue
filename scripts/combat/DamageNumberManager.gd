class_name DamageNumberManager
extends RefCounted

var damage_number_container: Control
var battlefield_container: HBoxContainer

func _init(container: Control, battlefield: HBoxContainer):
	damage_number_container = container
	battlefield_container = battlefield

# Spawn a damage number for the given target
func spawn_damage_number(damage: int, target_position: int, is_critical: bool = false, is_miss: bool = false, is_healing: bool = false):
	if not damage_number_container or not battlefield_container:
		print("ERROR: Damage number container or battlefield not set!")
		return
	
	# Get the target tile position
	var target_tile = battlefield_container.get_child(target_position)
	if not target_tile:
		print("ERROR: Target tile not found at position ", target_position)
		return
	
	# Calculate world position of the tile
	var tile_global_pos = target_tile.global_position
	var tile_size = target_tile.size
	
	# Center the damage number over the tile
	var damage_pos = Vector2(
		tile_global_pos.x + tile_size.x / 2 - 50,  # Center horizontally (50 is half of damage number width)
		tile_global_pos.y + tile_size.y / 2 - 25   # Center vertically (25 is half of damage number height)
	)
	
	# Create the damage number
	var damage_number = DamageNumber.new(damage, is_critical, is_miss, is_healing)
	damage_number_container.add_child(damage_number)
	damage_number.set_target_position(damage_pos)
	
	# Connect completion signal
	damage_number.animation_completed.connect(_on_damage_number_completed.bind(damage_number))

func _on_damage_number_completed(damage_number: DamageNumber):
	# Damage number will auto-remove itself, but we can do cleanup here if needed
	pass

# Convenience methods for different damage types
func show_damage(damage: int, target_position: int, is_critical: bool = false):
	spawn_damage_number(damage, target_position, is_critical, false, false)

func show_miss(target_position: int):
	spawn_damage_number(0, target_position, false, true, false)

func show_healing(healing: int, target_position: int):
	spawn_damage_number(healing, target_position, false, false, true) 
