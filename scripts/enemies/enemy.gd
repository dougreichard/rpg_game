class_name Enemy
extends CharacterBody2D

const ProjectileScript: Script = preload("res://scripts/systems/projectile.gd")

@export var data: EnemyData

var hp: float = 0.0
enum State { CHASE, WINDUP, STRIKE, RECOVER, HIT, AOE_TELEGRAPH, AOE_SLAM }
var _state: State = State.CHASE

var _windup_timer: float = 0.0
var _recover_timer: float = 0.0
var _hit_timer: float = 0.0
var _knockback: Vector2 = Vector2.ZERO

var _slam_cooldown_timer: float = 0.0
var _telegraph_timer: float = 0.0
var _telegraph_radius: float = 0.0
var _slam_active_timer: float = 0.0
var _slam_hitbox: Hitbox

const RECOVER_DURATION: float = 0.4
const HIT_DURATION: float = 0.25
const KNOCKBACK_FRICTION: float = 600.0
const HITSTOP_DURATION: float = 0.05
const SLAM_ACTIVE_DURATION: float = 0.15
const TELEGRAPH_COLOR: Color = Color(1.0, 0.3, 0.2, 0.85)
const TELEGRAPH_RANGE_COLOR: Color = Color(1.0, 0.3, 0.2, 0.3)
const TELEGRAPH_FILL_COLOR: Color = Color(1.0, 0.3, 0.2, 0.18)
const SLAM_FLASH_COLOR: Color = Color(1.0, 0.45, 0.3, 0.4)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $HitboxPivot/Hitbox
@onready var hitbox_pivot: Node2D = $HitboxPivot

func _ready() -> void:
	assert(data != null, name + " requires an EnemyData resource")
	hp = data.max_hp
	hitbox.damage = data.attack_damage
	hitbox.knockback_force = data.knockback_force
	hitbox.monitoring = false
	hurtbox.hit.connect(_on_hurtbox_hit)
	if sprite.sprite_frames == null:
		sprite.sprite_frames = PlaceholderArt.make_enemy_frames(data.sprite_color, data.is_stocky)
	sprite.play("walk")
	if data.is_boss:
		scale = Vector2(1.5, 1.5)
		_slam_cooldown_timer = data.slam_cooldown
		_build_slam_hitbox()

func _build_slam_hitbox() -> void:
	_slam_hitbox = Hitbox.new()
	_slam_hitbox.collision_layer = 32
	_slam_hitbox.collision_mask = 16
	_slam_hitbox.monitoring = false
	_slam_hitbox.damage = data.slam_damage
	_slam_hitbox.knockback_force = data.knockback_force
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = data.slam_radius
	shape.shape = circle
	_slam_hitbox.add_child(shape)
	add_child(_slam_hitbox)

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	match _state:
		State.CHASE:         _tick_chase()
		State.WINDUP:        _tick_windup()
		State.STRIKE:        _tick_strike()
		State.RECOVER:       _tick_recover()
		State.HIT:           _tick_hit(delta)
		State.AOE_TELEGRAPH: _tick_aoe_telegraph(delta)
		State.AOE_SLAM:      _tick_aoe_slam()
	if data.is_boss:
		queue_redraw()

func _tick_timers(delta: float) -> void:
	_windup_timer       = maxf(_windup_timer       - delta, 0.0)
	_recover_timer      = maxf(_recover_timer      - delta, 0.0)
	_hit_timer          = maxf(_hit_timer          - delta, 0.0)
	_slam_cooldown_timer = maxf(_slam_cooldown_timer - delta, 0.0)

func _get_target() -> Player:
	return GameManager.active_player

func _tick_chase() -> void:
	var target := _get_target()
	if target == null or target.hp <= 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var to_target: Vector2 = target.global_position - global_position
	if data.is_boss and _slam_cooldown_timer == 0.0 and to_target.length() <= data.slam_radius * 1.4:
		_enter_aoe_telegraph()
		return
	if to_target.length() <= data.attack_range:
		_enter_windup()
		return
	var dir: Vector2 = to_target.normalized()
	velocity = Vector2(dir.x * data.move_speed, dir.y * data.move_speed * 0.6)
	if sprite.sprite_frames != null:
		sprite.flip_h = dir.x < 0.0
	move_and_slide()

func _enter_windup() -> void:
	velocity = Vector2.ZERO
	_windup_timer = data.windup_duration
	_set_state(State.WINDUP)

func _tick_windup() -> void:
	if _windup_timer == 0.0:
		_enter_strike()

func _enter_strike() -> void:
	var target := _get_target()
	if data.is_ranged:
		_fire_projectile(target)
	else:
		if target != null:
			hitbox_pivot.position = (target.global_position - global_position).normalized() * 24.0
		hitbox.monitoring = true
	_set_state(State.STRIKE)

func _fire_projectile(target: Player) -> void:
	if target == null:
		return
	var p = ProjectileScript.new()
	p.collision_layer = 32
	p.collision_mask = 16
	p.damage = data.attack_damage
	p.knockback_force = data.knockback_force
	p.velocity = (target.global_position - global_position).normalized() * data.projectile_speed
	p.global_position = global_position
	get_tree().current_scene.add_child(p)

func _tick_strike() -> void:
	hitbox.monitoring = false
	_recover_timer = RECOVER_DURATION
	_set_state(State.RECOVER)

func _tick_recover() -> void:
	velocity = Vector2.ZERO
	if _recover_timer == 0.0:
		_set_state(State.CHASE)

func _enter_aoe_telegraph() -> void:
	velocity = Vector2.ZERO
	_telegraph_timer = data.slam_telegraph_duration
	_telegraph_radius = 0.0
	_set_state(State.AOE_TELEGRAPH)

func _tick_aoe_telegraph(delta: float) -> void:
	velocity = Vector2.ZERO
	_telegraph_timer = maxf(_telegraph_timer - delta, 0.0)
	var t: float = 1.0 - (_telegraph_timer / data.slam_telegraph_duration)
	_telegraph_radius = data.slam_radius * clampf(t, 0.0, 1.0)
	if _telegraph_timer == 0.0:
		_enter_aoe_slam()

func _enter_aoe_slam() -> void:
	_slam_active_timer = SLAM_ACTIVE_DURATION
	_slam_hitbox.monitoring = true
	CombatFX.shake(0.6)
	_set_state(State.AOE_SLAM)

func _tick_aoe_slam() -> void:
	velocity = Vector2.ZERO
	_slam_active_timer = maxf(_slam_active_timer - get_physics_process_delta_time(), 0.0)
	if _slam_active_timer == 0.0:
		_slam_hitbox.monitoring = false
		_slam_cooldown_timer = data.slam_cooldown
		_recover_timer = RECOVER_DURATION
		_set_state(State.RECOVER)

func _tick_hit(delta: float) -> void:
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_FRICTION * delta)
	velocity = _knockback
	move_and_slide()
	if _hit_timer == 0.0:
		_set_state(State.CHASE)

func _set_state(new_state: State) -> void:
	_state = new_state
	match _state:
		State.CHASE:         sprite.play("walk")
		State.WINDUP:        sprite.play("windup")
		State.STRIKE:        sprite.play("attack")
		State.RECOVER:       sprite.play("walk")
		State.HIT:           sprite.play("hurt")
		State.AOE_TELEGRAPH: sprite.play("windup")
		State.AOE_SLAM:      sprite.play("attack")

func _draw() -> void:
	if not data.is_boss:
		return
	if _state == State.AOE_TELEGRAPH:
		draw_circle(Vector2.ZERO, _telegraph_radius, TELEGRAPH_FILL_COLOR)
		draw_arc(Vector2.ZERO, _telegraph_radius, 0.0, TAU, 48, TELEGRAPH_COLOR, 3.0)
		draw_arc(Vector2.ZERO, data.slam_radius, 0.0, TAU, 48, TELEGRAPH_RANGE_COLOR, 1.5)
	elif _state == State.AOE_SLAM:
		draw_circle(Vector2.ZERO, data.slam_radius, SLAM_FLASH_COLOR)

func _on_hurtbox_hit(damage: float, knockback: Vector2) -> void:
	if _state == State.HIT:
		_hit_timer = HIT_DURATION
		return
	hp = maxf(hp - damage, 0.0)
	CombatFX.sparks(global_position, Color(1.0, 0.95, 0.4), 10)
	CombatFX.shake(0.3)
	if hp == 0.0:
		Audio.play("defeat")
		queue_free()
		return
	Audio.play("hit")
	_flash_white()
	_apply_hitstop()
	_knockback = knockback
	_hit_timer = HIT_DURATION
	_set_state(State.HIT)

func _flash_white() -> void:
	sprite.modulate = Color(5.0, 5.0, 5.0, 1.0)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _apply_hitstop() -> void:
	set_physics_process(false)
	await get_tree().create_timer(HITSTOP_DURATION, true, false, true).timeout
	if is_instance_valid(self):
		set_physics_process(true)
