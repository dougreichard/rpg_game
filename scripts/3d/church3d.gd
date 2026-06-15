extends Node3D
## 3D Old Parish Church — the first real level of the migration. A walkable, open-top
## nave (3/4 camera sees in) built from a floor + stone wall boxes + Synty church props
## (pews / altar stand / candles), ported from the 2D church's nave/side-chapel layout.
## Player spawns at the entrance; a couple of grunts in the nave. Camera follows.

const PlayerScript: Script = preload("res://scripts/3d/player_3d.gd")
const EnemyScript: Script = preload("res://scripts/3d/enemy_3d.gd")
const CameraRigScript: Script = preload("res://scripts/3d/camera_rig_3d.gd")
const QUINN: Resource = preload("res://data/characters/quinn.tres")
const GRUNT: Resource = preload("res://data/enemies/grunt.tres")

const STONE := Color(0.52, 0.50, 0.47)
const FLOOR_COL := Color(0.42, 0.36, 0.30)
const WALL_H := 3.0
const HALF_W := 6.0   # nave half-width (X)
const HALF_D := 8.5   # nave half-depth (Z); north = -Z (altar), south = +Z (entry)

var _shot_frames: int = -1

func _ready() -> void:
	_build_env()
	_floor(HALF_W * 2.0 + 1.0, HALF_D * 2.0 + 1.0)
	_walls()
	_furnish()
	var player := _spawn(PlayerScript, QUINN, Vector3(0.0, 0.1, HALF_D - 2.0))
	_camera(player)
	_spawn(EnemyScript, GRUNT, Vector3(-2.0, 0.1, 0.0))
	_spawn(EnemyScript, GRUNT, Vector3(2.5, 0.1, -2.0))
	if "--capture" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_args():
		_shot_frames = 18

func _build_env() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(40.0), 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.14, 0.13, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.58, 0.55)
	env.ambient_light_energy = 0.55
	we.environment = env
	add_child(we)

func _floor(w: float, d: float) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(w, 1.0, d)
	cs.shape = bs
	cs.position = Vector3(0, -0.5, 0)
	sb.add_child(cs)
	sb.add_child(_box_mesh(Vector3(w, 1.0, d), FLOOR_COL, Vector3(0, -0.5, 0)))
	add_child(sb)

func _walls() -> void:
	# Perimeter (north/east/west solid; south split for an entrance gap).
	_wall(Vector3(0, WALL_H * 0.5, -HALF_D), Vector3(HALF_W * 2.0, WALL_H, 0.4))      # north (behind altar)
	_wall(Vector3(-HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0))      # west
	_wall(Vector3(HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0))       # east
	_wall(Vector3(-HALF_W + 2.0, WALL_H * 0.5, HALF_D), Vector3(4.0, WALL_H, 0.4))    # south-left
	_wall(Vector3(HALF_W - 2.0, WALL_H * 0.5, HALF_D), Vector3(4.0, WALL_H, 0.4))     # south-right
	# Side-chapel divider (west alcove) — a short wall creating a second room feel.
	_wall(Vector3(-HALF_W + 2.2, WALL_H * 0.5, -2.0), Vector3(0.4, WALL_H, 5.0))

func _wall(center: Vector3, size: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	sb.add_child(_box_mesh(size, STONE, Vector3.ZERO))
	sb.position = center
	add_child(sb)

func _box_mesh(size: Vector3, col: Color, ofs: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 1.0
	bm.material = mat
	mi.mesh = bm
	mi.position = ofs
	return mi

func _furnish() -> void:
	# Altar + flanking candles at the north end.
	_prop("res://assets/models/props/altar.glb", Vector3(0, 0, -HALF_D + 1.6), 0.0)
	_prop("res://assets/models/props/candles.glb", Vector3(-1.6, 0, -HALF_D + 1.6), 0.0)
	_prop("res://assets/models/props/candles.glb", Vector3(1.6, 0, -HALF_D + 1.6), 0.0)
	# Two columns of pews facing the altar.
	for row: int in range(4):
		var z: float = -2.0 + float(row) * 2.4
		_prop("res://assets/models/props/pew.glb", Vector3(-2.4, 0, z), 0.0)
		_prop("res://assets/models/props/pew.glb", Vector3(2.4, 0, z), 0.0)

func _prop(path: String, pos: Vector3, yaw: float) -> void:
	var ps: PackedScene = load(path)
	if ps == null:
		return
	var n := ps.instantiate()
	n.position = pos
	n.rotation.y = yaw
	add_child(n)

func _spawn(scr: Script, res: Resource, pos: Vector3) -> CharacterBody3D:
	var b := CharacterBody3D.new()
	b.set_script(scr)
	b.set("data", res)
	b.position = pos
	add_child(b)
	return b

func _camera(target: Node3D) -> void:
	var cam := Camera3D.new()
	cam.set_script(CameraRigScript)
	cam.set("target", target)
	cam.current = true
	add_child(cam)

func _process(_delta: float) -> void:
	if _shot_frames < 0:
		return
	_shot_frames -= 1
	if _shot_frames == 0:
		get_viewport().get_texture().get_image().save_png("res://_arena3d_shot.png")
		print("SHOT_SAVED")
		get_tree().quit()
