extends Area2D

@export var player_group_name: String = "player"
@export var dialogue_ui_path: NodePath = ^"/root/Game/Hud/DialogueSystem"
@export var image_viewer_path: NodePath = ^"/root/Game/Hud/ImageViewer"

# NEW: drag Madhava's AnimatedSprite2D (world sprite) here in the Inspector
@export var npc_anim_path: NodePath

@export_multiline var npc_dialogue_raw: String = """
...

TORRICELLI:
Hello. I am Evangelista Torricelli.

TORRICELLI:
I worked on problems where geometry meets measurement—especially areas under curves and volumes of solids.

TORRICELLI:
A major tool I used is the method of indivisibles, developed from Cavalieri’s ideas.
The basic strategy is to treat a region as if it is built from infinitely many thin parallel pieces.

TORRICELLI:
For a flat region (an area), imagine sweeping a horizontal line from bottom to top.
At each height y, the region has a cross-section: a line segment with some length, call it L(y).

TORRICELLI:
If you add the lengths of these cross-sections across all heights—carefully—you obtain the total area.

TORRICELLI:
In modern language, this is the same structure as an integral:
Area = “sum of slice lengths” over the full height.

TORRICELLI:
For a solid (a volume), the same idea applies.
At each height y, the solid has a cross-section with some area, call it A(y).

TORRICELLI:
Adding those cross-sectional areas across the height gives the volume.

TORRICELLI:
This is important because it turns a difficult measurement problem into a repeatable method:

TORRICELLI:
1) describe the cross-section,
2) add the cross-sections,
3) refine the reasoning until the result is reliable.

TORRICELLI:
In my book Opera Geometrica, I applied these ideas to specific curves.
One example is the parabola.

TORRICELLI:
Archimedes had already found the area of a parabolic segment using classical geometry.
I worked on additional approaches using indivisibles—showing how “slice-based” reasoning can reach the same result.

TORRICELLI:
I also examined infinite sums more directly.
If you have a sequence of numbers a0, a1, a2, … that decreases and approaches a limit L,
then the telescoping series

TORRICELLI:
(a0 − a1) + (a1 − a2) + (a2 − a3) + …
adds up to a0 − L.

TORRICELLI:
That may look simple, but it is powerful:
it gives a clear way to prove convergence in certain cases and to compute sums like geometric series.

TORRICELLI:
It is another example of controlling an infinite process with precise reasoning.

TORRICELLI:
Finally, I studied a solid that forces you to think carefully about infinity.
Take the curve y = 1/x for x ≥ 1 and revolve it around the x-axis.

TORRICELLI:
The solid extends without end, yet its volume is finite.

TORRICELLI:
At the same time, the surface area grows without bound.
So the same object can have a finite “amount of space inside” but an infinite “amount of surface.”

TORRICELLI:
This result matters because it shows why you must define measurement methods carefully—especially when infinity is involved.

TORRICELLI:
So, if you summarize my contribution to the development toward calculus, it is this:

TORRICELLI:
I helped move geometry toward a method-based approach—
measuring curves and solids by slicing, summing, and controlling infinite processes.
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
