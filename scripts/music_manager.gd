extends Node

@onready var a: AudioStreamPlayer = $PlayerA
@onready var b: AudioStreamPlayer = $PlayerB

var _active: AudioStreamPlayer
var _inactive: AudioStreamPlayer
var _tween: Tween

# Track which zones are currently “claiming” music
var _zones: Array[Node] = []
var _current_zone: Node = null

func _ready() -> void:
	_active = a
	_inactive = b
	_active.volume_db = 0.0
	_inactive.volume_db = -80.0

func enter_zone(zone: Node) -> void:
	if not _zones.has(zone):
		_zones.append(zone)
	_update_music()

func exit_zone(zone: Node) -> void:
	_zones.erase(zone)
	_update_music()

func _update_music() -> void:
	# Choose highest music_priority zone (larger number = higher priority)
	var best: Node = null
	for z in _zones:
		if best == null or (z.music_priority > best.music_priority):
			best = z

	# If no zone, stop music (or play a default track)
	if best == null:
		_crossfade_to(null, 0.5, -6.0)
		_current_zone = null
		return

	# If already playing this zone’s stream, do nothing
	if _current_zone == best:
		return

	_current_zone = best
	_crossfade_to(best.music_stream, best.fade_time, best.target_volume_db)

func _crossfade_to(stream: AudioStream, fade_time: float, target_db: float) -> void:
	# Kill previous tween
	if _tween != null and _tween.is_running():
		_tween.kill()

	# If stream is null, fade out active and stop
	if stream == null:
		_tween = create_tween()
		_tween.tween_property(_active, "volume_db", -80.0, fade_time)
		_tween.finished.connect(func():
			_active.stop()
		)
		return

	# If same stream already active, just ensure volume
	if _active.stream == stream and _active.playing:
		_tween = create_tween()
		_tween.tween_property(_active, "volume_db", target_db, fade_time)
		return

	# Prepare inactive player with new stream
	_inactive.stream = stream
	_inactive.volume_db = -80.0
	_inactive.play()

	# Crossfade
	_tween = create_tween()
	_tween.tween_property(_active, "volume_db", -80.0, fade_time)
	_tween.parallel().tween_property(_inactive, "volume_db", target_db, fade_time)

	_tween.finished.connect(func():
		_active.stop()
		# Swap active/inactive
		var tmp = _active
		_active = _inactive
		_inactive = tmp
	)
