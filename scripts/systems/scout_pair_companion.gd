extends Node2D

# William & Mary (rabbits) — a puzzle-scout PAIR, always summoned and used
# together, never solo (see CLAUDE.md roster: "where one rabbit can pull a
# lever, the other can hold a counterweight — together they solve two-point
# puzzles a single companion can't"). Each instance of this script is ONE
# rabbit: it scurries to its own target point — squeezing through a gap the
# duo can't fit through — and holds there. The level pairs up two instances
# and watches for `is_holding` to go true on BOTH at once; that's the moment
# their two-point trick pays off.
# No class_name — preload()+untyped var, same gotcha as AnimalCompanion (see
# [[feedback-godot-technical]]).

const SCOUT_SPEED: float = 220.0
const ARRIVE_DISTANCE: float = 8.0
const LIFETIME: float = 8.0
const BODY_RADIUS: float = 7.0
const HOLD_RING_COLOR: Color = Color(1.0, 1.0, 1.0, 0.55)

enum Phase { SCOUT, HOLD }

var _target_point: Vector2 = Vector2.ZERO
var _color: Color = Color.WHITE
var _phase: Phase = Phase.SCOUT
var _life_timer: float = LIFETIME
var _sprite: AnimatedSprite2D = null
var _move_dir: Vector2 = Vector2.RIGHT

var is_holding: bool = false

func _ready() -> void:
	var sf: SpriteFrames = SpriteLoader.try_load_companion("william_and_mary")
	if sf != null:
		_sprite = AnimatedSprite2D.new()
		_sprite.sprite_frames = sf
		_sprite.scale = Vector2.ONE * SpriteLoader.COMPANION_SPRITE_SCALE
		add_child(_sprite)
	_update_sprite()

func setup(start_pos: Vector2, target_point: Vector2, color: Color) -> void:
	global_position = start_pos
	_target_point = target_point
	_color = color

func _process(delta: float) -> void:
	if is_holding:
		_update_sprite()
		queue_redraw()
		return
	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()
		return
	_tick_scout(delta)
	_update_sprite()
	queue_redraw()

func _tick_scout(delta: float) -> void:
	var to_point: Vector2 = _target_point - global_position
	if to_point.length() <= ARRIVE_DISTANCE:
		global_position = _target_point
		_phase = Phase.HOLD
		is_holding = true
		Audio.play("hit")
		return
	_move_dir = to_point.normalized()
	global_position += _move_dir * SCOUT_SPEED * delta

func _update_sprite() -> void:
	if _sprite == null:
		return
	var target_anim: String
	match _phase:
		Phase.SCOUT:
			target_anim = "hop_right_pair" if abs(_move_dir.x) >= abs(_move_dir.y) else "hop_down_pair"
		Phase.HOLD:
			target_anim = "brace_hold_right_pair"
	if _sprite.animation != target_anim:
		_sprite.play(target_anim)
	if _move_dir.x != 0.0:
		_sprite.flip_h = _move_dir.x < 0.0

func _draw() -> void:
	if _sprite != null:
		if _phase == Phase.HOLD:
			draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 14, HOLD_RING_COLOR, 2.0)
		return
	draw_circle(Vector2.ZERO, BODY_RADIUS, _color)
	if _phase == Phase.HOLD:
		draw_arc(Vector2.ZERO, BODY_RADIUS + 5.0, 0.0, TAU, 14, HOLD_RING_COLOR, 2.0)
