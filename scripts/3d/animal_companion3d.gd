extends Node3D
## 3D animal companion — Frosty's combat charge (CHARGE → STRIKE → RETURN). Spawned
## by Evan's Special near enemies: dashes the target, headbutts it (damage + knockback
## staggers/interrupts a windup), then trots back to Evan and despawns. Built from
## primitives for now (a small white dog); a Synty/Hunyuan pet mesh can swap in later.

const SPEED: float = 8.5
const STRIKE_DIST: float = 1.1
const RETURN_DIST: float = 1.0
const DAMAGE: float = 16.0

enum Phase { CHARGE, RETURN }

var _summoner: Node3D = null
var _target: Node3D = null
var _phase: int = Phase.CHARGE
var _struck: bool = false
var _life: float = 6.0

func setup(summoner: Node3D, target: Node3D, color: Color = Color(0.95, 0.95, 0.95)) -> void:
	_summoner = summoner
	_target = target
	_build(color)

func _build(color: Color) -> void:
	_box(Vector3(0.4, 0.32, 0.7), color, Vector3(0, 0.3, 0))           # body
	_box(Vector3(0.3, 0.3, 0.3), color, Vector3(0, 0.45, 0.42))        # head
	_box(Vector3(0.08, 0.3, 0.08), color.darkened(0.1), Vector3(-0.13, 0.15, 0.25))
	_box(Vector3(0.08, 0.3, 0.08), color.darkened(0.1), Vector3(0.13, 0.15, 0.25))
	_box(Vector3(0.08, 0.3, 0.08), color.darkened(0.1), Vector3(-0.13, 0.15, -0.25))
	_box(Vector3(0.08, 0.3, 0.08), color.darkened(0.1), Vector3(0.13, 0.15, -0.25))

func _box(size: Vector3, col: Color, ofs: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	var mat := StandardMaterial3D.new(); mat.albedo_color = col; mat.roughness = 1.0
	bm.material = mat; mi.mesh = bm; mi.position = ofs
	add_child(mi)

func _process(d: float) -> void:
	_life -= d
	if _life <= 0.0:
		queue_free(); return
	if _phase == Phase.CHARGE and (_target == null or not is_instance_valid(_target)):
		_phase = Phase.RETURN
	match _phase:
		Phase.CHARGE: _tick_charge(d)
		Phase.RETURN: _tick_return(d)

func _tick_charge(d: float) -> void:
	var to: Vector3 = _target.global_position - global_position; to.y = 0.0
	if to.length() <= STRIKE_DIST:
		_strike(to.normalized())
		return
	_move(to.normalized(), d)

func _strike(dir: Vector3) -> void:
	_struck = true
	Combat3D.strike(self, _target.global_position + Vector3(0, 0.9, 0), 1.0,
		Combat3D.L_ENEMY, func(b: Node) -> void:
			if b.has_method("take_damage"):
				b.take_damage(DAMAGE, dir))
	Audio.play("hit")
	_phase = Phase.RETURN

func _tick_return(d: float) -> void:
	if _summoner == null or not is_instance_valid(_summoner):
		queue_free(); return
	var to: Vector3 = _summoner.global_position - global_position; to.y = 0.0
	if to.length() <= RETURN_DIST:
		queue_free(); return
	_move(to.normalized(), d)

func _move(dir: Vector3, d: float) -> void:
	global_position += dir * SPEED * d
	rotation.y = atan2(dir.x, dir.z)
