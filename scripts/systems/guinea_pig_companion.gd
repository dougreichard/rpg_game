extends Node2D

# Guinea pig crowd cover  --  a scurrying group that floods an area with noise,
# drawing every guard's attention and giving the duo a window to slip past.
# Summoned by Evan's Special when there are no combat targets and Twinkle is on
# cooldown. Phases: SCATTER (scurry outward) -> FLOOD (hold + emit_noise pulses)
# -> DISPERSE (shrink + queue_free). Same no-class_name preload+untyped-var
# convention as all other companion scripts.

const SCATTER_SPEED: float = 45.0
const SCATTER_DURATION: float = 1.2
const FLOOD_DURATION: float = 4.0
const FLOOD_NOISE_INTERVAL: float = 0.6
const FLOOD_NOISE_RADIUS: float = 200.0
const DISPERSE_DURATION: float = 0.5

const _SPRITE_NAME: String = "guinea_pigs"

enum Phase { SCATTER, FLOOD, DISPERSE }

var _phase: Phase = Phase.SCATTER
var _timer: float = 0.0
var _noise_timer: float = 0.0
var _move_dir: Vector2 = Vector2.RIGHT
var _sprite: AnimatedSprite2D = null

func setup(spawn_pos: Vector2, scatter_dir: Vector2) -> void:
	global_position = spawn_pos
	_move_dir = scatter_dir.normalized() if scatter_dir.length_squared() > 0.0 else Vector2.RIGHT

func _ready() -> void:
	const SpriteLoader = preload("res://scripts/systems/sprite_loader.gd")
	var frames: SpriteFrames = SpriteLoader.try_load_companion(_SPRITE_NAME)
	if frames != null:
		_sprite = AnimatedSprite2D.new()
		_sprite.sprite_frames = frames
		_sprite.scale = Vector2(SpriteLoader.COMPANION_SPRITE_SCALE, SpriteLoader.COMPANION_SPRITE_SCALE)
		_sprite.play("flood_panic")
		add_child(_sprite)

func _process(delta: float) -> void:
	_timer += delta
	match _phase:
		Phase.SCATTER:   _tick_scatter(delta)
		Phase.FLOOD:     _tick_flood(delta)
		Phase.DISPERSE:  _tick_disperse()

func _tick_scatter(delta: float) -> void:
	global_position += _move_dir * SCATTER_SPEED * delta
	if _sprite != null:
		var anim := "scurry_right" if abs(_move_dir.x) >= abs(_move_dir.y) else "scurry_down"
		if _sprite.animation != anim:
			_sprite.play(anim)
		_sprite.flip_h = _move_dir.x < 0.0
	if _timer >= SCATTER_DURATION:
		_timer = 0.0
		_noise_timer = 0.0
		_phase = Phase.FLOOD
		if _sprite != null:
			_sprite.play("idle_scatter")

func _tick_flood(delta: float) -> void:
	_noise_timer += delta
	if _noise_timer >= FLOOD_NOISE_INTERVAL:
		_noise_timer = 0.0
		GameManager.emit_noise(global_position, FLOOD_NOISE_RADIUS)
	if _timer >= FLOOD_DURATION:
		_timer = 0.0
		_phase = Phase.DISPERSE
		if _sprite != null:
			_sprite.play("calm_regroup")

func _tick_disperse() -> void:
	var t: float = clampf(_timer / DISPERSE_DURATION, 0.0, 1.0)
	scale = Vector2.ONE * (1.0 - t)
	if _timer >= DISPERSE_DURATION:
		queue_free()

func _draw() -> void:
	if _sprite != null:
		return
	for i: int in 5:
		var angle: float = i * TAU / 5.0
		draw_circle(Vector2(cos(angle), sin(angle)) * 12.0, 5.0, Color(0.55, 0.38, 0.18))
