extends Node3D
## 3D animal companion — Frosty's combat charge (CHARGE → STRIKE → RETURN). Spawned
## by Evan's Special near enemies: dashes the target, headbutts it (damage + knockback
## staggers/interrupts a windup), then trots back to Evan and despawns. Built from
## primitives for now (a small white dog); a Synty/Hunyuan pet mesh can swap in later.

const SPEED: float = 8.5
const STRIKE_DIST: float = 1.1
const RETURN_DIST: float = 1.0
const DAMAGE: float = 16.0
const FrostyScene: PackedScene = preload("res://assets/models/pets/frosty.glb")
const PET_SCALE: float = 0.9   # frosty.glb is ~0.6 m tall raw; nose faces +Z (charge dir) at yaw 0

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

func _build(_color: Color) -> void:
	# Prop-Farm-rigged Frosty (quadruped) — plays its run clip while it charges/returns.
	# (_color unused now — Frosty is its own white mesh; breeds can vary the mesh later.)
	var pet: Node3D = FrostyScene.instantiate()
	pet.scale = Vector3.ONE * PET_SCALE
	add_child(pet)
	var ap: AnimationPlayer = _find_anim(pet)
	if ap != null:
		var clip: String = "run" if ap.has_animation("run") else ("walk" if ap.has_animation("walk") else "idle")
		if ap.has_animation(clip):
			ap.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			ap.play(clip)

func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null

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
