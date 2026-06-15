extends Node3D
## Gimme Dat Spoon — 3D set-piece (polished). Runs the REAL SpoonGame: six leads
## seated around a table, the camera cuts to whoever's turn it is, a 2D HUD narrates
## passes/powers/eliminations, and eliminated players dim + slump. Auto-plays for now
## (AI for every seat); human-choice input is the next increment.

const SpoonGameScript: Script = preload("res://scripts/systems/spoon_game.gd")
const SEAT_KEYS: Array = ["quinn", "erin", "evan", "ben", "ethan", "uncle_doug"]
const SEAT_NAMES: Array = ["Quinn", "Erin", "Evan", "Ben", "Ethan", "Uncle Doug"]
const RING_R: float = 1.75
const SEAT_Y: float = -0.35          # lower the seated figure so it meets the chair
const TURN_TIME: float = 1.7
const TABLE_GLB := "res://assets/models/props/table.glb"
const CHAIR_GLB := "res://assets/models/props/chair.glb"

var _game = null
var _cam: Camera3D = null
var _seat_pos: Array = []
var _seat_char: Array = []           # Node3D per seat
var _alive: Array = []               # bool per seat
var _turn_t: float = 0.0
var _running: bool = false
var _turn_label: Label = null
var _action_label: Label = null
var _banner: Label = null
var _shot_frames: int = -1

func _ready() -> void:
	_build_env()
	_floor()
	_prop(TABLE_GLB, Vector3.ZERO, 0.0)
	for i: int in range(SEAT_KEYS.size()):
		var ang: float = TAU * float(i) / float(SEAT_KEYS.size())
		var pos := Vector3(sin(ang) * RING_R, 0.0, cos(ang) * RING_R)
		_seat_pos.append(pos)
		_alive.append(true)
		var face_center: float = atan2(-pos.x, -pos.z)
		_prop(CHAIR_GLB, pos, face_center)
		_seat_char.append(_seat_character(SEAT_KEYS[i], pos, face_center))
	_cam = Camera3D.new()
	_cam.current = true
	add_child(_cam)
	_build_hud()
	_start_game()
	if "--capture" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_args():
		_shot_frames = 90  # let several turns play, then screenshot

func _build_env() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-60.0), deg_to_rad(30.0), 0.0)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	add_child(sun)
	var key := OmniLight3D.new()  # warm fill over the table
	key.position = Vector3(0, 3.2, 0)
	key.light_color = Color(1.0, 0.92, 0.78)
	key.light_energy = 2.5
	key.omni_range = 8.0
	add_child(key)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.06, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.46, 0.42)
	env.ambient_light_energy = 0.5
	we.environment = env
	add_child(we)

func _floor() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12, 12)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.26, 0.23)
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

func _seat_character(key: String, pos: Vector3, yaw: float) -> Node3D:
	var ps: PackedScene = load("res://assets/models/characters/%s.glb" % key)
	if ps == null:
		return null
	var n := ps.instantiate()
	n.position = pos + Vector3(0.0, SEAT_Y, 0.0)
	n.rotation.y = yaw
	add_child(n)
	var ap := _find_anim(n)
	if ap != null and ap.has_animation("sit"):
		ap.play("sit")
	return n

func _find_anim(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null

# --- HUD ---------------------------------------------------------------------
func _build_hud() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	_turn_label = _mk_label(cl, Vector2(0, 24), HORIZONTAL_ALIGNMENT_CENTER, 30)
	_action_label = _mk_label(cl, Vector2(0, -70), HORIZONTAL_ALIGNMENT_CENTER, 22)
	_action_label.anchor_top = 1.0; _action_label.anchor_bottom = 1.0
	_banner = _mk_label(cl, Vector2(0, 0), HORIZONTAL_ALIGNMENT_CENTER, 48)
	_banner.anchor_top = 0.5; _banner.anchor_bottom = 0.5
	_banner.visible = false
	_turn_label.text = "Gimme Dat Spoon"

func _mk_label(cl: CanvasLayer, ofs: Vector2, align: int, size: int) -> Label:
	var l := Label.new()
	l.anchor_left = 0.0; l.anchor_right = 1.0
	l.offset_top = ofs.y; l.offset_bottom = ofs.y + 60
	l.horizontal_alignment = align
	l.add_theme_font_override("font", UITheme.font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", UITheme.CREAM)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	cl.add_child(l)
	return l

# --- Game flow ---------------------------------------------------------------
func _start_game() -> void:
	var colors: Array = []
	for k: String in SEAT_KEYS:
		colors.append(Color.WHITE)
	_game = SpoonGameScript.new()
	_game.turn_changed.connect(_on_turn)
	_game.spoon_passed.connect(_on_pass)
	_game.power_activated.connect(_on_power)
	_game.player_eliminated.connect(_on_elim)
	_game.game_over.connect(_on_over)
	_game.start(SEAT_NAMES.duplicate(), colors)
	_running = true
	_turn_t = 1.0
	_cut_to(_game.active_idx, true)

func _on_turn(idx: int) -> void:
	_turn_label.text = "%s's turn" % SEAT_NAMES[idx]
	_cut_to(idx)

func _on_pass(from_idx: int, to_idx: int, spoon_type: String) -> void:
	_action_label.text = "%s slips a %s to %s" % [SEAT_NAMES[from_idx], spoon_type, SEAT_NAMES[to_idx]]

func _on_power(idx: int, spoon_type: String) -> void:
	_action_label.text = "%s plays %s!" % [SEAT_NAMES[idx], spoon_type.to_upper()]
	CombatFX.shake(0.2)
	_push_in()

func _on_elim(idx: int) -> void:
	_action_label.text = "%s is out!" % SEAT_NAMES[idx]
	_alive[idx] = false
	var ch: Node3D = _seat_char[idx]
	if ch != null:
		var tw := create_tween()
		tw.tween_property(ch, "rotation:x", deg_to_rad(30.0), 0.4)  # slump forward
		for mi in ch.find_children("*", "MeshInstance3D"):
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.4, 0.4, 0.42)
			(mi as MeshInstance3D).material_override = m

func _on_over(winner_idx: int) -> void:
	_running = false
	_turn_label.text = ""
	_action_label.text = ""
	_banner.text = "%s wins the spoon!" % SEAT_NAMES[winner_idx]
	_banner.visible = true
	_cut_to(winner_idx, false, true)

func _process(delta: float) -> void:
	if _running:
		_turn_t -= delta
		if _turn_t <= 0.0:
			_turn_t = TURN_TIME
			if _game != null:
				_game.take_ai_turn()
	if _shot_frames >= 0:
		_shot_frames -= 1
		if _shot_frames == 0:
			get_viewport().get_texture().get_image().save_png("res://_arena3d_shot.png")
			print("SHOT_SAVED")
			get_tree().quit()

# --- Camera ------------------------------------------------------------------
func _cut_to(seat: int, instant: bool = false, hero: bool = false) -> void:
	var sp: Vector3 = _seat_pos[seat]
	var look: Vector3 = sp + Vector3(0.0, 1.0, 0.0)
	var dist: float = RING_R + (1.6 if hero else 2.4)
	var cam_pos: Vector3 = -sp.normalized() * dist + Vector3(0.0, 2.5 if hero else 2.6, 0.0)
	if instant:
		_cam.global_position = cam_pos
		_cam.look_at(look, Vector3.UP)
		return
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(t: float) -> void:
		_cam.global_position = _cam.global_position.lerp(cam_pos, t)
		_cam.look_at(look, Vector3.UP), 0.0, 1.0, 0.6)

func _push_in() -> void:
	var look := _cam.global_position - _cam.global_transform.basis.z * 3.0
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	var near := _cam.global_position.lerp(look, 0.25)
	tw.tween_property(_cam, "global_position", near, 0.15)
	tw.tween_property(_cam, "global_position", _cam.global_position, 0.3)
