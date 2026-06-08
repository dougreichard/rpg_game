extends Node2D

# Guinea pigs (unnamed, per CLAUDE.md) — Erin's crowd-cover companion: a
# skittish herd that scatters from her position, flooding the floor and drawing
# every nearby guard's attention toward the chaos rather than the duo's actual
# location. Three-phase SCATTER → MILL → RETURN state machine; on arrival the
# whole herd emits a noise burst, then periodic pulses fire from random
# individual pigs' positions during MILL — pulling investigating and patrolling
# guards to a spread area, not a single point (wider coverage than Twinkle's
# single bark, fitting "flood a floor, drawing every eye" from their spec).
# No class_name — preload()+untyped var (see [[feedback-godot-technical]]).

const PIG_COUNT: int = 5
const SCATTER_SPEED: float = 155.0
const RETURN_SPEED: float = 240.0
const ARRIVE_DIST: float = 12.0
const SCATTER_DIST: float = 90.0
const NOISE_RADIUS: float = 185.0
const NOISE_INTERVAL: float = 0.8
const MILL_DURATION: float = 3.0
const LIFETIME: float = 8.0
const BODY_RADIUS: float = 5.0

enum Phase { SCATTER, MILL, RETURN }

var _summoner: Player = null
var _phase: Phase = Phase.SCATTER
var _life_timer: float = LIFETIME
var _mill_timer: float = MILL_DURATION
var _noise_timer: float = NOISE_INTERVAL
var _pig_pos: PackedVector2Array
var _pig_targets: PackedVector2Array
var _pig_colors: Array = []

func setup(summoner: Player) -> void:
	_summoner = summoner
	global_position = summoner.global_position
	_pig_pos.resize(PIG_COUNT)
	_pig_targets.resize(PIG_COUNT)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in PIG_COUNT:
		var jitter := Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-6.0, 6.0))
		_pig_pos[i] = global_position + jitter
		var angle: float = (float(i) / float(PIG_COUNT)) * TAU + rng.randf_range(-0.28, 0.28)
		_pig_targets[i] = global_position + Vector2(cos(angle), sin(angle)) * SCATTER_DIST * rng.randf_range(0.65, 1.0)
		_pig_colors.append(Color(
			rng.randf_range(0.60, 0.78),
			rng.randf_range(0.44, 0.60),
			rng.randf_range(0.32, 0.48)
		))

func _process(delta: float) -> void:
	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()
		return
	match _phase:
		Phase.SCATTER: _tick_scatter(delta)
		Phase.MILL:    _tick_mill(delta)
		Phase.RETURN:  _tick_return(delta)
	queue_redraw()

func _tick_scatter(delta: float) -> void:
	var all_arrived: bool = true
	for i in PIG_COUNT:
		var to: Vector2 = _pig_targets[i] - _pig_pos[i]
		if to.length() > ARRIVE_DIST:
			all_arrived = false
			_pig_pos[i] += to.normalized() * SCATTER_SPEED * delta
	if all_arrived:
		_phase = Phase.MILL
		_mill_timer = MILL_DURATION
		_noise_timer = NOISE_INTERVAL
		Audio.play("special")
		for i in PIG_COUNT:
			GameManager.emit_noise(_pig_pos[i], NOISE_RADIUS)

func _tick_mill(delta: float) -> void:
	_noise_timer -= delta
	if _noise_timer <= 0.0:
		_noise_timer = NOISE_INTERVAL
		GameManager.emit_noise(_pig_pos[randi() % PIG_COUNT], NOISE_RADIUS)
	_mill_timer -= delta
	if _mill_timer <= 0.0:
		_phase = Phase.RETURN

func _tick_return(delta: float) -> void:
	if _summoner == null or not is_instance_valid(_summoner):
		queue_free()
		return
	var all_arrived: bool = true
	for i in PIG_COUNT:
		_pig_targets[i] = _summoner.global_position
		var to: Vector2 = _pig_targets[i] - _pig_pos[i]
		if to.length() > ARRIVE_DIST:
			all_arrived = false
			_pig_pos[i] += to.normalized() * RETURN_SPEED * delta
	if all_arrived:
		queue_free()

func _draw() -> void:
	for i in PIG_COUNT:
		draw_circle(to_local(_pig_pos[i]), BODY_RADIUS, _pig_colors[i])
