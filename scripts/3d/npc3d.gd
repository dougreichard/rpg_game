extends Node3D
## Reusable 3D NPC: a Synty character mesh with idle/walk animation, optional
## waypoint wander, and an optional floating speech bubble (Label3D) that barks
## lines on a timer or on demand. Used for both stationary quest-givers and
## atmospheric wanderers across the 3D levels. No class_name — preload()+untyped.

const MESH_DIR := "res://assets/models/characters/"
const BARK_GAP_MS := 2500   # global min gap between ANY two NPC barks (one-at-a-time)

# Shared across all Npc3D instances so a crowd (e.g. the 12 town quest-givers) never
# talks over itself — replaces the old BubbleCoordinator node with a static gate.
static var _last_bark_ms: int = 0

# Configure via setup() before adding to the tree, or set fields directly.
var mesh_key: String = ""
var quips: Array = []          # random barks; empty = silent
var waypoints: Array = []      # Vector3 local targets; empty = stationary
var face_yaw: float = PI       # initial facing (default: toward +Z / the camera)
var paused: bool = false       # halt wander/bark (e.g. while the player is talking to it)
var speed: float = 1.6
var idle_time: float = 2.2
var yell_min: float = 5.0
var yell_max: float = 11.0
var bubble_dur: float = 3.0
var bubble_height: float = 2.6

var _mesh: Node3D = null
var _anim: AnimationPlayer = null
var _bubble: Label3D = null
var _target: int = 0
var _idle: float = 0.0
var _yell: float = 0.0
var _bubble_t: float = 0.0

func setup(key: String, p_quips: Array = [], p_waypoints: Array = []) -> Object:
	mesh_key = key
	quips = p_quips
	waypoints = p_waypoints
	return self

func _ready() -> void:
	var ps: PackedScene = load(MESH_DIR + mesh_key + ".glb") if mesh_key != "" else null
	if ps != null:
		_mesh = ps.instantiate()
		_mesh.rotation.y = face_yaw
		add_child(_mesh)
		_anim = _find_anim(_mesh)
		if _anim != null and _anim.has_animation("idle"):
			_anim.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
			_anim.play("idle")
	_make_bubble()   # always present so even quiet NPCs can say() on interaction
	_yell = randf_range(yell_min, yell_max)

func _make_bubble() -> void:
	_bubble = Label3D.new()
	_bubble.text = ""
	_bubble.font = UITheme.font()
	_bubble.font_size = 48
	_bubble.outline_size = 16
	_bubble.modulate = UITheme.CREAM
	_bubble.outline_modulate = Color(0, 0, 0, 0.95)
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.no_depth_test = true
	_bubble.fixed_size = true
	_bubble.pixel_size = 0.0011
	_bubble.position = Vector3(0.0, bubble_height, 0.0)
	_bubble.visible = false
	add_child(_bubble)

# Show a line above this NPC's head for bubble_dur seconds.
func say(text: String) -> void:
	if _bubble == null:
		return
	_bubble.text = text
	_bubble.visible = true
	_bubble_t = bubble_dur

func talk_pos() -> Vector3:
	return global_position

func _process(d: float) -> void:
	if _bubble_t > 0.0:
		_bubble_t -= d
		if _bubble_t <= 0.0:
			_bubble.visible = false
	if paused:
		_play("idle")
		return
	if not quips.is_empty():
		_yell -= d
		if _yell <= 0.0:
			var now: int = Time.get_ticks_msec()
			if now - _last_bark_ms >= BARK_GAP_MS:
				_last_bark_ms = now
				_yell = randf_range(yell_min, yell_max)
				say(quips[randi() % quips.size()])
			else:
				_yell = 0.5   # someone else is talking — retry shortly
	if waypoints.size() > 0:
		_wander(d)

func _wander(d: float) -> void:
	var tgt: Vector3 = waypoints[_target]
	var to: Vector3 = tgt - position; to.y = 0.0
	if to.length() < 0.15:
		_idle -= d
		if _idle <= 0.0:
			_idle = idle_time
			_target = (_target + 1) % waypoints.size()
		_play("idle")
	else:
		var step: Vector3 = to.normalized() * speed * d
		position += step
		if _mesh != null:
			_mesh.rotation.y = atan2(step.x, step.z)
		_play("walk")

func _play(anim: String) -> void:
	if _anim == null or not _anim.has_animation(anim) or _anim.current_animation == anim:
		return
	_anim.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
	_anim.play(anim)

func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null
