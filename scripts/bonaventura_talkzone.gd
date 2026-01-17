extends Area2D

@export var player_group_name: String = "player"
@export var dialogue_ui_path: NodePath = ^"/root/Game/Hud/DialogueSystem"
@export var image_viewer_path: NodePath = ^"/root/Game/Hud/ImageViewer"

# NEW: drag Madhava's AnimatedSprite2D (world sprite) here in the Inspector
@export var npc_anim_path: NodePath

@export_multiline var npc_dialogue_raw: String = """
...

CAVALIERI:
Hello. My name is Bonaventura Cavalieri.

CAVALIERI:
I worked in Italy as a mathematician, and I was interested in a basic question:
how do you measure the area of a curved shape, or the volume of a solid, when there is no simple formula?

CAVALIERI:
One method is to compare complicated shapes to simpler ones by breaking them into many thin parts.

CAVALIERI:
I developed what became known as the method of indivisibles.
The idea is to imagine a plane region as being made from an infinite collection of parallel line segments.

CAVALIERI:
Likewise, a solid can be imagined as being made from an infinite collection of parallel cross-sectional slices.

CAVALIERI:
You do not need to physically cut the shape.
You reason as if it were built from these layers.

CAVALIERI:
Here is the most important principle.

CAVALIERI:
Take two shapes that have the same height.
At a given height, draw a horizontal line through each shape.

CAVALIERI:
If, at every height, the length of the segment inside Shape A equals the length of the segment inside Shape B,
then the total areas of the two shapes are equal.

CAVALIERI:
In other words, if the "slice length" matches for every level, then the full area must match.

CAVALIERI:
The same idea works for volume.

CAVALIERI:
If two solids have the same height, and for every height the cross-sectional area of Solid A equals the cross-sectional area of Solid B,
then the volumes of the solids are equal.

CAVALIERI:
This is powerful because it replaces a difficult measurement problem with a simpler comparison problem.

CAVALIERI:
You do not need a single formula for the whole region.
You only need to understand what each slice looks like.

CAVALIERI:
This way of thinking is closely connected to integral calculus.
Later mathematicians formalized the idea of adding infinitely many thin slices using limits.

CAVALIERI:
But the strategy is already here:
measure by slicing, compare by matching slices, and sum the results.

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
