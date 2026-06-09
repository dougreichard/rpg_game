class_name Enemy
extends CharacterBody2D

const ProjectileScript: Script = preload("res://scripts/systems/projectile.gd")

@export var data: EnemyData

var hp: float = 0.0
enum State { PATROL, INVESTIGATE, CHASE, WINDUP, STRIKE, RECOVER, HIT, AOE_TELEGRAPH, AOE_SLAM }
var _state: State = State.PATROL

var _windup_timer: float = 0.0
var _recover_timer: float = 0.0
var _hit_timer: float = 0.0
var _knockback: Vector2 = Vector2.ZERO

var _slam_cooldown_timer: float = 0.0
var _telegraph_timer: float = 0.0
var _telegraph_radius: float = 0.0
var _slam_active_timer: float = 0.0
var _slam_hitbox: Hitbox

# Stealth — awareness FSM (PATROL → INVESTIGATE → CHASE). Guards start unaware
# and wander their spawn point; they escalate only once they actually detect
# the player (sight cone, raycast line-of-sight, or a nearby noise), and can
# be talked back down (Erin's Fast Talk) or lose the trail and stand down.
var _home_position: Vector2 = Vector2.ZERO
var _patrol_target: Vector2 = Vector2.ZERO
var _patrol_pause_timer: float = 0.0
var _facing_dir: Vector2 = Vector2.DOWN
var _alert_meter: float = 0.0
var _investigate_target: Vector2 = Vector2.ZERO
var _investigate_look_timer: float = 0.0

const RECOVER_DURATION: float = 0.4
const HIT_DURATION: float = 0.25
const KNOCKBACK_FRICTION: float = 600.0
const HITSTOP_DURATION: float = 0.05
const SLAM_ACTIVE_DURATION: float = 0.15
const TELEGRAPH_COLOR: Color = Color(1.0, 0.3, 0.2, 0.85)
const TELEGRAPH_RANGE_COLOR: Color = Color(1.0, 0.3, 0.2, 0.3)
const TELEGRAPH_FILL_COLOR: Color = Color(1.0, 0.3, 0.2, 0.18)
const SLAM_FLASH_COLOR: Color = Color(1.0, 0.45, 0.3, 0.4)

const WALL_COLLISION_MASK: int = 1
const SUSPICION_THRESHOLD: float = 0.35
const ALERT_THRESHOLD: float = 1.0
const SIGHT_GAIN_RATE: float = 0.6
const NOISE_ALERT_FLOOR: float = 0.4
const ALERT_DECAY_RATE: float = 0.25
const PATROL_SPEED_SCALE: float = 0.5
const PATROL_PAUSE_DURATION: float = 1.2
const PATROL_ARRIVE_DISTANCE: float = 12.0
const INVESTIGATE_LOOK_DURATION: float = 2.5
const VISION_CONE_SEGMENTS: int = 14
const VISION_CONE_COLOR_LOW: Color = Color(0.95, 0.95, 0.6, 0.10)
const VISION_CONE_COLOR_HIGH: Color = Color(1.0, 0.3, 0.2, 0.16)
const ALERT_RING_OFFSET := Vector2(0.0, -26.0)
const ALERT_RING_RADIUS: float = 13.0
const ALERT_RING_BG_COLOR: Color = Color(0.1, 0.1, 0.1, 0.35)
const ALERT_RING_LOW_COLOR: Color = Color(0.85, 0.85, 0.4, 0.9)
const ALERT_RING_HIGH_COLOR: Color = Color(1.0, 0.3, 0.2, 0.95)

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
		var loaded: SpriteFrames = SpriteLoader.try_load_enemy(data.enemy_name)
		sprite.sprite_frames = loaded if loaded != null \
			else PlaceholderArt.make_enemy_frames(data.sprite_color, data.enemy_name, data.is_stocky)
	sprite.play("walk")
	GameManager.noise_emitted.connect(_on_noise_emitted)
	GameManager.enemies_calmed.connect(_on_enemies_calmed)
	_home_position = global_position
	_patrol_target = _pick_patrol_point()
	if data.is_boss:
		scale = Vector2(1.5, 1.5)
		_slam_cooldown_timer = data.slam_cooldown
		_build_slam_hitbox()
		_set_state(State.CHASE)
	else:
		_set_state(State.PATROL)

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
		State.PATROL:        _tick_patrol(delta)
		State.INVESTIGATE:   _tick_investigate(delta)
		State.CHASE:         _tick_chase()
		State.WINDUP:        _tick_windup()
		State.STRIKE:        _tick_strike()
		State.RECOVER:       _tick_recover()
		State.HIT:           _tick_hit(delta)
		State.AOE_TELEGRAPH: _tick_aoe_telegraph(delta)
		State.AOE_SLAM:      _tick_aoe_slam()
	queue_redraw()

func _tick_timers(delta: float) -> void:
	_windup_timer       = maxf(_windup_timer       - delta, 0.0)
	_recover_timer      = maxf(_recover_timer      - delta, 0.0)
	_hit_timer          = maxf(_hit_timer          - delta, 0.0)
	_slam_cooldown_timer = maxf(_slam_cooldown_timer - delta, 0.0)

func _get_target() -> Player:
	return GameManager.active_player

# --- Stealth: PATROL / INVESTIGATE -----------------------------------------

func _pick_patrol_point() -> Vector2:
	var angle: float = randf() * TAU
	var dist: float = randf() * data.patrol_radius
	return _home_position + Vector2(cos(angle), sin(angle)) * dist

func _walk_toward(point: Vector2) -> bool:
	var to_point: Vector2 = point - global_position
	if to_point.length() <= PATROL_ARRIVE_DISTANCE:
		velocity = Vector2.ZERO
		move_and_slide()
		return true
	var dir: Vector2 = to_point.normalized()
	_facing_dir = dir
	velocity = Vector2(dir.x, dir.y * 0.6) * data.move_speed * PATROL_SPEED_SCALE
	if sprite.sprite_frames != null:
		sprite.flip_h = dir.x < 0.0
	move_and_slide()
	return false

func _update_alert(delta: float) -> bool:
	var target := _get_target()
	if target == null or target.hp <= 0.0:
		_alert_meter = maxf(_alert_meter - ALERT_DECAY_RATE * delta, 0.0)
		return false
	if _can_see(target):
		_investigate_target = target.global_position
		_alert_meter = minf(_alert_meter + SIGHT_GAIN_RATE * delta, ALERT_THRESHOLD)
		return true
	_alert_meter = maxf(_alert_meter - ALERT_DECAY_RATE * delta, 0.0)
	return false

func _can_see(target: Player) -> bool:
	if target.is_hidden:
		return false
	var to_target: Vector2 = target.global_position - global_position
	var dist: float = to_target.length()
	if dist > data.vision_range or dist <= 0.0:
		return false
	var half_angle: float = deg_to_rad(data.vision_angle_deg) * 0.5
	if absf(_facing_dir.angle_to(to_target / dist)) > half_angle:
		return false
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, WALL_COLLISION_MASK)
	return space_state.intersect_ray(query).is_empty()

func _tick_patrol(delta: float) -> void:
	_update_alert(delta)
	if _alert_meter >= ALERT_THRESHOLD:
		_enter_chase()
		return
	if _alert_meter >= SUSPICION_THRESHOLD:
		_enter_investigate()
		return
	if _patrol_pause_timer > 0.0:
		_patrol_pause_timer = maxf(_patrol_pause_timer - delta, 0.0)
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _walk_toward(_patrol_target):
		_patrol_pause_timer = PATROL_PAUSE_DURATION
		_patrol_target = _pick_patrol_point()

func _tick_investigate(delta: float) -> void:
	var seen: bool = _update_alert(delta)
	if _alert_meter >= ALERT_THRESHOLD:
		_enter_chase()
		return
	if _alert_meter < SUSPICION_THRESHOLD:
		_enter_patrol()
		return
	if seen:
		_investigate_look_timer = INVESTIGATE_LOOK_DURATION
	if _walk_toward(_investigate_target):
		_investigate_look_timer = maxf(_investigate_look_timer - delta, 0.0)
		if _investigate_look_timer <= 0.0:
			_enter_patrol()

func _enter_patrol() -> void:
	_alert_meter = 0.0
	_patrol_pause_timer = 0.0
	_patrol_target = _pick_patrol_point()
	_set_state(State.PATROL)

func _enter_investigate() -> void:
	_investigate_look_timer = INVESTIGATE_LOOK_DURATION
	_set_state(State.INVESTIGATE)

func _enter_chase() -> void:
	_alert_meter = ALERT_THRESHOLD
	_set_state(State.CHASE)

func _on_noise_emitted(position: Vector2, radius: float) -> void:
	if _state != State.PATROL and _state != State.INVESTIGATE:
		return
	if global_position.distance_to(position) > maxf(radius, data.hearing_range):
		return
	_investigate_target = position
	_alert_meter = maxf(_alert_meter, NOISE_ALERT_FLOOR)

func _on_enemies_calmed(position: Vector2, radius: float) -> void:
	if _state != State.INVESTIGATE and _state != State.CHASE and _state != State.RECOVER:
		return
	if global_position.distance_to(position) > radius:
		return
	_enter_patrol()

# --- Combat -----------------------------------------------------------------

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
		State.PATROL:        sprite.play("walk")
		State.INVESTIGATE:   sprite.play("walk")
		State.CHASE:         sprite.play("chase")
		State.WINDUP:        sprite.play("windup")
		State.STRIKE:        sprite.play("attack")
		State.RECOVER:       sprite.play("recover")
		State.HIT:           sprite.play("hurt")
		State.AOE_TELEGRAPH: sprite.play("windup")
		State.AOE_SLAM:      sprite.play("attack")

func _draw() -> void:
	_draw_awareness()
	if not data.is_boss:
		return
	if _state == State.AOE_TELEGRAPH:
		draw_circle(Vector2.ZERO, _telegraph_radius, TELEGRAPH_FILL_COLOR)
		draw_arc(Vector2.ZERO, _telegraph_radius, 0.0, TAU, 48, TELEGRAPH_COLOR, 3.0)
		draw_arc(Vector2.ZERO, data.slam_radius, 0.0, TAU, 48, TELEGRAPH_RANGE_COLOR, 1.5)
	elif _state == State.AOE_SLAM:
		draw_circle(Vector2.ZERO, data.slam_radius, SLAM_FLASH_COLOR)

# Stealth telegraph — mirrors the boss AoE warning ring: shows the player
# exactly what a guard can currently see (vision cone) and how close it is
# to noticing them (alert ring), so sneaking is readable, not guesswork.
func _draw_awareness() -> void:
	if _state != State.PATROL and _state != State.INVESTIGATE:
		return
	var t: float = clampf(_alert_meter / ALERT_THRESHOLD, 0.0, 1.0)
	_draw_vision_cone(VISION_CONE_COLOR_LOW.lerp(VISION_CONE_COLOR_HIGH, t))
	draw_arc(ALERT_RING_OFFSET, ALERT_RING_RADIUS, 0.0, TAU, 24, ALERT_RING_BG_COLOR, 3.0)
	if t > 0.02:
		var ring_color: Color = ALERT_RING_LOW_COLOR.lerp(ALERT_RING_HIGH_COLOR, t)
		draw_arc(ALERT_RING_OFFSET, ALERT_RING_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * t, 24, ring_color, 3.0)

func _draw_vision_cone(color: Color) -> void:
	var half_angle: float = deg_to_rad(data.vision_angle_deg) * 0.5
	var base_angle: float = _facing_dir.angle()
	var points := PackedVector2Array([Vector2.ZERO])
	for i in range(VISION_CONE_SEGMENTS + 1):
		var a: float = base_angle - half_angle + (2.0 * half_angle) * (float(i) / float(VISION_CONE_SEGMENTS))
		points.append(Vector2(cos(a), sin(a)) * data.vision_range)
	draw_colored_polygon(points, color)

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
