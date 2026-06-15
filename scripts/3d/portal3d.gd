extends Area3D
## A portal for multi-phase / multi-floor levels. When the active duo body walks
## through it, it either re-frames the follow camera for the room (REFRAME),
## returns to the overworld (EXIT — the lobby door), or carries the duo up/down a
## STAIR to another floor region (teleport + reframe; floors live in separate world
## regions so the top-down camera never sees two floors at once). Built by Level3D's
## add_room_portal / add_exit_portal / add_stairwell. No class_name — preload()+untyped.

enum Kind { REFRAME, EXIT, STAIR }

var kind: int = Kind.REFRAME
var cam_dist: float = 8.0
var cam_elev: float = 50.0
var dest: Vector3 = Vector3.ZERO     # STAIR: where the duo lands
var locked: bool = false             # STAIR: blocked until the level unlocks it
var level: Node = null
var _busy: bool = false

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
	if level == null or _busy or not (b is CharacterBody3D and b.is_in_group("player3d")):
		return
	match kind:
		Kind.REFRAME:
			level.reframe_camera(cam_dist, cam_elev)
		Kind.EXIT:
			level.return_to_overworld()
		Kind.STAIR:
			if locked:
				if level.has_method("on_stair_locked"):
					level.on_stair_locked()
				return
			_busy = true   # both duo bodies cross — only carry once
			level.teleport_duo(dest)
			level.reframe_camera(cam_dist, cam_elev)
			get_tree().create_timer(0.6).timeout.connect(func() -> void: _busy = false)
