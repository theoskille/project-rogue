class_name DamageNumber
extends Control

# Damage number properties
var damage_value: int
var is_critical: bool = false
var is_miss: bool = false
var is_healing: bool = false
var target_position: Vector2

# Animation properties
var animation_duration: float = 1.5
var float_distance: float = 50.0
var fade_start_time: float = 0.8

# UI elements
var damage_label: Label
var animation_timer: float = 0.0

# Signals
signal animation_completed

func _init(value: int, critical: bool = false, miss: bool = false, healing: bool = false):
	damage_value = value
	is_critical = critical
	is_miss = miss
	is_healing = healing

func _ready():
	# Set up the control
	custom_minimum_size = Vector2(100, 50)
	size = Vector2(100, 50)
	
	# Create the damage label
	damage_label = Label.new()
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	damage_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Set text and styling
	if is_miss:
		damage_label.text = "Miss"
		damage_label.modulate = Color.GRAY
		damage_label.add_theme_font_size_override("font_size", 24)
	else:
		damage_label.text = str(damage_value)
		if is_critical:
			damage_label.modulate = Color.YELLOW
			damage_label.add_theme_font_size_override("font_size", 28)
		elif is_healing:
			damage_label.modulate = Color.GREEN
			damage_label.add_theme_font_size_override("font_size", 24)
		else:
			damage_label.modulate = Color.RED
			damage_label.add_theme_font_size_override("font_size", 24)
	
	add_child(damage_label)
	
	# Start animation
	animation_timer = 0.0

func _process(delta):
	animation_timer += delta
	var progress = animation_timer / animation_duration
	
	if progress >= 1.0:
		# Animation complete
		animation_completed.emit()
		queue_free()
		return
	
	# Float upward
	var current_y_offset = float_distance * progress
	position.y = target_position.y - current_y_offset
	
	# Fade out
	if progress > fade_start_time:
		var fade_progress = (progress - fade_start_time) / (1.0 - fade_start_time)
		modulate.a = 1.0 - fade_progress
	
	# Scale effect for critical hits
	if is_critical:
		var scale_factor = 1.0 + 0.3 * sin(progress * PI * 4)  # Pulsing effect
		scale = Vector2(scale_factor, scale_factor)

func set_target_position(pos: Vector2):
	target_position = pos
	position = pos 