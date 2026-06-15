extends Level3D
## The Harbor & Docks (3D) — Quinn + Evan clear a pier overrun by smugglers, then
## Evan shoulders the cargo container blocking the crane platform aside (or a crowbar
## from the yard does it). Harbourmaster Viktor confirms Doug's name on the manifest.
## Enemy mix: Grunts (dock workers) + Runners (smugglers).

const QUINN := preload("res://data/characters/quinn.tres")
const EVAN := preload("res://data/characters/evan.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const RUNNER := preload("res://data/enemies/runner.tres")
const CrowbarItem: ItemData = preload("res://data/items/crowbar.tres")

const FLOOR_COL := Color(0.22, 0.24, 0.27)
const WATER_COL := Color(0.10, 0.22, 0.30)
const WALL_COL := Color(0.30, 0.28, 0.25)
const HALF_W := 8.5
const HALF_D := 8.0
const WALL_H := 3.0
const CONTAINER_POS := Vector3(0.0, 0.0, -HALF_D + 3.0)
const CRANE_POS := Vector3(0.0, 0.0, -HALF_D + 1.0)
const VIKTOR_POS := Vector3(HALF_W - 1.8, 0.0, HALF_D - 2.5)
const REACH := 2.4

var _cleared := false
var _enemies_cleared := false
var _container_moved := false
var _spawned := 0
var _viktor = null
var _container: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "harbor_docks"
	build_env(Color(0.09, 0.12, 0.15), Color(0.55, 0.6, 0.65), 0.6, 1.1)
	point_light(Vector3(0, 3.4, 0), Color(0.85, 0.9, 1.0), 2.0, 16.0)
	point_light(CRANE_POS + Vector3(0, 3.0, 0), Color(1.0, 0.8, 0.4), 1.8, 7.0)
	floor_box(HALF_W * 2.0 + 1.0, HALF_D * 2.0 + 1.0, FLOOR_COL)
	_water()
	_walls()
	_crane()
	_container_block()
	_dock_clutter()
	_crowbar_pickup()
	make_dialog()
	_build_hud()
	_viktor = spawn_npc("bellows", VIKTOR_POS, deg_to_rad(-110))   # weathered harbourmaster
	var p := spawn_duo([QUINN, EVAN], Vector3(0.0, 0.1, HALF_D - 1.5))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _water() -> void:
	# a strip of "water" past the back wall (visual only)
	var w := box_mesh(Vector3(HALF_W * 2.0 + 6.0, 0.1, 5.0), WATER_COL, Vector3(0, 0.02, -HALF_D - 3.0), 0.25)
	add_child(w)

func _walls() -> void:
	wall(Vector3(-HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(-HALF_W + 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(HALF_W - 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)
	# low quay wall at the water's edge (back), with a gap for the crane
	wall(Vector3(-HALF_W + 3.0, 0.4, -HALF_D), Vector3(6.0, 0.8, 0.4), WALL_COL.darkened(0.1))
	wall(Vector3(HALF_W - 3.0, 0.4, -HALF_D), Vector3(6.0, 0.8, 0.4), WALL_COL.darkened(0.1))

func _crane() -> void:
	# crane mast + jib over the platform
	add_child(box_mesh(Vector3(0.4, 5.0, 0.4), Color(0.8, 0.6, 0.15), CRANE_POS + Vector3(-1.6, 2.5, 0)))
	add_child(box_mesh(Vector3(4.5, 0.4, 0.4), Color(0.8, 0.6, 0.15), CRANE_POS + Vector3(0.4, 4.8, 0)))
	# hanging hook line
	add_child(box_mesh(Vector3(0.06, 1.6, 0.06), Color(0.2, 0.2, 0.2), CRANE_POS + Vector3(1.4, 3.9, 0)))
	# platform pad
	add_child(box_mesh(Vector3(3.0, 0.08, 2.0), Color(0.35, 0.33, 0.3), CRANE_POS + Vector3(0, 0.04, 0)))

# The cargo container blocking crane access — Evan (or a crowbar) shoves it.
func _container_block() -> void:
	_container = StaticBody3D.new()
	(_container as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(3.4, 2.0, 1.6); cs.shape = bs; cs.position = Vector3(0, 1.0, 0)
	_container.add_child(cs)
	var body := box_mesh(Vector3(3.4, 2.0, 1.6), Color(0.65, 0.25, 0.2), Vector3(0, 1.0, 0))
	_container.add_child(body)
	# corrugation ribs
	for i: int in range(6):
		var x: float = -1.4 + float(i) * 0.56
		_container.add_child(box_mesh(Vector3(0.08, 1.9, 1.62), Color(0.5, 0.18, 0.15), Vector3(x, 1.0, 0)))
	_container.position = CONTAINER_POS
	add_child(_container)

func _dock_clutter() -> void:
	# stacked shipping containers along the sides
	_stack(Vector3(-HALF_W + 1.6, 0, -2.0), Color(0.25, 0.45, 0.55))
	_stack(Vector3(-HALF_W + 1.6, 0, 2.0), Color(0.55, 0.5, 0.25))
	_stack(Vector3(HALF_W - 1.6, 0, -3.5), Color(0.5, 0.3, 0.45))
	prop("res://assets/models/props/barrel.glb", Vector3(-2.5, 0, 3.5))
	prop("res://assets/models/props/barrel.glb", Vector3(-3.1, 0, 3.7))
	prop("res://assets/models/props/barrel.glb", Vector3(2.8, 0, 4.0))

func _stack(pos: Vector3, col: Color) -> void:
	add_child(box_mesh(Vector3(2.6, 1.6, 1.4), col, pos + Vector3(0, 0.8, 0)))
	add_child(box_mesh(Vector3(2.6, 1.6, 1.4), col.darkened(0.12), pos + Vector3(0, 2.4, 0)))

func _crowbar_pickup() -> void:
	var box := box_mesh(Vector3(0.6, 0.5, 0.6), Color(0.45, 0.32, 0.18), Vector3(-HALF_W + 2.0, 0.25, 4.5))
	box.set_meta("crowbar", true)
	add_child(box)

func _spawn_enemies() -> void:
	spawn_enemy(GRUNT, Vector3(-2.0, 0.1, 1.0), "res://assets/models/enemies/grunt.glb"); _spawned += 1
	for spot: Vector3 in [Vector3(2.5, 0.1, 0.0), Vector3(1.0, 0.1, -2.5)]:
		spawn_enemy(RUNNER, spot, "res://assets/models/enemies/runner.glb"); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_container_moved = GameManager.get_level_flag(location_id, "container_moved", false)
	if _container_moved:
		_move_container(false)
	if _enemies_cleared and _container_moved:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, VIKTOR_POS, REACH):
		_talk_viktor(char_name); return
	# crowbar pickup
	for c in get_children():
		if c is MeshInstance3D and c.has_meta("crowbar") and near3(pp, c.position, REACH):
			GameManager.grant_item(char_name, CrowbarItem.id)
			c.queue_free()
			_hud_hint.text = "Picked up a crowbar — now you can pry the container."
			Audio.play("special"); return
	if not _container_moved and near3(pp, CONTAINER_POS, REACH + 0.8):
		var has_crowbar := GameManager.has_item("Quinn", CrowbarItem.id) or GameManager.has_item("Evan", CrowbarItem.id)
		if char_name == "Evan" or has_crowbar:
			_container_moved = true
			GameManager.set_level_flag(location_id, "container_moved", true)
			_move_container(true)
			_hud_hint.text = "The container grinds aside — the crane platform is clear."
			Audio.play("special")
		else:
			_hud_hint.text = "Too heavy. Evan can shift it — or pry it with a crowbar from the yard."

func _move_container(animate: bool) -> void:
	var to := CONTAINER_POS + Vector3(HALF_W - 1.5, 0, 1.5)
	if animate:
		create_tween().tween_property(_container, "position", to, 0.7)
	else:
		_container.position = to

func _talk_viktor(char_name: String) -> void:
	var tree: Dictionary
	if _enemies_cleared and _container_moved:
		tree = {"start": {"lines": ["\"Manifest confirms it -- Doug's name is on that shipment. You'll want to follow that lead.\""]}}
	elif _container_moved or _enemies_cleared:
		tree = {"start": {"lines": ["\"That container's still blocking the crane platform -- Evan or a crowbar will shift it.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"Harbourmaster Viktor. Pier's been overrun -- smugglers moved in with a suspicious manifest.\"",
			"\"That cargo container is blocking crane access. Evan can shift it bare-handed. If you're short-handed, there's a crowbar somewhere in the yard.\""]}}
	open_dialog("Viktor", Color(0.35, 0.4, 0.45), tree, char_name)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := make_hud_layer()
	_hud_goal = hud_label(cl, 24)
	_hud_goal.text = "Clear the pier, then Evan shifts the cargo container off the crane platform. (G interact, Tab swap)"
	_hud_hint = hud_label(cl, -70, 22, true)
	_hud_banner = hud_label(cl, 0, 40); _hud_banner.anchor_top = 0.5; _hud_banner.anchor_bottom = 0.5
	_hud_banner.visible = false

func _process(d: float) -> void:
	super._process(d)
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
		_hud_hint.text = "Pier clear! Move the container off the crane platform."
		if _viktor != null:
			_viktor.call("say", "Good. Now that container — Evan's got it.")
	if not _cleared and _enemies_cleared and _container_moved:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "DOCKS SECURED!\nDoug's trail leads on."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
