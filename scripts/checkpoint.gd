extends Area2D

@export var player_group_name: String = "player" # must match your Player group EXACTLY

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	print("Checkpoint ready:", name, " monitoring=", monitoring)

func _on_body_entered(body: Node2D) -> void:
	print("Checkpoint body_entered by:", body.name)

	if not body.is_in_group(player_group_name):
		print("Not in group:", player_group_name)
		return

	print("Player entered checkpoint. Baby mode =", GameManager.baby_mode)

	# Store checkpoint only if Baby Mode is ON
	if GameManager.baby_mode:
		GameManager.set_checkpoint(global_position)
	else:
		print("Baby mode OFF: not saving checkpoint")
