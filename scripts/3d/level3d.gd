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

var player: CharacterBody3D = null
var _shot_frames: int = -1

func _ready() -> void:
	_build_level()
	if "--capture" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_args():
		_shot_frames = 18

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

func spawn_enemy(data: Resource, pos: Vector3, mesh_path: String = "") -> CharacterBody3D:
	var e := CharacterBody3D.new()
	e.set_script(EnemyScript)
	e.set("data", data)
	if mesh_path != "":
		e.set("mesh_path", mesh_path)
	e.position = pos
	add_child(e)
	return e

# --- capture (windowed --capture) --------------------------------------------
func _process(_d: float) -> void:
	if _shot_frames < 0:
		return
	_shot_frames -= 1
	if _shot_frames == 0:
		get_viewport().get_texture().get_image().save_png("res://_arena3d_shot.png")
		print("SHOT_SAVED")
		get_tree().quit()
