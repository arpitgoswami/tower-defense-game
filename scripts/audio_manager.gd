extends Node
## Autoload "AudioManager": pooled one-shot SFX + looping music.

const SFX_NAMES: Array[String] = ["cast", "hit", "zombie_death", "coin", "upgrade", "deny", "wave", "game_over"]
const POOL_SIZE := 14

@export var sfx_volume_db: float = -4.0
@export var music_volume_db: float = -10.0

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0
var _music: AudioStreamPlayer


@warning_ignore("integer_division")
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in SFX_NAMES:
		_streams[n] = load("res://assets/audio/%s.wav" % n)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = music_volume_db
	var m := load("res://assets/audio/music.wav") as AudioStreamWAV
	if m:
		m.loop_mode = AudioStreamWAV.LOOP_FORWARD
		m.loop_begin = 0
		m.loop_end = m.data.size() / 2  # 16-bit mono -> 2 bytes per sample
		_music.stream = m
	add_child(_music)


func play(sfx: String, pitch_jitter: float = 0.0, extra_db: float = 0.0) -> void:
	var s: AudioStream = _streams.get(sfx)
	if s == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = s
	p.volume_db = sfx_volume_db + extra_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func play_music() -> void:
	if _music.stream != null and not _music.playing:
		_music.play()


func stop_music() -> void:
	_music.stop()
