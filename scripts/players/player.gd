class_name Player
extends CharacterBody2D

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

enum State { IDLE, WALK, ATTACK, DASH, HURT, DOWN }
var _state: State = State.IDLE

var _attack_timer: float = 0.0
var _dash_timer: float = 0.0
var _hurt_timer: float = 0.0
var _iframe_timer: float = 0.0
var _knockback: Vector2 = Vector2.ZERO
var _dash_vel: Vector2 = Vector2.ZERO

const DASH_DURATION: float = 0.2
const HURT_DURATION: float = 0.3
const KNOCKBACK_FRICTION: float = 800.0
const BIES_GAIN_PER_HIT: float = 0.1
const STANDBY_LEASH: float = 300.0
const REVIVE_HOLD_DURATION: float = 1.5
const REVIVE_HP_FRACTION: float = 0.5
const REVIVE_RING_OFFSET := Vector2(0.0, -32.0)
const REVIVE_RING_RADIUS: float = 12.0
const REVIVE_RING_BG_COLOR: Color = Color(0.4, 1.0, 0.6, 0.25)
const REVIVE_RING_FILL_COLOR: Color = Color(0.4, 1.0, 0.6, 0.95)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $HitboxPivot/Hitbox
@onready var hitbox_pivot: Node2D = $HitboxPivot

func _ready() -> void:
	assert(data != null, name + " requires a CharacterData resource")
	hp = data.max_hp
	hitbox.damage = data.attack_damage
	hitbox.monitoring = false
	hurtbox.hit.connect(_on_hurtbox_hit)
	hitbox.hit_landed.connect(register_hit_landed)
	if sprite.sprite_frames == null:
		sprite.sprite_frames = PlaceholderArt.make_player_frames(data.sprite_color)
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
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

func _tick_idle() -> void:
	velocity = Vector2.ZERO
	if not is_active:
		return
	if Input.is_action_just_pressed("attack"):
		_enter_attack()
	elif Input.is_action_just_pressed("dash"):
		_enter_dash()
	elif Input.is_action_just_pressed("special"):
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
	velocity = Vector2(facing.x * data.move_speed, facing.y * data.move_speed * 0.6)
	move_and_slide()
	if Input.is_action_just_pressed("attack"):
		_enter_attack()
	elif Input.is_action_just_pressed("dash"):
		_enter_dash()
	elif Input.is_action_just_pressed("special"):
		_use_special()

func _tick_attack() -> void:
	velocity = Vector2.ZERO
	hitbox.monitoring = _attack_timer > data.attack_cooldown * 0.5
	if _attack_timer == 0.0:
		hitbox.monitoring = false
		_set_state(State.IDLE)

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
	hitbox_pivot.position = facing * 24.0
	_attack_timer = data.attack_cooldown
	Audio.play("attack")
	_set_state(State.ATTACK)

func _enter_dash() -> void:
	var dir := _get_move()
	if dir.length_squared() == 0.0:
		dir = facing
	_dash_vel = dir.normalized() * data.move_speed * 2.5
	_dash_timer = DASH_DURATION
	_iframe_timer = data.dash_iframe_duration
	Audio.play("dash")
	_set_state(State.DASH)

func _set_state(new_state: State) -> void:
	_state = new_state
	match _state:
		State.IDLE:   sprite.play("idle")
		State.WALK:   sprite.play("walk")
		State.ATTACK: sprite.play("attack")
		State.DASH:   sprite.play("dash")
		State.HURT:   sprite.play("hurt")
		State.DOWN:   sprite.play("down")

func _use_special() -> void:
	Audio.play("special")
	special_used.emit(data.character_name)

func _get_move() -> Vector2:
	if not is_active:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func _on_hurtbox_hit(damage: float, knockback: Vector2) -> void:
	if _iframe_timer > 0.0 or _state == State.DOWN:
		return
	hp = maxf(hp - damage, 0.0)
	hp_changed.emit(hp, data.max_hp)
	Audio.play("hurt")
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
	if is_active:
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
	if _state != State.DOWN or revive_progress <= 0.0:
		return
	var t: float = revive_progress / REVIVE_HOLD_DURATION
	draw_arc(REVIVE_RING_OFFSET, REVIVE_RING_RADIUS, 0.0, TAU, 28, REVIVE_RING_BG_COLOR, 4.0)
	draw_arc(REVIVE_RING_OFFSET, REVIVE_RING_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * t, 28, REVIVE_RING_FILL_COLOR, 4.0)
