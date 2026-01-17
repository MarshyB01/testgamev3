extends Area2D

@export var player_group_name: String = "player"
@export var dialogue_ui_path: NodePath = ^"/root/Game/Hud/DialogueSystem"
@export var image_viewer_path: NodePath = ^"/root/Game/Hud/ImageViewer"

# NEW: drag Madhava's AnimatedSprite2D (world sprite) here in the Inspector
@export var npc_anim_path: NodePath

@export_multiline var npc_dialogue_raw: String = """
...

BARROW:
Hello. I am Isaac Barrow. I taught mathematics at Cambridge.

BARROW:
My work matters here because I helped connect two problems that, for a long time, were treated as separate:

BARROW:
(1) the tangent problem - finding the slope of a curve at a point,
and
(2) the area problem - finding the area under a curve.

BARROW:
To explain the connection, suppose you start with a curve y = f(x).

BARROW:
Now define a new quantity A(x): the area under f(x) from a fixed starting point up to x.

BARROW:
So A(x) is not a single number-it is a function of x, because the area grows as x increases.

BARROW:
Here is the key idea:
if you increase x by a small amount, the area increases by a thin "strip."

BARROW:
That strip is approximately a rectangle with width Delta x and height f(x).

BARROW:
So the change in area is approximately:
DeltaA ~= f(x) * Delta x

BARROW:
If you divide both sides by Delta x, you get:
DeltaA / Delta x ~= f(x)

BARROW:
And if you make Delta x smaller and smaller, this becomes an exact statement:
the rate at which the area function A(x) changes is f(x).

BARROW:
In modern notation, that is:
A'(x) = f(x)

BARROW:
This is one direction of what is now called the Fundamental Theorem of Calculus:
d/dx of the accumulated area under a curve gives back the original function.

BARROW:
The other direction is the inverse idea:
if F'(x) = f(x), then the area under f from a to b equals F(b) - F(a).

BARROW:
What I did was present this relationship clearly using geometry.

BARROW:
Instead of relying on modern symbols, I used diagrams:
thin area strips, tangent lines, and similar triangles to show why the two problems are inverses.

BARROW:
So my contribution is not a single trick.
It is the bridge:
tangents and areas are connected through accumulation and rate of change.
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
