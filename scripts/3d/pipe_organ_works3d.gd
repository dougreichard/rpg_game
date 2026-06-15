extends Level3D
## Bellows & Sons Pipe Organ Works — first migrated combat level (Layer 1: the 3D
## environment + combat). A workshop hall with a pipe-organ centerpiece (built from
## primitives), a manager's office alcove, industrial dressing, and Grunts + a Runner.
## The organ-repair puzzle, loot, Mr. Bellows' dialog + secret passage come next.

const QUINN: Resource = preload("res://data/characters/quinn.tres")
const GRUNT: Resource = preload("res://data/enemies/grunt.tres")
const RUNNER: Resource = preload("res://data/enemies/runner.tres")

const FLOOR_COL := Color(0.30, 0.27, 0.24)
const WALL_COL := Color(0.40, 0.37, 0.34)
const HALL_W := 9.0    # half-width X
const HALL_D := 7.0    # half-depth Z (north -Z = organ, south +Z = entry)
const WALL_H := 3.2

func _build_level() -> void:
	build_env(Color(0.10, 0.10, 0.12), Color(0.55, 0.50, 0.44), 0.5, 1.0)
	point_light(Vector3(0, 3.0, -3.0), Color(1.0, 0.85, 0.6), 3.0, 12.0)   # over the organ
	point_light(Vector3(-6.5, 2.6, 4.0), Color(0.9, 0.85, 0.7), 1.6, 7.0)  # office
	floor_box(HALL_W * 2.0 + 1.0, HALL_D * 2.0 + 1.0, FLOOR_COL)
	_walls()
	_organ()
	_dressing()
	_office()
	spawn_player(QUINN, Vector3(0.0, 0.1, HALL_D - 1.5))
	spawn_enemy(GRUNT, Vector3(-2.5, 0.1, -1.0), "res://assets/models/enemies/grunt.glb")
	spawn_enemy(GRUNT, Vector3(3.0, 0.1, 0.0), "res://assets/models/enemies/grunt.glb")
	spawn_enemy(RUNNER, Vector3(0.5, 0.1, -3.0), "res://assets/models/enemies/runner.glb")

func _walls() -> void:
	wall(Vector3(0, WALL_H * 0.5, -HALL_D), Vector3(HALL_W * 2.0, WALL_H, 0.4), WALL_COL)        # north
	wall(Vector3(-HALL_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALL_D * 2.0), WALL_COL)        # west
	wall(Vector3(HALL_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALL_D * 2.0), WALL_COL)         # east
	wall(Vector3(-HALL_W + 2.5, WALL_H * 0.5, HALL_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)      # south-left
	wall(Vector3(HALL_W - 2.5, WALL_H * 0.5, HALL_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)       # south-right (entry gap)
	# office divider (west alcove)
	wall(Vector3(-HALL_W + 3.0, WALL_H * 0.5, 2.5), Vector3(0.4, WALL_H, 4.0), WALL_COL)

# Pipe organ built from primitives: a wooden case + a row of metal pipes of varying
# height + a keyboard console. Recognisable as the workshop's centrepiece.
func _organ() -> void:
	var base_z := -HALL_D + 1.2
	var brass := Color(0.72, 0.6, 0.32)
	var wood := Color(0.34, 0.22, 0.14)
	# case / backboard
	add_child(box_mesh(Vector3(5.0, 2.2, 0.6), wood, Vector3(0, 1.1, base_z - 0.4)))
	# pipes
	for i: int in range(11):
		var x: float = -2.0 + float(i) * 0.4
		var h: float = 1.4 + 0.9 * sin(float(i) * 0.9) + (0.6 if i % 2 == 0 else 0.0)
		var pipe := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.14; cm.bottom_radius = 0.14; cm.height = h
		var mat := StandardMaterial3D.new()
		mat.albedo_color = brass; mat.metallic = 0.6; mat.roughness = 0.35
		cm.material = mat
		pipe.mesh = cm
		pipe.position = Vector3(x, 1.4 + h * 0.5, base_z)
		add_child(pipe)
	# console / keyboard shelf
	add_child(box_mesh(Vector3(2.4, 0.5, 0.7), wood, Vector3(0, 0.9, base_z + 0.7)))
	add_child(box_mesh(Vector3(2.2, 0.08, 0.4), Color(0.92, 0.9, 0.85), Vector3(0, 1.16, base_z + 0.75)))

func _dressing() -> void:
	prop("res://assets/models/props/shelf.glb", Vector3(HALL_W - 0.8, 0, -3.0), deg_to_rad(-90))
	prop("res://assets/models/props/shelf.glb", Vector3(HALL_W - 0.8, 0, -0.5), deg_to_rad(-90))
	prop("res://assets/models/props/barrel.glb", Vector3(HALL_W - 1.4, 0, 3.5))
	prop("res://assets/models/props/barrel.glb", Vector3(HALL_W - 2.1, 0, 3.7))
	prop("res://assets/models/props/pipe_small.glb", Vector3(-HALL_W + 0.6, 2.4, -2.0), 0.0)

func _office() -> void:
	prop("res://assets/models/props/desk.glb", Vector3(-HALL_W + 1.4, 0, 4.2), deg_to_rad(90))
	prop("res://assets/models/props/shelf.glb", Vector3(-HALL_W + 0.8, 0, 1.6), deg_to_rad(90))
