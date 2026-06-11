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


func _tick_active() -> void:
	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move.length() > 0.01:
		facing = move.normalized()
		velocity = Vector2(facing.x * MOVE_SPEED, facing.y * MOVE_SPEED * VERTICAL_SCALE)
		_play_walk()
	else:
		velocity = Vector2.ZERO
		sprite.play("idle")
	move_and_slide()


func _tick_follow() -> void:
	if global_position.distance_to(follow_target) > TELEPORT_DISTANCE:
		global_position = follow_target
		velocity = Vector2.ZERO
		return
	var to_target: Vector2 = follow_target - global_position
	if to_target.length() <= FOLLOW_STOP_DISTANCE:
		velocity = Vector2.ZERO
		sprite.play("idle")
	else:
		facing = to_target.normalized()
		velocity = facing * FOLLOW_SPEED
		_play_walk()
	move_and_slide()


func _play_walk() -> void:
	sprite.flip_h = facing.x < 0.0
	var anim: String = "walk_right"
	if abs(facing.y) > abs(facing.x):
		anim = "walk_down" if facing.y > 0.0 else "walk_up"
	sprite.play(anim)
