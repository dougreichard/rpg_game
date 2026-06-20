extends Level3D
## The Harbor & Docks (3D) — Quinn + Evan. Multi-room: a combat-free OFFICE lobby
## (harbourmaster Viktor + exit), the DOCK YARD (Grunts + Runners; the cargo container,
## the crane, the dock-power panel, the manifest/lantern locker), and an optional
## STOREROOM to the east (opened with the gym boiler key → bonus). Evan shoulders the
## container off the crane platform; Quinn repairs the dock power; with the crank handle
## the crane lifts Doug's manifest crate (his trail). Concrete/dirt surfaces, rusted-
## steel trim. Win = pier cleared + container moved + crane run.

const QUINN := preload("res://data/characters/quinn.tres")
const EVAN := preload("res://data/characters/evan.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const RUNNER := preload("res://data/enemies/runner.tres")
const CrowbarItem: ItemData = preload("res://data/items/crowbar.tres")
const LanternItem: ItemData = preload("res://data/items/pocket_lantern.tres")
const CrankItem: ItemData = preload("res://data/items/crane_crank_handle.tres")
const BoilerKeyItem: ItemData = preload("res://data/items/boiler_key.tres")
const BiesCharmItem: ItemData = preload("res://data/items/bies_charm.tres")
const CrateTagItem: ItemData = preload("res://data/items/doug_crate_tag.tres")

# --- thematic surfaces (concrete / dirt / rusted-steel trim) ---
const FLOOR_CONCRETE := "res://assets/art/tiles/synty_floor_concrete.png"
const FLOOR_TILE := "res://assets/art/tiles/synty_floor_tile.png"
const FLOOR_DIRT := "res://assets/art/tiles/synty_floor_dirt.png"
const WALL_CONCRETE := "res://assets/art/tiles/synty_wall_concrete.png"
const WALL_BRICK := "res://assets/art/tiles/synty_wall_brick.png"
const FT_YARD := Color(0.78, 0.80, 0.82)
const WT_YARD := Color(0.74, 0.74, 0.74)
const FT_OFFICE := Color(0.80, 0.80, 0.82)
const FT_STORE := Color(0.74, 0.68, 0.58)
const WT_STORE := Color(0.72, 0.62, 0.54)
const CORNER_COL := Color(0.40, 0.30, 0.22)   # solid rusted-steel trim
const WATER_COL := Color(0.10, 0.22, 0.30)

const WALL_H := 3.0
const REACH := 2.4

# Enlarged dock yard (24x20), office/storeroom pushed out behind longer corridors.
const OFFICE_C := Vector3(0, 0, 19.0)
const VIKTOR_POS := Vector3(3.5, 0, 20.5)
const CONTAINER_POS := Vector3(0.0, 0.0, -6.0)
const CRANE_POS := Vector3(0.0, 0.0, -8.0)
const POWER_POS := Vector3(-10.0, 0, -2.0)
const CRANK_PICKUP := Vector3(9.0, 0, 6.0)
const CROWBAR_PICKUP := Vector3(-9.0, 0, 6.0)
const LOCKER_POS := Vector3(10.0, 0, -2.0)
const STORE_C := Vector3(20.5, 0, 0.0)
const STORE_GATE := Vector3(16.0, 0, 0.0)
const STORE_LOOT := Vector3(20.5, 0, -2.0)

var _cleared := false
var _enemies_cleared := false
var _container_moved := false
var _power_on := false
var _crane_run := false
var _lantern_taken := false
var _store_open := false
var _store_loot := false
var _spawned := 0
var _viktor = null
var _container: Node3D = null
var _crate: Node3D = null
var _store_wall: Node3D = null
var _store_box: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "harbor_docks"
	multi_room = true
	build_env(Color(0.09, 0.12, 0.15), Color(0.55, 0.6, 0.65), 0.6, 1.1)
	point_light(Vector3(0, 3.4, 0), Color(0.85, 0.9, 1.0), 2.0, 16.0)
	point_light(CRANE_POS + Vector3(0, 3.0, 0), Color(1.0, 0.8, 0.4), 1.8, 7.0)
	point_light(OFFICE_C + Vector3(0, 2.8, 0), Color(0.9, 0.9, 1.0), 1.8, 10.0)
	point_light(STORE_C + Vector3(0, 2.6, 0), Color(1.0, 0.7, 0.4), 1.4, 7.0)
	_rooms()
	_water()
	_crane()
	_container_block()
	_dock_clutter()
	_power_panel()
	_locker_stand()
	_crank_pickup()
	_crowbar_pickup()
	_store_contents()
	make_dialog()
	_build_hud()
	_viktor = spawn_npc("bellows", VIKTOR_POS, 0.0)   # weathered harbourmaster (faces camera)
	prop("res://assets/models/props/desk.glb", VIKTOR_POS + Vector3(0, 0, 1.0), 0.0)   # harbourmaster's desk
	add_exit_portal(OFFICE_C + Vector3(0, 0, 5.0), Vector3(3, 3, 1.4))
	var p := spawn_duo([QUINN, EVAN], OFFICE_C + Vector3(0.0, 0.1, 1.0))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _rooms() -> void:
	# Dock yard — concrete, combat. Openings: south (office), east (storeroom).
	set_theme(FLOOR_CONCRETE, WALL_CONCRETE)
	room(Vector3.ZERO, 24, 20, FT_YARD, WT_YARD, WALL_H, ["s", "e"], 4.0, true)
	corridor(Vector3(0, 0, 10), "s", 4.0, FT_YARD, WT_YARD, 4.0, WALL_H, true, CORNER_COL)        # → office
	corridor(Vector3(12, 0, 0), "e", 4.0, FT_YARD, WT_YARD, 4.0, WALL_H, true, CORNER_COL)        # → storeroom
	# Office — tile floor, concrete walls (combat-free). South vestibule = exit.
	set_theme(FLOOR_TILE, WALL_CONCRETE)
	room(OFFICE_C, 14, 10, FT_OFFICE, WT_YARD, 3.2, ["n", "s"], 4.0, true)
	corridor(OFFICE_C + Vector3(0, 0, 5.0), "s", 2.0, FT_OFFICE, WT_YARD, 4.0, 3.2, true, CORNER_COL)
	# Storeroom — dirt floor, brick walls. Threshold sealed until the boiler key.
	set_theme(FLOOR_DIRT, WALL_BRICK)
	room(STORE_C, 9, 9, FT_STORE, WT_STORE, 3.0, ["w"], 4.0, true)
	_store_wall = _gate_panel(STORE_GATE, 3.0)

func _gate_panel(pos: Vector3, h: float) -> Node3D:
	var size := Vector3(0.4, h, 4.0)
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = size; cs.shape = bs; cs.position = Vector3(0, h * 0.5, 0)
	sb.add_child(cs); sb.add_child(box_mesh(size, WT_STORE, Vector3(0, h * 0.5, 0), 0.0, wall_tex))
	sb.position = pos
	add_child(sb)
	return sb

func _water() -> void:
	add_child(box_mesh(Vector3(34.0, 0.1, 7.0), WATER_COL, Vector3(0, 0.02, -13.5), 0.25))

func _crane() -> void:
	# Generated Synty gantry crane (synty-prop-gen) — VISUAL ONLY, no collision/logic rides
	# on it. Split into co-registered parts so each takes its own tint: grey steel base legs
	# + safety-yellow boom/gantry.
	_tint_crane_part("res://assets/models/props/dock_crane_body.glb", Color(0.45, 0.47, 0.50))
	_tint_crane_part("res://assets/models/props/dock_crane_top.glb", Color(0.86, 0.70, 0.18))
	add_child(box_mesh(Vector3(3.0, 0.08, 2.0), Color(0.35, 0.33, 0.3), CRANE_POS + Vector3(0, 0.04, 0)))  # platform pad
	# (crane parts added above via _tint_crane_part)
	# the manifest crate the crane lifts (Doug's trail) — sits on the platform (Synty crate)
	_crate = prop("res://assets/models/town/deck_crate.glb", CRANE_POS + Vector3(1.4, 0, 0), 0.0)

func _tint_crane_part(path: String, col: Color) -> void:
	var part := prop(path, CRANE_POS + Vector3(0, 0, 1.0), 0.0, 4.3)
	if part == null:
		return
	var tint := StandardMaterial3D.new()
	tint.albedo_color = col; tint.roughness = 0.5; tint.metallic = 0.4
	for mi: Node in part.find_children("*", "MeshInstance3D"):
		(mi as MeshInstance3D).material_override = tint

func _container_block() -> void:
	_container = StaticBody3D.new()
	(_container as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(3.4, 2.0, 1.6); cs.shape = bs; cs.position = Vector3(0, 1.0, 0)
	_container.add_child(cs)
	# Prop-Farm shipping container as the visual (child of the collision body → sinks with it
	# when Evan shoves it clear). ~4.6m long → scale to the 3.4m collision footprint.
	var c: Node3D = load("res://assets/models/props/cargo_container.glb").instantiate()
	c.scale = Vector3(0.74, 0.74, 0.74)
	_container.add_child(c)
	_container.position = CONTAINER_POS
	add_child(_container)

func _dock_clutter() -> void:
	_stack(Vector3(-10.5, 0, -3.0), Color(0.25, 0.45, 0.55))
	_stack(Vector3(-10.5, 0, 2.0), Color(0.55, 0.5, 0.25))
	_stack(Vector3(10.5, 0, -6.0), Color(0.5, 0.3, 0.45))
	prop("res://assets/models/props/barrel.glb", Vector3(-3.0, 0, 5.5))
	prop("res://assets/models/props/barrel.glb", Vector3(-3.6, 0, 5.7))
	prop("res://assets/models/props/barrel.glb", Vector3(3.4, 0, 6.0))
	# Prop-Farm container stacks + forklift + dock detail (bollards/buoys along the water edge)
	prop("res://assets/models/props/cargo_container.glb", Vector3(-9.5, 0, -7.5), deg_to_rad(90), 0.8)
	prop("res://assets/models/props/cargo_container.glb", Vector3(9.0, 0, 6.0), deg_to_rad(70), 0.8)
	prop("res://assets/models/props/forklift.glb", Vector3(5.5, 0, 4.0), deg_to_rad(210))
	for b: Vector3 in [Vector3(-4.0, 0, -9.0), Vector3(0.0, 0, -9.2), Vector3(4.0, 0, -9.0)]:
		prop("res://assets/models/props/dock_bollard.glb", b, 0.0)
	prop("res://assets/models/props/life_buoy.glb", Vector3(-11.0, 0, -8.0), deg_to_rad(40))
	prop("res://assets/models/props/life_buoy.glb", Vector3(11.0, 0, -8.0), deg_to_rad(-40))

func _stack(pos: Vector3, col: Color) -> void:
	add_child(box_mesh(Vector3(2.6, 1.6, 1.4), col, pos + Vector3(0, 0.8, 0)))
	add_child(box_mesh(Vector3(2.6, 1.6, 1.4), col.darkened(0.12), pos + Vector3(0, 2.4, 0)))

# Dock-power panel — Quinn rewires it to power the crane.
func _power_panel() -> void:
	prop("res://assets/models/props/control_panel.glb", POWER_POS, deg_to_rad(90))   # dock-power panel (Prop Farm)
	add_child(box_mesh(Vector3(0.12, 0.4, 0.4), Color(0.8, 0.2, 0.15), POWER_POS + Vector3(0.35, 1.2, 0), 1.5))  # dead light glint

# Manifest / lantern locker — Evan forces it, or Quinn dials it once the manifest is up.
func _locker_stand() -> void:
	prop("res://assets/models/props/gym_lockers.glb", LOCKER_POS, deg_to_rad(180))   # reused locker bank

func _crank_pickup() -> void:
	var box := box_mesh(Vector3(0.5, 0.4, 0.5), Color(0.5, 0.42, 0.2), CRANK_PICKUP + Vector3(0, 0.2, 0))
	box.set_meta("crank", true)
	add_child(box)

func _crowbar_pickup() -> void:
	var box := box_mesh(Vector3(0.6, 0.4, 0.6), Color(0.45, 0.32, 0.18), CROWBAR_PICKUP + Vector3(0, 0.2, 0))
	box.set_meta("crowbar", true)
	add_child(box)

func _store_contents() -> void:
	_store_box = box_mesh(Vector3(0.6, 0.6, 0.6), Color(0.5, 0.4, 0.7), STORE_LOOT + Vector3(0, 0.3, 0), 0.6)
	add_child(_store_box)

func _spawn_enemies() -> void:
	spawn_enemy(GRUNT, Vector3(-2.0, 0.1, 1.0), "res://assets/models/enemies/grunt.glb"); _spawned += 1
	for spot: Vector3 in [Vector3(2.5, 0.1, 0.0), Vector3(1.0, 0.1, -2.5)]:
		spawn_enemy(RUNNER, spot, "res://assets/models/enemies/runner.glb"); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_container_moved = GameManager.get_level_flag(location_id, "container_moved", false)
	_power_on = GameManager.get_level_flag(location_id, "power_on", false)
	_crane_run = GameManager.get_level_flag(location_id, "crane_run", false)
	_lantern_taken = GameManager.get_level_flag(location_id, "lantern_taken", false)
	_store_open = GameManager.get_level_flag(location_id, "store_open", false)
	_store_loot = GameManager.get_level_flag(location_id, "store_loot", false)
	if _container_moved: _move_container(false)
	if _crane_run and _crate != null: _crate.position += Vector3(0, 3.0, 0)
	if _store_open: _open_store(false)
	if _store_loot and _store_box != null: _store_box.queue_free(); _store_box = null
	if _enemies_cleared and _container_moved and _crane_run:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, VIKTOR_POS, REACH):
		_talk_viktor(char_name); return
	# pickups (crank handle / crowbar)
	for c in get_children():
		if c is MeshInstance3D and c.has_meta("crank") and near3(pp, c.position, REACH):
			GameManager.grant_item(char_name, CrankItem.id); c.queue_free()
			_hud_hint.text = "Picked up the crane crank handle."; Audio.play("special"); return
		if c is MeshInstance3D and c.has_meta("crowbar") and near3(pp, c.position, REACH):
			GameManager.grant_item(char_name, CrowbarItem.id); c.queue_free()
			_hud_hint.text = "Picked up a crowbar — now you can pry the container."; Audio.play("special"); return
	# container (Evan / crowbar)
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
		return
	# dock power (Quinn)
	if not _power_on and near3(pp, POWER_POS, REACH):
		if char_name == "Quinn":
			_power_on = true
			GameManager.set_level_flag(location_id, "power_on", true)
			_hud_hint.text = "Quinn rewires the dock panel — the crane hums with power."
			Audio.play("special")
		else:
			_hud_hint.text = "The power panel's fried — Quinn's repair job."
		return
	# crane (needs container moved + power + the crank handle)
	if not _crane_run and near3(pp, CRANE_POS, REACH + 1.0):
		var has_crank := GameManager.has_item("Quinn", CrankItem.id) or GameManager.has_item("Evan", CrankItem.id)
		if not _container_moved:
			_hud_hint.text = "The container's still blocking the crane platform."
		elif not _power_on:
			_hud_hint.text = "No power to the crane — Quinn needs to fix the dock panel."
		elif not has_crank:
			_hud_hint.text = "The crane needs its crank handle — there's one in the yard."
		else:
			_run_crane(char_name)
		return
	# manifest / lantern locker (Evan force, or Quinn dial once the manifest is up)
	if not _lantern_taken and near3(pp, LOCKER_POS, REACH):
		if char_name == "Evan":
			_open_locker(char_name, "Evan wrenches the locker open")
		elif char_name == "Quinn" and _crane_run:
			_open_locker(char_name, "Quinn dials the crate numbers off the lifted manifest")
		else:
			_hud_hint.text = "Locked tight. Evan can force it — or Quinn can dial it once the manifest crate is up."
		return
	# storeroom (optional, boiler key)
	if not _store_open and near3(pp, STORE_GATE, REACH):
		if GameManager.has_item("Quinn", BoilerKeyItem.id) or GameManager.has_item("Evan", BoilerKeyItem.id):
			_open_store(true)
			_hud_hint.text = "The boiler key fits the old supply door — it swings open."
			Audio.play("special")
		else:
			_hud_hint.text = "An old supply door, locked. The key looks like a gym boiler key."
		return
	if not _store_loot and _store_open and near3(pp, STORE_LOOT, REACH):
		_store_loot = true
		GameManager.set_level_flag(location_id, "store_loot", true)
		GameManager.grant_item(char_name, BiesCharmItem.id)
		if _store_box != null: _store_box.queue_free(); _store_box = null
		_hud_hint.text = "Tucked in the supply room: a Bies charm. (Found Bies Charm)"
		Audio.play("special")

func _run_crane(char_name: String) -> void:
	_crane_run = true
	GameManager.set_level_flag(location_id, "crane_run", true)
	GameManager.grant_item(char_name, CrateTagItem.id)
	if _crate != null:
		create_tween().tween_property(_crate, "position:y", _crate.position.y + 3.0, 0.8)
	open_dialog("Manifest Crate", Color(0.4, 0.45, 0.5),
		{"start": {"lines": [
			"The crane groans and hauls a crate clear of the hold. Stencilled on the side: a name Doug used.",
			"Inside, packing slips -- and a routing tag. Doug shipped himself out of here, in a crate, heading inland.",
			"Picked up: Shipping Crate Tag."]}}, char_name)
	Audio.play("special")

func _open_locker(char_name: String, how: String) -> void:
	_lantern_taken = true
	GameManager.set_level_flag(location_id, "lantern_taken", true)
	GameManager.grant_item(char_name, LanternItem.id)
	_hud_hint.text = "%s — a pocket lantern inside. (Stowed; handy for dark places underground.)" % how
	Audio.play("special")

func _open_store(animate: bool) -> void:
	_store_open = true
	GameManager.set_level_flag(location_id, "store_open", true)
	(_store_wall as StaticBody3D).collision_layer = 0
	if animate:
		create_tween().tween_property(_store_wall, "position:y", -3.4, 0.6)
	else:
		_store_wall.position.y = -3.4

func _move_container(animate: bool) -> void:
	var to := CONTAINER_POS + Vector3(-6.0, 0, 2.5)
	if animate:
		create_tween().tween_property(_container, "position", to, 0.7)
	else:
		_container.position = to

func _talk_viktor(char_name: String) -> void:
	var tree: Dictionary
	if _enemies_cleared and _container_moved and _crane_run:
		tree = {"start": {"lines": ["\"So it's true -- Doug crated himself out on that shipment. Heading for the old picture house, by the routing. Go after him.\""]}}
	elif _container_moved or _enemies_cleared:
		tree = {"start": {"lines": ["\"Fix the dock power, fit the crank, and run the crane -- that manifest crate is the lead you want.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"Harbourmaster Viktor. Pier's been overrun -- smugglers moved in with a suspicious manifest.\"",
			"\"Clear them out. Then: Evan shifts the container off the crane, Quinn powers the dock panel, and you'll need the crank handle from the yard to run the crane.\"",
			"\"That crane lifts the crate with Doug's name on it. And mind the supply room east -- locked, but an old boiler key would fit.\""]}}
	GameManager.set_level_flag(location_id, "viktor_met", true)
	open_dialog("Viktor", Color(0.35, 0.4, 0.45), tree, char_name)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	build_default_hud()
	_hud_goal = hud_goal; _hud_hint = hud_toast; _hud_banner = hud_ribbon
	_hud_goal.text = "Clear the pier; Evan moves the container, Quinn powers the dock, run the crane on Doug's crate. (G interact, Tab swap)"

func _process(d: float) -> void:
	super._process(d)
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
		_hud_hint.text = "Pier clear! Move the container, power the dock, run the crane."
		if _viktor != null:
			_viktor.call("say", "Good. Now the container and the crane.")
	if not _cleared and _enemies_cleared and _container_moved and _crane_run:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "DOCKS SECURED!\nDoug's trail leads on."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
