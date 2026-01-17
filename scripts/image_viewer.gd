extends Control

signal images_finished

@onready var panel: Panel = $Panel
@onready var texture_rect: TextureRect = $Panel/TextureRect

var _images: Array[Texture2D] = []
var _index: int = 0
var _active: bool = false

func _ready() -> void:
	hide()
	set_process_unhandled_input(false)

func open_images(images: Array[Texture2D]) -> void:
	if images.is_empty():
		emit_signal("images_finished")
		return

	_images = images
	_index = 0
	_active = true

	_show_current()
	show()
	set_process_unhandled_input(true)

func _show_current() -> void:
	texture_rect.texture = _images[_index]

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if event.is_action_pressed("dialogue_next"):
		get_viewport().set_input_as_handled()
		advance()

func advance() -> void:
	_index += 1
	if _index >= _images.size():
		close()
	else:
		_show_current()

func close() -> void:
	_active = false
	hide()
	set_process_unhandled_input(false)
	emit_signal("images_finished")
