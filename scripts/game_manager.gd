extends Node

# --- Coins / score ---
var score: int = 0

# If GameManager is Autoload, you should use absolute paths (not ../Hud)
@export var score_label_path: NodePath = ^"/root/Game/Hud/UI/ScoreLabel"
@onready var score_label: Label = get_node_or_null(score_label_path) as Label

# --- Win / 11 coins trigger ---
@export var win_target: int = 11
@export var image_viewer_path: NodePath = ^"/root/Game/Hud/ImageViewer"
@export var win_images: Array[Texture2D] = []  # drag PNG(s) here in Inspector

var _win_triggered: bool = false

# --- Baby mode / checkpoints ---
var baby_mode: bool = false
var checkpoint_position: Vector2 = Vector2.ZERO
var has_checkpoint: bool = false

func _ready() -> void:
	_update_score_label()

func add_point() -> void:
	score += 1
	_update_score_label()

	# Trigger once at 11+
	if not _win_triggered and score >= win_target:
		_win_triggered = true
		_trigger_win()

func _update_score_label() -> void:
	if score_label != null:
		score_label.text = str(score) + " Coins"

func _trigger_win() -> void:
	# Freeze player movement
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("set_controls_enabled"):
		player.call("set_controls_enabled", false)

	# Show win image(s)
	var viewer := get_node_or_null(image_viewer_path)
	if viewer != null and viewer.has_method("open_images") and win_images.size() > 0:
		viewer.call("open_images", win_images)
	else:
		push_warning("GameManager: win trigger fired, but ImageViewer not found or win_images is empty.")

# Call this when starting a new level/run if you want it to be repeatable
func reset_coins() -> void:
	score = 0
	_win_triggered = false
	_update_score_label()

func set_baby_mode(enabled: bool) -> void:
	baby_mode = enabled
	print("Baby Mode:", baby_mode)

func set_checkpoint(pos: Vector2) -> void:
	checkpoint_position = pos
	has_checkpoint = true
	print("Checkpoint set:", checkpoint_position)

func clear_checkpoint() -> void:
	has_checkpoint = false
	checkpoint_position = Vector2.ZERO
