extends Node
## Sound manager. Autoloaded as Sfx. Pools one-shot players and runs 3 ambience loops.

var _cache := {}
var _pool: Array[AudioStreamPlayer] = []
var _amb := {}
var _amb_target := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music","SFX"]:
		if AudioServer.get_bus_index(bus)<0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
	GameState.apply_sound()
	for i in 16:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	for n in ["amb_wind", "amb_drone", "amb_colour"]:
		var p := AudioStreamPlayer.new()
		var s := _stream(n)
		if s is AudioStreamWAV:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = int(s.get_length() * s.mix_rate)
		p.stream = s
		p.bus = "Music"
		p.volume_db = -80.0
		add_child(p)
		_amb[n] = p
		_amb_target[n] = -80.0

func _stream(n: String) -> AudioStream:
	if not _cache.has(n):
		var path := "res://audio/%s.wav" % n
		_cache[n] = load(path) if ResourceLoader.exists(path) else null
	return _cache[n]

func play(n: String, vol_db := 0.0, pitch := 1.0) -> void:
	var s := _stream(n)
	if s == null:
		return
	for p in _pool:
		if not p.playing:
			p.stream = s
			p.volume_db = vol_db
			p.pitch_scale = pitch
			p.play()
			return
	# all busy: steal the first
	_pool[0].stream = s
	_pool[0].volume_db = vol_db
	_pool[0].pitch_scale = pitch
	_pool[0].play()

func play_var(n: String, vol_db := 0.0, spread := 0.06) -> void:
	play(n, vol_db, 1.0 + randf_range(-spread, spread))

## Ambience: set target loudness (dB) for each loop; fades smoothly.
func ambience(wind_db: float, drone_db: float, colour_db: float) -> void:
	_amb_target["amb_wind"] = wind_db
	_amb_target["amb_drone"] = drone_db
	_amb_target["amb_colour"] = colour_db
	for n in _amb:
		var p: AudioStreamPlayer = _amb[n]
		if not p.playing and p.stream:
			p.play()

func _process(delta: float) -> void:
	for n in _amb:
		var p: AudioStreamPlayer = _amb[n]
		p.volume_db = move_toward(p.volume_db, _amb_target[n], 30.0 * delta)

func silence_all() -> void:
	for n in _amb:
		_amb_target[n] = -80.0
		_amb[n].stop()
		_amb[n].volume_db = -80
	for p in _pool: p.stop()
