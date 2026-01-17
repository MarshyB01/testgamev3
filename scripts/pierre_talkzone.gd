extends Area2D

@export var player_group_name: String = "player"
@export var dialogue_ui_path: NodePath = ^"/root/Game/Hud/DialogueSystem"
@export var image_viewer_path: NodePath = ^"/root/Game/Hud/ImageViewer"

# NEW: drag Madhava's AnimatedSprite2D (world sprite) here in the Inspector
@export var npc_anim_path: NodePath

@export_multiline var npc_dialogue_raw: String = """
...

FERMAT:
Hello. I am Pierre de Fermat.

FERMAT:
I studied number theory, geometry, and methods for solving problems that involve finding the best possible value—such as the highest point, the lowest point, or the line that just touches a curve.

FERMAT:
Two ideas from my work connect directly to what later became calculus:
finding tangents to curves, and finding maxima and minima.

FERMAT:
Start with tangents.
Suppose you have a curve and you want the slope of the tangent line at a particular point.

FERMAT:
In my time, there was no standard “derivative” notation, but the goal was the same: determine the instantaneous slope.

FERMAT:
My method was based on comparing values at two very close inputs.
Take a point x, and then take a nearby point x + e, where e is a small change.

FERMAT:
Compute the expression for the curve at x and at x + e.
Then compare them.

FERMAT:
When you are finding a tangent, you are looking for the line that just touches the curve at x.

FERMAT:
That touching condition can be found by forcing the slope computed from the two points to behave like a single slope at x.

FERMAT:
In practice, this means you simplify the difference between f(x + e) and f(x),
cancel what you can, and then examine what remains as e becomes extremely small.

FERMAT:
This approach leads to the same kind of expression that later appears in the derivative:

FERMAT:
a ratio involving a change in output divided by a change in input,
with the idea of letting the change become very small.

FERMAT:
Now consider maxima and minima.
If a function has a maximum or minimum at x, then nearby values do not improve it.

FERMAT:
The value at x is, in a local sense, the best.

FERMAT:
So I again compare f(x) and f(x + e).
At a maximum or minimum, the change from x to x + e should not produce a first-order improvement.

FERMAT:
That produces an equation that allows you to solve for the critical point.

FERMAT:
I called this approach “adequality.”
The name is less important than the idea:

FERMAT:
compare a quantity with a nearby version of itself,
and use that comparison to locate tangents and extreme values.

FERMAT:
Later, calculus formalized these ideas into differentiation rules.
But the structure is already present here:

FERMAT:
use a small increment, form a difference, simplify,
and extract a condition that identifies slope or an extremum.
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
