extends Node2D

# Cosmetic overworld townsfolk — wander a short distance from a home point,
# pause, and pick a new spot. No class_name, see CLAUDE.md "Godot Technical
# Patterns" preload()+untyped-var convention.

const WANDER_RADIUS: float = 64.0
const WANDER_SPEED: float = 45.0
const PAUSE_MIN: float = 1.0
const PAUSE_MAX: float = 3.0
const ARRIVE_DISTANCE: float = 4.0

var sprite: AnimatedSprite2D
var npc_name: String = ""
var quest_id: String = ""
var _home: Vector2
var _target: Vector2
var _pause_timer: float = 0.0
var _rng := RandomNumberGenerator.new()


# `name`/`quest` identify this townsfolk for overworld_map.gd's dialog/quest
# system -- see CLAUDE.md "NPC dialog & quests". Cosmetic-only NPCs (none,
# currently) would simply leave quest blank.
func setup(frames: SpriteFrames, home: Vector2, name: String = "", quest: String = "") -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.play("idle")
	add_child(sprite)
	npc_name = name
	quest_id = quest
	_home = home
	global_position = home
	_rng.randomize()
	_pick_new_target()


func _pick_new_target() -> void:
	var angle: float = _rng.randf_range(0.0, TAU)
	var dist: float = _rng.randf_range(0.0, WANDER_RADIUS)
	_target = _home + Vector2(cos(angle), sin(angle)) * dist


func _process(delta: float) -> void:
	if _pause_timer > 0.0:
		_pause_timer -= delta
		return
	var to_target: Vector2 = _target - global_position
	if to_target.length() <= ARRIVE_DISTANCE:
		sprite.play("idle")
		_pause_timer = _rng.randf_range(PAUSE_MIN, PAUSE_MAX)
		_pick_new_target()
		return
	var dir: Vector2 = to_target.normalized()
	sprite.flip_h = dir.x < 0.0
	var anim: String = "walk_right"
	if abs(dir.y) > abs(dir.x):
		anim = "walk_down" if dir.y > 0.0 else "walk_up"
	sprite.play(anim)
	global_position += dir * WANDER_SPEED * delta
