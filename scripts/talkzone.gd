extends Area2D

@export var player_group_name: String = "player"
@export var dialogue_ui_path: NodePath = ^"/root/Game/Hud/DialogueSystem"
@export var image_viewer_path: NodePath = ^"/root/Game/Hud/ImageViewer"

# NEW: drag the NPC's AnimatedSprite2D here (world sprite)
@export var npc_anim_path: NodePath 

@export_multiline var npc_dialogue_raw: String = """
...

ARCHIMEDES: 
Hello. I am Archimedes of Syracuse.

ARCHIMEDES:
In my work, I focus on measuring things that look difficult to measure—especially curved shapes like circles, parabolas, and spheres.

ARCHIMEDES:
One of my most important ideas is what people later call the method of exhaustion.

ARCHIMEDES:
The goal is to find an exact area or volume by trapping it between two values we can calculate.

ARCHIMEDES:
Here is the basic method using a circle:

ARCHIMEDES:
First, draw a polygon inside the circle. That polygon’s area is smaller than the circle’s area.
So it gives a lower bound.

ARCHIMEDES:
Next, draw a polygon outside the circle. That polygon’s area is larger than the circle’s area.
So it gives an upper bound.

ARCHIMEDES:
The true area of the circle must be between those two numbers.
Then you increase the number of sides of the polygons.

ARCHIMEDES:
As the number of sides increases, both polygons fit the circle more closely, and the gap between the bounds gets smaller.

ARCHIMEDES:
If you can make that gap as small as you want, then you can determine the circle’s area to any required accuracy.

ARCHIMEDES:
This is a key idea behind limits: getting closer and closer to a value in a controlled way.

ARCHIMEDES:
I used the same approach to study other curved regions, including the area under a parabola, and to compare volumes of solids like spheres and cylinders.

ARCHIMEDES:
The important point is that curved shapes can be measured using a process of approximation that becomes exact in the limit.
"""

# Assign PNGs here in the Inspector (per NPC)
@export var image_pages: Array[Texture2D] = []

@onready var dialogue_ui := get_node_or_null(dialogue_ui_path)
@onready var image_viewer := get_node_or_null(image_viewer_path)
@onready var npc_anim := get_node_or_null(npc_anim_path) as AnimatedSprite2D

var _current_player: Node2D = null
var _dialogue_running: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _dialogue_running:
		return
	if not body.is_in_group(player_group_name):
		return
	if dialogue_ui == null:
		push_error("TalkZone: DialogueSystem not found at: %s" % dialogue_ui_path)
		return

	_dialogue_running = true
	_current_player = body

	# Freeze player immediately
	if body.has_method("set_controls_enabled"):
		body.call("set_controls_enabled", false)

	# Open dialogue pages
	var pages: PackedStringArray = npc_dialogue_raw.split("\n\n", false)

	# UPDATED: pass the NPC's moving sprite info to the DialogueSystem
	if npc_anim != null and npc_anim.sprite_frames != null:
		dialogue_ui.call(
			"open_lines",
			pages,
			npc_anim.sprite_frames,
			npc_anim.animation,
			npc_anim.speed_scale,
			npc_anim.flip_h
		)
	else:
		# Fallback: dialogue text only
		dialogue_ui.call("open_lines", pages)

	# Connect once to dialogue end
	if dialogue_ui.has_signal("dialogue_finished"):
		if not dialogue_ui.dialogue_finished.is_connected(_on_dialogue_finished):
			dialogue_ui.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished() -> void:
	# If we have images, show them next (do NOT re-enable movement yet)
	if image_pages.size() > 0 and image_viewer != null and image_viewer.has_method("open_images"):
		if image_viewer.has_signal("images_finished"):
			if not image_viewer.images_finished.is_connected(_on_images_finished):
				image_viewer.images_finished.connect(_on_images_finished)

		image_viewer.call("open_images", image_pages)
		return

	# Otherwise, end normally
	_finish_interaction()

func _on_images_finished() -> void:
	_finish_interaction()

func _finish_interaction() -> void:
	_dialogue_running = false

	if _current_player != null and is_instance_valid(_current_player):
		if _current_player.has_method("set_controls_enabled"):
			_current_player.call("set_controls_enabled", true)

	_current_player = null
