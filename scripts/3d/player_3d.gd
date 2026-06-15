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
const LEASH: float = 9.0         # teleport to the active's side past this (~300px)

@export var data: CharacterData = null
@export var mesh_path: String = ""

var hp: float = 100.0
var bies_charge: float = 0.0   # 0..1; +0.1 per hit landed, spent on Bies Mode
var mode: int = Mode.ACTIVE
var follow_target: Node3D = null
var _speed: float = 5.0
var _mesh: Node3D = null
var _anim: AnimationPlayer = null
var _facing: Vector3 = Vector3.FORWARD
var _attack_cd: float = 0.0
var _attack_anim_t: float = 0.0
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
	if _input_locked:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var dir := Vector3.ZERO
	var prefix := ""
	if mode == Mode.ACTIVE:
		dir = _move_input("")
	elif mode == Mode.STANDBY_P2:
		prefix = "p2_"
		dir = _move_input("p2_")
	else:  # STANDBY_AI — follow the active teammate
		if follow_target != null and is_instance_valid(follow_target):
			var to: Vector3 = follow_target.global_position - global_position
			to.y = 0.0
			if to.length() > LEASH:
				global_position = follow_target.global_position - to.normalized() * FOLLOW_STOP
			elif to.length() > FOLLOW_STOP:
				dir = to.normalized()
	velocity.x = dir.x * _speed
	velocity.z = dir.z * _speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	var moving := dir.length() > 0.05
	if moving:
		_facing = dir.normalized()
	if _mesh != null and moving:
		var want_yaw := atan2(dir.x, dir.z)
		_mesh.rotation.y = lerp_angle(_mesh.rotation.y, want_yaw, clampf(TURN_LERP * delta, 0.0, 1.0))
	_attack_anim_t = maxf(_attack_anim_t - delta, 0.0)
	if _anim != null:
		if _attack_anim_t > 0.0:
			if _anim.current_animation != "attack":
				_anim.play("attack")
		else:
			var want := "walk" if moving else "idle"
			if _anim.current_animation != want:
				_anim.play(want)
	# actions (player-controlled modes only)
	if mode == Mode.STANDBY_AI:
		return
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	if _attack_cd == 0.0 and Input.is_action_just_pressed(prefix + "attack"):
		_attack()
	if Input.is_action_just_pressed(prefix + "special"):
		special_used.emit(active_name())

func _attack() -> void:
	_attack_cd = data.attack_cooldown if data != null else 0.5
	_attack_anim_t = 0.35
	var dmg: float = data.attack_damage if data != null else 20.0
	var pos := global_position + _facing * 1.3 + Vector3(0.0, 0.9, 0.0)
	Audio.play("attack")
	Combat3D.strike(self, pos, 0.8, Combat3D.L_ENEMY, func(b: Node) -> void:
		if b.has_method("take_damage"):
			b.take_damage(dmg, _facing)
			bies_charge = minf(bies_charge + 0.1, 1.0))

func take_damage(amount: float, _from: Vector3) -> void:
	hp = maxf(hp - amount, 0.0)
	Audio.play("hurt")
