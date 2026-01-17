extends Area2D

@export var player_group_name: String = "player"
@export var dialogue_ui_path: NodePath = ^"/root/Game/Hud/DialogueSystem"
@export var image_viewer_path: NodePath = ^"/root/Game/Hud/ImageViewer"

# NEW: drag Madhava's AnimatedSprite2D (world sprite) here in the Inspector
@export var npc_anim_path: NodePath

@export_multiline var npc_dialogue_raw: String = """
...

KEPLER:
Greetings. I am Johannes Kepler.

KEPLER:
My work is mainly about understanding motion in the heavens and making accurate predictions.
To do that, I relied on careful observation data—especially the measurements collected by Tycho Brahe.

KEPLER:
The first major conclusion I reached is that planets do not move in perfect circles.
Their paths are ellipses, with the Sun at one focus.

KEPLER:
Second, I found a rule that connects motion and area:
a planet sweeps out equal areas in equal intervals of time.

KEPLER:
In other words, if you pick any two time periods of the same length, the “sector area” traced out by the line from the Sun to the planet will be the same.

KEPLER:
This idea matters because it links time to accumulation.
Instead of describing motion only by position, it describes motion by how much area has built up over time.

KEPLER:
Later, calculus gives a direct language for this relationship between rate and accumulated quantity.

KEPLER:
Third, I discovered a pattern relating the size of an orbit to the time it takes to complete it:
larger orbits have longer periods, in a precise relationship.

KEPLER:
I also worked on a more practical problem that connects to the same mathematical direction:
measuring volumes accurately.

KEPLER:
In my time, merchants needed reliable ways to measure the volume of wine barrels.
Barrels are not perfect cylinders, so you cannot compute their volume with one simple formula.

KEPLER:
My approach was to treat the barrel as if it were made of many thin slices.
Imagine cutting the barrel into a stack of very thin circular layers.

KEPLER:
Each layer behaves like a short cylinder: its volume is approximately
(area of the circle) × (thickness of the slice).

KEPLER:
If you add the volumes of all the slices, you get an approximation of the barrel’s total volume.
And the more slices you use—the thinner you make them—the better the approximation becomes.

KEPLER:
This is important because it is the same general idea behind integration:

KEPLER:
a curved shape can be measured by breaking it into many simple parts,
adding them, and improving accuracy by refining the partition.

KEPLER:
So my contribution to the development of calculus is not one single formula.
It is the consistent use of measurable rules and approximations:

KEPLER:
elliptical motion described by area over time,
and volume measured by summing many thin cross-sections.
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

	# UPDATED: pass Madhava's moving sprite info to DialogueSystem
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
