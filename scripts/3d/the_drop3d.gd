extends Level3D
## The Drop (3D) — Evan + Ethan. A wooded touchdown clearing: Evan clears the
## landing-site wreckage blocking the way out, and Ethan hacks the parachute's
## jammed chute release tangled in the snag grove to the north. Rio, ex-crew,
## points to a marquee with Doug's name. Enemy mix: Grunt + Runner + a Brute.
## Win: enemies cleared + chute hacked + landing cleared.

const EVAN := preload("res://data/characters/evan.tres")
const ETHAN := preload("res://data/characters/ethan.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const RUNNER := preload("res://data/enemies/runner.tres")
const BRUTE := preload("res://data/enemies/brute.tres")

const FLOOR_COL := Color(0.16, 0.20, 0.13)
const WALL_COL := Color(0.14, 0.17, 0.11)
const HALF_W := 7.5
const HALF_D := 9.0
const WALL_H := 3.0
const WRECK_POS := Vector3(0.0, 0.0, 1.0)               # wreckage gating the clearing
const CHUTE_POS := Vector3(2.5, 0.0, -HALF_D + 2.2)     # jammed chute release in the grove
const RIO_POS := Vector3(-HALF_W + 2.0, 0.0, HALF_D - 3.0)
const REACH := 2.4

var _cleared := false
var _enemies_cleared := false
var _landing_cleared := false
var _chute_hacked := false
var _spawned := 0
var _rio = null
var _wreck: Node3D = null
var _chute_lights: Array = []
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "the_drop"
	build_env(Color(0.05, 0.08, 0.06), Color(0.5, 0.55, 0.45), 0.6, 1.0)
	point_light(Vector3(0, 4.0, 2.0), Color(0.7, 0.85, 0.7), 1.8, 18.0)
	point_light(CHUTE_POS + Vector3(0, 2.0, 0), Color(0.4, 0.8, 1.0), 1.4, 5.0)
	floor_box(HALF_W * 2.0 + 1.0, HALF_D * 2.0 + 1.0, FLOOR_COL)
	_tree_line()
	_walls()
	_parachute()
	_wreckage()
	_chute_release()
	make_dialog()
	_build_hud()
	_rio = spawn_npc("bellows", RIO_POS, deg_to_rad(-60))
	var p := spawn_duo([EVAN, ETHAN], Vector3(0.0, 0.1, HALF_D - 1.5))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _walls() -> void:
	wall(Vector3(0, WALL_H * 0.5, -HALF_D), Vector3(HALF_W * 2.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(-HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(-HALF_W + 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(HALF_W - 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)

func _tree_line() -> void:
	for spot: Vector3 in [Vector3(-5.5, 0, -3.0), Vector3(-3.0, 0, -6.0), Vector3(5.0, 0, -5.0),
			Vector3(-6.0, 0, 3.0), Vector3(6.0, 0, 2.0), Vector3(4.0, 0, 5.0)]:
		_pine(spot)

func _pine(pos: Vector3) -> void:
	add_child(box_mesh(Vector3(0.3, 1.2, 0.3), Color(0.25, 0.16, 0.10), pos + Vector3(0, 0.6, 0)))
	for i: int in range(3):
		var r: float = 1.0 - float(i) * 0.25
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.0; cm.bottom_radius = r; cm.height = 1.0
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.15, 0.34, 0.18)
		cm.material = mat; cone.mesh = cm; cone.position = pos + Vector3(0, 1.4 + float(i) * 0.6, 0)
		add_child(cone)

func _parachute() -> void:
	# a draped parachute canopy snagged in the grove (visual anchor for the chute)
	var canopy := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 1.6; sm.height = 1.6; sm.is_hemisphere = true
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.85, 0.5, 0.2); mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sm.material = mat; canopy.mesh = sm; canopy.position = CHUTE_POS + Vector3(0, 2.4, 0)
	add_child(canopy)

func _wreckage() -> void:
	_wreck = StaticBody3D.new()
	(_wreck as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(4.0, 1.6, 1.8); cs.shape = bs; cs.position = Vector3(0, 0.8, 0)
	_wreck.add_child(cs)
	for i: int in range(7):
		var r := box_mesh(Vector3(0.9, 0.7, 0.8), Color(0.3, 0.3, 0.32).darkened(randf() * 0.2),
			Vector3(randf_range(-1.6, 1.6), randf_range(0.3, 1.2), randf_range(-0.6, 0.6)))
		r.rotation = Vector3(randf() * 0.5, randf(), randf() * 0.5)
		_wreck.add_child(r)
	_wreck.position = WRECK_POS
	add_child(_wreck)

func _chute_release() -> void:
	add_child(box_mesh(Vector3(0.9, 1.0, 0.5), Color(0.2, 0.22, 0.24), CHUTE_POS + Vector3(0, 0.5, 0)))
	for i: int in range(3):
		var pip := box_mesh(Vector3(0.16, 0.06, 0.1), Color(0.9, 0.3, 0.25), CHUTE_POS + Vector3(-0.3 + float(i) * 0.3, 1.0, 0.28), 1.2)
		add_child(pip); _chute_lights.append(pip)

func _spawn_enemies() -> void:
	spawn_enemy(GRUNT, Vector3(-2.0, 0.1, -1.0), "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(RUNNER, Vector3(2.5, 0.1, -1.5), "res://assets/models/enemies/runner.glb"); _spawned += 1
	spawn_enemy(BRUTE, Vector3(0.0, 0.1, -3.0), "res://assets/models/enemies/grunt.glb", 1.45, Color(0.6, 0.55, 0.5)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_landing_cleared = GameManager.get_level_flag(location_id, "landing_cleared", false)
	_chute_hacked = GameManager.get_level_flag(location_id, "chute_hacked", false)
	if _landing_cleared: _clear_wreck(false)
	if _chute_hacked: _set_chute_solved()
	if _enemies_cleared and _landing_cleared and _chute_hacked:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, RIO_POS, REACH): _talk_rio(char_name); return
	if char_name == "Evan" and not _landing_cleared and near3(pp, WRECK_POS, REACH + 0.8):
		_landing_cleared = true
		GameManager.set_level_flag(location_id, "landing_cleared", true)
		_clear_wreck(true)
		_hud_hint.text = "Evan drags the wreckage clear — the way out opens."
		Audio.play("special"); return
	if char_name == "Ethan" and not _chute_hacked and near3(pp, CHUTE_POS, REACH):
		_chute_hacked = true
		GameManager.set_level_flag(location_id, "chute_hacked", true)
		_set_chute_solved()
		_hud_hint.text = "Ethan frees the jammed chute release."
		Audio.play("special"); return
	if char_name != "Evan" and not _landing_cleared and near3(pp, WRECK_POS, REACH + 0.8):
		_hud_hint.text = "The wreckage is too heavy — Evan can shift it."
	elif char_name != "Ethan" and not _chute_hacked and near3(pp, CHUTE_POS, REACH):
		_hud_hint.text = "The chute release needs Ethan's hacking."

func _clear_wreck(animate: bool) -> void:
	if animate:
		var tw := create_tween()
		tw.tween_property(_wreck, "position:y", -2.0, 0.6)
		tw.tween_callback(func() -> void: (_wreck as StaticBody3D).collision_layer = 0)
	else:
		_wreck.position.y = -2.0
		(_wreck as StaticBody3D).collision_layer = 0

func _set_chute_solved() -> void:
	for pip in _chute_lights:
		var m := ((pip as MeshInstance3D).mesh as BoxMesh).material as StandardMaterial3D
		m.albedo_color = Color(0.3, 0.95, 0.4); m.emission = m.albedo_color

func _talk_rio(char_name: String) -> void:
	var tree: Dictionary
	if _enemies_cleared and _landing_cleared and _chute_hacked:
		tree = {"start": {"lines": ["\"That's our way out. The marquee sign I saw before the drop -- it had his name on it. Move.\""]}}
	elif _landing_cleared or _chute_hacked:
		tree = {"start": {"lines": ["\"Evan clears the wreckage, Ethan hacks the jammed chute release -- both needed.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"Rio. I was crew until I saw the manifest -- I'm not their problem anymore.\"",
			"\"Evan: that wreckage has to move before we get out. Ethan: the chute release jammed on impact -- hack it in the snag grove north of here.\""]}}
	open_dialog("Rio", Color(0.4, 0.42, 0.36), tree, char_name)

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
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
	if not _cleared:
		var bits := []
		bits.append("crew " + ("OK" if _enemies_cleared else "..."))
		bits.append("wreckage " + ("OK" if _landing_cleared else "..."))
		bits.append("chute " + ("OK" if _chute_hacked else "..."))
		_hud_goal.text = "Clear the crew; Evan moves the wreckage, Ethan frees the chute. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
	if not _cleared and _enemies_cleared and _landing_cleared and _chute_hacked:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "LANDING CLEAR!\nThe marquee is next."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
