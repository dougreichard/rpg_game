extends Level3D
## Bellows & Sons Pipe Organ Works (3D) — MULTI-FLOOR, the game's opening level.
##
## Story beat: Quinn arrives ALONE. Mr. Bellows (lobby) says some punks chased a
## young woman -- Erin -- into the back Storeroom. Quinn clears the Storeroom grunts;
## Erin steps out from behind the crates and JOINS the party (Duo3D.add_member). She
## was tracking a lead on Uncle Doug and came to find Quinn.
##
## Repair puzzle (crafting): Quinn gathers raw materials spread across two floors --
## a warped plank (Storeroom), an out-of-tune long pipe + a gear blank (Pipe Loft) --
## and MILLS them at the Workshop tools: the table saw squares the plank and cuts the
## pipe to length; the tuning bench tunes the cut pipe and trues the gear. Each raw
## item's description hints which tool to use. Erin then fast-talks the tuning key out
## of Bellows, which unlocks the organ console so Quinn can fit the three finished
## parts. Win = enemies cleared (Storeroom + Loft) + organ repaired.
##
## Floor 1 — Lobby (Bellows + organ console, combat-free) · Storeroom (grunts + Erin
##           + plank) · Workshop (table saw + tuning bench) · stair alcove
## Floor 2 — Pipe Loft (out-of-tune pipe + gear blank, runners) + secret spare-gear nook

const QUINN := preload("res://data/characters/quinn.tres")
const ERIN := preload("res://data/characters/erin.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const RUNNER := preload("res://data/enemies/runner.tres")
const TuningKeyItem: ItemData = preload("res://data/items/tuning_key.tres")
const SpareGearItem: ItemData = preload("res://data/items/spare_clockwork_gear.tres")
const TicketQuinn: ItemData = preload("res://data/items/ticket_quinn.tres")
const TicketErin: ItemData = preload("res://data/items/ticket_erin.tres")
const Station := preload("res://scripts/3d/work_station3d.gd")

# Per-room thematic surfaces — each space gets its own floor + wall texture so the
# building reads as a sequence of different rooms (grand entry → service passages →
# storeroom → workshop → pipe loft). Textures are tinted by the FT_/WT_ colours below.
const TILE_FLOOR := "res://assets/art/tiles/synty_floor_tile.png"
const MARBLE_FLOOR := "res://assets/art/tiles/synty_floor_marble.png"
const WOOD_FLOOR := "res://assets/art/tiles/synty_floor_workshop.png"
const CONCRETE_FLOOR := "res://assets/art/tiles/synty_floor_concrete.png"
const BRICK_WALL := "res://assets/art/tiles/synty_wall_brick.png"
const WOOD_WALL := "res://assets/art/tiles/synty_wall_wood.png"
const CONCRETE_WALL := "res://assets/art/tiles/synty_wall_concrete.png"
const STONE_WALL := "res://assets/art/tiles/synty_wall_stone.png"
# tints (multiply the texture): warm for finished rooms, cooler/greyer for service areas
const FT_WARM := Color(0.88, 0.80, 0.68)
const WT_WARM := Color(0.82, 0.76, 0.70)
const FT_COOL := Color(0.80, 0.81, 0.82)
const WT_COOL := Color(0.76, 0.77, 0.78)
const WALL_COL := Color(0.80, 0.74, 0.70)   # secret-wall tint (brick)
const CORNER_COL := Color(0.20, 0.17, 0.14) # solid dark-iron trim on corridor corner posts
const WOOD := Color(0.34, 0.22, 0.14)
const BRASS := Color(0.72, 0.6, 0.32)
const STEEL := Color(0.55, 0.57, 0.62)

const F1 := Vector3(0, 0, 0)             # workshop floor
const F2 := Vector3(60, 0, 0)            # pipe loft

const ORGAN := Vector3(-3.5, 0, -4.8)    # F1 lobby: console visual anchor
const ORGAN_HIT := Vector3(-3.5, 0, -3.6)  # F1 lobby: organ interaction point
const BELLOWS := Vector3(3.5, 0, -3.5)   # F1 lobby
const PLANK_SRC := Vector3(15.5, 0, 3.0) # F1 storeroom: warped plank
const ERIN_HIDE := Vector3(15.5, 0, -3.0)  # F1 storeroom: Erin behind crates
const SAW := Vector3(-13.0, 0, -2.5)     # F1 workshop: table saw
const BENCH := Vector3(-13.0, 0, 2.5)    # F1 workshop: tuning bench
const PIPE_SRC := Vector3(-3.0, 0, -11.0)  # F2 loft: out-of-tune pipe
const GEAR_SRC := Vector3(3.0, 0, -13.0)   # F2 loft: gear blank
const LEVER := Vector3(5.5, 0, -11.0)    # F2 loft: secret lever
const GEAR_BONUS := Vector3(0, 0, -20.0) # F2 nook: spare clockwork gear (secret)

const REACH := 2.2
const F_WORK := Vector2(8.5, 50.0)
const F_LOFT := Vector2(9.5, 52.0)

const ORGAN_PARTS := ["windchest_board", "brass_organ_pipe", "trued_gear"]

var _organ_node: MeshInstance3D = null
var _organ_base: Node3D = null      # part-additive: bare console (always)
var _organ_pipes: Node3D = null     # the pipe bank that installs with the brass pipe
var _organ_station: Node3D = null
var _stations: Array = []
var _erin_npc: Node3D = null
var _store_grunts: Array = []
var _secret_wall: Node3D = null
var _gear_box: Node3D = null

var _organ_repaired := false
var _secret_revealed := false
var _gear_bonus_open := false
var _erin_recruited := false
var _storeroom_done := false
var _cleared := false
var _enemies_cleared := false
var _spawned := 0

var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "pipe_organ_works"
	multi_room = true
	build_env(Color(0.10, 0.10, 0.12), Color(0.55, 0.50, 0.44), 0.5, 1.0)
	set_theme("res://assets/art/tiles/synty_floor_workshop.png", "res://assets/art/tiles/synty_wall_brick.png")
	_floor1()
	_floor2()
	_links()
	make_dialog()
	_build_hud()
	spawn_npc("bellows", F1 + BELLOWS, deg_to_rad(180))
	var p := spawn_duo([QUINN], F1 + Vector3(0, 0.1, 4.0))   # Quinn arrives ALONE
	p.special_used.connect(_on_special)
	reframe_camera(F_WORK.x, F_WORK.y)
	_spawn_enemies()
	_restore()

# --- Floor 1: Lobby + Storeroom + Workshop + stair alcove --------------------
func _floor1() -> void:
	# Lobby — marble-floored entry hall with brick walls (the grand first room)
	set_theme(MARBLE_FLOOR, BRICK_WALL)
	room(F1, 12, 12, FT_WARM, WT_WARM, 3.2, ["s", "e", "w", "n"], 3.0, true)            # lobby
	# Service passages — plain concrete floor + walls, so the corridors read as
	# connectors rather than rooms. Each carries its own floor (no global slab now).
	set_theme(CONCRETE_FLOOR, CONCRETE_WALL)
	corridor(F1 + Vector3(0, 0, 6), "s", 2.5, FT_COOL, WT_COOL, 3.0, 3.2, true, CORNER_COL)   # entrance vestibule (exit portal)
	corridor(F1 + Vector3(6, 0, 0), "e", 3.0, FT_COOL, WT_COOL, 3.0, 3.2, true, CORNER_COL)   # → storeroom
	corridor(F1 + Vector3(-6, 0, 0), "w", 3.0, FT_COOL, WT_COOL, 3.0, 3.2, true, CORNER_COL)  # → workshop
	corridor(F1 + Vector3(0, 0, -6), "n", 3.0, FT_COOL, WT_COOL, 3.0, 3.2, true, CORNER_COL)  # → stair alcove
	room(F1 + Vector3(0, 0, -12.5), 5, 7, FT_COOL, WT_COOL, 3.2, ["s"], 3.0, true)      # stair alcove
	# Storeroom — utilitarian concrete floor, brick walls
	set_theme(CONCRETE_FLOOR, BRICK_WALL)
	room(F1 + Vector3(13, 0, 0), 8, 10, FT_COOL, WT_WARM, 3.2, ["w"], 3.0, true)        # storeroom
	# Workshop — wood-plank floor + wood-panel walls (the working room)
	set_theme(WOOD_FLOOR, WOOD_WALL)
	room(F1 + Vector3(-13, 0, 0), 8, 10, FT_WARM, WT_WARM, 3.2, ["e"], 3.0, true)       # workshop
	point_light(F1 + Vector3(0, 3.0, -2), Color(1.0, 0.85, 0.6), 2.6, 12.0)
	point_light(F1 + Vector3(13, 2.8, 0), Color(0.9, 0.85, 0.7), 1.8, 8.0)
	point_light(F1 + Vector3(-13, 2.8, 0), Color(0.8, 0.9, 1.0), 1.8, 8.0)
	_organ()
	_workshop_tools()
	prop("res://assets/models/props/desk.glb", F1 + BELLOWS + Vector3(0, 0, -0.9), deg_to_rad(180))
	prop("res://assets/models/props/shelf.glb", F1 + Vector3(5.5, 0, -5.6), 0.0)
	# Storeroom: crates Erin hides behind + a barrel cluster
	prop("res://assets/models/props/barrel.glb", F1 + Vector3(14.3, 0, -3.0))
	prop("res://assets/models/props/barrel.glb", F1 + Vector3(14.6, 0, -3.7))
	add_child(box_mesh(Vector3(1.2, 1.4, 1.2), WOOD, F1 + Vector3(14.4, 0.7, -2.4)))
	add_child(box_mesh(Vector3(1.0, 1.0, 1.0), WOOD.lightened(0.05), F1 + Vector3(16.0, 0.5, -3.2)))
	# Erin hiding behind the crates (non-combat NPC until recruited)
	_erin_npc = spawn_npc("erin", F1 + ERIN_HIDE, deg_to_rad(180))
	# raw material: warped plank (storeroom)
	var plank := add_station(Station.Kind.SOURCE, F1 + PLANK_SRC, "Warped Plank")
	plank.set("produces", "rough_plank")
	add_child(box_mesh(Vector3(1.6, 0.3, 0.5), WOOD.lightened(0.1), F1 + PLANK_SRC + Vector3(0, 0.2, 0)))
	_register_station(plank)
	plank.connect("produced", func(_id: String) -> void: GameManager.set_level_flag(location_id, "plank_taken", true))
	# the organ as an ASSEMBLY fixture (gated behind the tuning key)
	_organ_station = add_station(Station.Kind.ASSEMBLY, F1 + ORGAN_HIT, "Organ", "Quinn")
	_organ_station.set("parts", ORGAN_PARTS.duplicate())
	_register_station(_organ_station)
	_organ_station.connect("produced", func(id: String) -> void:
		GameManager.set_level_flag(location_id, "organ_part_" + id, true)
		if id == "brass_organ_pipe": _reveal_pipes())   # the pipe bank visibly installs
	_organ_station.connect("completed", _on_organ_complete)
	add_exit_portal(F1 + Vector3(0, 0, 6.3), Vector3(3, 3, 1.4))

func _organ() -> void:
	# Generated Synty low-poly organ (synty-prop-gen), split in Blender into co-registered
	# PARTS for a part-additive build: the bare console always stands; the pipe bank
	# installs when the brass pipe is fitted; the whole thing warms + glows when repaired.
	# VISUAL ONLY — the organ's collision + ASSEMBLY station/marker (ORGAN_HIT) are unchanged.
	_organ_base = prop("res://assets/models/props/organ_part_base.glb", F1 + ORGAN, 0.0, 2.9)
	_organ_pipes = prop("res://assets/models/props/organ_part_pipes.glb", F1 + ORGAN, 0.0, 2.9)
	_tint_prop(_organ_pipes, BRASS, 0.4, 0.5)
	if _organ_pipes != null: _organ_pipes.visible = false
	var bx: float = (F1 + ORGAN).x
	# thin key-strip that glows on the restored organ (the solved cue) — sized/placed for the 2.9 organ
	_organ_node = box_mesh(Vector3(2.0, 0.1, 0.32), Color(0.92, 0.9, 0.85), Vector3(bx, 1.45, (F1 + ORGAN).z + 1.15))
	add_child(_organ_node)
	_set_organ_phase(false)   # _restore() flips it if already repaired

func _tint_prop(node: Node, col: Color, rough: float, metal: float) -> void:
	if node == null:
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = col; m.roughness = rough; m.metallic = metal
	for mi: Node in node.find_children("*", "MeshInstance3D"):
		(mi as MeshInstance3D).material_override = m

# Render a prop's baked-in vertex colours (multi-tone, no texture) instead of a flat tint.
func _apply_vcolor(node: Node, rough: float = 0.8) -> void:
	if node == null:
		return
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color.WHITE; m.roughness = rough; m.metallic = 0.0
	for mi: Node in node.find_children("*", "MeshInstance3D"):
		(mi as MeshInstance3D).material_override = m

func _reveal_pipes() -> void:
	if _organ_pipes != null: _organ_pipes.visible = true

func _set_organ_phase(fixed: bool) -> void:
	# base reads dusty/derelict until repaired, warm wood once restored
	_tint_prop(_organ_base, Color(0.55, 0.40, 0.22) if fixed else Color(0.32, 0.29, 0.25), 0.7, 0.1)
	if fixed:
		_reveal_pipes()
	if _organ_node != null:
		_organ_node.visible = fixed
		if fixed: _organ_node.material_override = _glow_mat()

func _workshop_tools() -> void:
	# Table saw — squares the plank, cuts the pipe to length.
	# VISUAL ONLY (synty-prop-gen): generated saw mesh replaces the box+blade primitives;
	# the TOOL station/marker + recipes are unchanged. Shape-only mesh → tint it (steel).
	_tint_prop(prop("res://assets/models/props/table_saw.glb", F1 + SAW, 0.0, 1.4), STEEL, 0.5, 0.35)
	var saw := add_station(Station.Kind.TOOL, F1 + SAW + Vector3(0, 0, 1.0), "Table Saw", "Quinn")
	saw.set("recipes", [
		{"in": "rough_plank", "out": "windchest_board"},
		{"in": "rough_organ_pipe", "out": "cut_organ_pipe"}])
	_register_station(saw)
	# Tuning bench — tunes the cut pipe, trues the gear. VISUAL ONLY: generated bench mesh,
	# split (synty-prop-gen split_prop) into co-registered parts so each takes its own tint —
	# wood body (legs/table) + steel rod-rack/tools. Both at the same pos/yaw/scale; rotated
	# PI so the open working front faces the player's approach (-Z marker).
	_tint_prop(prop("res://assets/models/props/tuning_bench_body.glb", F1 + BENCH, PI, 1.3), WOOD.lightened(0.04), 0.7, 0.0)
	_tint_prop(prop("res://assets/models/props/tuning_bench_top.glb", F1 + BENCH, PI, 1.3), STEEL, 0.4, 0.4)
	var bench := add_station(Station.Kind.TOOL, F1 + BENCH + Vector3(0, 0, -1.0), "Tuning Bench", "Quinn")
	bench.set("recipes", [
		{"in": "cut_organ_pipe", "out": "brass_organ_pipe"},
		{"in": "gear_blank", "out": "trued_gear"}])
	_register_station(bench)

func _register_station(s: Node3D) -> void:
	_stations.append(s)
	s.connect("message", _on_station_message)

func _on_station_message(text: String) -> void:
	_hud_hint.text = text

# --- Floor 2: Pipe Loft + secret nook ---------------------------------------
func _floor2() -> void:
	# Landing — wood floor + wood walls (top of the stairs)
	set_theme(WOOD_FLOOR, WOOD_WALL)
	room(F2, 6, 8, FT_WARM, WT_WARM, 3.0, ["n"], 3.0, true)                        # landing
	corridor(F2 + Vector3(0, 0, -4), "n", 1.0, FT_WARM, WT_WARM, 3.0, 3.0, true, CORNER_COL)  # landing → pipe hall
	# Pipe loft — grand tiled floor + stone walls (the showpiece room)
	set_theme(TILE_FLOOR, STONE_WALL)
	# "n" opening (gap 3) is the doorway to the secret nook — the removable _secret_wall
	# fills exactly that gap, so dropping it actually opens a passage (see _reveal_secret).
	room(F2 + Vector3(0, 0, -11), 14, 12, FT_WARM, WT_WARM, 4.0, ["s", "n"], 3.0, true)  # pipe hall
	point_light(F2 + Vector3(0, 3.4, -11), Color(1.0, 0.85, 0.6), 2.6, 13.0)
	# tall organ pipes rising through the loft
	for i: int in range(9):
		var x: float = -2.0 + float(i) * 0.5
		var h: float = 2.6 + 1.4 * abs(sin(float(i)))
		var pipe := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.16; cm.bottom_radius = 0.16; cm.height = h
		var mat := StandardMaterial3D.new(); mat.albedo_color = BRASS.darkened(0.05); mat.metallic = 0.6; mat.roughness = 0.35
		cm.material = mat; pipe.mesh = cm; pipe.position = F2 + Vector3(x + 2.5, 1.4 + h * 0.5, -15.0)
		add_child(pipe)
	# raw material: out-of-tune long pipe
	var pipe_src := add_station(Station.Kind.SOURCE, F2 + PIPE_SRC, "Out-of-Tune Pipe")
	pipe_src.set("produces", "rough_organ_pipe")
	add_child(box_mesh(Vector3(0.7, 0.7, 0.7), Color(0.45, 0.32, 0.18), F2 + PIPE_SRC + Vector3(0, 0.35, 0)))
	_register_station(pipe_src)
	pipe_src.connect("produced", func(_id: String) -> void: GameManager.set_level_flag(location_id, "pipe_taken", true))
	# raw material: gear blank
	var gear_src := add_station(Station.Kind.SOURCE, F2 + GEAR_SRC, "Gear Blank")
	gear_src.set("produces", "gear_blank")
	var gmesh := MeshInstance3D.new()
	var gcm := CylinderMesh.new(); gcm.top_radius = 0.4; gcm.bottom_radius = 0.4; gcm.height = 0.18
	var gmat := StandardMaterial3D.new(); gmat.albedo_color = STEEL.darkened(0.15); gmat.metallic = 0.7; gmat.roughness = 0.4
	gcm.material = gmat; gmesh.mesh = gcm; gmesh.position = F2 + GEAR_SRC + Vector3(0, 0.2, 0)
	add_child(gmesh)
	_register_station(gear_src)
	gear_src.connect("produced", func(_id: String) -> void: GameManager.set_level_flag(location_id, "gear_taken", true))
	# secret lever + hidden nook with the spare gear (bonus)
	add_child(box_mesh(Vector3(0.2, 0.7, 0.2), Color(0.3, 0.3, 0.34), F2 + LEVER + Vector3(0, 0.9, 0)))
	add_child(box_mesh(Vector3(0.1, 0.4, 0.1), Color(0.8, 0.2, 0.2), F2 + LEVER + Vector3(0, 1.3, 0)))
	# secret nook — concrete floor + stone walls. Its south side is FULLY open (gap =
	# width) so it builds no south wall to overlap/z-fight the pipe-hall north wall;
	# the pipe hall's "n" segments + the removable _secret_wall are the only walls at z=-17.
	set_theme(CONCRETE_FLOOR, STONE_WALL)
	room(F2 + Vector3(0, 0, -20), 6, 6, FT_COOL, WT_WARM, 2.8, ["s"], 6.0, true)  # nook
	_gear_box = box_mesh(Vector3(0.7, 0.7, 0.7), Color(0.45, 0.32, 0.18), F2 + GEAR_BONUS + Vector3(0, 0.35, 0))
	add_child(_gear_box)
	# the removable panel — fills the pipe-hall "n" gap (3 wide), full pipe-hall height
	# (4), abutting the wall segments (touching, not overlapping). Drops out of sight
	# when the lever is pulled.
	_secret_wall = StaticBody3D.new()
	(_secret_wall as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(3.0, 4.0, 0.4); cs.shape = bs; cs.position = Vector3(0, 2.0, 0)
	_secret_wall.add_child(cs); _secret_wall.add_child(box_mesh(Vector3(3.0, 4.0, 0.4), WALL_COL, Vector3(0, 2.0, 0), 0.0, wall_tex))
	_secret_wall.position = F2 + Vector3(0, 0, -17)
	add_child(_secret_wall)

func _links() -> void:
	add_floor_link(
		F1 + Vector3(0, 0, -15.0), F1 + Vector3(0, 0.1, -12.0), F_WORK,
		F2 + Vector3(0, 0, 3.5), F2 + Vector3(0, 0.1, 0.0), F_LOFT,
		WOOD.lightened(0.1))

func _spawn_enemies() -> void:
	# Lobby is combat-free. Storeroom grunts only spawn if Erin hasn't been found;
	# loft runners only spawn if the level isn't already cleared.
	if GameManager.get_level_flag(location_id, "enemies_cleared", false):
		return
	if not GameManager.get_level_flag(location_id, "erin_recruited", false):
		_store_grunts.append(spawn_enemy(GRUNT, F1 + Vector3(11.5, 0.1, -2.0), "res://assets/models/enemies/grunt.glb"))
		_store_grunts.append(spawn_enemy(GRUNT, F1 + Vector3(14.5, 0.1, 2.0), "res://assets/models/enemies/grunt.glb"))
		_spawned += 2
	spawn_enemy(RUNNER, F2 + Vector3(-1.0, 0.1, -9.0), "res://assets/models/enemies/runner.glb"); _spawned += 1
	spawn_enemy(RUNNER, F2 + Vector3(4.0, 0.1, -12.0), "res://assets/models/enemies/runner.glb"); _spawned += 1

func _restore() -> void:
	_organ_repaired = GameManager.get_level_flag(location_id, "organ_repaired", false)
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_secret_revealed = GameManager.get_level_flag(location_id, "secret_revealed", false)
	_gear_bonus_open = GameManager.get_level_flag(location_id, "gear_bonus_open", false)
	_erin_recruited = GameManager.get_level_flag(location_id, "erin_recruited", false)
	# raw sources already collected → dim their markers
	if GameManager.get_level_flag(location_id, "plank_taken", false): _restore_source("rough_plank")
	if GameManager.get_level_flag(location_id, "pipe_taken", false): _restore_source("rough_organ_pipe")
	if GameManager.get_level_flag(location_id, "gear_taken", false): _restore_source("gear_blank")
	# parts already fitted → re-place on the organ
	for part: String in ORGAN_PARTS:
		if GameManager.get_level_flag(location_id, "organ_part_" + part, false):
			_organ_station.call("restore_part", part)
	if GameManager.get_level_flag(location_id, "organ_part_brass_organ_pipe", false):
		_reveal_pipes()   # pipe bank stays installed across re-entry
	if _erin_recruited:
		_recruit_erin(false)
		_storeroom_done = true
	_set_organ_phase(_organ_repaired)
	if _secret_revealed:
		_secret_wall.position.y = -5.0; (_secret_wall as StaticBody3D).collision_layer = 0
	if _gear_bonus_open: _dim(_gear_box)
	if _enemies_cleared and _organ_repaired:
		_win(false)

func _restore_source(produces_id: String) -> void:
	for s: Node3D in _stations:
		if s.get("kind") == Station.Kind.SOURCE and s.get("produces") == produces_id:
			s.call("restore_taken")
			return

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	# Raw materials are shared across the duo (whoever grabbed them), so pass the
	# party names — the active operator can mill/fit a part Erin is carrying.
	var party: Array = player.duo_names() if player.has_method("duo_names") else [char_name]
	# crafting stations (sources / tools / organ) — the organ stays locked until
	# Erin gets the tuning key from Bellows.
	for s: Node3D in _stations:
		if s == _organ_station:
			if not _key_given():
				if near3(pp, F1 + ORGAN_HIT, REACH + 0.4):
					_hud_hint.text = "The organ console is locked -- Erin needs Mr. Bellows' tuning key first."
					return
				continue
		if s.call("try_use", char_name, pp, party):
			return
	# secret lever → reveal the spare-gear nook
	if char_name == "Quinn" and not _secret_revealed and near3(pp, F2 + LEVER, REACH):
		_reveal_secret(); return
	# spare clockwork gear (bonus secret reward)
	if _secret_revealed and not _gear_bonus_open and near3(pp, F2 + GEAR_BONUS, REACH):
		_gear_bonus_open = true
		GameManager.grant_item(player.active_name(), SpareGearItem.id)
		GameManager.set_level_flag(location_id, "gear_bonus_open", true)
		_dim(_gear_box)
		_hud_hint.text = "Picked up: %s" % SpareGearItem.display_name
		Audio.play("special"); return
	# Mr. Bellows
	if near3(pp, F1 + BELLOWS, REACH + 0.6):
		_talk_bellows(char_name); return

func _key_given() -> bool:
	return GameManager.get_level_flag(location_id, "tuning_key_given", false)

func _on_organ_complete() -> void:
	_organ_repaired = true
	_set_organ_phase(true)   # derelict organ → restored organ
	GameManager.set_level_flag(location_id, "organ_repaired", true)
	_hud_hint.text = "The organ breathes again!"
	Audio.play("special")

func _dim(box: Node3D) -> void:
	((box.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = Color(0.30, 0.24, 0.16)

func _reveal_secret() -> void:
	_secret_revealed = true
	GameManager.set_level_flag(location_id, "secret_revealed", true)
	create_tween().tween_property(_secret_wall, "position:y", -5.0, 0.6)
	(_secret_wall as StaticBody3D).collision_layer = 0
	_hud_hint.text = "A hidden parts closet opens at the back of the loft."
	Audio.play("special")

func _glow_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.4, 1.0, 0.5)
	m.emission_enabled = true; m.emission = Color(0.3, 1.0, 0.45); m.emission_energy_multiplier = 1.5
	return m

# --- Erin recruit ------------------------------------------------------------
func _recruit_erin(show_line: bool) -> void:
	_erin_recruited = true
	GameManager.set_level_flag(location_id, "erin_recruited", true)
	var at: Vector3 = _erin_npc.global_position if is_instance_valid(_erin_npc) else (F1 + ERIN_HIDE)
	if is_instance_valid(_erin_npc):
		_erin_npc.queue_free()
		_erin_npc = null
	if player.has_method("add_member"):
		player.call("add_member", ERIN, at)
	refresh_duo_inventory_names()   # so Erin's bag now shows a tab in the inventory
	# Quinn's + Erin's Grand Marquee tickets — Erin was carrying both (the lead she chased)
	GameManager.grant_item("Quinn", TicketQuinn.id)
	GameManager.grant_item("Erin", TicketErin.id)
	if show_line:
		Audio.play("swap")
		var tree := {"start": {"lines": [
			"Erin steps out from behind the crates, brushing sawdust off her jacket.",
			"Erin: \"Quinn! Took you long enough. I caught a lead on Uncle Doug and came to find you --\"",
			"\"-- then those punks cornered me back here. Good timing. Let's get this place running.\"",
			"\"And leave old Bellows to me -- I'll have that tuning key out of him in a minute.\""]}}
		open_dialog("Erin", Color(0.7, 0.35, 0.3), tree, player.active_name())

# --- dialog ------------------------------------------------------------------
func _talk_bellows(char_name: String) -> void:
	var given: bool = _key_given()
	var tree: Dictionary
	if given:
		tree = {"start": {"lines": ["Mr. Bellows: \"Get that organ singing again, and there's a place for you both here.\""]}}
	elif _erin_recruited:
		tree = {
			"start": {"lines": [
				"Mr. Bellows: \"So you found the girl. Good. Now -- that organ's still dead as a doornail.\"",
				"\"If you mean to fix it you'll want my tuning key, and I don't part with it easily.\""],
				"choices": [
					{"text": "Talk the tuning key out of him", "best_with": "Erin", "next": "give", "next_alt": "need_erin"}]},
			"give": {"lines": [
				"Erin: \"That key on your belt, Mr. Bellows -- the one your father gave you. Quinn needs it, and you know it.\"",
				"He sighs and hands over a small brass tuning key."],
				"effects": {"grant_items": [TuningKeyItem.id], "set_flag": "tuning_key_given", "flag_value": true}},
			"need_erin": {"lines": ["\"I don't hand that key to just anyone. Maybe your sharp-tongued friend can change my mind.\""]},
		}
	else:
		tree = {"start": {"lines": [
			"Mr. Bellows: \"This place is falling apart and the organ hasn't breathed in months.\"",
			"\"And not ten minutes ago some punks chased a young woman -- Erin, she said -- into my back storeroom.\"",
			"\"If she's a friend of yours, you'd best get her out of there before they do something stupid.\""]}}
	GameManager.set_level_flag(location_id, "manager_met", true)
	open_dialog("Mr. Bellows", Color(0.35, 0.4, 0.32), tree, char_name)

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
	# Erin joins once the Storeroom grunts are down (the loft runners don't count).
	if not _storeroom_done and not _store_grunts.is_empty():
		var any_alive := false
		for g in _store_grunts:
			if is_instance_valid(g):
				any_alive = true
				break
		if not any_alive:
			_storeroom_done = true
			_recruit_erin(true)
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
	if not _cleared:
		var parts_n: int = _organ_station.call("placed_count")
		var bits := []
		bits.append("Erin " + ("OK" if _erin_recruited else "..."))
		bits.append("key " + ("OK" if _key_given() else "..."))
		bits.append("parts %d/3" % parts_n)
		bits.append("organ " + ("OK" if _organ_repaired else "..."))
		bits.append("workers " + ("OK" if _enemies_cleared else "..."))
		_hud_goal.text = "Find Erin (back room), gather wood/pipe/gear, mill them at the workshop tools, get the key (Erin -> Bellows), fit the parts, clear the workers. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
	if not _cleared and _enemies_cleared and _organ_repaired:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "THE ORGAN SINGS!\nWorkshop restored."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
