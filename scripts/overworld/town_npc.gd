extends Node2D

# Cosmetic overworld townsfolk — wander a short distance from a home point,
# pause, and pick a new spot. No class_name, see CLAUDE.md "Godot Technical
# Patterns" preload()+untyped-var convention.

const WANDER_RADIUS: float = 64.0
const WANDER_SPEED: float = 45.0
const PAUSE_MIN: float = 1.0
const PAUSE_MAX: float = 3.0
const ARRIVE_DISTANCE: float = 4.0

const SpeechBubbleScript: Script = preload("res://scripts/systems/speech_bubble.gd")
const TOWN_ID: String = "town"
const BUBBLE_DURATION: float = 3.5
const BUBBLE_OFFSET := Vector2(0.0, -52.0)

# Billboard juice — matches overworld_player: footstep dust while wandering. (The
# bob + ground-shadow ellipse were dropped — the shadow looked like a detached
# circle that made the NPC float.)
const STEP_DUST_INTERVAL: float = 0.34
const DUST_FEET_OFFSET: Vector2 = Vector2(0.0, 4.0)
var _step_dust_t: float = 0.0

var sprite: AnimatedSprite2D
var npc_name: String = ""
var quest_id: String = ""
var color: Color = Color.WHITE
var _home: Vector2
var _target: Vector2
var _pause_timer: float = 0.0
var _rng := RandomNumberGenerator.new()
var _bubble        = null  # SpeechBubbleScript instance — null until setup_bubble() called
var _bubble_pre:  String = ""
var _bubble_post: String = ""


# `name`/`quest` identify this townsfolk for overworld_map.gd's dialog/quest
# system -- see CLAUDE.md "NPC dialog & quests". `npc_color` is stashed for
# the dialog box portrait -- needed because NPC_DATA isn't always parallel to
# the spawned _npcs array (some entries are conditionally spawned). Cosmetic-
# only NPCs (none, currently) would simply leave quest blank.
func setup(frames: SpriteFrames, home: Vector2, name: String = "", quest: String = "", npc_color: Color = Color.WHITE) -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.play("idle")
	add_child(sprite)
	npc_name = name
	quest_id = quest
	color = npc_color
	_home = home
	global_position = home
	_rng.randomize()
	_pick_new_target()


func setup_bubble(pre: String, post: String) -> void:
	_bubble_pre  = pre
	_bubble_post = post
	_bubble = SpeechBubbleScript.new()
	_bubble.position = BUBBLE_OFFSET
	add_child(_bubble)

# Called by BubbleCoordinator — reads current quest state and shows the
# appropriate line. No-op if this NPC has no bubble configured.
func fire_bubble() -> void:
	if _bubble == null:
		return
	var state: String = GameManager.get_level_flag(TOWN_ID, "quest_" + quest_id, "not_started")
	var txt: String = _bubble_post if state == "complete" else _bubble_pre
	if txt != "":
		_bubble.show_text(txt, BUBBLE_DURATION)

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
	# 8-way genuine render per facing (no flipping); PIL/static fall back to 3+flip.
	var anim: String = "walk_" + SpriteLoader.dir_suffix(dir)
	if sprite.sprite_frames.has_animation(anim):
		sprite.flip_h = false
	else:
		var fb: Array = SpriteLoader.cardinal_fallback(dir)
		anim = "walk_" + String(fb[0])
		if not sprite.sprite_frames.has_animation(anim):
			anim = "walk_down"
		sprite.flip_h = bool(fb[1])
	sprite.play(anim)
	global_position += dir * WANDER_SPEED * delta
	_step_dust_t -= delta
	if _step_dust_t <= 0.0:
		_step_dust_t = STEP_DUST_INTERVAL
		CombatFX.dust(global_position + DUST_FEET_OFFSET, 3)
