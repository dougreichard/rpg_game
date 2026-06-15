extends CharacterBody3D
## 3D enemy — a trimmed port of enemy.gd's combat FSM (chase → windup → strike →
## recover, plus hit/death) onto CharacterBody3D + Area3D damage volumes. Stealth/
## patrol comes later; this validates 3D combat for the church slice. Uses the same
## EnemyData resource and an animated Synty glTF (idle/walk/run).

const PX_PER_M: float = 32.0
const GRAVITY: float = 24.0
const TURN_LERP: float = 12.0
const RECOVER_TIME: float = 0.5
const HIT_TIME: float = 0.25
const KNOCKBACK_FRICTION: float = 10.0

enum State { CHASE, WINDUP, STRIKE, RECOVER, HIT, DEAD }

@export var data: EnemyData = null
@export var mesh_path: String = "res://assets/models/enemies/grunt.glb"

var hp: float = 60.0
var _speed: float = 2.5
var _state: State = State.CHASE
var _t: float = 0.0
var _mesh_root: Node3D = null
var _anim: AnimationPlayer = null
var _target: Node3D = null
var _knockback: Vector3 = Vector3.ZERO

func _ready() -> void:
	if data != null:
		hp = data.max_hp
		_speed = data.move_speed / PX_PER_M
	collision_layer = Combat3D.L_ENEMY
	collision_mask = Combat3D.L_WORLD
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	shape.shape = cap
	shape.position = Vector3(0.0, 0.85, 0.0)
	add_child(shape)
	var ps: PackedScene = load(mesh_path)
	if ps != null:
		_mesh_root = ps.instantiate()
		add_child(_mesh_root)
		_anim = _find_anim(_mesh_root)
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

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player3d")
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	_t = maxf(_t - delta, 0.0)
	match _state:
		State.CHASE:    _tick_chase(delta)
		State.WINDUP:   _tick_windup()
		State.STRIKE:   _tick_strike()
		State.RECOVER:  _tick_idle_wait(State.CHASE)
		State.HIT:      _tick_hit(delta)
	move_and_slide()

func _tick_chase(delta: float) -> void:
	if _target == null:
		velocity.x = 0.0; velocity.z = 0.0
		return
	var to: Vector3 = _target.global_position - global_position
	to.y = 0.0
	var rng: float = (data.attack_range / PX_PER_M) if data != null else 1.4
	if to.length() <= rng:
		velocity.x = 0.0; velocity.z = 0.0
		_enter_windup()
		return
	var dir := to.normalized()
	velocity.x = dir.x * _speed
	velocity.z = dir.z * _speed
	_face(dir, delta)
	_play("walk")

func _enter_windup() -> void:
	_t = data.windup_duration if data != null else 0.6
	_state = State.WINDUP
	_play("idle")
	_set_tint(Color(1.0, 0.45, 0.45))  # telegraph (no 3D windup clip yet)

func _tick_windup() -> void:
	velocity.x = 0.0; velocity.z = 0.0
	if _t == 0.0:
		_state = State.STRIKE

func _tick_strike() -> void:
	_clear_tint()
	var dmg: float = data.attack_damage if data != null else 12.0
	var aim := Vector3.FORWARD
	if _target != null:
		aim = (_target.global_position - global_position).normalized()
	Combat3D.strike(self, global_position + aim * 1.1 + Vector3(0, 0.9, 0), 0.8,
		Combat3D.L_PLAYER, func(b: Node) -> void:
			if b.has_method("take_damage"):
				b.take_damage(dmg, aim))
	_t = RECOVER_TIME
	_state = State.RECOVER

func _tick_idle_wait(next: State) -> void:
	velocity.x = 0.0; velocity.z = 0.0
	_play("idle")
	if _t == 0.0:
		_state = next

func _tick_hit(delta: float) -> void:
	_knockback = _knockback.move_toward(Vector3.ZERO, KNOCKBACK_FRICTION * delta)
	velocity.x = _knockback.x
	velocity.z = _knockback.z
	if _t == 0.0:
		_state = State.CHASE

func take_damage(amount: float, from_dir: Vector3) -> void:
	if _state == State.DEAD:
		return
	hp = maxf(hp - amount, 0.0)
	CombatFX.shake(0.3)
	_set_tint(Color(3, 3, 3))
	get_tree().create_timer(0.09, false).timeout.connect(_clear_tint)
	if hp == 0.0:
		_die()
		return
	Audio.play("hit")
	var kbf: float = (data.knockback_force / PX_PER_M) if data != null else 4.0
	_knockback = from_dir.normalized() * kbf
	_t = HIT_TIME
	_state = State.HIT

func _die() -> void:
	_state = State.DEAD
	Audio.play("defeat")
	if data != null:
		GameManager.enemy_defeated.emit(data.enemy_name, data.is_boss)
	var tw := create_tween()
	tw.tween_interval(0.1)
	tw.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.25)
	tw.tween_callback(queue_free)

func _face(dir: Vector3, delta: float) -> void:
	if _mesh_root != null and dir.length() > 0.05:
		var want := atan2(dir.x, dir.z)
		_mesh_root.rotation.y = lerp_angle(_mesh_root.rotation.y, want, clampf(TURN_LERP * delta, 0.0, 1.0))

func _play(anim: String) -> void:
	if _anim != null and _anim.current_animation != anim:
		_anim.play(anim)

func _set_tint(c: Color) -> void:
	if _mesh_root == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for mi in _mesh_root.find_children("*", "MeshInstance3D"):
		(mi as MeshInstance3D).material_override = mat

func _clear_tint() -> void:
	if _mesh_root == null:
		return
	for mi in _mesh_root.find_children("*", "MeshInstance3D"):
		(mi as MeshInstance3D).material_override = null
