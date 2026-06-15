extends Node3D
## Active-duo controller — owns two Player3D bodies (both on screen). Player 1 drives
## the ACTIVE body; the standby either follows (single-player AI) or, once any P2
## input is seen, becomes player-2 controlled (local co-op) — matching the 2D duo.
## Swap (Tab) flips which body is active. Exposes the active body's position/name/
## special so levels treat the duo like a single "player".

signal special_used(character_name: String)

const PlayerScript: Script = preload("res://scripts/3d/player_3d.gd")
# Player3D.Mode int values: ACTIVE=0, STANDBY_AI=1, STANDBY_P2=2
const M_ACTIVE := 0
const M_AI := 1
const M_P2 := 2
const P2_ACTIONS := ["p2_move_left", "p2_move_right", "p2_move_up", "p2_move_down",
	"p2_attack", "p2_special"]

var bodies: Array = []
var active: int = 0
var coop: bool = false
var camera = null

func setup(datas: Array, pos: Vector3, cam, parent: Node) -> void:
	camera = cam
	for i in datas.size():
		var body := CharacterBody3D.new()
		body.set_script(PlayerScript)
		body.set("data", datas[i])
		body.position = pos + Vector3(float(i) * 1.3, 0.0, 0.0)
		parent.add_child(body)
		body.special_used.connect(_forward)
		bodies.append(body)
	_apply_roles()
	if camera != null and not bodies.is_empty():
		camera.set("target", bodies[active])

func _apply_roles() -> void:
	for i in bodies.size():
		if i == active:
			bodies[i].mode = M_ACTIVE
			bodies[i].follow_target = null
		else:
			bodies[i].mode = M_P2 if coop else M_AI
			bodies[i].follow_target = bodies[active]

func _process(_d: float) -> void:
	if bodies.size() > 1:
		if not coop and _p2_pressed():
			coop = true
			_apply_roles()
		if Input.is_action_just_pressed("swap"):
			active = (active + 1) % bodies.size()
			_apply_roles()
			if camera != null:
				camera.set("target", bodies[active])
			Audio.play("swap")
	if not bodies.is_empty():
		global_position = bodies[active].global_position

func _p2_pressed() -> bool:
	for a: String in P2_ACTIONS:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return false

func _forward(character_name: String) -> void:
	special_used.emit(character_name)

func active_name() -> String:
	return bodies[active].active_name() if not bodies.is_empty() else "Quinn"

func duo_names() -> Array:
	var names: Array = []
	for b in bodies:
		names.append(b.active_name())
	while names.size() < 2:
		names.append("Quinn")
	return names

func set_input_locked(v: bool) -> void:
	for b in bodies:
		b.set_input_locked(v)
