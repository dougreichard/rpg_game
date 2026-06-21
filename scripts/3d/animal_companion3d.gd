extends Node3D
## 3D animal companion — Frosty's combat charge (CHARGE → STRIKE → RETURN). Spawned
## by Evan's Special near enemies: dashes the target, headbutts it (damage + knockback
## staggers/interrupts a windup), then trots back to Evan and despawns. Built from
## primitives for now (a small white dog); a Synty/Hunyuan pet mesh can swap in later.

const SPEED: float = 8.5
const STRIKE_DIST: float = 1.1
const RETURN_DIST: float = 1.0
const DAMAGE: float = 16.0
const STRIKE_TIME: float = 0.45   # brief lunge dwell so the 'bite' clip reads before returning
const FrostyScene: PackedScene = preload("res://assets/models/pets/frosty.glb")
const PET_SCALE: float = 0.9   # frosty.glb is ~0.6 m tall raw; nose faces +Z (charge dir) at yaw 0

enum Phase { CHARGE, STRIKE, RETURN }

var _summoner: Node3D = null
var _target: Node3D = null
var _phase: int = Phase.CHARGE
var _struck: bool = false
var _life: float = 6.0
var _strike_t: float = 0.0
var _anim: AnimationPlayer = null

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
	_anim = _find_anim(pet)
	_play("run", true)   # charge in at a run

func _play(clip: String, loop: bool) -> void:
	if _anim == null or not _anim.has_animation(clip):
		return
	_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	_anim.play(clip)

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
		_play("run", true)
	match _phase:
		Phase.CHARGE: _tick_charge(d)
		Phase.STRIKE: _tick_strike(d)
		Phase.RETURN: _tick_return(d)

func _tick_charge(d: float) -> void:
	var to: Vector3 = _target.global_position - global_position; to.y = 0.0
	if to.length() <= STRIKE_DIST:
		# lunge: face the target, play the bite, dwell briefly (damage lands mid-bite)
		if to.length() > 0.001:
			rotation.y = atan2(to.x, to.z)
		_phase = Phase.STRIKE
		_strike_t = STRIKE_TIME
		_struck = false
		_play("bite", false)
		return
	_move(to.normalized(), d)

func _tick_strike(d: float) -> void:
	_strike_t -= d
	# apply the hit once, partway through the lunge
	if not _struck and _strike_t <= STRIKE_TIME * 0.5:
		var dir: Vector3 = Vector3.FORWARD
		if _target != null and is_instance_valid(_target):
			dir = (_target.global_position - global_position); dir.y = 0.0; dir = dir.normalized()
		_strike(dir)
	if _strike_t <= 0.0:
		_phase = Phase.RETURN
		_play("run", true)

func _strike(dir: Vector3) -> void:
	_struck = true
	var at: Vector3 = (_target.global_position if _target != null and is_instance_valid(_target) else global_position)
	Combat3D.strike(self, at + Vector3(0, 0.9, 0), 1.0,
		Combat3D.L_ENEMY, func(b: Node) -> void:
			if b.has_method("take_damage"):
				b.take_damage(DAMAGE, dir))
	Audio.play("hit")

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
