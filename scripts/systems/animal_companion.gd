extends Node2D

const HitboxScript: Script = preload("res://scripts/systems/hitbox.gd")

const CHARGE_SPEED: float = 320.0
const RETURN_SPEED: float = 260.0
const ARRIVE_DISTANCE: float = 26.0
const STRIKE_RADIUS: float = 16.0
const STUN_DAMAGE: float = 1.0
const STUN_KNOCKBACK: float = 110.0
const LIFETIME: float = 4.0
const BODY_RADIUS: float = 11.0

enum Phase { CHARGE, RETURN }

var _summoner: Player = null
var _target: Enemy = null
var _phase: Phase = Phase.CHARGE
var _life_timer: float = LIFETIME
var _color: Color = Color.WHITE
var _hitbox = null

func setup(summoner: Player, target: Enemy, color: Color) -> void:
	_summoner = summoner
	_target = target
	_color = color
	global_position = summoner.global_position + Vector2(0.0, -11.0)
	_build_hitbox()

func _build_hitbox() -> void:
	_hitbox = HitboxScript.new()
	_hitbox.collision_layer = 8
	_hitbox.collision_mask = 64
	_hitbox.monitoring = true
	_hitbox.damage = STUN_DAMAGE
	_hitbox.knockback_force = STUN_KNOCKBACK
	_hitbox.hit_landed.connect(_on_hit_landed)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = STRIKE_RADIUS
	shape.shape = circle
	_hitbox.add_child(shape)
	add_child(_hitbox)

func _on_hit_landed() -> void:
	if _phase != Phase.CHARGE:
		return
	_hitbox.set_deferred("monitoring", false)
	Audio.play("hit")
	_phase = Phase.RETURN

func _process(delta: float) -> void:
	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()
		return
	match _phase:
		Phase.CHARGE: _tick_charge(delta)
		Phase.RETURN: _tick_return(delta)
	queue_redraw()

func _tick_charge(delta: float) -> void:
	if not is_instance_valid(_target) or _target.hp <= 0.0:
		_hitbox.monitoring = false
		_phase = Phase.RETURN
		return
	var to_target: Vector2 = _target.global_position - global_position
	if to_target.length() <= ARRIVE_DISTANCE:
		_hitbox.monitoring = false
		_phase = Phase.RETURN
		return
	global_position += to_target.normalized() * CHARGE_SPEED * delta

func _tick_return(delta: float) -> void:
	if not is_instance_valid(_summoner):
		queue_free()
		return
	var to_summoner: Vector2 = _summoner.global_position - global_position
	if to_summoner.length() <= ARRIVE_DISTANCE:
		queue_free()
		return
	global_position += to_summoner.normalized() * RETURN_SPEED * delta

func _draw() -> void:
	draw_circle(Vector2.ZERO, BODY_RADIUS, _color)
	draw_circle(Vector2(BODY_RADIUS * 0.4, -BODY_RADIUS * 0.4), BODY_RADIUS * 0.3, Color.WHITE)
