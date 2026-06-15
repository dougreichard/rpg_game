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

const BIES_SLOWDOWN := 0.4
const BIES_DURATION := 5.0
const REVIVE_RADIUS := 2.0      # metres (~48 px)
const REVIVE_HOLD := 1.5

var bodies: Array = []
var active: int = 0
var coop: bool = false
var camera = null
var _bies_t: float = 0.0
var _game_over: bool = false
var _go_layer: CanvasLayer = null

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

func _process(d: float) -> void:
	if _game_over:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return
	_tick_bies(d)
	_tick_revive(d)
	if _game_over:
		return
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

# Co-op revive: stand the upright teammate near a downed one for REVIVE_HOLD to
# revive them at half HP. Both down → game over. If the active body goes down,
# control snaps to the upright partner so the player can go revive them.
func _tick_revive(d: float) -> void:
	if bodies.size() < 2:
		if not bodies.is_empty() and bodies[0].is_down():
			_trigger_game_over()
		return
	if bodies[active].is_down() and not bodies[1 - active].is_down():
		active = 1 - active
		_apply_roles()
		if camera != null:
			camera.set("target", bodies[active])
	var down_count := 0
	for b in bodies:
		if b.is_down():
			down_count += 1
	if down_count >= bodies.size():
		_trigger_game_over()
		return
	for i in bodies.size():
		var downed = bodies[i]
		var helper = bodies[1 - i]
		if downed.is_down() and not helper.is_down():
			if downed.global_position.distance_to(helper.global_position) <= REVIVE_RADIUS:
				downed.revive_progress += d
				if downed.revive_progress >= REVIVE_HOLD:
					downed.revive()
					Audio.play("special")
			else:
				downed.revive_progress = maxf(downed.revive_progress - d * 2.0, 0.0)

func _trigger_game_over() -> void:
	if _game_over:
		return
	_game_over = true
	_go_layer = CanvasLayer.new(); _go_layer.layer = 40
	var bg := ColorRect.new(); bg.color = Color(0.05, 0.02, 0.02, 0.82)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT); _go_layer.add_child(bg)
	_go_label("BOTH DOWN", 270, 60, Color(0.9, 0.3, 0.25))
	_go_label("Press Enter to retry", 360, 28, UITheme.CREAM)
	get_tree().current_scene.add_child(_go_layer)
	Audio.play("defeat")

func _go_label(text: String, y: float, size: int, col: Color) -> void:
	var l := Label.new()
	l.text = text
	l.anchor_right = 1.0; l.offset_top = y; l.offset_bottom = y + size + 12
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UITheme.font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	_go_layer.add_child(l)

# Bies Mode — bullet time. The active body spends a full charge to slow the
# world (Engine.time_scale) for BIES_DURATION real seconds.
func _tick_bies(d: float) -> void:
	if _bies_t > 0.0:
		_bies_t -= d / maxf(Engine.time_scale, 0.01)   # count real time while slowed
		if _bies_t <= 0.0:
			Engine.time_scale = 1.0
			GameManager.bies_ended.emit()
		return
	if bodies.is_empty():
		return
	if Input.is_action_just_pressed("bies_mode") and bodies[active].bies_charge >= 1.0:
		bodies[active].bies_charge = 0.0
		_bies_t = BIES_DURATION
		Engine.time_scale = BIES_SLOWDOWN
		Audio.play("bies")
		GameManager.bies_activated.emit()

func bies_charge() -> float:
	return bodies[active].bies_charge if not bodies.is_empty() else 0.0

# Carry the whole duo to a new spot (stairwell between floor regions).
func teleport_to(pos: Vector3) -> void:
	for i in bodies.size():
		bodies[i].global_position = pos + Vector3(float(i) * 1.1, 0.0, 0.0)
	if not bodies.is_empty():
		global_position = bodies[active].global_position
		if camera != null:
			camera.set("global_position", bodies[active].global_position + camera.get("_offset"))

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
