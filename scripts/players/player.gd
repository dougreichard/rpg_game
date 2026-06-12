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

enum State { IDLE, WALK, ATTACK, DASH, HURT, DOWN }
var _state: State = State.IDLE

var _attack_timer: float = 0.0
var _dash_timer: float = 0.0
var _hurt_timer: float = 0.0
var _iframe_timer: float = 0.0
var _flash_timer: float = 0.0
var _knockback: Vector2 = Vector2.ZERO
var _dash_vel: Vector2 = Vector2.ZERO
var _buffered_action: String = ""

const DASH_DURATION: float = 0.2
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
	if sprite.sprite_frames == null:
		var loaded: SpriteFrames = SpriteLoader.try_load_player(data.character_name)
		if loaded != null:
			sprite.sprite_frames = loaded
			sprite.scale = Vector2.ONE * SpriteLoader.PLAYER_SPRITE_SCALE
		else:
			sprite.sprite_frames = PlaceholderArt.make_player_frames(data.sprite_color, data.character_name)
	sprite.play("idle")

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

func _tick_timers(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_dash_timer   = maxf(_dash_timer   - delta, 0.0)
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
	sprite.flip_h = facing.x < 0.0
	_play_directional("walk")
	velocity = Vector2(facing.x * data.move_speed, facing.y * data.move_speed * 0.6)
	move_and_slide()
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
			sprite.flip_h = facing.x < 0.0
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
	_set_state(State.DASH)

func _set_state(new_state: State) -> void:
	_state = new_state
	match _state:
		State.IDLE:   sprite.play("idle")
		State.WALK:   _play_directional("walk")
		State.ATTACK: sprite.play("attack")
		State.DASH:   sprite.play("dash")
		State.HURT:   sprite.play("hurt")
		State.DOWN:   sprite.play("down")

# Picks walk_down / walk_up / walk_right (or run_*) based on facing.
# Flipping for left-facing is handled by sprite.flip_h in _tick_walk.
# Falls back to `base` if the directional variant is not in the sheet
# (e.g. PlaceholderArt fallback which only has "walk" / "run").
func _play_directional(base: String) -> void:
	var anim: String
	if abs(facing.y) > abs(facing.x):
		anim = (base + "_down") if facing.y > 0.0 else (base + "_up")
	else:
		anim = base + "_right"
	if not sprite.sprite_frames.has_animation(anim):
		anim = base
	if sprite.animation != anim:
		sprite.play(anim)

func _use_special() -> void:
	Audio.play("special")
	if data.character_name == "Erin":
		GameManager.calm_enemies(global_position, FAST_TALK_CALM_RADIUS)
	special_used.emit(data.character_name)

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
