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

enum State { CHASE, WINDUP, STRIKE, RECOVER, HIT, DEAD, AOE_TELEGRAPH, AOE_SLAM }

const ProjectileScript: Script = preload("res://scripts/3d/projectile3d.gd")

@export var data: EnemyData = null
@export var mesh_path: String = "res://assets/models/enemies/grunt.glb"
@export var mesh_scale: float = 1.0
@export var mesh_tint: Color = Color(1, 1, 1, 1)   # multiplies the base mesh albedo

var hp: float = 60.0
var _speed: float = 2.5
var _state: State = State.CHASE
var _t: float = 0.0
var _mesh_root: Node3D = null
var _anim: AnimationPlayer = null
var _target: Node3D = null
var _knockback: Vector3 = Vector3.ZERO
var _slam_cd: float = 0.0
var _ring: MeshInstance3D = null

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
		_mesh_root.scale = Vector3.ONE * mesh_scale
		add_child(_mesh_root)
		if mesh_tint != Color(1, 1, 1, 1):
			for mi in _mesh_root.find_children("*", "MeshInstance3D"):
				var src := (mi as MeshInstance3D).get_active_material(0)
				var nm: StandardMaterial3D = src.duplicate() if src is StandardMaterial3D else StandardMaterial3D.new()
				nm.albedo_color = nm.albedo_color * mesh_tint
				(mi as MeshInstance3D).material_override = nm
		_anim = _find_anim(_mesh_root)
		if _anim != null:
			for a: String in ["idle", "walk", "chase"]:
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
	_slam_cd = maxf(_slam_cd - delta, 0.0)
	match _state:
		State.CHASE:          _tick_chase(delta)
		State.WINDUP:         _tick_windup()
		State.STRIKE:         _tick_strike()
		State.RECOVER:        _tick_recover()
		State.HIT:            _tick_hit(delta)
		State.AOE_TELEGRAPH:  _tick_aoe_telegraph(delta)
		State.AOE_SLAM:       _tick_aoe_slam()
	move_and_slide()

func _tick_chase(delta: float) -> void:
	if _target == null:
		velocity.x = 0.0; velocity.z = 0.0
		return
	var to: Vector3 = _target.global_position - global_position
	to.y = 0.0
	# Boss ground-slam: when off cooldown and the player is within slam reach, telegraph it.
	if data != null and data.is_boss and _slam_cd == 0.0 and to.length() <= (data.slam_radius / PX_PER_M):
		_enter_aoe_telegraph()
		return
	var rng: float = (data.attack_range / PX_PER_M) if data != null else 1.4
	if to.length() <= rng:
		velocity.x = 0.0; velocity.z = 0.0
		_enter_windup()
		return
	var dir := to.normalized()
	velocity.x = dir.x * _speed
	velocity.z = dir.z * _speed
	_face(dir, delta)
	_play("chase")

func _enter_windup() -> void:
	_t = data.windup_duration if data != null else 0.6
	_state = State.WINDUP
	_play("windup")
	_set_tint(Color(1.0, 0.45, 0.45))  # telegraph: clip + red flash

func _tick_windup() -> void:
	velocity.x = 0.0; velocity.z = 0.0
	if _t == 0.0:
		_state = State.STRIKE

func _tick_strike() -> void:
	_clear_tint()
	_play("attack")
	var dmg: float = data.attack_damage if data != null else 12.0
	var aim := Vector3.FORWARD
	if _target != null:
		aim = (_target.global_position - global_position).normalized()
	if data != null and data.is_ranged:
		# Sentry: fire a projectile down the aim line instead of a melee swing.
		var proj: Area3D = ProjectileScript.new()
		proj.call("setup", aim, (data.projectile_speed / PX_PER_M), dmg)
		proj.position = global_position + aim * 0.8 + Vector3(0, 0.9, 0)
		get_parent().add_child(proj)
		Audio.play("attack")
	else:
		Combat3D.strike(self, global_position + aim * 1.1 + Vector3(0, 0.9, 0), 0.8,
			Combat3D.L_PLAYER, func(b: Node) -> void:
				if b.has_method("take_damage"):
					b.take_damage(dmg, aim))
	_t = RECOVER_TIME
	_state = State.RECOVER

# --- Boss ground-slam: expanding warning ring, then one damage window ---------
func _enter_aoe_telegraph() -> void:
	velocity.x = 0.0; velocity.z = 0.0
	_t = data.slam_telegraph_duration
	_state = State.AOE_TELEGRAPH
	_play("windup")
	_set_tint(Color(1.0, 0.4, 0.3))
	var radius: float = data.slam_radius / PX_PER_M
	_ring = MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = radius; cm.bottom_radius = radius; cm.height = 0.06
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.25, 0.15, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true; mat.emission = Color(1.0, 0.3, 0.15); mat.emission_energy_multiplier = 1.2
	cm.material = mat; _ring.mesh = cm
	_ring.position = Vector3(0, 0.05, 0)
	_ring.scale = Vector3(0.05, 1.0, 0.05)
	add_child(_ring)

func _tick_aoe_telegraph(_delta: float) -> void:
	velocity.x = 0.0; velocity.z = 0.0
	if _ring != null and data.slam_telegraph_duration > 0.0:
		var p: float = 1.0 - (_t / data.slam_telegraph_duration)   # grow 0→1
		_ring.scale = Vector3(lerpf(0.05, 1.0, p), 1.0, lerpf(0.05, 1.0, p))
	if _t == 0.0:
		_state = State.AOE_SLAM

func _tick_aoe_slam() -> void:
	_clear_tint()
	_play("attack")
	if _ring != null:
		_ring.queue_free(); _ring = null
	var radius: float = data.slam_radius / PX_PER_M
	CombatFX.shake(0.6)
	Audio.play("special")
	Combat3D.strike(self, global_position + Vector3(0, 0.5, 0), radius,
		Combat3D.L_PLAYER, func(b: Node) -> void:
			if b.has_method("take_damage"):
				b.take_damage(data.slam_damage, (b.global_position - global_position).normalized()))
	_slam_cd = data.slam_cooldown
	_t = RECOVER_TIME
	_state = State.RECOVER

func _tick_recover() -> void:
	velocity.x = 0.0; velocity.z = 0.0
	_play("recover")
	if _t == 0.0:
		_state = State.CHASE

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
		if _ring != null:
			_ring.queue_free(); _ring = null
		_die()
		return
	Audio.play("hit")
	# Boss commits to its slam — damage lands but the wind-up isn't interrupted.
	if _state == State.AOE_TELEGRAPH or _state == State.AOE_SLAM:
		return
	_play("hurt")
	var kbf: float = (data.knockback_force / PX_PER_M) if data != null else 4.0
	_knockback = from_dir.normalized() * kbf
	_t = HIT_TIME
	_state = State.HIT

func _die() -> void:
	_state = State.DEAD
	_play("death")
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
