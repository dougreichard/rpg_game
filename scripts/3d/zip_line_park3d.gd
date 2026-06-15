extends Level3D
## Zip Line Park (3D) — Ethan + Ben. Ethan hacks the Mid Platform control panel to
## restore power; then Ben catches the High Platform release on a TIMING window —
## press G (Ben's Special) while the pulse reads OPEN. Lena warns from the landing.
## Enemy mix: a Grunt + two Runners. Win: enemies cleared + panel hacked + release timed.

const ETHAN := preload("res://data/characters/ethan.tres")
const BEN := preload("res://data/characters/ben.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const RUNNER := preload("res://data/enemies/runner.tres")

const PULSE_SPEED := 2.4
const PULSE_OPEN := 0.82           # window when pulse magnitude exceeds this
const FLOOR_COL := Color(0.18, 0.24, 0.20)
const WALL_COL := Color(0.24, 0.30, 0.26)
const HALF_W := 8.5
const HALF_D := 8.0
const WALL_H := 2.6
const PANEL_POS := Vector3(-4.0, 0.0, -HALF_D + 2.0)    # Mid Platform control panel
const RELEASE_POS := Vector3(4.0, 0.0, -HALF_D + 2.0)   # High Platform release
const LENA_POS := Vector3(0.0, 0.0, HALF_D - 3.0)
const REACH := 2.2

var _cleared := false
var _enemies_cleared := false
var _panel_hacked := false
var _release_timed := false
var _spawned := 0
var _pulse := 0.0
var _lena = null
var _panel_lights: Array = []
var _release_light: MeshInstance3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_pulse: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "zip_line"
	build_env(Color(0.06, 0.09, 0.10), Color(0.5, 0.55, 0.5), 0.6, 1.1)
	point_light(Vector3(0, 3.4, 0), Color(0.9, 1.0, 0.95), 2.0, 16.0)
	point_light(PANEL_POS + Vector3(0, 2.0, 0), Color(0.4, 0.7, 1.0), 1.4, 5.0)
	point_light(RELEASE_POS + Vector3(0, 2.0, 0), Color(1.0, 0.7, 0.4), 1.4, 5.0)
	floor_box(HALF_W * 2.0 + 1.0, HALF_D * 2.0 + 1.0, FLOOR_COL)
	_walls()
	_towers()
	_ziplines()
	_panel()
	_release()
	make_dialog()
	_build_hud()
	_lena = spawn_npc("congregant_f", LENA_POS, PI)
	var p := spawn_duo([ETHAN, BEN], Vector3(0.0, 0.1, HALF_D - 1.5))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _walls() -> void:
	wall(Vector3(0, WALL_H * 0.5, -HALF_D), Vector3(HALF_W * 2.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(-HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(-HALF_W + 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(HALF_W - 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)

const LANDING_POS := Vector3(-6.0, 0, HALF_D - 2.0)

func _towers() -> void:
	_tower(LANDING_POS, 2.2, Color(0.4, 0.5, 0.4))                          # Landing (off to the side)
	_tower(PANEL_POS + Vector3(0, 0, -0.6), 3.4, Color(0.35, 0.45, 0.55))  # Mid
	_tower(RELEASE_POS + Vector3(0, 0, -0.6), 4.6, Color(0.5, 0.45, 0.35)) # High

func _tower(pos: Vector3, h: float, col: Color) -> void:
	add_child(box_mesh(Vector3(2.0, 0.3, 2.0), col, pos + Vector3(0, 0.15, 0)))           # base pad
	for sx: float in [-0.8, 0.8]:
		for sz: float in [-0.8, 0.8]:
			add_child(box_mesh(Vector3(0.18, h, 0.18), col.darkened(0.2), pos + Vector3(sx, h * 0.5, sz)))  # legs
	add_child(box_mesh(Vector3(2.0, 0.2, 2.0), col.lightened(0.1), pos + Vector3(0, h, 0)))   # deck

func _ziplines() -> void:
	_cable(LANDING_POS + Vector3(0, 2.2, 0), PANEL_POS + Vector3(0, 3.4, -0.6))
	_cable(PANEL_POS + Vector3(0, 3.4, -0.6), RELEASE_POS + Vector3(0, 4.6, -0.6))

func _cable(a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5
	var line := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.03; cm.bottom_radius = 0.03; cm.height = a.distance_to(b)
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.1, 0.1, 0.1); mat.metallic = 0.5
	cm.material = mat; line.mesh = cm
	line.position = mid
	line.look_at_from_position(mid, b, Vector3.UP)
	line.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
	add_child(line)

func _panel() -> void:
	add_child(box_mesh(Vector3(1.0, 1.1, 0.5), Color(0.2, 0.2, 0.26), PANEL_POS + Vector3(0, 0.55, 0)))
	for i: int in range(3):
		var pip := box_mesh(Vector3(0.16, 0.06, 0.1), Color(0.85, 0.25, 0.2), PANEL_POS + Vector3(-0.3 + float(i) * 0.3, 1.0, 0.28), 1.2)
		add_child(pip)
		_panel_lights.append(pip)

func _release() -> void:
	add_child(box_mesh(Vector3(0.8, 1.0, 0.4), Color(0.26, 0.22, 0.18), RELEASE_POS + Vector3(0, 0.5, 0)))
	_release_light = box_mesh(Vector3(0.3, 0.3, 0.12), Color(0.6, 0.6, 0.2), RELEASE_POS + Vector3(0, 1.1, 0.22), 1.0)
	add_child(_release_light)

func _spawn_enemies() -> void:
	spawn_enemy(GRUNT, Vector3(0.0, 0.1, 0.5), "res://assets/models/enemies/grunt.glb"); _spawned += 1
	for spot: Vector3 in [Vector3(-2.5, 0.1, -1.0), Vector3(2.5, 0.1, -1.0)]:
		spawn_enemy(RUNNER, spot, "res://assets/models/enemies/runner.glb"); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_panel_hacked = GameManager.get_level_flag(location_id, "panel_hacked", false)
	_release_timed = GameManager.get_level_flag(location_id, "release_timed", false)
	if _panel_hacked: _set_panel_solved()
	if _release_timed and _release_light != null:
		((_release_light.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = Color(0.3, 0.95, 0.4)
	if _enemies_cleared and _panel_hacked and _release_timed:
		_win(false)

func _open() -> bool:
	return abs(sin(_pulse)) > PULSE_OPEN

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, LENA_POS, REACH): _talk_lena(char_name); return
	if char_name == "Ethan" and not _panel_hacked and near3(pp, PANEL_POS, REACH):
		_panel_hacked = true
		GameManager.set_level_flag(location_id, "panel_hacked", true)
		_set_panel_solved()
		_hud_hint.text = "Power restored! Now Ben catches the release window up top."
		Audio.play("special"); return
	if char_name == "Ben" and _panel_hacked and not _release_timed and near3(pp, RELEASE_POS, REACH):
		if _open():
			_release_timed = true
			GameManager.set_level_flag(location_id, "release_timed", true)
			((_release_light.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = Color(0.3, 0.95, 0.4)
			_hud_hint.text = "Perfect timing! The high line releases."
			Audio.play("special")
		else:
			_hud_hint.text = "Mistimed — wait for the window to read OPEN, then press G."
			Audio.play("hurt")
		return
	if char_name == "Ben" and not _panel_hacked and near3(pp, RELEASE_POS, REACH):
		_hud_hint.text = "The line's dead — Ethan must restore power at the Mid panel first."
	elif char_name != "Ethan" and not _panel_hacked and near3(pp, PANEL_POS, REACH):
		_hud_hint.text = "The control panel needs Ethan's hacking."

func _set_panel_solved() -> void:
	for pip in _panel_lights:
		var m := ((pip as MeshInstance3D).mesh as BoxMesh).material as StandardMaterial3D
		m.albedo_color = Color(0.3, 0.95, 0.4); m.emission = m.albedo_color

func _talk_lena(char_name: String) -> void:
	var tree: Dictionary
	if _enemies_cleared and _panel_hacked and _release_timed:
		tree = {"start": {"lines": ["\"Lines fully restored. Unusual technique on that timing window -- but it worked.\""]}}
	elif _panel_hacked:
		tree = {"start": {"lines": ["\"Ethan: control panel on the Mid Platform. Then Ben catches the timing window up top.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"Safety briefing: all riders clip in. Someone cut the release power -- lines are dead.\"",
			"\"Ethan: the control panel on the Mid Platform will restore power. Ben, once it's live the High Platform release opens a timed window -- watch the ring and press G when it pulses green.\""]}}
	open_dialog("Lena", Color(0.45, 0.55, 0.5), tree, char_name)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := make_hud_layer()
	_hud_goal = hud_label(cl, 24)
	_hud_pulse = hud_label(cl, 84, 26)
	_hud_hint = hud_label(cl, -70, 22, true)
	_hud_banner = hud_label(cl, 0, 40); _hud_banner.anchor_top = 0.5; _hud_banner.anchor_bottom = 0.5
	_hud_banner.visible = false

func _process(d: float) -> void:
	super._process(d)
	_pulse += d * PULSE_SPEED
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
	if not _cleared:
		var bits := []
		bits.append("riders " + ("OK" if _enemies_cleared else "..."))
		bits.append("panel " + ("OK" if _panel_hacked else "..."))
		bits.append("release " + ("OK" if _release_timed else "..."))
		_hud_goal.text = "Ethan hacks the Mid panel; Ben times the High release. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
		_update_pulse_hud()
	if not _cleared and _enemies_cleared and _panel_hacked and _release_timed:
		_win(true)

func _update_pulse_hud() -> void:
	if _release_timed or not _panel_hacked:
		_hud_pulse.text = ""
		return
	var mag: float = abs(sin(_pulse))
	var filled := int(round(mag * 10.0))
	var bar := "▮".repeat(filled) + "▯".repeat(10 - filled)
	if _open():
		_hud_pulse.text = "RELEASE WINDOW  [%s]  ● OPEN — press G!" % bar
		_hud_pulse.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		_hud_pulse.text = "RELEASE WINDOW  [%s]  ○ wait" % bar
		_hud_pulse.add_theme_color_override("font_color", UITheme.CREAM)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""; _hud_pulse.text = ""
	_hud_banner.text = "PARK ONLINE!\nThe lines run again."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
