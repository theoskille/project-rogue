class_name CombatAnimationOverlay
extends Control

# Video player for animations (optional for testing)
@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var overlay_background: ColorRect = $OverlayBackground

# Animation state
var current_action: CombatAction
var is_playing: bool = false

# Signals
signal animation_completed(action: CombatAction)

func _ready():
	# Initially hidden
	hide()
	
	# Connect video player signals if it exists
	if video_player:
		video_player.finished.connect(_on_video_finished)
	else:
		print("INFO: VideoStreamPlayer not found - animations will be skipped")

func play_attack_animation(action: CombatAction):
	current_action = action
	is_playing = true
	
	# Show overlay
	show()
	
	# If no video player, skip animation and complete immediately
	if not video_player:
		print("INFO: Skipping animation for ", action.attack_name)
		# Use a small delay to simulate animation time
		await get_tree().create_timer(0.5).timeout
		_on_video_finished()
		return
	
	# Load and play video
	var attack_name = action.attack_name
	var video_path = "res://assets/animations/attacks/" + attack_name.to_lower().replace(" ", "_") + ".ogv"
	
	# Debug output
	print("DEBUG: Attack name: '", attack_name, "'")
	print("DEBUG: Video path: '", video_path, "'")
	
	# Check if video file exists
	if not FileAccess.file_exists(video_path):
		print("WARNING: Video file not found: ", video_path)
		# Fallback: skip animation and complete immediately
		await get_tree().create_timer(0.5).timeout
		_on_video_finished()
		return
	
	print("DEBUG: Video file found, loading...")
	var video_stream = load(video_path)
	if video_stream:
		print("DEBUG: Video loaded successfully, playing...")
		video_player.stream = video_stream
		video_player.play()
	else:
		print("ERROR: Failed to load video: ", video_path)
		await get_tree().create_timer(0.5).timeout
		_on_video_finished()

func _on_video_finished():
	is_playing = false
	hide()
	
	# Emit completion signal
	if current_action:
		animation_completed.emit(current_action)
		current_action = null

func is_animation_playing() -> bool:
	return is_playing

# Public method to skip animation (for testing)
func skip_animation():
	if is_playing:
		if video_player:
			video_player.stop()
		_on_video_finished() 
