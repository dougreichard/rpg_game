extends CharacterBody2D

# Lightweight overworld duo member — no class_name, see
# CLAUDE.md "Godot Technical Patterns" preload()+untyped-var convention.
# ACTIVE is input-driven (move_* actions); FOLLOW walks toward follow_target,
# mirroring the in-level standby's "hold position / follow" behavior.

enum Mode { ACTIVE, FOLLOW }

const MOVE_SPEED: float = 160.0
const VERTICAL_SCALE: float = 0.6
const FOLLOW_SPEED: float = 170.0
const FOLLOW_STOP_DISTANCE: float = 36.0
const TELEPORT_DISTANCE: float = 300.0

# Billboard juice: a soft ground shadow so the feet-anchored Synty character
# billboard reads as standing on the map. (The walk cycle is now frame-animated,
# so the old programmatic sine bob was dropped — it competed with the animation.)
const SHADOW_OFFSET: Vector2 = Vector2(0.0, 2.0)
const SHADOW_RADIUS: float = 8.5
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.26)

var mode: Mode = Mode.ACTIVE
var follow_target: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.DOWN
var input_locked: bool = false
var character_name: String = ""

var sprite: AnimatedSprite2D


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	add_child(shape)


func setup(frames: SpriteFrames, sprite_scale: float = 1.0, name_in: String = "") -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.play("idle")
	add_child(sprite)
	character_name = name_in


func _physics_process(_delta: float) -> void:
	if GameManager.is_paused() or input_locked:
		return
	match mode:
		Mode.ACTIVE:
			_tick_active()
		Mode.FOLLOW:
			_tick_follow()


func _draw() -> void:
	draw_set_transform(SHADOW_OFFSET, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, SHADOW_RADIUS, SHADOW_COLOR)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _tick_active() -> void:
	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move.length() > 0.01:
		facing = move.normalized()
		velocity = Vector2(facing.x * MOVE_SPEED, facing.y * MOVE_SPEED * VERTICAL_SCALE)
		_play_walk()
	else:
		velocity = Vector2.ZERO
		_play_idle()
	move_and_slide()


func _tick_follow() -> void:
	if global_position.distance_to(follow_target) > TELEPORT_DISTANCE:
		global_position = follow_target
		velocity = Vector2.ZERO
		return
	var to_target: Vector2 = follow_target - global_position
	if to_target.length() <= FOLLOW_STOP_DISTANCE:
		velocity = Vector2.ZERO
		_play_idle()
	else:
		facing = to_target.normalized()
		velocity = facing * FOLLOW_SPEED
		_play_walk()
	move_and_slide()


# 8-way: a genuine render per facing (no flipping). Falls back to 3-facing + flip
# for static/PIL frames that lack the diagonal/left strips.
func _play_walk() -> void:
	var anim: String = "walk_" + SpriteLoader.dir_suffix(facing)
	if sprite.sprite_frames.has_animation(anim):
		sprite.flip_h = false
	else:
		var fb: Array = SpriteLoader.cardinal_fallback(facing)
		anim = "walk_" + String(fb[0])
		sprite.flip_h = bool(fb[1])
	sprite.play(anim)


# Directional idle: freeze the walk strip on its neutral mid frame so the duo keeps
# facing their last heading when stopped (falls back to a bare "idle" if present).
func _play_idle() -> void:
	var anim: String = "walk_" + SpriteLoader.dir_suffix(facing)
	if sprite.sprite_frames.has_animation(anim):
		sprite.flip_h = false
		sprite.play(anim)
		sprite.set_frame_and_progress(sprite.sprite_frames.get_frame_count(anim) / 2, 0.0)
		sprite.pause()
	elif sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
