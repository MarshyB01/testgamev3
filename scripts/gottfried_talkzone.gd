extends Area2D

@export var player_group_name: String = "player"
@export var dialogue_ui_path: NodePath = ^"/root/Game/Hud/DialogueSystem"
@export var image_viewer_path: NodePath = ^"/root/Game/Hud/ImageViewer"

# NEW: drag Madhava's AnimatedSprite2D (world sprite) here in the Inspector
@export var npc_anim_path: NodePath

@export_multiline var npc_dialogue_raw: String = """
...

LEIBNIZ:
Hello. I am Gottfried Wilhelm Leibniz.

LEIBNIZ:
My contribution to calculus was developing a clear, systematic way to work with rates of change and accumulated quantities,
and—just as importantly—creating notation that made these ideas easier to communicate and use.

LEIBNIZ:
There are two central problems.

LEIBNIZ:
First: the tangent problem.
Given a curve, how do you find its slope at a single point?

LEIBNIZ:
Second: the area problem.
Given a curve, how do you find the area under it, or more generally, the total amount accumulated as x changes?

LEIBNIZ:
To handle the tangent problem, I introduced the idea of differentials.
If x changes by a very small amount, call it dx, then the corresponding change in y is dy.

LEIBNIZ:
The key quantity is the ratio dy/dx.

LEIBNIZ:
This ratio represents how fast y changes compared to x at a point.
In modern terms, this is the derivative.

LEIBNIZ:
This way of writing it is useful because it matches the way problems are set up.
You often start with a relationship between x and y, and you want a rule for how small changes relate.

LEIBNIZ:
For example, if y depends on x, then dy tells you how y responds to a small change dx.
The derivative dy/dx summarizes that local behavior.

LEIBNIZ:
To handle the area problem, I introduced the integral sign ∫.
It represents summing many small pieces.

LEIBNIZ:
You can imagine splitting an interval into tiny widths dx, building thin rectangles with height f(x), and adding them.

LEIBNIZ:
So ∫ f(x) dx means:
take the function f(x), multiply by an infinitesimal width dx, and sum across the interval.

LEIBNIZ:
The most important connection is that these two operations are inverses.
Differentiation breaks a quantity into its local rate of change.

LEIBNIZ:
Integration rebuilds a quantity from those local changes.

LEIBNIZ:
In other words:
if F'(x) = f(x), then ∫ f(x) dx = F(x) + C.

LEIBNIZ:
And for a definite interval, the accumulated total is F(b) − F(a).

LEIBNIZ:
This relationship turns many geometry and physics problems into an organized procedure:

LEIBNIZ:
1) translate the situation into a function,
2) differentiate to analyze local change, or integrate to find total accumulation,
3) interpret the result back in the original context.

LEIBNIZ:
My notation made calculus portable.

LEIBNIZ:
The symbols dx, dy, dy/dx, and ∫ are compact, consistent, and easy to apply across many problems.
Because of that, calculus could spread, be taught, and be extended much more rapidly.

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
