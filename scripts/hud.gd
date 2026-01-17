extends CanvasLayer

# IMPORTANT: replace the path below with your copied node path
@onready var baby_toggle: CheckButton = $BabyModeToggle

func _ready() -> void:
	if baby_toggle == null:
		push_error("Hud: BabyModeToggle node not found. Fix the node path in hud.gd.")
		return

	# Prevent Space/Enter from toggling it
	baby_toggle.focus_mode = Control.FOCUS_NONE

	# Sync the toggle to the current (autoload) GameManager state
	baby_toggle.button_pressed = GameManager.baby_mode

func _on_baby_mode_toggle_toggled(button_pressed: bool) -> void:
	print("HUD toggled ->", button_pressed)
	GameManager.set_baby_mode(button_pressed)
	print("Autoload baby_mode now ->", GameManager.baby_mode)
