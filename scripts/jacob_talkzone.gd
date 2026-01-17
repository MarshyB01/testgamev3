extends Area2D

@export var player_group_name: String = "player"
@export var dialogue_ui_path: NodePath = ^"/root/Game/Hud/DialogueSystem"
@export var image_viewer_path: NodePath = ^"/root/Game/Hud/ImageViewer"

# NEW: drag Madhava's AnimatedSprite2D (world sprite) here in the Inspector
@export var npc_anim_path: NodePath

@export_multiline var npc_dialogue_raw: String = """
...

JAKOB BERNOULLI:
Hello. I am Jakob Bernoulli—sometimes written as Jacob Bernoulli.

JAKOB BERNOULLI:
I worked in Basel, and I was part of the generation that helped develop calculus after Newton and Leibniz.
My work focused on making calculus more systematic, especially in two areas: series/summation methods and differential equations.

JAKOB BERNOULLI:
First, I studied patterns in sums—especially sums of powers:
1^p + 2^p + 3^p + … + n^p.

JAKOB BERNOULLI:
These sums appear naturally when you approximate area using rectangles.
If you break an interval into equal steps, the heights often involve powers of the step number.

JAKOB BERNOULLI:
So, efficient formulas for these sums make approximation and computation much faster.

JAKOB BERNOULLI:
To organize these formulas, I introduced and studied what are now called Bernoulli numbers.
They appear as constant coefficients that repeatedly show up when you write general formulas for sums of powers.

JAKOB BERNOULLI:
For example, there are closed forms such as:
1 + 2 + … + n = n(n+1)/2,

JAKOB BERNOULLI:
and
1^2 + 2^2 + … + n^2 = n(n+1)(2n+1)/6.

JAKOB BERNOULLI:
As the power increases, the formulas become more complicated.
Bernoulli numbers provide a structured way to build those formulas rather than re-deriving each one from scratch.

JAKOB BERNOULLI:
Second, I worked extensively with series expansions.

JAKOB BERNOULLI:
A power series rewrites a function as an infinite polynomial-like sum.
This is valuable because polynomials are easier to differentiate, integrate, and approximate.

JAKOB BERNOULLI:
When a function can be expressed as a series, you can:

JAKOB BERNOULLI:
- differentiate term-by-term to study rates of change,
- integrate term-by-term to estimate accumulated quantities,
- and control accuracy by using enough terms.

JAKOB BERNOULLI:
Third, I studied differential equations and curves defined by them.

JAKOB BERNOULLI:
Instead of describing a curve by a simple formula y = f(x), a differential equation describes a relationship involving derivatives,
which often reflects a physical or geometric rule.

JAKOB BERNOULLI:
A well-known example connected to my name is the logarithmic spiral, sometimes called the spira mirabilis.
It is a curve that keeps the same shape as it grows—its geometry repeats under scaling.

JAKOB BERNOULLI:
It can be described by an equation of the form r = a·e^(bθ),
and it has clean relationships between angles and tangents.

JAKOB BERNOULLI:
Overall, my contribution to calculus is this:
I helped turn calculus into a more organized toolkit—
with reliable summation formulas (supported by Bernoulli numbers),

JAKOB BERNOULLI:
series methods for computation and approximation,
and differential-equation thinking for describing curves and change.
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
