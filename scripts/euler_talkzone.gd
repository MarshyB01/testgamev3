extends Area2D

@export var player_group_name: String = "player"
@export var dialogue_ui_path: NodePath = ^"/root/Game/Hud/DialogueSystem"
@export var image_viewer_path: NodePath = ^"/root/Game/Hud/ImageViewer"

# NEW: drag Madhava's AnimatedSprite2D (world sprite) here in the Inspector
@export var npc_anim_path: NodePath

@export_multiline var npc_dialogue_raw: String = """
...

EULER:
Hello. I am Leonhard Euler.

EULER:
By the time I began working, the main ideas of calculus already existed.
My contribution was to expand them, organize them, and apply them across many fields so they became a complete, usable system.

EULER:
There are three themes that summarize my role:

EULER:
(1) standard methods for differential equations,
(2) power series as a general tool for calculus,
and
(3) connecting functions, exponentials, and trigonometry in a unified way.

EULER:
First: differential equations.
Many important problems are not written as y = f(x).

EULER:
Instead, they are written in terms of how a quantity changes:
an equation involving derivatives such as y', y'', and so on.

EULER:
For example, if the rate of change of a quantity depends on the quantity itself, you get equations like:
y' = k y.

EULER:
This leads to exponential growth or decay.
If acceleration depends on position, you get second-order equations that describe oscillations and motion.

EULER:
I developed and taught systematic techniques for solving many common forms,
including linear differential equations and equations that can be separated into x-parts and y-parts.

EULER:
Second: power series.
A power series rewrites a function as an infinite sum of powers:

EULER:
f(x) = a0 + a1 x + a2 x^2 + a3 x^3 + …

EULER:
This is powerful because differentiation and integration become simple:
you can differentiate and integrate term by term.

EULER:
That lets you approximate functions, solve equations, and compute values that are otherwise difficult to obtain.

EULER:
If you look back at earlier work like the Kerala School, you see the same idea.
What I did was treat series as a standard, general method and use it widely and consistently.

EULER:
Third: unification of exponentials and trigonometry.
One of the most important identities connected to my name is:

EULER:
e^(i x) = cos(x) + i sin(x).

EULER:
This is not just a curiosity.
It shows that exponential behavior and circular (trigonometric) behavior are deeply connected.

EULER:
From this identity, many results follow efficiently, including formulas for sine and cosine, and many series expansions.

EULER:
Because of work like this, calculus becomes more than a set of tricks.
It becomes a connected language:

EULER:
rates of change, accumulated quantities, infinite sums, and differential equations all fit together.

EULER:
So if you ask what I did in the history of calculus, the answer is:
I helped turn calculus into a complete toolkit that could be taught, expanded, and applied at scale.

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
