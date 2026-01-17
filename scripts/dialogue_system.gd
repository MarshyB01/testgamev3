extends Control

signal dialogue_finished

@onready var dialogue_label: RichTextLabel = $HBoxContainer/VBoxContainer/RichTextLabel
@onready var portrait_anim: AnimatedSprite2D = $HBoxContainer/SpeakerParent/PortraitAnim

var _lines: PackedStringArray = PackedStringArray()
var _index: int = 0
var _active: bool = false

func _ready() -> void:
	hide()
	set_process_unhandled_input(false)
	if portrait_anim != null:
		portrait_anim.hide()

# Dialogue pages + animated sprite data (frames/anim/speed/flip)
func open_lines(
	lines: PackedStringArray,
	frames: SpriteFrames = null,
	anim: StringName = &"idle",
	speed: float = 1.0,
	flip_h: bool = false
) -> void:
	if lines.is_empty():
		return

	_lines = lines
	_index = 0
	_active = true

	_set_animated_sprite(frames, anim, speed, flip_h)
	_show_current()

	show()
	set_process_unhandled_input(true)

func _set_animated_sprite(frames: SpriteFrames, anim: StringName, speed: float, flip_h: bool) -> void:
	if portrait_anim == null:
		return

	if frames == null:
		portrait_anim.hide()
		portrait_anim.stop()
		return

	portrait_anim.sprite_frames = frames
	portrait_anim.speed_scale = speed
	portrait_anim.flip_h = flip_h

	# Fall back safely if the requested animation doesn't exist
	if portrait_anim.sprite_frames.has_animation(anim):
		portrait_anim.animation = anim
	elif portrait_anim.sprite_frames.has_animation(&"default"):
		portrait_anim.animation = &"default"
	else:
		# If neither exists, just use the first available animation (prevents blank)
		var names := portrait_anim.sprite_frames.get_animation_names()
		if names.size() > 0:
			portrait_anim.animation = names[0]

	portrait_anim.show()
	portrait_anim.play()

func _show_current() -> void:
	dialogue_label.text = _lines[_index]

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if event.is_action_pressed("dialogue_next"):
		get_viewport().set_input_as_handled()
		advance()

func advance() -> void:
	_index += 1
	if _index >= _lines.size():
		close()
	else:
		_show_current()

func close() -> void:
	_active = false
	hide()
	set_process_unhandled_input(false)

	if portrait_anim != null:
		portrait_anim.stop()

	emit_signal("dialogue_finished")
