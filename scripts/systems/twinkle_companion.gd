extends Node2D

# Twinkle (Pomeranian) — a distraction tool, not a brawler: trots a short
# distance away from her summoner in the direction they're facing, lets out
# a loud bark (rings out a noise burst via GameManager.emit_noise — see
# CLAUDE.md "Stealth & awareness"), then returns. Patrolling/investigating
# guards within earshot go to investigate the bark's location instead of the
# duo's actual position — "rile up a crowd for cover" from her CLAUDE.md
# roster spec, the noise-hub half of the stealth toolkit Calvin & Coolidge's
# combat-charge pattern doesn't touch.
# No class_name — preload()+untyped var, same gotcha as AnimalCompanion (see
# [[feedback-godot-technical]]).

const TROT_SPEED: float = 200.0
const RETURN_SPEED: float = 220.0
const ARRIVE_DISTANCE: float = 10.0
const TROT_DISTANCE: float = 140.0
const BARK_RADIUS: float = 220.0
const BARK_PAUSE: float = 0.5
const LIFETIME: float = 4.0
const BODY_RADIUS: float = 8.0
const BODY_COLOR: Color = Color(0.95, 0.85, 0.55)
const BARK_RING_COLOR: Color = Color(1.0, 1.0, 1.0, 0.6)

enum Phase { TROT_OUT, BARK, RETURN }

var _summoner: Player = null
var _bark_point: Vector2 = Vector2.ZERO
var _phase: Phase = Phase.TROT_OUT
var _life_timer: float = LIFETIME
var _bark_timer: float = 0.0

func setup(summoner: Player, direction: Vector2) -> void:
	_summoner = summoner
	global_position = summoner.global_position
	var dir: Vector2 = direction if direction.length_squared() > 0.0 else Vector2.RIGHT
	_bark_point = global_position + dir.normalized() * TROT_DISTANCE

func _process(delta: float) -> void:
	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()
		return
	match _phase:
		Phase.TROT_OUT: _tick_trot_out(delta)
		Phase.BARK:     _tick_bark(delta)
		Phase.RETURN:   _tick_return(delta)
	queue_redraw()

func _tick_trot_out(delta: float) -> void:
	var to_point: Vector2 = _bark_point - global_position
	if to_point.length() <= ARRIVE_DISTANCE:
		_phase = Phase.BARK
		_bark_timer = BARK_PAUSE
		Audio.play("special")
		GameManager.emit_noise(global_position, BARK_RADIUS)
		return
	global_position += to_point.normalized() * TROT_SPEED * delta

func _tick_bark(delta: float) -> void:
	_bark_timer = maxf(_bark_timer - delta, 0.0)
	if _bark_timer <= 0.0:
		_phase = Phase.RETURN

func _tick_return(delta: float) -> void:
	if _summoner == null or not is_instance_valid(_summoner):
		queue_free()
		return
	var to_summoner: Vector2 = _summoner.global_position - global_position
	if to_summoner.length() <= ARRIVE_DISTANCE:
		queue_free()
		return
	global_position += to_summoner.normalized() * RETURN_SPEED * delta

func _draw() -> void:
	draw_circle(Vector2.ZERO, BODY_RADIUS, BODY_COLOR)
	if _phase == Phase.BARK:
		draw_arc(Vector2.ZERO, BODY_RADIUS + 6.0, 0.0, TAU, 16, BARK_RING_COLOR, 2.0)
