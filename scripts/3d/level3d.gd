class_name Level3D
extends Node3D
## Reusable base for 3D levels in the migration. Subclasses implement _build_level()
## using the helpers here (environment, floor/wall boxes, prop placement, player/
## enemy spawns, follow camera). Keeps each level script focused on layout while the
## plumbing (lighting, collision layers, capture) lives here. Logic systems
## (GameManager, quests, save, DialogBox) are reused unchanged.

const PlayerScript: Script = preload("res://scripts/3d/player_3d.gd")
const EnemyScript: Script = preload("res://scripts/3d/enemy_3d.gd")
const CameraRigScript: Script = preload("res://scripts/3d/camera_rig_3d.gd")
const Duo3DScript: Script = preload("res://scripts/3d/duo3d.gd")
const Npc3DScript: Script = preload("res://scripts/3d/npc3d.gd")
const DialogBoxScript: Script = preload("res://scripts/ui/dialog_box.gd")

var player: Node3D = null  # a Player3D (single) or a Duo3D controller
const OVERWORLD_3D := "res://scenes/3d/Overworld3D.tscn"

var location_id: String = ""   # set by subclass; used by dialog-effect helper
var dialog = null              # shared DialogBox (created by make_dialog)
var allow_overworld_exit := true   # the overworld itself disables this
var _shot_frames: int = -1

func _ready() -> void:
	_build_level()
	if allow_overworld_exit and location_id != "":
		_add_exit_hint()
	if "--capture" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_args():
		_shot_frames = 18
	if "--capture-late" in OS.get_cmdline_user_args() or "--capture-late" in OS.get_cmdline_args():
		_shot_frames = 440

func _add_exit_hint() -> void:
	var cl := CanvasLayer.new(); add_child(cl)
	var l := Label.new()
	l.anchor_left = 1.0; l.anchor_right = 1.0; l.anchor_top = 1.0; l.anchor_bottom = 1.0
	l.offset_left = -200; l.offset_right = -12; l.offset_top = -40; l.offset_bottom = -10
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.text = "Esc — Town Map"
	l.add_theme_font_override("font", UITheme.font())
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", UITheme.CREAM)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	cl.add_child(l)

func _input(e: InputEvent) -> void:
	if allow_overworld_exit and e.is_action_pressed("ui_cancel"):
		if dialog != null and dialog.has_method("is_open") and dialog.is_open():
			return
		get_tree().change_scene_to_file(OVERWORLD_3D)

# Override in subclasses: build env, floor, walls, props, spawns.
func _build_level() -> void:
	pass

# --- environment -------------------------------------------------------------
func build_env(bg: Color, ambient: Color, ambient_e: float = 0.55, sun_e: float = 1.15) -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(40.0), 0.0)
	sun.light_energy = sun_e
	sun.shadow_enabled = true
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient
	env.ambient_light_energy = ambient_e
	we.environment = env
	add_child(we)

func point_light(pos: Vector3, color: Color, energy: float, rng: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	add_child(l)

# --- geometry ----------------------------------------------------------------
func floor_box(w: float, d: float, col: Color, center := Vector3.ZERO) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(w, 1.0, d)
	cs.shape = bs
	cs.position = Vector3(0, -0.5, 0)
	sb.add_child(cs)
	sb.add_child(box_mesh(Vector3(w, 1.0, d), col, Vector3(0, -0.5, 0)))
	sb.position = center
	add_child(sb)

func wall(center: Vector3, size: Vector3, col: Color) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	sb.add_child(box_mesh(size, col, Vector3.ZERO))
	sb.position = center
	add_child(sb)

func box_mesh(size: Vector3, col: Color, ofs: Vector3, emissive: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 1.0
	if emissive > 0.0:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = emissive
	bm.material = mat
	mi.mesh = bm
	mi.position = ofs
	return mi

func prop(path: String, pos: Vector3, yaw: float = 0.0, scale: float = 1.0) -> Node3D:
	var ps: PackedScene = load(path)
	if ps == null:
		return null
	var n := ps.instantiate()
	n.position = pos
	n.rotation.y = yaw
	n.scale = Vector3.ONE * scale
	add_child(n)
	return n

# --- actors ------------------------------------------------------------------
func spawn_player(data: Resource, pos: Vector3, with_camera: bool = true) -> CharacterBody3D:
	var p := CharacterBody3D.new()
	p.set_script(PlayerScript)
	p.set("data", data)
	p.position = pos
	add_child(p)
	player = p
	if with_camera:
		var cam := Camera3D.new()
		cam.set_script(CameraRigScript)
		cam.set("target", p)
		cam.current = true
		add_child(cam)
	return p

# Spawns the active duo (both bodies on screen) + follow camera. Returns the Duo3D
# controller, which levels treat like the "player" (global_position / special_used /
# active_name / set_input_locked all reflect the active body).
func spawn_duo(datas: Array, pos: Vector3, with_camera: bool = true) -> Node3D:
	var duo := Node3D.new()
	duo.set_script(Duo3DScript)
	add_child(duo)
	var cam: Camera3D = null
	if with_camera:
		cam = Camera3D.new()
		cam.set_script(CameraRigScript)
		cam.current = true
		add_child(cam)
	duo.call("setup", datas, pos, cam, self)
	player = duo
	return duo

func spawn_enemy(data: Resource, pos: Vector3, mesh_path: String = "", mesh_scale: float = 1.0, mesh_tint: Color = Color(1, 1, 1, 1)) -> CharacterBody3D:
	var e := CharacterBody3D.new()
	e.set_script(EnemyScript)
	e.set("data", data)
	if mesh_path != "":
		e.set("mesh_path", mesh_path)
	e.set("mesh_scale", mesh_scale)
	e.set("mesh_tint", mesh_tint)
	e.position = pos
	add_child(e)
	return e

# Spawn a reusable Npc3D (mesh + idle/walk + optional wander + speech bubble).
func spawn_npc(key: String, pos: Vector3, yaw: float = PI, quips: Array = [], waypoints: Array = []) -> Node3D:
	var n := Node3D.new()
	n.set_script(Npc3DScript)
	n.set("mesh_key", key)
	n.set("quips", quips)
	n.set("waypoints", waypoints)
	n.set("face_yaw", yaw)
	n.position = pos
	add_child(n)
	return n

func enemies_alive() -> int:
	var n := 0
	for c in get_children():
		if c is CharacterBody3D and c.get_script() == EnemyScript:
			n += 1
	return n

func near3(a: Vector3, b: Vector3, reach: float = 2.0) -> bool:
	return Vector2(a.x - b.x, a.z - b.z).length() < reach

# --- dialog plumbing (shared) ------------------------------------------------
func make_dialog() -> Object:
	dialog = DialogBoxScript.new()
	var cl := CanvasLayer.new()
	cl.add_child(dialog)
	add_child(cl)
	if not dialog.closed.is_connected(_on_dialog_closed_default):
		dialog.closed.connect(_on_dialog_closed_default)
	return dialog

func open_dialog(npc: String, col: Color, tree: Dictionary, char_name: String) -> void:
	if dialog == null or (dialog.has_method("is_open") and dialog.is_open()):
		return
	if player != null and player.has_method("set_input_locked"):
		player.set_input_locked(true)
	dialog.open(npc, col, tree, "start", char_name)

# Default effect application: grant_items / set_flag / consume_item, keyed to
# location_id. Subclasses can connect their own handler instead (or also).
func _on_dialog_closed_default(effects: Array) -> void:
	if player != null and player.has_method("set_input_locked"):
		player.set_input_locked(false)
	apply_dialog_effects(effects)

func apply_dialog_effects(effects: Array) -> void:
	var who: String = player.active_name() if (player != null and player.has_method("active_name")) else "Quinn"
	for e in effects:
		if not (e is Dictionary):
			continue
		if e.has("grant_items"):
			for id in e["grant_items"]:
				GameManager.grant_item(who, id)
		if e.has("consume_item"):
			GameManager.consume_item(who, e["consume_item"])
		if e.has("set_flag") and location_id != "":
			GameManager.set_level_flag(location_id, e["set_flag"], e.get("flag_value", true))

# Call from a subclass _unhandled_input to drive dialog paging/choices.
func dialog_input() -> bool:
	if dialog == null or not (dialog.has_method("is_open") and dialog.is_open()):
		return false
	if Input.is_action_just_pressed("ui_accept"):
		if dialog.is_choice_mode():
			dialog.select_choice()
		else:
			dialog.advance()
	elif Input.is_action_just_pressed("ui_up"):
		dialog.move_choice_cursor(-1)
	elif Input.is_action_just_pressed("ui_down"):
		dialog.move_choice_cursor(1)
	return true

# --- HUD labels (shared) -----------------------------------------------------
func make_hud_layer() -> CanvasLayer:
	var cl := CanvasLayer.new()
	add_child(cl)
	return cl

func hud_label(cl: CanvasLayer, y: float, size: int = 22, from_bottom: bool = false) -> Label:
	var l := Label.new()
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.offset_left = 40
	l.offset_right = -40
	if from_bottom:
		l.anchor_top = 1.0
		l.anchor_bottom = 1.0
	l.offset_top = y
	l.offset_bottom = y + 70
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UITheme.font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", UITheme.CREAM)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	cl.add_child(l)
	return l

# --- capture (windowed --capture) --------------------------------------------
func _process(_d: float) -> void:
	if _shot_frames < 0:
		return
	_shot_frames -= 1
	if _shot_frames == 0:
		get_viewport().get_texture().get_image().save_png("res://_arena3d_shot.png")
		print("SHOT_SAVED")
		get_tree().quit()
