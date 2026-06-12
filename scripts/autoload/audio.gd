extends Node

const SAMPLE_RATE: int = 22050
const POOL_SIZE: int = 8

# Note frequencies (equal temperament). "R" = rest.
const NOTE_FREQ: Dictionary = {
	"A2": 110.00, "B2": 123.47,
	"C3": 130.81, "D3": 146.83, "E3": 164.81, "F3": 174.61,
	"G3": 196.00, "A3": 220.00, "B3": 246.94,
	"C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23,
	"G4": 392.00, "A4": 440.00, "Bb4": 466.16, "B4": 493.88,
	"C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46,
	"G5": 783.99, "A5": 880.00, "B5": 987.77,
	"C6": 1046.50, "D6": 1174.66, "R": 0.0,
}

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.65

var _players: Array = []
var _music_player: AudioStreamPlayer = null
var _cache: Dictionary = {}
var _current_track: String = ""

const SETTINGS_PATH: String = "user://settings.cfg"

func _ready() -> void:
	for i: int in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	load_settings()

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	sfx_volume  = clampf(cfg.get_value("audio", "sfx_volume",  sfx_volume),  0.0, 1.0)
	music_volume = clampf(cfg.get_value("audio", "music_volume", music_volume), 0.0, 1.0)

# --- Public API ---

func play(sfx_name: String) -> void:
	var stream = _get_stream(sfx_name)
	if stream == null:
		return
	var player: AudioStreamPlayer = _next_player()
	player.stream = stream
	player.volume_db = linear_to_db(master_volume * sfx_volume)
	player.play()

func play_music(track_name: String) -> void:
	if _current_track == track_name and _music_player.playing:
		return
	_current_track = track_name
	var stream = _get_music_stream(track_name)
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(master_volume * music_volume)
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()
	_current_track = ""

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)

func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	if _music_player != null and _music_player.playing:
		_music_player.volume_db = linear_to_db(master_volume * music_volume)

# --- Internals ---

func _next_player() -> AudioStreamPlayer:
	for p: AudioStreamPlayer in _players:
		if not p.playing:
			return p
	return _players[0]

func _get_stream(sfx_name: String):
	if _cache.has(sfx_name):
		return _cache[sfx_name]
	for ext: String in ["wav", "ogg"]:
		var path := "res://assets/sfx/" + sfx_name + "." + ext
		if ResourceLoader.exists(path):
			var s = load(path)
			_cache[sfx_name] = s
			return s
	var stream: AudioStreamWAV = _build_sfx(sfx_name)
	if stream != null:
		_cache[sfx_name] = stream
	return stream

func _get_music_stream(track_name: String):
	var key := "music_" + track_name
	if _cache.has(key):
		return _cache[key]
	for ext: String in ["ogg", "wav"]:
		var path := "res://assets/music/" + track_name + "." + ext
		if ResourceLoader.exists(path):
			var s = load(path)
			if s is AudioStreamWAV:
				s.loop_mode = AudioStreamWAV.LOOP_FORWARD
				s.loop_begin = 0
				s.loop_end = int(s.get_length() * float(s.mix_rate)) - 1
			_cache[key] = s
			return s
	var stream: AudioStreamWAV = _build_music(track_name)
	if stream != null:
		_cache[key] = stream
	return stream

# --- SFX synthesis ---

func _build_sfx(sfx_name: String) -> AudioStreamWAV:
	match sfx_name:
		"attack":    return _tone_adsr(400.0, 0.005, 0.025, 0.0,  0.0,  0.5,  0.60, "square")
		"dash":      return _sweep_adsr(300.0, 820.0, 0.13, 0.50)
		"special":   return _chord_sweep(200.0, 900.0, 0.38, 0.50)
		"hit":       return _noise_burst(0.06, 0.60)
		"hurt":      return _tone_adsr(160.0, 0.005, 0.02, 0.08, 0.03, 0.35, 0.55, "square")
		"defeat":    return _defeat_sound()
		"swap":      return _tone_adsr(680.0, 0.003, 0.0,  0.0,  0.07, 0.9,  0.38, "sine")
		"bies":      return _sweep_adsr(1200.0, 100.0, 0.65, 0.55)
		"ui_move":   return _tone_adsr(520.0, 0.002, 0.0,  0.0,  0.04, 0.9,  0.25, "sine")
		"ui_select": return _tone_adsr(820.0, 0.002, 0.0,  0.0,  0.09, 0.9,  0.40, "sine")
		"dice_roll":     return _noise_burst(0.12, 0.35)
		"spoon_pass":    return _tone_adsr(900.0, 0.001, 0.01, 0.0,  0.06, 0.0,  0.25, "sine")
		"spoon_power":   return _chord_sweep(350.0, 950.0, 0.35, 0.40)
		"spoon_eliminate": return _sweep_adsr(500.0, 120.0, 0.45, 0.5)
		"spoon_victory": return _sweep_adsr(440.0, 1100.0, 0.6, 0.55)
		_: return null

# Full ADSR envelope tone. sustain_level = amplitude during sustain phase (0–1).
func _tone_adsr(freq: float, attack: float, decay: float, sustain: float,
		release: float, sustain_level: float, volume: float, wave: String) -> AudioStreamWAV:
	var dur: float = attack + decay + sustain + release
	var n: int = int(SAMPLE_RATE * dur)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i: int in n:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float
		if t < attack:
			env = (t / attack) if attack > 0.0 else 1.0
		elif t < attack + decay:
			env = lerpf(1.0, sustain_level, (t - attack) / decay) if decay > 0.0 else sustain_level
		elif t < attack + decay + sustain:
			env = sustain_level
		else:
			var rt: float = t - attack - decay - sustain
			env = sustain_level * (1.0 - rt / release) if release > 0.0 else 0.0
		var v: float
		match wave:
			"square":
				v = 1.0 if sin(TAU * freq * t) >= 0.0 else -1.0
			"triangle":
				var ph: float = fmod(t * freq, 1.0)
				v = 4.0 * ph - 1.0 if ph < 0.5 else 3.0 - 4.0 * ph
			_:
				v = sin(TAU * freq * t)
		samples[i] = clampf(v * volume * env, -1.0, 1.0)
	return _to_wav(samples)

# Frequency sweep with a sine-shaped amplitude envelope (ramps up then down).
func _sweep_adsr(freq_start: float, freq_end: float, duration: float, volume: float) -> AudioStreamWAV:
	var n: int = int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var phase: float = 0.0
	for i: int in n:
		var progress: float = float(i) / float(n)
		var freq: float = lerpf(freq_start, freq_end, progress)
		phase += TAU * freq / float(SAMPLE_RATE)
		var env: float = sin(progress * PI)
		samples[i] = clampf(sin(phase) * volume * env, -1.0, 1.0)
	return _to_wav(samples)

# Three-voice chord sweep — fuller sound for Special ability.
func _chord_sweep(freq_start: float, freq_end: float, duration: float, volume: float) -> AudioStreamWAV:
	var n: int = int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var ratios: Array = [1.0, 1.26, 1.5]
	var phases: Array = [0.0, 0.0, 0.0]
	for i: int in n:
		var progress: float = float(i) / float(n)
		var freq: float = lerpf(freq_start, freq_end, progress)
		var env: float = 1.0 - progress * 0.85
		var v: float = 0.0
		for j: int in ratios.size():
			phases[j] = phases[j] + TAU * freq * ratios[j] / float(SAMPLE_RATE)
			v += sin(phases[j]) / float(ratios.size())
		samples[i] = clampf(v * volume * env, -1.0, 1.0)
	return _to_wav(samples)

func _noise_burst(duration: float, volume: float) -> AudioStreamWAV:
	var n: int = int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i: int in n:
		var env: float = 1.0 - float(i) / float(n)
		samples[i] = (randf() * 2.0 - 1.0) * volume * env
	return _to_wav(samples)

# Descending sweep mixed with noise — used for game-over / defeat.
func _defeat_sound() -> AudioStreamWAV:
	var n: int = int(SAMPLE_RATE * 0.8)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var phase: float = 0.0
	for i: int in n:
		var progress: float = float(i) / float(n)
		var freq: float = lerpf(280.0, 40.0, progress)
		phase += TAU * freq / float(SAMPLE_RATE)
		var env: float = 1.0 - progress * 0.65
		var noise: float = (randf() * 2.0 - 1.0) * 0.28
		samples[i] = clampf((sin(phase) * 0.55 + noise) * 0.55 * env, -1.0, 1.0)
	return _to_wav(samples)

# --- Music synthesis ---
#
# Three looping chiptune tracks generated entirely in code.
# Dropping a real OGG/WAV at res://assets/music/<name>.ogg|wav overrides
# the procedural version automatically — no code change needed.

func _build_music(track_name: String) -> AudioStreamWAV:
	match track_name:
		"overworld":
			return _make_music_track(
				# Melody — C major, upbeat 4-bar loop
				[["C5",1],["E5",1],["G5",1],["E5",1],
				 ["F5",1],["A5",1],["C6",1],["A5",1],
				 ["G4",1],["B4",1],["D5",1],["B4",1],
				 ["C5",1],["G5",1],["E5",1],["C5",1]],
				# Bass — I IV V I chord roots
				[["C3",2],["C3",2], ["F3",2],["F3",2],
				 ["G3",2],["G3",2], ["C3",2],["C3",2]],
				130.0, "triangle", "square")
		"combat":
			return _make_music_track(
				# Melody — A minor, tense driving loop
				[["A4",1],["C5",1],["E5",1],["C5",1],
				 ["D5",1],["F5",1],["A5",1],["F5",1],
				 ["E4",1],["G4",1],["B4",1],["G4",1],
				 ["A4",1],["E5",1],["C5",1],["A4",1]],
				# Bass
				[["A2",2],["A2",2], ["D3",2],["D3",2],
				 ["E3",2],["E3",2], ["A2",2],["A2",2]],
				155.0, "square", "square")
		"boss":
			return _make_music_track(
				# Melody — A minor, staccato dramatic loop
				[["A4",1],["R",1],["E5",1],["R",1],
				 ["F5",1],["R",1],["C5",1],["R",1],
				 ["G4",1],["R",1],["E5",1],["R",1],
				 ["A4",1],["R",1],["A4",2]],
				# Bass
				[["A2",2],["A2",2], ["F3",2],["F3",2],
				 ["E3",2],["E3",2], ["A2",2],["A2",2]],
				165.0, "square", "square")
		"victory":
			return _make_music_track(
				# Melody — C major, slow triumphant fanfare (half-notes at 72 bpm = grand, ceremonial)
				[["G4",2],["C5",2],["E5",2],["G5",2],
				 ["F5",2],["E5",2],["D5",2],["C5",4],
				 ["E5",2],["G5",2],["A5",2],["G5",2],
				 ["F5",2],["E5",2],["D5",2],["C5",4]],
				# Bass — slow, full C major cadence
				[["C3",4],["C3",4], ["F3",4],["F3",4],
				 ["G3",4],["G3",4], ["C3",4],["C3",4]],
				72.0, "triangle", "square")
		_:
			return null

func _make_music_track(melody: Array, bass: Array, bpm: float,
		mel_wave: String, bass_wave: String) -> AudioStreamWAV:
	var beat_sec: float = 60.0 / bpm
	var mel_s: PackedFloat32Array = _notes_to_samples(melody, beat_sec, mel_wave, 0.45)
	var bas_s: PackedFloat32Array = _notes_to_samples(bass,   beat_sec, bass_wave, 0.32)
	var n: int = max(mel_s.size(), bas_s.size())
	var mixed := PackedFloat32Array()
	mixed.resize(n)
	for i: int in n:
		var m: float = mel_s[i] if i < mel_s.size() else 0.0
		var b: float = bas_s[i] if i < bas_s.size() else 0.0
		mixed[i] = clampf((m + b) * 0.75, -1.0, 1.0)
	var wav: AudioStreamWAV = _to_wav(mixed)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = n - 1
	return wav

func _notes_to_samples(notes: Array, beat_sec: float, wave: String, vol: float) -> PackedFloat32Array:
	var total: int = 0
	for nd: Array in notes:
		total += int(SAMPLE_RATE * nd[1] * beat_sec)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var pos: int = 0
	for nd: Array in notes:
		var freq: float = NOTE_FREQ.get(nd[0], 0.0)
		var note_n: int = int(SAMPLE_RATE * nd[1] * beat_sec)
		var gate_n: int = int(note_n * 0.80)
		for i: int in note_n:
			if pos + i >= total:
				break
			if freq < 1.0 or i >= gate_n:
				samples[pos + i] = 0.0
			else:
				var t: float = float(i) / float(SAMPLE_RATE)
				var env: float = 1.0 - float(i) / float(gate_n)
				var v: float
				match wave:
					"square":
						v = 1.0 if sin(TAU * freq * t) >= 0.0 else -1.0
					"triangle":
						var ph: float = fmod(t * freq, 1.0)
						v = 4.0 * ph - 1.0 if ph < 0.5 else 3.0 - 4.0 * ph
					_:
						v = sin(TAU * freq * t)
				samples[pos + i] = v * vol * env
		pos += note_n
	return samples

# --- WAV conversion ---

func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i: int in samples.size():
		var v: int = clampi(int(samples[i] * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	return wav
