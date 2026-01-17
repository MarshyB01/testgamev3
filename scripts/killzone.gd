extends Area2D

@onready var timer: Timer = $Timer

@export var respawn_grace_seconds: float = 0.35
@export var respawn_y_offset: float = 12.0 # spawns slightly ABOVE checkpoint

var _dying: bool = false
var _dead_player: Node2D = null
var _dead_collider: CollisionShape2D = null

var _ignore_player: Node2D = null
var _ignore_until_msec: int = 0

func _on_body_entered(body: Node2D) -> void:
	# Ignore immediately after respawn
	if body == _ignore_player and Time.get_ticks_msec() < _ignore_until_msec:
		return

	if _dying:
		return
	if not body.is_in_group("player"):
		return

	_dying = true
	_dead_player = body
	_dead_collider = body.get_node_or_null("CollisionShape2D") as CollisionShape2D

	print("u died")

	# Disable collision (do NOT delete it)
	if _dead_collider != null:
		_dead_collider.set_deferred("disabled", true)

	timer.start()

func _on_timer_timeout() -> void:
	# Baby Mode respawn
	if GameManager.baby_mode and GameManager.has_checkpoint and _dead_player != null and is_instance_valid(_dead_player):
		# Move player to checkpoint (slightly above)
		_dead_player.global_position = GameManager.checkpoint_position + Vector2(0, -respawn_y_offset)

		# Reset velocity if CharacterBody2D
		if _dead_player is CharacterBody2D:
			(_dead_player as CharacterBody2D).velocity = Vector2.ZERO

		# Wait one physics frame so the teleport "sticks" before re-enabling collision
		await get_tree().physics_frame

		# Re-enable collision safely
		if _dead_collider != null and is_instance_valid(_dead_collider):
			_dead_collider.set_deferred("disabled", false)

		# Prevent immediate re-kill
		_ignore_player = _dead_player
		_ignore_until_msec = Time.get_ticks_msec() + int(respawn_grace_seconds * 1000.0)

		_dead_player = null
		_dead_collider = null
		_dying = false
		return

	# Normal mode: reload the level
	get_tree().reload_current_scene()
