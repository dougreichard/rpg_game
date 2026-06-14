class_name Player
extends CharacterBody2D

const ProjectileScript: Script = preload("res://scripts/systems/projectile.gd")
const PLAYER_HIT_LAYER: int = 8
const PLAYER_HIT_MASK: int = 64

signal hp_changed(current: float, maximum: float)
signal bies_charge_changed(charge: float)
signal special_used(character_name: String)
signal died
signal revived

@export var data: CharacterData
@export var is_active: bool = true

var hp: float = 0.0
var bies_charge: float = 0.0
var facing: Vector2 = Vector2.RIGHT
var revive_progress: float = 0.0

# Stealth: true while standing inside a HidingSpot — guards' vision checks
# treat a hidden player as unseeable (still audible if loud nearby).
var is_hidden: bool = false
var action_prefix: String = ""

# Frozen while a dialog box is open -- see GameManager.set_dialog_active().
# Mirrors overworld_player.gd's input_locked guard.
var input_locked: bool = false

enum State { IDLE, WALK, ATTACK, DASH, HURT, DOWN, SPECIAL }
var _state: State = State.IDLE

var _attack_timer: float = 0.0
var _special_timer: float = 0.0
var _dash_timer: float = 0.0
var _hurt_timer: float = 0.0
var _iframe_timer: float = 0.0
var _flash_timer: float = 0.0
var _knockback: Vector2 = Vector2.ZERO
var _dash_vel: Vector2 = Vector2.ZERO
var _buffered_action: String = ""

const DASH_DURATION: float = 0.2
const SPECIAL_DURATION: float = 0.55
const HURT_DURATION: float = 0.18
const FLASH_DURATION: float = 0.1
const KNOCKBACK_FRICTION: float = 800.0
const BIES_GAIN_PER_HIT: float = 0.1
const STANDBY_LEASH: float = 300.0
const REVIVE_HOLD_DURATION: float = 1.5
const REVIVE_HP_FRACTION: float = 0.5
const REVIVE_RING_OFFSET := Vector2(0.0, -32.0)
const REVIVE_RING_RADIUS: float = 12.0
const REVIVE_RING_BG_COLOR: Color = Color(0.4, 1.0, 0.6, 0.25)
const REVIVE_RING_FILL_COLOR: Color = Color(0.4, 1.0, 0.6, 0.95)

# Stealth: how far attacking/dashing rings out — patrolling guards within
# range may hear it and go investigate even if they can't see the player.
const ATTACK_NOISE_RADIUS: float = 110.0
const DASH_NOISE_RADIUS: float = 160.0

# Footstep dust cadence (seconds between feet puffs while walking).
const STEP_DUST_INTERVAL: float = 0.3
var _step_dust_t: float = 0.0
# Stealth: Erin's Fast Talk doubles as a "stand down" tool — guards within
# this radius who are suspicious or alerted are talked back into patrolling.
const FAST_TALK_CALM_RADIUS: float = 130.0
const HIDDEN_MODULATE: Color = Color(1.0, 1.0, 1.0, 0.55)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $HitboxPivot/Hitbox
@onready var hitbox_pivot: Node2D = $HitboxPivot

func _ready() -> void:
	assert(data != null, name + " requires a CharacterData resource")
	hp = data.max_hp
	hitbox.damage = data.attack_damage
	hitbox.collision_layer = PLAYER_HIT_LAYER
	hitbox.collision_mask = PLAYER_HIT_MASK
	hitbox.monitoring = false
	# Duplicate the hitbox shape so we can resize it per-character without
	# modifying the shared sub-resource in Player.tscn.
	var col_shape := hitbox.get_node("CollisionShape2D") as CollisionShape2D
	var rect := col_shape.shape.duplicate() as RectangleShape2D
	rect.size = data.attack_hitbox_size
	col_shape.shape = rect
	hurtbox.hit.connect(_on_hurtbox_hit)
	hitbox.hit_landed.connect(register_hit_landed)
	if sprite.sprite_frames == null and not _try_synty_billboard():
		var loaded: SpriteFrames = SpriteLoader.try_load_player(data.character_name)
		if loaded != null:
			sprite.sprite_frames = loaded
			sprite.scale = Vector2.ONE * SpriteLoader.PLAYER_SPRITE_SCALE
		else:
			sprite.sprite_frames = PlaceholderArt.make_player_frames(data.sprite_color, data.character_name)
	sprite.play("idle")

# In-level combat billboard: reuse the character's overworld Synty billboard
# (assets/art/synty/characters/<name>.png) for every player anim. Static (no walk
# frames), but the code-driven attack arc (_draw), hit-flash, dash motion + i-
# frames, and a walk bob carry combat readability. Centered so it aligns with the
# hurtbox; PIL combat sheet is the fallback.
const PLAYER_BILLBOARD_H: float = 42.0
const PLAYER_BILLBOARD_ANIMS: Array = ["idle", "walk_down", "walk_up", "walk_right",
	"run_down", "run_up", "run_right", "attack", "special", "talk", "talk_closeup",
	"hurt", "down", "revive", "dash", "interact", "doorway"]
const PLAYER_BOB_AMPLITUDE: float = 2.4
const PLAYER_BOB_SPEED: float = 13.0
const PLAYER_SHADOW_OFFSET: Vector2 = Vector2(0.0, 15.0)
const PLAYER_SHADOW_RADIUS: float = 8.0
const PLAYER_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.24)

# Per-animation playback speed (fps) and which animations loop. Keyed by the base
# name (the _down/_up/_right facing suffix is stripped before lookup).
# fps tuned for the (now richer) frame counts — walk/run are 14-frame cycles, so
# they need a higher fps to keep the stride brisk rather than slow-motion.
const ANIM_FPS: Dictionary = {
	"idle": 7.0, "walk": 18.0, "run": 24.0, "attack": 16.0, "special": 9.0,
	"hurt": 13.0, "down": 9.0, "dash": 18.0, "revive": 10.0,
}
const ANIM_LOOPING: Array = ["idle", "walk", "run"]

var _is_billboard: bool = false
var _is_animated_billboard: bool = false
var _bob_phase: float = 0.0

func _try_synty_billboard() -> bool:
	# Prefer a multi-frame directional set (assets/art/synty/characters/anim/<name>/)
	# baked by render_anim_lead.sh; fall back to the single static billboard PNG.
	if _load_animated_frames("res://assets/art/synty/characters/anim/" + data.character_name.to_lower()):
		return true
	var path: String = "res://assets/art/synty/characters/" + data.character_name.to_lower() + ".png"
	if not ResourceLoader.exists(path):
		return false
	var tex: Texture2D = load(path)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for a: String in PLAYER_BILLBOARD_ANIMS:
		sf.add_animation(a)
		sf.set_animation_loop(a, true)
		sf.add_frame(a, tex)
	sprite.sprite_frames = sf
	sprite.scale = Vector2.ONE * (PLAYER_BILLBOARD_H / float(tex.get_height()))
	_is_billboard = true
	return true

# Builds a SpriteFrames from sprite-strip PNGs (one per animation) under dir_path.
# Each strip is a row of square frames (frame side == strip height); the file
# basename is the animation name. Combat/seated strips and the directional walk/run
# set all live together; scale is locked to the "idle" frame so actions don't resize
# the character. Returns false (caller falls back) if the directory has no strips.
func _load_animated_frames(dir_path: String) -> bool:
	var da: DirAccess = DirAccess.open(dir_path)
	if da == null:
		return false
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var scale_h: float = 0.0
	var any: bool = false
	for f: String in da.get_files():
		if not f.ends_with(".png"):
			continue
		var tex: Texture2D = load(dir_path + "/" + f)
		if tex == null:
			continue
		var anim: String = f.get_basename()
		var side: int = tex.get_height()
		var cols: int = maxi(1, tex.get_width() / side)
		sf.add_animation(anim)
		sf.set_animation_loop(anim, _anim_base(anim) in ANIM_LOOPING)
		sf.set_animation_speed(anim, ANIM_FPS.get(_anim_base(anim), 10.0))
		for c: int in cols:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(c * side, 0, side, side)
			sf.add_frame(anim, at)
		if anim == "idle" or scale_h == 0.0:
			scale_h = float(side)
		any = true
	if not any:
		return false
	sprite.sprite_frames = sf
	# Scale by the figure's bbox height (not the padded square side) so the player
	# matches the NPCs' on-screen height. Stays centered (hurtbox alignment).
	var m: Dictionary = SpriteLoader.anim_figure_metrics(data.character_name)
	var fig_h: float = float(m.get("h", 0))
	sprite.scale = Vector2.ONE * (SpriteLoader.HUMAN_FIGURE_H / fig_h if fig_h > 0.0 else PLAYER_BILLBOARD_H / scale_h)
	_is_billboard = true
	_is_animated_billboard = true
	return true

# Strips the directional facing suffix: "walk_down_right" -> "walk", "idle" -> "idle".
func _anim_base(anim: String) -> String:
	for suffix: String in ["_down_right", "_down_left", "_up_right", "_up_left",
			"_down", "_up", "_right", "_left"]:
		if anim.ends_with(suffix):
			return anim.trim_suffix(suffix)
	return anim

func _update_bob(delta: float) -> void:
	# A small vertical bounce sells the walk's weight (the in-place clip has little
	# of its own). Subtler for animated billboards (the legs already stride) than
	# for the static single-frame fallback. Scales with playback speed so a faster
	# stride bounces faster.
	if _state == State.WALK:
		var amp: float = PLAYER_BOB_AMPLITUDE * (0.55 if _is_animated_billboard else 1.0)
		_bob_phase += delta * PLAYER_BOB_SPEED * (sprite.speed_scale if _is_animated_billboard else 1.0)
		sprite.position.y = -absf(sin(_bob_phase)) * amp
	else:
		sprite.position.y = move_toward(sprite.position.y, 0.0, delta * 30.0)

func _physics_process(delta: float) -> void:
	if GameManager.is_paused() or input_locked:
		return
	_tick_timers(delta)
	if _flash_timer <= 0.0:
		sprite.modulate = HIDDEN_MODULATE if is_hidden else Color.WHITE
	if is_active and _state in [State.ATTACK, State.HURT]:
		if Input.is_action_just_pressed(action_prefix + "attack"):
			_buffered_action = "attack"
		elif Input.is_action_just_pressed(action_prefix + "dash"):
			_buffered_action = "dash"
		elif Input.is_action_just_pressed(action_prefix + "special"):
			_buffered_action = "special"
	match _state:
		State.IDLE:   _tick_idle()
		State.WALK:   _tick_walk(delta)
		State.ATTACK: _tick_attack()
		State.DASH:   _tick_dash()
		State.HURT:   _tick_hurt(delta)
		State.DOWN:   _tick_down()
		State.SPECIAL: _tick_special()
	if _is_billboard:
		_update_bob(delta)

func _tick_timers(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_dash_timer   = maxf(_dash_timer   - delta, 0.0)
	_special_timer = maxf(_special_timer - delta, 0.0)
	_hurt_timer   = maxf(_hurt_timer   - delta, 0.0)
	_iframe_timer = maxf(_iframe_timer - delta, 0.0)
	_flash_timer  = maxf(_flash_timer  - delta, 0.0)

func _tick_idle() -> void:
	velocity = Vector2.ZERO
	if not is_active:
		return
	var do_attack := _buffered_action == "attack" or Input.is_action_just_pressed(action_prefix + "attack")
	var do_dash   := _buffered_action == "dash"   or Input.is_action_just_pressed(action_prefix + "dash")
	var do_special := _buffered_action == "special" or Input.is_action_just_pressed(action_prefix + "special")
	_buffered_action = ""
	if do_attack:
		_enter_attack()
	elif do_dash:
		_enter_dash()
	elif do_special:
		_use_special()
	elif _get_move().length_squared() > 0.0:
		_set_state(State.WALK)

func _tick_walk(delta: float) -> void:
	var move := _get_move()
	if not is_active or move.length_squared() == 0.0:
		_set_state(State.IDLE)
		return
	facing = move.normalized()
	_play_directional("walk")  # sets flip_h itself (8-way render, or 3+flip fallback)
	velocity = Vector2(facing.x * data.move_speed, facing.y * data.move_speed * 0.6)
	move_and_slide()
	# Tie the step cadence to actual ground speed so the feet don't slide ("skate").
	if _is_animated_billboard:
		sprite.speed_scale = clampf(velocity.length() / data.move_speed, 0.7, 1.5)
	_step_dust_t -= delta
	if _step_dust_t <= 0.0 and velocity.length() > 8.0:
		_step_dust_t = STEP_DUST_INTERVAL
		CombatFX.dust(global_position + PLAYER_SHADOW_OFFSET, 4)
	if Input.is_action_just_pressed(action_prefix + "attack"):
		_enter_attack()
	elif Input.is_action_just_pressed(action_prefix + "dash"):
		_enter_dash()
	elif Input.is_action_just_pressed(action_prefix + "special"):
		_use_special()

func _tick_attack() -> void:
	velocity = Vector2.ZERO
	if not data.is_ranged:
		var move := _get_move()
		if is_active and move.length_squared() > 0.0:
			facing = move.normalized()
			_play_directional("attack")  # re-aim the strip + flip to the new facing
			hitbox_pivot.position = facing * data.attack_reach
		hitbox.monitoring = _attack_timer > data.attack_cooldown * 0.5
	queue_redraw()
	if _attack_timer == 0.0:
		if not data.is_ranged:
			hitbox.monitoring = false
		_set_state(State.IDLE)
		queue_redraw()

func _tick_dash() -> void:
	velocity = _dash_vel
	move_and_slide()
	if _dash_timer == 0.0:
		_set_state(State.IDLE)

func _tick_hurt(delta: float) -> void:
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_FRICTION * delta)
	velocity = _knockback
	move_and_slide()
	if _hurt_timer == 0.0:
		_set_state(State.IDLE)

func _tick_down() -> void:
	velocity = Vector2.ZERO
	queue_redraw()

func _tick_special() -> void:
	velocity = Vector2.ZERO
	if _special_timer == 0.0:
		_set_state(State.IDLE)

func _enter_attack() -> void:
	_attack_timer = data.attack_cooldown
	Audio.play("attack")
	GameManager.emit_noise(global_position, ATTACK_NOISE_RADIUS)
	if data.is_ranged:
		_fire_projectile()
	else:
		hitbox_pivot.position = facing * data.attack_reach
	_set_state(State.ATTACK)

func _fire_projectile() -> void:
	var p = ProjectileScript.new()
	p.collision_layer = PLAYER_HIT_LAYER
	p.collision_mask = PLAYER_HIT_MASK
	p.damage = data.attack_damage
	p.knockback_force = hitbox.knockback_force
	p.velocity = facing * data.projectile_speed
	p.global_position = global_position + facing * 16.0
	get_tree().current_scene.add_child(p)

func _enter_dash() -> void:
	var dir := _get_move()
	if dir.length_squared() == 0.0:
		dir = facing
	_dash_vel = dir.normalized() * data.move_speed * 2.5
	_dash_timer = DASH_DURATION
	_iframe_timer = data.dash_iframe_duration
	Audio.play("dash")
	GameManager.emit_noise(global_position, DASH_NOISE_RADIUS)
	CombatFX.dust(global_position + PLAYER_SHADOW_OFFSET, 9, Color(0.82, 0.78, 0.68, 0.4), 1.7)
	_set_state(State.DASH)

func _set_state(new_state: State) -> void:
	_state = new_state
	sprite.speed_scale = 1.0  # walk re-derives this from velocity each frame
	# Combat/reaction states use directional strips too when the animated
	# billboard provides them; _play_directional falls back to the bare name
	# (single static billboard / PIL sheet) when a facing variant is absent.
	match _state:
		State.IDLE:   _play_idle()
		State.WALK:   _play_directional("walk")
		State.ATTACK: _play_directional("attack")
		State.DASH:   _play_directional("dash")
		State.HURT:   _play_directional("hurt")
		State.DOWN:   _play_directional("down")
		State.SPECIAL: _play_directional("special")

# Picks the 8-way directional strip (walk_down_right, attack_left, …) for the
# animated Synty billboards — a genuine render per facing, no flipping. Falls back
# to the 3-facing + flip convention for PIL/static sheets, then to bare `base`.
func _play_directional(base: String) -> void:
	var sf: SpriteFrames = sprite.sprite_frames
	var anim: String = base + "_" + SpriteLoader.dir_suffix(facing)
	if sf.has_animation(anim):
		sprite.flip_h = false
	else:
		var fb: Array = SpriteLoader.cardinal_fallback(facing)
		anim = base + "_" + String(fb[0])
		if sf.has_animation(anim):
			sprite.flip_h = bool(fb[1])
		else:
			anim = base
			sprite.flip_h = facing.x < 0.0
	if sprite.animation != anim:
		sprite.play(anim)

# Directional idle: keep facing the last heading when stopped. Reuses the walk
# strip frozen on its neutral (legs-together) mid frame — no separate idle render,
# so feet/scale anchoring stays identical to walk. Static/PIL sheets get bare "idle".
func _play_idle() -> void:
	if _is_animated_billboard:
		var anim: String = "walk_" + SpriteLoader.dir_suffix(facing)
		if sprite.sprite_frames.has_animation(anim):
			sprite.flip_h = false
			sprite.play(anim)
			sprite.set_frame_and_progress(sprite.sprite_frames.get_frame_count(anim) / 2, 0.0)
			sprite.pause()
			return
	sprite.play("idle")

func _use_special() -> void:
	Audio.play("special")
	if data.character_name == "Erin":
		GameManager.calm_enemies(global_position, FAST_TALK_CALM_RADIUS)
	special_used.emit(data.character_name)
	# Punctuate the special with an expanding ring + shake so it reads as a burst.
	CombatFX.ring(global_position, Color(0.6, 0.85, 1.0, 0.9), 40.0)
	CombatFX.shake(0.4)
	# Play the special animation (HA laugh, etc.) so the ability reads on-screen.
	_special_timer = SPECIAL_DURATION
	_set_state(State.SPECIAL)

func _get_move() -> Vector2:
	if not is_active:
		return Vector2.ZERO
	return Input.get_vector(action_prefix + "move_left", action_prefix + "move_right", action_prefix + "move_up", action_prefix + "move_down")

func _on_hurtbox_hit(damage: float, knockback: Vector2) -> void:
	if _iframe_timer > 0.0 or _state == State.DOWN:
		return
	hp = maxf(hp - damage, 0.0)
	hp_changed.emit(hp, data.max_hp)
	Audio.play("hurt")
	sprite.modulate = Color(5.0, 5.0, 5.0, 1.0)
	_flash_timer = FLASH_DURATION
	CombatFX.sparks(global_position, Color(1.0, 0.25, 0.25), 6)
	CombatFX.shake(0.5)
	if hp == 0.0:
		_set_state(State.DOWN)
		died.emit()
		return
	_knockback = knockback
	_hurt_timer = HURT_DURATION
	_set_state(State.HURT)

func register_hit_landed() -> void:
	bies_charge = minf(bies_charge + BIES_GAIN_PER_HIT, 1.0)
	bies_charge_changed.emit(bies_charge)

func leash_to(target_pos: Vector2) -> void:
	if is_active or is_down():
		return
	if global_position.distance_squared_to(target_pos) > STANDBY_LEASH * STANDBY_LEASH:
		global_position = target_pos + Vector2(48.0, 0.0)

func is_down() -> bool:
	return _state == State.DOWN

func revive() -> void:
	if _state != State.DOWN:
		return
	hp = data.max_hp * REVIVE_HP_FRACTION
	hp_changed.emit(hp, data.max_hp)
	revive_progress = 0.0
	_iframe_timer = data.dash_iframe_duration
	Audio.play("special")
	CombatFX.sparks(global_position, REVIVE_RING_FILL_COLOR, 12)
	revived.emit()
	_set_state(State.IDLE)
	queue_redraw()

func _draw() -> void:
	if _is_billboard:
		draw_set_transform(PLAYER_SHADOW_OFFSET, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, PLAYER_SHADOW_RADIUS, PLAYER_SHADOW_COLOR)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _state == State.ATTACK:
		var half := data.attack_cooldown * 0.5
		if _attack_timer > half:
			var t := (_attack_timer - half) / half
			if data.is_ranged:
				_draw_ranged_flash(t)
			else:
				_draw_attack_arc(t, data.attack_reach + 8.0,
						data.attack_arc_spread * 0.5, data.attack_arc_color)
	if _state != State.DOWN:
		return
	draw_arc(Vector2.ZERO, GameManager.REVIVE_RADIUS, 0.0, TAU, 28,
			Color(0.4, 1.0, 0.6, 0.18), 1.5)
	if revive_progress <= 0.0:
		return
	var revive_t: float = revive_progress / REVIVE_HOLD_DURATION
	draw_arc(REVIVE_RING_OFFSET, REVIVE_RING_RADIUS, 0.0, TAU, 28, REVIVE_RING_BG_COLOR, 4.0)
	draw_arc(REVIVE_RING_OFFSET, REVIVE_RING_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * revive_t, 28, REVIVE_RING_FILL_COLOR, 4.0)

func _draw_attack_arc(t: float, radius: float, half_angle: float, color: Color) -> void:
	const ARC_SEGS: int = 10
	var angle := facing.angle()
	var fill := Color(color.r, color.g, color.b, t * 0.42)
	var rim  := Color(color.r * 1.1, color.g * 1.1, color.b * 1.1, t * 0.75)
	var pts  := PackedVector2Array()
	pts.append(Vector2.ZERO)
	for i in range(ARC_SEGS + 1):
		var a := angle - half_angle + (float(i) / ARC_SEGS) * half_angle * 2.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(pts, fill)
	draw_arc(Vector2.ZERO, radius, angle - half_angle, angle + half_angle, ARC_SEGS, rim, 2.0)

func _draw_ranged_flash(t: float) -> void:
	var c := data.attack_arc_color
	var beam_end := facing * (data.attack_reach + 48.0)
	draw_line(Vector2.ZERO, beam_end, Color(c.r, c.g, c.b, t * 0.8), 3.0)
	draw_circle(beam_end, 5.0, Color(c.r, c.g, c.b, t * 0.65))
