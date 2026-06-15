extends Level3D
## The Recording Studio (3D) — Quinn + Ben fight through a studio that's been
## "scrambled" while Ethan is sealed inside the glass recording booth. Ben tunes
## the soundboard console (his ear for pitch), which slides the booth's glass door
## up and frees Ethan (unlocks him). Ethan calls directions from behind the glass
## via speech bubbles, then talks once freed. Enemy mix: Grunts + Runners.

const QUINN := preload("res://data/characters/quinn.tres")
const BEN := preload("res://data/characters/ben.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const RUNNER := preload("res://data/enemies/runner.tres")
const TicketEthanItem: ItemData = preload("res://data/items/ticket_ethan.tres")

const FLOOR_COL := Color(0.20, 0.19, 0.23)
const WALL_COL := Color(0.27, 0.25, 0.30)
const HALF_W := 7.0
const HALF_D := 8.0
const WALL_H := 3.2
const CONSOLE_POS := Vector3(0.0, 0.0, -1.0)
const BOOTH_MIN := Vector3(-HALF_W + 0.4, 0.0, -HALF_D + 0.4)  # back-left corner booth
const ETHAN_POS := Vector3(-HALF_W + 2.4, 0.0, -HALF_D + 2.0)
const DOOR_POS := Vector3(-HALF_W + 4.4, 0.0, -HALF_D + 2.6)
const REACH := 2.2

const ETHAN_QUIPS := [
	"Every channel's inverted -- retune it from the console!",
	"Runners flank -- don't let them split you up!",
	"The door's locked from this side. The console, Ben!",
	"Two hours under a mixing desk. Two HOURS.",
]

var _cleared := false
var _enemies_cleared := false
var _console_tuned := false
var _ethan_freed := false
var _spawned := 0
var _ethan = null
var _door: Node3D = null
var _console_lights: Array = []
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "recording_studio"
	build_env(Color(0.05, 0.05, 0.07), Color(0.45, 0.43, 0.5), 0.5, 0.9)
	point_light(Vector3(0, 3.0, 0.0), Color(0.8, 0.75, 0.9), 2.0, 13.0)
	point_light(ETHAN_POS + Vector3(0, 2.6, 0), Color(0.5, 0.9, 0.8), 1.8, 6.0)  # booth glow
	point_light(CONSOLE_POS + Vector3(0, 1.6, 0.5), Color(0.4, 0.7, 1.0), 1.4, 4.0)  # console glow
	floor_box(HALF_W * 2.0 + 1.0, HALF_D * 2.0 + 1.0, FLOOR_COL)
	_walls()
	_acoustic_foam()
	_booth()
	_console()
	_mic_stand(Vector3(3.5, 0, -3.0))
	_mic_stand(Vector3(4.5, 0, 1.5))
	make_dialog()
	_build_hud()
	_ethan = spawn_npc("ethan", ETHAN_POS, deg_to_rad(120), ETHAN_QUIPS)
	_ethan.set("yell_min", 4.0); _ethan.set("yell_max", 8.0)
	var p := spawn_duo([QUINN, BEN], Vector3(0.0, 0.1, HALF_D - 1.5))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _walls() -> void:
	wall(Vector3(0, WALL_H * 0.5, -HALF_D), Vector3(HALF_W * 2.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(-HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(-HALF_W + 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(HALF_W - 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)

func _acoustic_foam() -> void:
	# wedge-foam strips along the side walls (alternating dark squares)
	for i: int in range(6):
		var z: float = -6.0 + float(i) * 2.0
		var c: Color = Color(0.13, 0.12, 0.15) if i % 2 == 0 else Color(0.18, 0.17, 0.2)
		add_child(box_mesh(Vector3(0.12, 1.6, 1.4), c, Vector3(HALF_W - 0.25, 1.8, z)))

func _booth() -> void:
	# glass-walled booth in the back-left corner; the front-facing pane is the door.
	var gx := -HALF_W + 3.4   # front glass wall runs along here in Z
	_glass(Vector3(gx, 1.4, -HALF_D + 2.6), Vector3(0.12, 2.8, 4.0))         # side glass (along Z)
	_glass(Vector3(-HALF_W + 1.5, 1.4, -HALF_D + 4.6), Vector3(3.8, 2.8, 0.12))  # front glass (along X)
	# booth floor accent
	add_child(box_mesh(Vector3(3.6, 0.05, 3.8), Color(0.16, 0.20, 0.22), Vector3(-HALF_W + 1.9, 0.04, -HALF_D + 2.6)))
	# sliding glass door (rises into ceiling when console tuned)
	_door = _glass(DOOR_POS, Vector3(0.12, 2.8, 1.8))

func _glass(pos: Vector3, size: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.75, 0.85, 0.22)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.4; mat.roughness = 0.1
	bm.material = mat; mi.mesh = bm; mi.position = pos
	add_child(mi)
	return mi

func _console() -> void:
	prop("res://assets/models/props/desk.glb", CONSOLE_POS, 0.0)
	# tilted console surface with channel lights
	var surf := box_mesh(Vector3(2.4, 0.08, 0.9), Color(0.14, 0.14, 0.17), CONSOLE_POS + Vector3(0, 1.0, 0))
	surf.rotation.x = deg_to_rad(-18)
	add_child(surf)
	for i: int in range(8):
		var x: float = -1.0 + float(i) * 0.28
		var lite := box_mesh(Vector3(0.12, 0.04, 0.12), Color(0.9, 0.25, 0.2), CONSOLE_POS + Vector3(x, 1.12, 0.0), 1.5)
		lite.rotation.x = deg_to_rad(-18)
		add_child(lite)
		_console_lights.append(lite)

func _mic_stand(pos: Vector3) -> void:
	var pole := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.03; cm.bottom_radius = 0.03; cm.height = 1.7
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.1, 0.1, 0.12); mat.metallic = 0.6
	cm.material = mat; pole.mesh = cm; pole.position = pos + Vector3(0, 0.85, 0)
	add_child(pole)
	add_child(box_mesh(Vector3(0.18, 0.12, 0.12), Color(0.08, 0.08, 0.1), pos + Vector3(0, 1.6, 0)))

func _spawn_enemies() -> void:
	spawn_enemy(GRUNT, Vector3(2.5, 0.1, 1.0), "res://assets/models/enemies/grunt.glb"); _spawned += 1
	for spot: Vector3 in [Vector3(-2.0, 0.1, 2.0), Vector3(3.0, 0.1, -2.0)]:
		spawn_enemy(RUNNER, spot, "res://assets/models/enemies/runner.glb"); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_console_tuned = GameManager.get_level_flag(location_id, "console_tuned", false)
	if _console_tuned:
		_open_door(false); _set_console_solved(); _ethan_freed = true; _ethan.set("quips", [])
	if _enemies_cleared and _console_tuned:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if char_name == "Ben" and not _console_tuned and near3(pp, CONSOLE_POS, REACH):
		_tune_console(char_name); return
	if near3(pp, ETHAN_POS, REACH + 1.2):
		_talk_ethan(char_name); return
	if not _console_tuned and near3(pp, CONSOLE_POS, REACH):
		_hud_hint.text = "The soundboard needs Ben's ear — swap to Ben."

func _tune_console(char_name: String) -> void:
	_console_tuned = true
	_ethan_freed = true
	GameManager.set_level_flag(location_id, "console_tuned", true)
	_set_console_solved()
	_open_door(true)
	GameManager.grant_item(char_name, TicketEthanItem.id)
	_ethan.set("quips", [])
	_ethan.call("say", "Door's opening! Finally!")
	_hud_hint.text = "Ben re-tunes the board. The booth slides open — Ethan's free! (Found Ethan's ticket)"
	Audio.play("special")

func _set_console_solved() -> void:
	for lite in _console_lights:
		((lite as MeshInstance3D).mesh as BoxMesh).material.albedo_color = Color(0.3, 0.95, 0.4)
		((lite as MeshInstance3D).mesh as BoxMesh).material.emission = Color(0.3, 0.95, 0.4)

func _open_door(animate: bool) -> void:
	var to := DOOR_POS + Vector3(0, WALL_H, 0)
	if animate:
		create_tween().tween_property(_door, "position", to, 0.6)
	else:
		_door.position = to

func _talk_ethan(char_name: String) -> void:
	var tree: Dictionary
	if _ethan_freed:
		tree = {"start": {"lines": [
			"\"Door's opening! I've been crouched under this mixing desk for two hours.\"",
			"\"Their whole setup was reversed on purpose. Someone knew what they were doing.\""]}}
	elif _enemies_cleared:
		tree = {"start": {"lines": ["\"Ben -- the console! Get to it. The door's locked from this side until it's fixed.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"Quinn! Ben! Can you hear me?! The soundboard is scrambled -- every channel's inverted.\"",
			"\"Ben, retune it from the console. The runners like to flank -- don't let them split you up.\""]}}
	open_dialog("Ethan", Color(0.38, 0.52, 0.45), tree, char_name)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := make_hud_layer()
	_hud_goal = hud_label(cl, 24)
	_hud_goal.text = "Clear the studio; Ben tunes the soundboard to free Ethan from the booth. (G interact, Tab swap)"
	_hud_hint = hud_label(cl, -70, 22, true)
	_hud_banner = hud_label(cl, 0, 40); _hud_banner.anchor_top = 0.5; _hud_banner.anchor_bottom = 0.5
	_hud_banner.visible = false

func _process(_d: float) -> void:
	super._process(_d)
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
		_hud_hint.text = "Studio clear! Bring Ben to the soundboard console."
		if _ethan != null and not _ethan_freed:
			_ethan.call("say", "Now the console, Ben!")
	if not _cleared and _enemies_cleared and _console_tuned:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "STUDIO CLEARED!\nEthan joins the crew!"
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
