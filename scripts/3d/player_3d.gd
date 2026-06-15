extends CharacterBody3D
## 3D lead — movement, facing, attack, and a minimal active-duo SWAP (Quinn<->Erin).
## One controllable body that swaps which character mesh/stats/ability is active
## (the standby-follower nuance from 2D comes later). Stats from CharacterData.

signal special_used(character_name: String)

const PX_PER_M: float = 32.0
const GRAVITY: float = 24.0
const TURN_LERP: float = 14.0
const MESH_DIR: String = "res://assets/models/characters/"

@export var data: CharacterData = null          # single-character mode
@export var duo: Array[CharacterData] = []       # duo mode (overrides `data`)

var hp: float = 100.0
var _datas: Array = []
var _meshes: Array = []
var _anims: Array = []
var _active: int = 0
var _speed: float = 5.0
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
	_datas = duo.duplicate() if not duo.is_empty() else ([data] if data != null else [])
	for d: CharacterData in _datas:
		var ps: PackedScene = load(MESH_DIR + d.character_name.to_lower() + ".glb")
		var m: Node3D = ps.instantiate() if ps != null else Node3D.new()
		add_child(m)
		var ap := _find_anim(m)
		if ap != null:
			for a: String in ["idle", "walk", "run"]:
				var an: Animation = ap.get_animation(a)
				if an != null:
					an.loop_mode = Animation.LOOP_LINEAR
			ap.play("idle")
		_meshes.append(m)
		_anims.append(ap)
	if not _datas.is_empty():
		hp = _datas[0].max_hp
		_set_active(0)

func _find_anim(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null

func _set_active(i: int) -> void:
	_active = i
	for j in _meshes.size():
		_meshes[j].visible = (j == i)
	_speed = _datas[_active].move_speed / PX_PER_M

func active_name() -> String:
	return _datas[_active].character_name if not _datas.is_empty() else "Quinn"

func set_input_locked(v: bool) -> void:
	_input_locked = v

func _physics_process(delta: float) -> void:
	if _input_locked:
		velocity = Vector3.ZERO
		return
	if _datas.size() > 1 and Input.is_action_just_pressed("swap"):
		_set_active((_active + 1) % _datas.size())
		Audio.play("swap")
	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := Vector3(move.x, 0.0, move.y)
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
	var mesh: Node3D = _meshes[_active]
	var anim: AnimationPlayer = _anims[_active]
	if moving:
		var want_yaw := atan2(dir.x, dir.z)
		mesh.rotation.y = lerp_angle(mesh.rotation.y, want_yaw, clampf(TURN_LERP * delta, 0.0, 1.0))
	_attack_anim_t = maxf(_attack_anim_t - delta, 0.0)
	if anim != null:
		if _attack_anim_t > 0.0:
			if anim.current_animation != "attack":
				anim.play("attack")
		else:
			var want := "walk" if moving else "idle"
			if anim.current_animation != want:
				anim.play(want)
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	if _attack_cd == 0.0 and Input.is_action_just_pressed("attack"):
		_attack()
	if Input.is_action_just_pressed("special"):
		special_used.emit(active_name())

func _attack() -> void:
	var d: CharacterData = _datas[_active]
	_attack_cd = d.attack_cooldown
	_attack_anim_t = 0.35
	var pos := global_position + _facing * 1.3 + Vector3(0.0, 0.9, 0.0)
	Audio.play("attack")
	Combat3D.strike(self, pos, 0.8, Combat3D.L_ENEMY, func(b: Node) -> void:
		if b.has_method("take_damage"):
			b.take_damage(d.attack_damage, _facing))

func take_damage(amount: float, _from: Vector3) -> void:
	hp = maxf(hp - amount, 0.0)
	Audio.play("hurt")
