extends Node2D

# Lizard (unnamed, per CLAUDE.md) — Evan's vertical-traversal scout:
# scales walls and pipes the duo can't reach to flip a switch or drop a
# rope/ladder down. Three-phase CLIMB → PERCH → RETURN state machine.
# On PERCH it emits `target_reached` so the level can wire up whatever
# gate the lizard solves (alternate route, à la William & Mary in The Drop).
# No class_name — preload()+untyped var (see [[feedback-godot-technical]]).

signal target_reached

const CLIMB_SPEED: float = 120.0
const RETURN_SPEED: float = 160.0
const ARRIVE_DIST: float = 10.0
const PERCH_DURATION: float = 0.55
const BODY_W: float = 6.0
const BODY_H: float = 10.0
const COLOR_IDLE: Color = Color(0.35, 0.55, 0.25)
const COLOR_PERCH: Color = Color(0.55, 0.85, 0.3)

enum Phase { CLIMB, PERCH, RETURN }

var _summoner: Player = null
var _target: Vector2 = Vector2.ZERO
var _phase: Phase = Phase.CLIMB
var _perch_timer: float = PERCH_DURATION
var _draw_color: Color = COLOR_IDLE

func setup(summoner: Player, target_world_pos: Vector2) -> void:
	_summoner = summoner
	global_position = summoner.global_position
	_target = target_world_pos

func _process(delta: float) -> void:
	match _phase:
		Phase.CLIMB:  _tick_climb(delta)
		Phase.PERCH:  _tick_perch(delta)
		Phase.RETURN: _tick_return(delta)
	queue_redraw()

func _tick_climb(delta: float) -> void:
	var to: Vector2 = _target - global_position
	if to.length() <= ARRIVE_DIST:
		_phase = Phase.PERCH
		_perch_timer = PERCH_DURATION
		_draw_color = COLOR_PERCH
		target_reached.emit()
	else:
		global_position += to.normalized() * CLIMB_SPEED * delta

func _tick_perch(delta: float) -> void:
	_perch_timer -= delta
	# Flicker the color to telegraph the switch-flip moment
	_draw_color = COLOR_PERCH if int(_perch_timer * 10) % 2 == 0 else COLOR_IDLE
	if _perch_timer <= 0.0:
		_phase = Phase.RETURN
		_draw_color = COLOR_IDLE
		if _summoner == null or not is_instance_valid(_summoner):
			queue_free()

func _tick_return(delta: float) -> void:
	if _summoner == null or not is_instance_valid(_summoner):
		queue_free()
		return
	var to: Vector2 = _summoner.global_position - global_position
	if to.length() <= ARRIVE_DIST:
		queue_free()
	else:
		global_position += to.normalized() * RETURN_SPEED * delta

func _draw() -> void:
	# Small elongated lizard body — two offset ovals suggesting head+torso
	draw_rect(Rect2(-BODY_W * 0.5, -BODY_H * 0.5, BODY_W, BODY_H), _draw_color)
	draw_rect(Rect2(-BODY_W * 0.4, -BODY_H * 0.5 - 4.0, BODY_W * 0.8, 5.0),
			_draw_color.lightened(0.15))
	# Tiny eye dot
	draw_circle(Vector2(BODY_W * 0.25, -BODY_H * 0.5 - 2.0), 1.2,
			Color(0.1, 0.1, 0.1))
