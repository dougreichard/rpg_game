extends Node3D
## Minimal 3D test arena for the migration vertical slice: ground + warm lighting +
## a 3/4 follow camera + a Player3D. Validates mesh import, camera, and movement in
## true 3D before the church environment + combat are layered on.
## Run windowed with --capture to save a screenshot then quit (headless can't render).

const PlayerScript: Script = preload("res://scripts/3d/player_3d.gd")
const EnemyScript: Script = preload("res://scripts/3d/enemy_3d.gd")
const CameraRigScript: Script = preload("res://scripts/3d/camera_rig_3d.gd")
const QUINN: Resource = preload("res://data/characters/quinn.tres")
const GRUNT: Resource = preload("res://data/enemies/grunt.tres")

var _shot_frames: int = -1

func _ready() -> void:
	_build_world()
	var player := _build_player()
	_build_camera(player)
	_build_enemy(Vector3(2.5, 0.1, -2.5))
	if "--capture" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_args():
		_shot_frames = 18  # let a few frames render, then screenshot + quit

func _build_world() -> void:
	# Ground: a big box (collision + visual) in a warm Synty-ish tone.
	var ground := StaticBody3D.new()
	var gcol := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(40.0, 1.0, 40.0)
	gcol.shape = gbox
	gcol.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(gcol)
	var gmesh := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(40.0, 1.0, 40.0)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.46, 0.42, 0.34)
	gmat.roughness = 1.0
	pm.material = gmat
	gmesh.mesh = pm
	gmesh.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(gmesh)
	add_child(ground)
	# Light + warm environment.
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(35.0), 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.62, 0.70)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.62, 0.58)
	env.ambient_light_energy = 0.5
	we.environment = env
	add_child(we)

func _build_player() -> CharacterBody3D:
	var p := CharacterBody3D.new()
	p.set_script(PlayerScript)
	p.set("data", QUINN)
	p.position = Vector3(0.0, 0.1, 0.0)
	add_child(p)
	return p

func _build_enemy(pos: Vector3) -> void:
	var e := CharacterBody3D.new()
	e.set_script(EnemyScript)
	e.set("data", GRUNT)
	e.position = pos
	add_child(e)

func _build_camera(target: Node3D) -> void:
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
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://_arena3d_shot.png")
		print("SHOT_SAVED")
		get_tree().quit()
