extends Camera3D
## 3/4 top-down follow camera for the 3D migration. Sits at a fixed elevation/
## azimuth offset from a target, smoothly follows, and exposes a tween API for
## set-piece moves (spoon turns, boss intros). Mirrors the 2D Camera2D-follow role.

# Elevation above the horizon (deg) and ground distance. ~52° reads top-down enough
# for a brawler while keeping the warm Synty 3/4 feel; tune to taste.
const ELEV_DEG: float = 52.0
const DISTANCE: float = 6.5
const FOLLOW_LERP: float = 8.0
const HEIGHT_LOOK: float = 0.9  # aim a touch above the feet

var target: Node3D = null
var dist: float = DISTANCE
var elev: float = ELEV_DEG
var _offset: Vector3 = Vector3.ZERO
var _scripted: bool = false  # true while a tween move owns the camera

# Re-frame the follow (e.g. pull back for the overworld overview). Recomputes the
# fixed offset; takes effect next follow tick.
func reframe(p_dist: float, p_elev: float) -> void:
	dist = p_dist
	elev = p_elev
	var el: float = deg_to_rad(elev)
	_offset = Vector3(0.0, sin(el) * dist, cos(el) * dist)

func _ready() -> void:
	var el: float = deg_to_rad(elev)
	# Camera up and toward +Z (screen-south), looking north + down at the target.
	_offset = Vector3(0.0, sin(el) * dist, cos(el) * dist)
	if target != null:
		global_position = target.global_position + _offset
		look_at(target.global_position + Vector3(0.0, HEIGHT_LOOK, 0.0), Vector3.UP)

func _physics_process(delta: float) -> void:
	if _scripted or target == null or not is_instance_valid(target):
		return
	var want: Vector3 = target.global_position + _offset
	global_position = global_position.lerp(want, clampf(FOLLOW_LERP * delta, 0.0, 1.0))
	look_at(target.global_position + Vector3(0.0, HEIGHT_LOOK, 0.0), Vector3.UP)

# Set-piece move: glide to a world position looking at `look`, over `dur`. While
# scripted, normal follow is suspended; call resume_follow() to hand control back.
func move_to(pos: Vector3, look: Vector3, dur: float = 0.8) -> Tween:
	_scripted = true
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(t: float) -> void:
		global_position = global_position.lerp(pos, t)
		look_at(look, Vector3.UP), 0.0, 1.0, dur)
	return tw

func resume_follow() -> void:
	_scripted = false
