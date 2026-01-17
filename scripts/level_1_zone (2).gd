extends Area2D

@export var player_group_name: String = "player"

@export var music_stream: AudioStream
@export var music_priority: int = 0        # higher = overrides others
@export var fade_time: float = 0.5
@export var target_volume_db: float = -6.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(player_group_name):
		MusicManager.enter_zone(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(player_group_name):
		MusicManager.exit_zone(self)
