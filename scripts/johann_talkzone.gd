extends Area2D

@export var player_group_name: String = "player"
@export var dialogue_ui_path: NodePath = ^"/root/Game/Hud/DialogueSystem"
@export var image_viewer_path: NodePath = ^"/root/Game/Hud/ImageViewer"

# NEW: drag Madhava's AnimatedSprite2D (world sprite) here in the Inspector
@export var npc_anim_path: NodePath

@export_multiline var npc_dialogue_raw: String = """
...

BERNOULLI:
Hello. I am Johann Bernoulli.

BERNOULLI:
I worked on developing and applying the new methods of calculus, especially to problems where you must find a "best" answer:
the fastest, the shortest, the greatest, the least.

BERNOULLI:
One of my most famous problems is called the brachistochrone problem.
It asks this:

BERNOULLI:
Given two points at different heights, what curve should a bead follow-under gravity, with no friction-
so that it reaches the lower point in the least time?

BERNOULLI:
Many people assume the straight line is fastest.
But "shortest distance" is not the same as "least time."

BERNOULLI:
To see why, focus on speed.
As the bead drops, it gains speed because it loses height.
A larger drop early in the motion produces a larger speed sooner.

BERNOULLI:
Now break the path into tiny pieces.
Over a very small piece of the curve, the time taken is approximately

BERNOULLI:
dt = ds / v,

BERNOULLI:
where ds is a small length of the path and v is the bead's speed on that piece.

BERNOULLI:
So the total travel time is built by adding up ds / v along the entire curve.

BERNOULLI:
The key point is that v depends on how far the bead has fallen.
So choosing the curve changes the speed profile over the whole trip.

BERNOULLI:
A curve that drops steeply at the beginning can be faster overall, even if it is longer.

BERNOULLI:
This problem is important because it is not about maximizing or minimizing at a single point.
It is about choosing an entire curve-the whole path-so that the total time is as small as possible.

BERNOULLI:
That idea leads to what later becomes the calculus of variations:
optimization where the "unknown" is a function or a curve, not just a number.

BERNOULLI:
The surprising answer is that the fastest curve is a cycloid,
the curve traced by a point on a rolling circle.

BERNOULLI:
It drops quickly at first to build speed, then levels out to carry that speed efficiently.

BERNOULLI:
I shared this problem publicly as a challenge, because it forced mathematicians to show that calculus was not only a new set of rules,
but a powerful method for solving real optimization problems.

BERNOULLI:
Beyond that, I worked extensively with differential equations-equations involving derivatives-
because they describe change directly.

BERNOULLI:
Many physical and geometric systems are best expressed that way.

BERNOULLI:
So my role in the development of calculus is strongly tied to application:
turning calculus into a tool for optimization, motion, and problems where you must choose the best possible path.
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
