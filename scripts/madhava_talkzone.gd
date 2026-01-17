extends Area2D

@export var player_group_name: String = "player"
@export var dialogue_ui_path: NodePath = ^"/root/Game/Hud/DialogueSystem"
@export var image_viewer_path: NodePath = ^"/root/Game/Hud/ImageViewer"

# NEW: drag Madhava's AnimatedSprite2D (world sprite) here in the Inspector
@export var npc_anim_path: NodePath

@export_multiline var npc_dialogue_raw: String = """
...

MADHAVA:
Welcome. I am Madhava of Sangamagrama, from the Kerala school of astronomy and mathematics.

MADHAVA:
My work is focused on calculation—especially what astronomy demands: accurate angles, arc lengths, and reliable numerical methods.

MADHAVA:
Sine, cosine, and arctangent are essential for astronomy, but they are not easy to compute directly for many angles.

MADHAVA:
So I looked for a way to rewrite these functions into forms that are easier to calculate.

MADHAVA:
The key idea is to express a function as a sum of many simpler pieces.

MADHAVA:
If each piece is easy to compute, then adding enough pieces gives a strong approximation of the original function.

MADHAVA:
Start with something simple: a small angle measured in radians.
For small angles, sine behaves almost like the angle itself.

MADHAVA:
That is why the first term for sine is just 0.

MADHAVA:
But sine is not exactly 0, so we need a correction.

MADHAVA:
The next correction depends on 0^3, because the sine curve bends away from a straight line in a symmetric way.

MADHAVA:
That correction is subtracted: 0 − (0^3 / 3!).

MADHAVA:
Even that is still not perfect.
So we add a smaller correction that depends on 0^5, then subtract an even smaller correction with 0^7, and so on.

MADHAVA:
This creates a repeating pattern: alternating signs, odd powers, and factorials in the denominators.

MADHAVA:
So the structure for sine looks like this:
0 − 0^3/3! + 0^5/5! − 0^7/7! + …

MADHAVA:
Cosine follows the same logic, but cosine starts near 1 when the angle is small.
So its first term is 1, and then it decreases with a 0^2 correction:

MADHAVA:
1 − 0^2/2! + 0^4/4! − 0^6/6! + …

MADHAVA:
These are infinite series: they have no final term.
But for practical computation, you do not need every term.

MADHAVA:
Each new term is smaller than the previous one once 0 is not too large, so the sum settles toward a stable value.

MADHAVA:
Arctangent can also be rewritten into an infinite series.

MADHAVA:
One useful form is built from a repeating odd-power pattern:
x − x^3/3 + x^5/5 − x^7/7 + …

MADHAVA:
This matters because arctan(1) equals π/4.
So, if you can compute arctan(1) accurately, you can compute π.

MADHAVA:
However, there is an important practical issue.
When x = 1, this series improves slowly, because the terms shrink only as 1/(odd number).

MADHAVA:
So I studied ways to improve the approximation by understanding the leftover error when you stop the sum.

MADHAVA:
If you can estimate what remains after the last term you compute, you can correct for it.
That turns a slow method into a faster one, which is critical for real astronomical calculations.

MADHAVA:
The main contribution of these methods is not only the final numbers.

MADHAVA:
It is the idea that curved behavior can be captured through a controlled process of adding terms:
a finite computation that can be made as accurate as needed by extending the pattern.
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
