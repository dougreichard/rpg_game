extends Area3D
## A room portal for multi-phase levels. When the active duo body walks through it,
## it either re-frames the follow camera for the room being entered (REFRAME) or
## returns to the overworld (EXIT — the lobby door). Built by Level3D.add_room_portal
## / add_exit_portal. No class_name — preload()+untyped.

enum Kind { REFRAME, EXIT }

var kind: int = Kind.REFRAME
var cam_dist: float = 8.0
var cam_elev: float = 50.0
var level: Node = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = Combat3D.L_PLAYER
	monitoring = true
	body_entered.connect(_on_body)

func setup(size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = size
	cs.shape = bs; cs.position = Vector3(0, size.y * 0.5, 0)
	add_child(cs)

func _on_body(b: Node) -> void:
	if not (b is CharacterBody3D and b.is_in_group("player3d")):
		return
	if level == null:
		return
	if kind == Kind.REFRAME:
		level.reframe_camera(cam_dist, cam_elev)
	elif kind == Kind.EXIT:
		level.return_to_overworld()
