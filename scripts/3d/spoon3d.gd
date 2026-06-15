extends Node3D
## Gimme Dat Spoon as a 3D set-piece (Phase 1) — the camera-choreography experiment.
## Six leads sit around a dining table; the camera CUTS/glides to whoever's turn it
## is, with a push-in beat on the "grab". Proves 3D set-piece flow. The full SpoonGame
## turn/AI logic + 2D choice HUD slot in later; this drives a demo turn cycle.

const SEAT_LEADS: Array = ["quinn", "erin", "evan", "ben", "ethan", "quinn"]
const RING_R: float = 1.7
const TABLE_GLB := "res://assets/models/props/table.glb"
const CHAIR_GLB := "res://assets/models/props/chair.glb"
const TURN_TIME: float = 1.6

var _cam: Camera3D = null
var _seat_pos: Array = []      # Vector3 per seat
var _active: int = 0
var _turn_t: float = 0.0
var _shot_frames: int = -1

func _ready() -> void:
	_build_env()
	_floor()
	_prop(TABLE_GLB, Vector3.ZERO, 0.0)
	for i: int in range(SEAT_LEADS.size()):
		var ang: float = TAU * float(i) / float(SEAT_LEADS.size())
		var pos := Vector3(sin(ang) * RING_R, 0.0, cos(ang) * RING_R)
		_seat_pos.append(pos)
		var face_center: float = atan2(-pos.x, -pos.z)
		_prop(CHAIR_GLB, pos, face_center)
		_seat_character(SEAT_LEADS[i], pos, face_center)
	_cam = Camera3D.new()
	_cam.current = true
	add_child(_cam)
	_cut_to(0, true)
	_turn_t = TURN_TIME
	if "--capture" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_args():
		_shot_frames = 24

func _build_env() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-60.0), deg_to_rad(30.0), 0.0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.09, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.56, 0.5)
	env.ambient_light_energy = 0.6
	we.environment = env
	add_child(we)

func _floor() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(10, 10)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.30, 0.26)
	mat.roughness = 1.0
	pm.material = mat
	mi.mesh = pm
	add_child(mi)

func _prop(path: String, pos: Vector3, yaw: float) -> void:
	var ps: PackedScene = load(path)
	if ps == null:
		return
	var n := ps.instantiate()
	n.position = pos
	n.rotation.y = yaw
	add_child(n)

func _seat_character(key: String, pos: Vector3, yaw: float) -> void:
	var ps: PackedScene = load("res://assets/models/characters/%s.glb" % key)
	if ps == null:
		return
	var n := ps.instantiate()
	n.position = pos + Vector3(0.0, 0.45, 0.0)  # seat height
	n.rotation.y = yaw
	add_child(n)
	var ap := _find_anim(n)
	if ap != null and ap.has_animation("sit"):
		ap.play("sit")

func _find_anim(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null

# Frame the active player: camera near the table centre, raised, looking at them.
func _cut_to(seat: int, instant: bool = false) -> void:
	_active = seat
	var sp: Vector3 = _seat_pos[seat]
	var look: Vector3 = sp + Vector3(0.0, 1.0, 0.0)
	# Camera across the table from the active player, raised — looks back at them
	# with the table in the foreground.
	var cam_pos: Vector3 = -sp.normalized() * (RING_R + 2.4) + Vector3(0.0, 2.6, 0.0)
	if instant:
		_cam.global_position = cam_pos
		_cam.look_at(look, Vector3.UP)
		return
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(t: float) -> void:
		_cam.global_position = _cam.global_position.lerp(cam_pos, t)
		_cam.look_at(look, Vector3.UP), 0.0, 1.0, 0.7)

func _process(delta: float) -> void:
	_turn_t -= delta
	if _turn_t <= 0.0:
		_turn_t = TURN_TIME
		_cut_to((_active + 1) % SEAT_LEADS.size())
	if _shot_frames >= 0:
		_shot_frames -= 1
		if _shot_frames == 0:
			get_viewport().get_texture().get_image().save_png("res://_arena3d_shot.png")
			print("SHOT_SAVED")
			get_tree().quit()
