extends Level3D
## VR Escape Room (3D) — Quinn + Ethan. A cyber boot-chamber flanked by two
## corrupted simulation zones: Stage Alpha (warm amber glitch — Quinn patches the
## physics-glitch node) and Stage Beta (teal glitch — Ethan hacks the system
## console once Alpha is stable). ARIA, the virtual assistant, hovers as a glowing
## orb. Enemy mix: Grunts + a Sentry (glitchy). Win: enemies + glitch + system hack.

const QUINN := preload("res://data/characters/quinn.tres")
const ETHAN := preload("res://data/characters/ethan.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const SENTRY := preload("res://data/enemies/sentry.tres")

const FLOOR_COL := Color(0.07, 0.08, 0.12)
const WALL_COL := Color(0.12, 0.14, 0.22)
const ALPHA_COL := Color(0.35, 0.22, 0.10)
const BETA_COL := Color(0.08, 0.24, 0.26)
const NEON := Color(0.3, 0.8, 1.0)
const HALF_W := 9.0
const HALF_D := 8.0
const WALL_H := 3.2
const GLITCH_POS := Vector3(-5.0, 0.0, -HALF_D + 2.2)    # Stage Alpha node
const CONSOLE_POS := Vector3(5.0, 0.0, -HALF_D + 2.2)    # Stage Beta console
const ARIA_POS := Vector3(0.0, 0.0, -HALF_D + 2.4)
const REACH := 2.2

var _cleared := false
var _enemies_cleared := false
var _glitch_repaired := false
var _system_hacked := false
var _spawned := 0
var _aria_orb: MeshInstance3D = null
var _aria_bob := 0.0
var _glitch_node: MeshInstance3D = null
var _console_lights: Array = []
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "vr_room"
	build_env(Color(0.02, 0.02, 0.05), Color(0.35, 0.4, 0.55), 0.5, 0.7)
	point_light(Vector3(0, 3.4, 0), NEON, 1.8, 14.0)
	point_light(GLITCH_POS + Vector3(0, 2.0, 0), Color(1.0, 0.6, 0.2), 1.8, 6.0)
	point_light(CONSOLE_POS + Vector3(0, 2.0, 0), Color(0.2, 0.9, 0.9), 1.8, 6.0)
	floor_box(HALF_W * 2.0 + 1.0, HALF_D * 2.0 + 1.0, FLOOR_COL)
	_zone(GLITCH_POS, ALPHA_COL)   # Stage Alpha pad
	_zone(CONSOLE_POS, BETA_COL)   # Stage Beta pad
	_grid_lines()
	_walls()
	_glitch()
	_console()
	_aria()
	add_hiding_spot(Vector3(-6.5, 0, 3.0))   # unlit boot-chamber corner
	make_dialog()
	_build_hud()
	var p := spawn_duo([QUINN, ETHAN], Vector3(0.0, 0.1, HALF_D - 1.5))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _zone(center: Vector3, col: Color) -> void:
	add_child(box_mesh(Vector3(6.0, 0.06, 6.0), col, center + Vector3(0, 0.04, 1.5), 0.4))

func _grid_lines() -> void:
	for i: int in range(int(HALF_W)):
		var x: float = -HALF_W + 1.0 + float(i) * 2.0
		add_child(box_mesh(Vector3(0.04, 0.02, HALF_D * 2.0), NEON, Vector3(x, 0.06, 0), 0.8))

func _walls() -> void:
	wall(Vector3(0, WALL_H * 0.5, -HALF_D), Vector3(HALF_W * 2.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(-HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(-HALF_W + 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(HALF_W - 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)

func _glitch() -> void:
	# a jittering corrupted node (Quinn patches it)
	_glitch_node = box_mesh(Vector3(0.8, 0.8, 0.8), Color(1.0, 0.5, 0.2), GLITCH_POS + Vector3(0, 1.2, 0), 1.4)
	add_child(_glitch_node)
	add_child(box_mesh(Vector3(0.2, 1.2, 0.2), Color(0.5, 0.3, 0.15), GLITCH_POS + Vector3(0, 0.6, 0)))

func _console() -> void:
	add_child(box_mesh(Vector3(1.2, 1.0, 0.6), Color(0.1, 0.18, 0.2), CONSOLE_POS + Vector3(0, 0.5, 0)))
	var screen := box_mesh(Vector3(1.0, 0.7, 0.06), Color(0.1, 0.4, 0.42), CONSOLE_POS + Vector3(0, 1.3, 0.3), 0.7)
	screen.rotation.x = deg_to_rad(-12); add_child(screen)
	for i: int in range(3):
		var pip := box_mesh(Vector3(0.16, 0.06, 0.1), Color(0.9, 0.3, 0.25), CONSOLE_POS + Vector3(-0.3 + float(i) * 0.3, 0.95, 0.32), 1.2)
		add_child(pip); _console_lights.append(pip)

func _aria() -> void:
	_aria_orb = MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.35; sm.height = 0.7
	var mat := StandardMaterial3D.new()
	mat.albedo_color = NEON; mat.emission_enabled = true; mat.emission = NEON; mat.emission_energy_multiplier = 2.0
	sm.material = mat; _aria_orb.mesh = sm
	_aria_orb.position = ARIA_POS + Vector3(0, 1.6, 0)
	add_child(_aria_orb)

func _spawn_enemies() -> void:
	for spot: Vector3 in [Vector3(-2.0, 0.1, 1.0), Vector3(2.5, 0.1, 0.0)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(SENTRY, Vector3(0.0, 0.1, -2.0), "res://assets/models/enemies/grunt.glb", 1.0, Color(0.4, 0.9, 0.9)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_glitch_repaired = GameManager.get_level_flag(location_id, "glitch_repaired", false)
	_system_hacked = GameManager.get_level_flag(location_id, "system_hacked", false)
	if _glitch_repaired: _stabilise_glitch()
	if _system_hacked: _set_console_solved()
	if _enemies_cleared and _glitch_repaired and _system_hacked:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, ARIA_POS, REACH + 0.6): _talk_aria(char_name); return
	if char_name == "Quinn" and not _glitch_repaired and near3(pp, GLITCH_POS, REACH):
		_glitch_repaired = true
		GameManager.set_level_flag(location_id, "glitch_repaired", true)
		_stabilise_glitch()
		_hud_hint.text = "Quinn patches the physics-glitch node — Stage Alpha stabilises."
		Audio.play("special"); return
	if char_name == "Ethan" and not _system_hacked and near3(pp, CONSOLE_POS, REACH):
		if _glitch_repaired:
			_system_hacked = true
			GameManager.set_level_flag(location_id, "system_hacked", true)
			_set_console_solved()
			_hud_hint.text = "Ethan hacks the Stage Beta console — the simulation unlocks."
			Audio.play("special")
		else:
			_hud_hint.text = "Beta won't accept the hack until Alpha is stable — patch the glitch first."
		return
	if char_name != "Quinn" and not _glitch_repaired and near3(pp, GLITCH_POS, REACH):
		_hud_hint.text = "The glitch node needs Quinn's tools."
	elif char_name != "Ethan" and not _system_hacked and near3(pp, CONSOLE_POS, REACH):
		_hud_hint.text = "The system console needs Ethan's hacking."

func _stabilise_glitch() -> void:
	var m := (_glitch_node.mesh as BoxMesh).material as StandardMaterial3D
	m.albedo_color = Color(0.3, 0.95, 0.5); m.emission = Color(0.3, 0.95, 0.5)

func _set_console_solved() -> void:
	for pip in _console_lights:
		var m := ((pip as MeshInstance3D).mesh as BoxMesh).material as StandardMaterial3D
		m.albedo_color = Color(0.3, 0.95, 0.4); m.emission = m.albedo_color

func _talk_aria(char_name: String) -> void:
	var tree: Dictionary
	if _enemies_cleared and _glitch_repaired and _system_hacked:
		tree = {"start": {"lines": ["\"All stages nominal. Most test subjects don't make it past Beta. Well done.\""]}}
	elif _glitch_repaired or _system_hacked:
		tree = {"start": {"lines": ["\"Status: Quinn patches Stage Alpha first, then Ethan hacks Stage Beta.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"ARIA -- virtual assistant. Alert: two simulation stages are corrupted.\"",
			"\"Quinn: Stage Alpha has a physics-glitch node -- your tools can patch it. Ethan: Stage Beta's system console needs a direct hack once Alpha is stable.\""]}}
	open_dialog("ARIA", NEON, tree, char_name)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := make_hud_layer()
	_hud_goal = hud_label(cl, 24)
	_hud_hint = hud_label(cl, -70, 22, true)
	_hud_banner = hud_label(cl, 0, 40); _hud_banner.anchor_top = 0.5; _hud_banner.anchor_bottom = 0.5
	_hud_banner.visible = false

func _process(d: float) -> void:
	super._process(d)
	# ARIA hovers; the glitch node jitters until patched
	_aria_bob += d
	if _aria_orb != null:
		_aria_orb.position.y = ARIA_POS.y + 1.6 + 0.15 * sin(_aria_bob * 2.0)
	if _glitch_node != null and not _glitch_repaired:
		_glitch_node.position = GLITCH_POS + Vector3(randf_range(-0.05, 0.05), 1.2 + randf_range(-0.05, 0.05), randf_range(-0.05, 0.05))
		_glitch_node.rotation.y += d * 3.0
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
	if not _cleared:
		var bits := []
		bits.append("threats " + ("OK" if _enemies_cleared else "..."))
		bits.append("alpha " + ("OK" if _glitch_repaired else "..."))
		bits.append("beta " + ("OK" if _system_hacked else "..."))
		_hud_goal.text = "Quinn patches Stage Alpha, then Ethan hacks Stage Beta. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
	if not _cleared and _enemies_cleared and _glitch_repaired and _system_hacked:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "SIMULATION CLEARED!\nAll stages nominal."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
