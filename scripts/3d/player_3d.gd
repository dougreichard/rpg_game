extends CharacterBody3D
## 3D lead — movement + facing on the ground plane. The combat FSM and skeletal
## animation (AnimationTree) get layered on once AnimLocomotion clips are back; for
## now this validates camera + movement + mesh import in true 3D. Stats come from the
## same CharacterData resource the 2D player uses (px/s converted to m/s).

const PX_PER_M: float = 32.0          # gameplay grid was 32px; map to 1 m
const GRAVITY: float = 24.0
const TURN_LERP: float = 14.0

@export var data: CharacterData = null
@export var mesh_path: String = "res://assets/models/characters/quinn.glb"

var _speed: float = 5.0
var _mesh_root: Node3D = null
var _anim: AnimationPlayer = null
var _facing: Vector3 = Vector3.FORWARD
var hp: float = 100.0
var _attack_cd: float = 0.0

func _ready() -> void:
	if data != null:
		_speed = data.move_speed / PX_PER_M
		hp = data.max_hp
	# Combat layers: this body IS a player; it collides with the world.
	collision_layer = Combat3D.L_PLAYER
	collision_mask = Combat3D.L_WORLD
	add_to_group("player3d")
	# Body collision (capsule) so the character collides with walls/props.
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	shape.shape = cap
	shape.position = Vector3(0.0, 0.85, 0.0)
	add_child(shape)
	# Visual mesh (bind pose for now).
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
	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Screen up (-y input) = into the scene (-Z); right (+x) = +X.
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
	# Face travel direction (smooth yaw).
	if _mesh_root != null and moving:
		var want_yaw := atan2(dir.x, dir.z)
		_mesh_root.rotation.y = lerp_angle(_mesh_root.rotation.y, want_yaw, clampf(TURN_LERP * delta, 0.0, 1.0))
	# Locomotion animation.
	if _anim != null:
		var want := "walk" if moving else "idle"
		if _anim.current_animation != want:
			_anim.play(want)
	# Attack (no 3D attack clip yet — spawns the damage volume; visuals later).
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	if _attack_cd == 0.0 and Input.is_action_just_pressed("attack"):
		_attack()

func _attack() -> void:
	var dmg: float = data.attack_damage if data != null else 20.0
	var reach: float = 1.3
	_attack_cd = data.attack_cooldown if data != null else 0.5
	var pos := global_position + _facing * reach + Vector3(0.0, 0.9, 0.0)
	Audio.play("attack")
	Combat3D.strike(self, pos, 0.8, Combat3D.L_ENEMY, func(b: Node) -> void:
		if b.has_method("take_damage"):
			b.take_damage(dmg, _facing))

func take_damage(amount: float, _from: Vector3) -> void:
	hp = maxf(hp - amount, 0.0)
	Audio.play("hurt")
