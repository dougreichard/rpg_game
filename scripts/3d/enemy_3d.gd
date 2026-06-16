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

# Stealth tunables (ported from enemy.gd)
const SUSPICION_THRESHOLD: float = 0.35
const ALERT_THRESHOLD: float = 1.0
const NOISE_ALERT_FLOOR: float = 0.4
const ALERT_DECAY_RATE: float = 0.25
const SIGHT_GAIN_RATE: float = 0.6
const PATROL_SPEED_SCALE: float = 0.5
const PATROL_PAUSE_DURATION: float = 1.2
const PATROL_ARRIVE_DISTANCE: float = 0.45   # metres
const INVESTIGATE_LOOK_DURATION: float = 2.5

enum State { PATROL, INVESTIGATE, CHASE, WINDUP, STRIKE, RECOVER, HIT, DEAD, AOE_TELEGRAPH, AOE_SLAM }

const ProjectileScript: Script = preload("res://scripts/3d/projectile3d.gd")

@export var data: EnemyData = null
@export var mesh_path: String = "res://assets/models/enemies/grunt.glb"
@export var mesh_scale: float = 1.0
@export var mesh_tint: Color = Color(1, 1, 1, 1)   # multiplies the base mesh albedo

var hp: float = 60.0
var _speed: float = 2.5
var _state: State = State.PATROL
var _t: float = 0.0
var _mesh_root: Node3D = null
var _anim: AnimationPlayer = null
var _target: Node3D = null
var _knockback: Vector3 = Vector3.ZERO
var _slam_cd: float = 0.0
var _ring: MeshInstance3D = null

var _home: Vector3 = Vector3.ZERO
var _patrol_target: Vector3 = Vector3.ZERO
var _patrol_pause: float = 0.0
var _alert: float = 0.0
var _investigate: Vector3 = Vector3.ZERO
var _look_timer: float = 0.0
var _facing: Vector3 = Vector3.FORWARD
var _cone: MeshInstance3D = null
var _cone_mat: StandardMaterial3D = null

func _ready() -> void:
	if data != null:
		hp = data.max_hp
		_speed = data.move_speed / PX_PER_M
	collision_layer = Combat3D.L_ENEMY
	collision_mask = Combat3D.L_WORLD
	add_to_group("enemy3d")
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

	# Stealth: patrol the home area until the player is seen/heard. Bosses are
	# known confrontations — they skip straight to chase.
	_home = global_position
	_patrol_target = _pick_patrol_point()
	_state = State.CHASE if (data != null and data.is_boss) else State.PATROL
	GameManager.noise_emitted.connect(_on_noise_emitted)
	GameManager.enemies_calmed.connect(_on_enemies_calmed)
	if _state == State.PATROL:
		_build_vision_cone()

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
	_target = _nearest_player()
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	_t = maxf(_t - delta, 0.0)
	_slam_cd = maxf(_slam_cd - delta, 0.0)
	match _state:
		State.PATROL:         _tick_patrol(delta)
		State.INVESTIGATE:    _tick_investigate(delta)
		State.CHASE:          _tick_chase(delta)
		State.WINDUP:         _tick_windup()
		State.STRIKE:         _tick_strike()
		State.RECOVER:        _tick_recover()
		State.HIT:            _tick_hit(delta)
		State.AOE_TELEGRAPH:  _tick_aoe_telegraph(delta)
		State.AOE_SLAM:       _tick_aoe_slam()
	move_and_slide()
	_update_vision_cone()

# --- Stealth: patrol / investigate / detection -------------------------------
func _nearest_player() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for p in get_tree().get_nodes_in_group("player3d"):
		if not is_instance_valid(p) or p.get("is_downed") == true:
			continue   # ignore downed players — go for whoever's still up
		var d: float = global_position.distance_to((p as Node3D).global_position)
		if d < best_d:
			best_d = d; best = p
	return best

func _pick_patrol_point() -> Vector3:
	var a: float = randf() * TAU
	var r: float = randf() * ((data.patrol_radius / PX_PER_M) if data != null else 2.5)
	return _home + Vector3(cos(a), 0.0, sin(a)) * r

# Walk on the XZ plane toward a point at patrol speed; returns true once arrived.
func _walk_toward(point: Vector3) -> void:
	var to: Vector3 = point - global_position; to.y = 0.0
	if to.length() <= PATROL_ARRIVE_DISTANCE:
		velocity.x = 0.0; velocity.z = 0.0
		return
	var dir := to.normalized()
	_facing = dir
	velocity.x = dir.x * _speed * PATROL_SPEED_SCALE
	velocity.z = dir.z * _speed * PATROL_SPEED_SCALE
	_face(dir, get_physics_process_delta_time())
	_play("walk")

func _arrived(point: Vector3) -> bool:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length() <= PATROL_ARRIVE_DISTANCE

func _can_see(target: Node3D) -> bool:
	if target.get("is_hidden") == true:
		return false
	var to: Vector3 = target.global_position - global_position; to.y = 0.0
	var dist: float = to.length()
	if dist > (data.vision_range / PX_PER_M) or dist <= 0.01:
		return false
	var half: float = deg_to_rad(data.vision_angle_deg) * 0.5
	var fwd := Vector2(_facing.x, _facing.z)
	if absf(fwd.angle_to(Vector2(to.x, to.z) / dist)) > half:
		return false
	var ss := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 0.9, 0), target.global_position + Vector3(0, 0.9, 0), Combat3D.L_WORLD)
	q.exclude = [self]
	return ss.intersect_ray(q).is_empty()

func _update_alert(delta: float) -> bool:
	var t := _nearest_player()
	if t == null or t.get("hp") != null and float(t.get("hp")) <= 0.0:
		_alert = maxf(_alert - ALERT_DECAY_RATE * delta, 0.0)
		return false
	if _can_see(t):
		_investigate = t.global_position
		_alert = minf(_alert + SIGHT_GAIN_RATE * delta, ALERT_THRESHOLD)
		return true
	_alert = maxf(_alert - ALERT_DECAY_RATE * delta, 0.0)
	return false

func _tick_patrol(delta: float) -> void:
	_update_alert(delta)
	if _alert >= ALERT_THRESHOLD:
		_enter_chase(); return
	if _alert >= SUSPICION_THRESHOLD:
		_state = State.INVESTIGATE; _look_timer = INVESTIGATE_LOOK_DURATION; return
	if _patrol_pause > 0.0:
		_patrol_pause = maxf(_patrol_pause - delta, 0.0)
		velocity.x = 0.0; velocity.z = 0.0
		_play("idle")
		return
	_walk_toward(_patrol_target)
	if _arrived(_patrol_target):
		_patrol_pause = PATROL_PAUSE_DURATION
		_patrol_target = _pick_patrol_point()

func _tick_investigate(delta: float) -> void:
	var seen: bool = _update_alert(delta)
	if _alert >= ALERT_THRESHOLD:
		_enter_chase(); return
	if _alert < SUSPICION_THRESHOLD:
		_enter_patrol(); return
	if seen:
		_look_timer = INVESTIGATE_LOOK_DURATION
	_walk_toward(_investigate)
	if _arrived(_investigate):
		velocity.x = 0.0; velocity.z = 0.0
		_play("idle")
		_look_timer = maxf(_look_timer - delta, 0.0)
		if _look_timer <= 0.0:
			_enter_patrol()

func _enter_patrol() -> void:
	_alert = 0.0; _patrol_pause = 0.0
	_patrol_target = _pick_patrol_point()
	_state = State.PATROL

func _enter_chase() -> void:
	if _state == State.PATROL or _state == State.INVESTIGATE:
		Audio.play("alert")
	_alert = ALERT_THRESHOLD
	_state = State.CHASE

func _on_noise_emitted(position: Vector2, radius: float) -> void:
	if _state != State.PATROL and _state != State.INVESTIGATE:
		return
	var reach: float = maxf(radius, (data.hearing_range / PX_PER_M) if data != null else 2.8)
	if Vector2(global_position.x, global_position.z).distance_to(position) > reach:
		return
	_investigate = Vector3(position.x, 0.0, position.y)
	_alert = maxf(_alert, NOISE_ALERT_FLOOR)
	if _state == State.PATROL:
		_state = State.INVESTIGATE; _look_timer = INVESTIGATE_LOOK_DURATION

func _on_enemies_calmed(position: Vector2, radius: float) -> void:
	if _state != State.INVESTIGATE and _state != State.CHASE and _state != State.RECOVER:
		return
	if Vector2(global_position.x, global_position.z).distance_to(position) > radius:
		return
	_enter_patrol()

# --- vision-cone telegraph (flat translucent sector on the ground) -----------
func _build_vision_cone() -> void:
	var rng: float = (data.vision_range / PX_PER_M) if data != null else 5.3
	var half: float = deg_to_rad(data.vision_angle_deg) * 0.5 if data != null else deg_to_rad(50)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 12
	for i in segs:
		var a0: float = -half + (2.0 * half) * float(i) / float(segs)
		var a1: float = -half + (2.0 * half) * float(i + 1) / float(segs)
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(sin(a0), 0, cos(a0)) * rng)
		st.add_vertex(Vector3(sin(a1), 0, cos(a1)) * rng)
	_cone = MeshInstance3D.new()
	_cone.mesh = st.commit()
	_cone_mat = StandardMaterial3D.new()
	_cone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cone_mat.albedo_color = Color(0.9, 0.85, 0.4, 0.12)
	_cone.material_override = _cone_mat
	_cone.position = Vector3(0, 0.06, 0)
	add_child(_cone)

func _update_vision_cone() -> void:
	if _cone == null:
		return
	if _state == State.CHASE or _state == State.DEAD:
		_cone.visible = false
		return
	_cone.visible = true
	_cone.rotation.y = atan2(_facing.x, _facing.z)
	var hot: Color = Color(1.0, 0.3, 0.2, 0.30)
	var cool: Color = Color(0.9, 0.85, 0.4, 0.10)
	_cone_mat.albedo_color = cool.lerp(hot, clampf(_alert / ALERT_THRESHOLD, 0.0, 1.0))

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
	_facing = dir
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
	Combat3D.spark(self, global_position + Vector3(0, 1.0, 0), Color(1.0, 0.95, 0.6))
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
