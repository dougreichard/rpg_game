extends CharacterBody3D
## 3D character body — one lead. Input source depends on `mode`: ACTIVE = player 1,
## STANDBY_P2 = player 2 (co-op), STANDBY_AI = follow the active teammate (hold +
## leash-teleport, like the 2D standby). A Duo3D controller owns two of these and
## handles swapping which is active. Stats from CharacterData.

signal special_used(character_name: String)

enum Mode { ACTIVE, STANDBY_AI, STANDBY_P2 }

const PX_PER_M: float = 32.0
const GRAVITY: float = 24.0
const TURN_LERP: float = 14.0
const MESH_DIR: String = "res://assets/models/characters/"
const FOLLOW_STOP: float = 1.6   # standby keeps roughly this gap
const FOLLOW_RAMP: float = 1.2   # standby eases speed to 0 over this distance into FOLLOW_STOP
const LEASH: float = 9.0         # teleport to the active's side past this (~300px)
const MOVE_START: float = 0.25   # walk/idle hysteresis (intent magnitude) — enter walk
const MOVE_STOP: float = 0.06    # …and drop back to idle (held in between → no flip-flop)
const CompanionScript: Script = preload("res://scripts/3d/animal_companion3d.gd")
const COMPANION_CD: float = 6.0
const COMPANION_RANGE: float = 12.0   # only summons when an enemy is this close

@export var data: CharacterData = null
@export var mesh_path: String = ""

var hp: float = 100.0
var bies_charge: float = 0.0   # 0..1; +0.1 per hit landed, spent on Bies Mode
var is_hidden: bool = false    # set by 3D hiding volumes; suppresses enemy sight
var is_downed: bool = false     # hp hit 0 — revivable by a teammate, not dead
var revive_progress: float = 0.0
var _iframes: float = 0.0
var _companion_cd: float = 0.0
var mode: int = Mode.ACTIVE
var follow_target: Node3D = null
var _speed: float = 5.0
var _mesh: Node3D = null
var _anim: AnimationPlayer = null
var _facing: Vector3 = Vector3.FORWARD
var _moving: bool = false
var _attack_cd: float = 0.0
var _attack_anim_t: float = 0.0
var _special_anim_t: float = 0.0
var _input_locked: bool = false

func _ready() -> void:
	collision_layer = Combat3D.L_PLAYER
	collision_mask = Combat3D.L_WORLD
	add_to_group("player3d")
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	shape.shape = cap
	shape.position = Vector3(0.0, 0.85, 0.0)
	add_child(shape)
	if data != null:
		_speed = data.move_speed / PX_PER_M
		hp = data.max_hp
	var path := mesh_path
	if path == "" and data != null:
		path = MESH_DIR + data.character_name.to_lower() + ".glb"
	var ps: PackedScene = load(path) if path != "" else null
	if ps != null:
		_mesh = ps.instantiate()
		add_child(_mesh)
		_anim = _find_anim(_mesh)
		if _anim != null:
			for a: String in ["idle", "walk", "run"]:
				var an: Animation = _anim.get_animation(a)
				if an != null:
					an.loop_mode = Animation.LOOP_LINEAR
			_anim.play("idle")

func _find_anim(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null

func active_name() -> String:
	return data.character_name if data != null else "Quinn"

func set_input_locked(v: bool) -> void:
	_input_locked = v

func _move_input(prefix: String) -> Vector3:
	var v := Input.get_vector(prefix + "move_left", prefix + "move_right", prefix + "move_up", prefix + "move_down")
	return Vector3(v.x, 0.0, v.y)

func _physics_process(delta: float) -> void:
	_iframes = maxf(_iframes - delta, 0.0)
	# Tick anim timers before any early-return so a special/attack started just
	# before a dialog (which locks input) still resolves instead of replaying after.
	_attack_anim_t = maxf(_attack_anim_t - delta, 0.0)
	_special_anim_t = maxf(_special_anim_t - delta, 0.0)
	if is_downed or _input_locked:
		velocity.x = 0.0; velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = 0.0
		move_and_slide()
		return
	var dir := Vector3.ZERO
	var prefix := ""
	if mode == Mode.ACTIVE:
		dir = _move_input("")
	elif mode == Mode.STANDBY_P2:
		prefix = "p2_"
		dir = _move_input("p2_")
	else:  # STANDBY_AI — follow the active teammate, easing speed to 0 near the gap
		if follow_target != null and is_instance_valid(follow_target):
			var to: Vector3 = follow_target.global_position - global_position
			to.y = 0.0
			var dist: float = to.length()
			if dist > LEASH:
				global_position = follow_target.global_position - to.normalized() * FOLLOW_STOP
			elif dist > FOLLOW_STOP:
				# ramp 0→1 over FOLLOW_RAMP so it decelerates in instead of
				# overshooting and oscillating across the threshold.
				dir = to.normalized() * clampf((dist - FOLLOW_STOP) / FOLLOW_RAMP, 0.0, 1.0)
	velocity.x = dir.x * _speed
	velocity.z = dir.z * _speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	# Walk/idle with hysteresis: only flip state at distinct enter/leave
	# thresholds, so neither the standby nor the active restarts the clip
	# frame-to-frame (that per-frame restart was the A-pose jitter).
	var intent: float = dir.length()
	if _moving and intent < MOVE_STOP:
		_moving = false
	elif not _moving and intent > MOVE_START:
		_moving = true
	if intent > MOVE_STOP:
		_facing = dir.normalized()
		if _mesh != null:
			var want_yaw := atan2(dir.x, dir.z)
			_mesh.rotation.y = lerp_angle(_mesh.rotation.y, want_yaw, clampf(TURN_LERP * delta, 0.0, 1.0))
	if _anim != null:
		if _attack_anim_t > 0.0:
			if _anim.current_animation != "attack":
				_anim.play("attack")
		elif _special_anim_t > 0.0:
			if _anim.current_animation != "special":
				_anim.play("special")
		else:
			var want := "walk" if _moving else "idle"
			if _anim.current_animation != want:
				_anim.play(want)
	# actions (player-controlled modes only)
	if mode == Mode.STANDBY_AI:
		return
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	if _attack_cd == 0.0 and Input.is_action_just_pressed(prefix + "attack"):
		_attack()
	_companion_cd = maxf(_companion_cd - delta, 0.0)
	if Input.is_action_just_pressed(prefix + "special"):
		_special_anim_t = 0.6
		if _anim != null:
			_anim.play("special")
		# Erin's special doubles as a distraction — calms nearby alerted guards.
		if active_name() == "Erin":
			GameManager.calm_enemies(Vector2(global_position.x, global_position.z), 130.0 / PX_PER_M)
		# Evan's special summons Frosty to charge a nearby enemy (combat only).
		if active_name() == "Evan":
			_summon_companion()
		special_used.emit(active_name())

func _summon_companion() -> void:
	if _companion_cd > 0.0:
		return
	var targets := _nearest_enemies(2)
	if targets.is_empty():
		return
	_companion_cd = COMPANION_CD * GameManager.companion_cooldown_scale()
	# One threat → Frosty alone (schnoodle); two threats → the Calvin & Coolidge pair
	# (Great Pyrenees), one charging each enemy.
	var breed := "frosty" if targets.size() == 1 else "great_pyrenees"
	var offs := [Vector3(-0.4, 0, 0), Vector3(0.4, 0, 0)]
	for i in targets.size():
		var comp: Node3D = CompanionScript.new()
		comp.position = global_position + offs[i]
		get_parent().add_child(comp)
		comp.call("setup", self, targets[i], breed)
	GameManager.companion_summoned.emit("frosty" if breed == "frosty" else "calvin_coolidge")
	Audio.play("special")

func _nearest_enemies(n: int) -> Array:
	var es: Array = []
	for e in get_tree().get_nodes_in_group("enemy3d"):
		if is_instance_valid(e) and global_position.distance_to((e as Node3D).global_position) < COMPANION_RANGE:
			es.append(e)
	es.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	return es.slice(0, n)

func _attack() -> void:
	_attack_cd = data.attack_cooldown if data != null else 0.5
	_attack_anim_t = 0.35
	var dmg: float = data.attack_damage if data != null else 20.0
	var pos := global_position + _facing * 1.3 + Vector3(0.0, 0.9, 0.0)
	Audio.play("attack")
	# a swing makes noise — patrolling guards investigate (110px ≈ 3.4 m)
	GameManager.emit_noise(Vector2(global_position.x, global_position.z), 110.0 / PX_PER_M)
	Combat3D.strike(self, pos, 0.8, Combat3D.L_ENEMY, func(b: Node) -> void:
		if b.has_method("take_damage"):
			b.take_damage(dmg, _facing)
			bies_charge = minf(bies_charge + 0.1, 1.0))

func take_damage(amount: float, _from: Vector3) -> void:
	if is_downed or _iframes > 0.0:
		return
	hp = maxf(hp - amount, 0.0)
	Audio.play("hurt")
	Combat3D.spark(self, global_position + Vector3(0, 1.0, 0), Color(1.0, 0.4, 0.35))
	if hp <= 0.0:
		_go_down()

func is_down() -> bool:
	return is_downed

func _go_down() -> void:
	is_downed = true
	revive_progress = 0.0
	Audio.play("defeat")
	if _mesh != null:
		_mesh.rotation.x = deg_to_rad(82)   # crumple to the ground
		_mesh.position.y = 0.2

# Revived by a teammate — back to half HP with brief invulnerability.
func revive() -> void:
	is_downed = false
	revive_progress = 0.0
	hp = (data.max_hp if data != null else 100.0) * 0.5
	_iframes = 1.2
	if _mesh != null:
		_mesh.rotation.x = 0.0
		_mesh.position.y = 0.0
