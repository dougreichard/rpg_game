extends Node

const SAMPLE_RATE: int = 22050
const POOL_SIZE: int = 8

var _players: Array = []
var _cache: Dictionary = {}

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func play(sfx_name: String) -> void:
	var stream: AudioStreamWAV = _get_stream(sfx_name)
	if stream == null:
		return
	var player: AudioStreamPlayer = _next_player()
	player.stream = stream
	player.play()

func _next_player() -> AudioStreamPlayer:
	for p: AudioStreamPlayer in _players:
		if not p.playing:
			return p
	return _players[0]

func _get_stream(sfx_name: String) -> AudioStreamWAV:
	if _cache.has(sfx_name):
		return _cache[sfx_name]
	var stream: AudioStreamWAV = _build(sfx_name)
	if stream != null:
		_cache[sfx_name] = stream
	return stream

func _build(sfx_name: String) -> AudioStreamWAV:
	match sfx_name:
		"attack":   return _tone(420.0, 0.06, 0.5, "square")
		"dash":     return _sweep(320.0, 760.0, 0.12, 0.4)
		"special":  return _sweep(220.0, 920.0, 0.35, 0.5)
		"hit":      return _tone(190.0, 0.08, 0.55, "noise")
		"hurt":     return _tone(140.0, 0.12, 0.55, "square")
		"defeat":   return _tone(90.0, 0.25, 0.5, "noise")
		"swap":     return _tone(620.0, 0.05, 0.35, "sine")
		"bies":     return _sweep(950.0, 160.0, 0.6, 0.5)
		"ui_move":  return _tone(520.0, 0.04, 0.3, "sine")
		"ui_select": return _tone(760.0, 0.09, 0.4, "sine")
		_: return null

func _tone(freq: float, duration: float, volume: float, wave: String) -> AudioStreamWAV:
	var n: int = int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - float(i) / float(n)
		var v: float
		match wave:
			"square": v = 1.0 if sin(TAU * freq * t) >= 0.0 else -1.0
			"noise":  v = randf() * 2.0 - 1.0
			_:        v = sin(TAU * freq * t)
		samples[i] = v * volume * env
	return _to_wav(samples)

func _sweep(freq_start: float, freq_end: float, duration: float, volume: float) -> AudioStreamWAV:
	var n: int = int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var phase: float = 0.0
	for i in n:
		var progress: float = float(i) / float(n)
		var freq: float = lerpf(freq_start, freq_end, progress)
		phase += TAU * freq / float(SAMPLE_RATE)
		var env: float = 1.0 - progress
		samples[i] = sin(phase) * volume * env
	return _to_wav(samples)

func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v: int = clampi(int(samples[i] * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	return wav
