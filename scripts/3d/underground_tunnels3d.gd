extends Level3D
## The Underground Tunnels (3D) — Evan + Ethan. Evan forces the west rubble; Ethan
## hacks the east hatch in three passes (multi-step gate, 3 pips). Cyrus maintains
## the tunnels. A lantern lights the dark; a rusty key opens a shortcut door (an
## instant exit). Enemy mix: Grunts + a Runner on patrol.

const EVAN := preload("res://data/characters/evan.tres")
const ETHAN := preload("res://data/characters/ethan.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const RUNNER := preload("res://data/enemies/runner.tres")
const LanternItem: ItemData = preload("res://data/items/pocket_lantern.tres")

const HATCH_PRESSES_REQUIRED := 3
const FLOOR_COL := Color(0.16, 0.15, 0.14)
const WALL_COL := Color(0.22, 0.21, 0.19)
const HALF_W := 9.0
const HALF_D := 7.5
const WALL_H := 2.8
const RUBBLE_POS := Vector3(-HALF_W + 1.6, 0.0, 0.0)
const HATCH_POS := Vector3(HALF_W - 1.6, 0.0, 0.0)
const CYRUS_POS := Vector3(0.0, 0.0, -HALF_D + 1.6)
const LANTERN_POS := Vector3(0.0, 0.0, 2.5)
const REACH := 2.2

var _cleared := false
var _enemies_cleared := false
var _rubble_cleared := false
var _hatch_progress := 0
var _spawned := 0
var _cyrus = null
var _rubble: Node3D = null
var _hatch_pips: Array = []
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "underground"
	build_env(Color(0.03, 0.03, 0.04), Color(0.30, 0.30, 0.34), 0.35, 0.45)  # dim
	point_light(Vector3(0, 2.4, 0), Color(0.7, 0.7, 0.85), 1.2, 9.0)
	point_light(CYRUS_POS + Vector3(0, 2.0, 0), Color(1.0, 0.7, 0.4), 1.4, 5.0)  # Cyrus's work lamp
	floor_box(HALF_W * 2.0 + 1.0, HALF_D * 2.0 + 1.0, FLOOR_COL)
	_walls()
	_pipes()
	_rubble_pile()
	_hatch()
	_lantern_pickup()
	make_dialog()
	_build_hud()
	_cyrus = spawn_npc("bellows", CYRUS_POS, PI)
	var p := spawn_duo([EVAN, ETHAN], Vector3(0.0, 0.1, HALF_D - 1.5))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _walls() -> void:
	wall(Vector3(0, WALL_H * 0.5, -HALF_D), Vector3(HALF_W * 2.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(0, WALL_H * 0.5, HALF_D), Vector3(HALF_W * 2.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(-HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	# arched rib supports across the tunnel
	for x: float in [-5.0, -2.0, 2.0, 5.0]:
		add_child(box_mesh(Vector3(0.3, WALL_H, 0.3), WALL_COL.lightened(0.05), Vector3(x, WALL_H * 0.5, -HALF_D + 0.5)))
		add_child(box_mesh(Vector3(0.3, WALL_H, 0.3), WALL_COL.lightened(0.05), Vector3(x, WALL_H * 0.5, HALF_D - 0.5)))

func _pipes() -> void:
	# pipes running along the ceiling line
	for z: float in [-3.0, 3.0]:
		var pipe := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.12; cm.bottom_radius = 0.12; cm.height = HALF_W * 2.0
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.3, 0.28, 0.24); mat.metallic = 0.5
		cm.material = mat; pipe.mesh = cm; pipe.rotation.z = deg_to_rad(90); pipe.position = Vector3(0, WALL_H - 0.3, z)
		add_child(pipe)

func _rubble_pile() -> void:
	_rubble = StaticBody3D.new()
	(_rubble as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(2.0, 1.8, 3.0); cs.shape = bs; cs.position = Vector3(0, 0.9, 0)
	_rubble.add_child(cs)
	for i: int in range(9):
		var r := box_mesh(Vector3(0.7, 0.6, 0.7), Color(0.28, 0.26, 0.22).darkened(randf() * 0.2),
			Vector3(randf_range(-0.7, 0.7), randf_range(0.3, 1.5), randf_range(-1.2, 1.2)))
		r.rotation = Vector3(randf(), randf(), randf())
		_rubble.add_child(r)
	_rubble.position = RUBBLE_POS
	add_child(_rubble)

func _hatch() -> void:
	add_child(box_mesh(Vector3(1.6, 0.1, 1.6), Color(0.3, 0.3, 0.34), HATCH_POS + Vector3(0, 0.06, 0)))
	add_child(box_mesh(Vector3(1.2, 0.25, 1.2), Color(0.4, 0.4, 0.45), HATCH_POS + Vector3(0, 0.2, 0)))  # hatch lid
	for i: int in range(HATCH_PRESSES_REQUIRED):
		var pip := box_mesh(Vector3(0.18, 0.06, 0.18), Color(0.8, 0.25, 0.2), HATCH_POS + Vector3(-0.4 + float(i) * 0.4, 0.5, 0), 1.0)
		add_child(pip)
		_hatch_pips.append(pip)

func _lantern_pickup() -> void:
	var box := box_mesh(Vector3(0.4, 0.5, 0.4), Color(0.8, 0.7, 0.3), LANTERN_POS + Vector3(0, 0.25, 0), 0.8)
	box.set_meta("lantern", true)
	add_child(box)

func _spawn_enemies() -> void:
	for spot: Vector3 in [Vector3(-2.0, 0.1, 1.0), Vector3(2.5, 0.1, -1.5)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(RUNNER, Vector3(0.0, 0.1, -2.0), "res://assets/models/enemies/runner.glb"); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_rubble_cleared = GameManager.get_level_flag(location_id, "rubble_cleared", false)
	_hatch_progress = int(GameManager.get_level_flag(location_id, "hatch_progress", 0))
	if _rubble_cleared:
		_clear_rubble(false)
	_refresh_pips()
	if _enemies_cleared and _rubble_cleared and _hatch_progress >= HATCH_PRESSES_REQUIRED:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, CYRUS_POS, REACH): _talk_cyrus(char_name); return
	for c in get_children():
		if c is MeshInstance3D and c.has_meta("lantern") and near3(pp, c.position, REACH):
			GameManager.grant_item(char_name, LanternItem.id); c.queue_free()
			_hud_hint.text = "Lantern lit — the tunnels brighten."
			_brighten()
			Audio.play("special"); return
	if char_name == "Evan" and not _rubble_cleared and near3(pp, RUBBLE_POS, REACH + 0.6):
		_rubble_cleared = true
		GameManager.set_level_flag(location_id, "rubble_cleared", true)
		_clear_rubble(true)
		_hud_hint.text = "Evan heaves the rubble aside — the west passage is open."
		Audio.play("special"); return
	if char_name == "Ethan" and _hatch_progress < HATCH_PRESSES_REQUIRED and near3(pp, HATCH_POS, REACH):
		_hatch_progress += 1
		GameManager.set_level_flag(location_id, "hatch_progress", _hatch_progress)
		_refresh_pips()
		if _hatch_progress >= HATCH_PRESSES_REQUIRED:
			_hud_hint.text = "Hatch hacked! The east passage unlocks."
		else:
			_hud_hint.text = "Hatch hack: pass %d of %d." % [_hatch_progress, HATCH_PRESSES_REQUIRED]
		Audio.play("special"); return
	if char_name != "Evan" and not _rubble_cleared and near3(pp, RUBBLE_POS, REACH + 0.6):
		_hud_hint.text = "The rubble's too heavy — Evan can force it."
	elif char_name != "Ethan" and _hatch_progress < HATCH_PRESSES_REQUIRED and near3(pp, HATCH_POS, REACH):
		_hud_hint.text = "The hatch needs Ethan's hacking passes."

func _clear_rubble(animate: bool) -> void:
	if animate:
		var tw := create_tween()
		tw.tween_property(_rubble, "position:y", -2.0, 0.6)
		tw.tween_callback(func() -> void: (_rubble as StaticBody3D).collision_layer = 0)
	else:
		_rubble.position.y = -2.0
		(_rubble as StaticBody3D).collision_layer = 0

func _refresh_pips() -> void:
	for i: int in _hatch_pips.size():
		var done: bool = i < _hatch_progress
		var m := ((_hatch_pips[i] as MeshInstance3D).mesh as BoxMesh).material as StandardMaterial3D
		m.albedo_color = Color(0.3, 0.95, 0.4) if done else Color(0.8, 0.25, 0.2)
		m.emission = m.albedo_color

func _brighten() -> void:
	for c in get_children():
		if c is WorldEnvironment:
			(c.environment as Environment).ambient_light_energy = 0.7

func _talk_cyrus(char_name: String) -> void:
	var tree: Dictionary
	if _enemies_cleared and _rubble_cleared and _hatch_progress >= HATCH_PRESSES_REQUIRED:
		tree = {"start": {"lines": ["\"Both passages clear. I'll get maintenance back in here properly now. Good work.\""]}}
	elif _rubble_cleared or _hatch_progress > 0:
		tree = {"start": {"lines": ["\"West rubble needs Evan, east hatch needs Ethan's hacking passes -- and keep that lantern close.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"Cyrus -- I maintain these tunnels. Or I did before the patrol showed up.\"",
			"\"West passage has rubble Evan can force open. East side there's a locked hatch -- Ethan will need a few passes at it. And grab the lantern from the junction first -- it's dark in there.\""]}}
	open_dialog("Cyrus", Color(0.4, 0.38, 0.32), tree, char_name)

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
		bits.append("patrol " + ("OK" if _enemies_cleared else "..."))
		bits.append("rubble " + ("OK" if _rubble_cleared else "..."))
		bits.append("hatch %d/%d" % [_hatch_progress, HATCH_PRESSES_REQUIRED])
		_hud_goal.text = "Clear the patrol; Evan forces the west rubble, Ethan hacks the east hatch. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
	if not _cleared and _enemies_cleared and _rubble_cleared and _hatch_progress >= HATCH_PRESSES_REQUIRED:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "TUNNELS CLEARED!\nBoth passages open."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
