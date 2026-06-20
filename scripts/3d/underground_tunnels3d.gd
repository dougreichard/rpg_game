extends Level3D
## The Underground Tunnels (3D) — Evan + Ethan. A descending THREE-DEPTH dungeon
## (each depth is its own world region so the top-down camera only ever sees one):
##   Depth 1 — Maintenance: the LOBBY (Cyrus + overworld exit, combat-free) + a Pump
##             Room holding the security badge. Stairs down to Depth 2.
##   Depth 2 — The Junction: the patrol (2 Grunts + Runner) + dark-alcove hiding spots.
##             West passage blocked by Evan's rubble → Storeroom (rusty key + a lore
##             photo). East Hatch Bay: Ethan's 3-pip hatch hack (the security badge
##             auto-fills one pip) → unlocks the stairs DOWN to Depth 3.
##   Depth 3 — The Sealed Vault: Evan forces the seized wheel AND Ethan hacks the lock
##             panel → the blast door grinds open (a short Uncle-Doug clue). The rusty
##             key opens a maintenance-ladder SHORTCUT straight back up to Depth 1.
## You must already carry the pocket lantern (gated at the overworld; found at the
## Harbor & Docks) — that's why it's lit down here. Win = patrol cleared + rubble +
## hatch hacked + vault opened.

const EVAN := preload("res://data/characters/evan.tres")
const ETHAN := preload("res://data/characters/ethan.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const RUNNER := preload("res://data/enemies/runner.tres")
const BadgeItem: ItemData = preload("res://data/items/security_badge.tres")
const KeyItem: ItemData = preload("res://data/items/rusty_key.tres")
const PhotoItem: ItemData = preload("res://data/items/faded_photograph.tres")

const FlashlightItem: ItemData = preload("res://data/items/doug_flashlight.tres")

const HATCH_PRESSES_REQUIRED := 3
const REACH := 2.2

# --- thematic surfaces (concrete / dirt / stone, rust trim) ---
const FLOOR_CONCRETE := "res://assets/art/tiles/synty_floor_concrete.png"
const FLOOR_DIRT := "res://assets/art/tiles/synty_floor_dirt.png"
const WALL_CONCRETE := "res://assets/art/tiles/synty_wall_concrete.png"
const WALL_STONE := "res://assets/art/tiles/synty_wall_stone.png"
const FLOOR_COL := Color(0.6, 0.58, 0.54)   # texture tint (kept dim — lantern-lit)
const WALL_COL := Color(0.58, 0.56, 0.5)
const STONE := Color(0.28, 0.26, 0.22)
const STEEL := Color(0.4, 0.42, 0.46)

const F1 := Vector3(0, 0, 0)            # Depth 1 — Maintenance (lobby)
const F2 := Vector3(60, 0, 0)           # Depth 2 — Junction
const F3 := Vector3(120, 0, 0)          # Depth 3 — Vault

const F_D1 := Vector2(9.0, 52.0)
const F_D2 := Vector2(9.5, 53.0)
const F_D3 := Vector2(8.5, 52.0)

# Depth 1 (relative to F1)
const CYRUS := Vector3(-3.0, 0, -4.0)
const BADGE := Vector3(11.0, 0, 2.0)
# Depth 2 (relative to F2)
const RUBBLE := Vector3(-6.5, 0, -9.0)
const HATCH := Vector3(8.0, 0, -9.0)
const KEY_LOOT := Vector3(-11.0, 0, -10.5)
const PHOTO_LOOT := Vector3(-11.0, 0, -7.5)
# Depth 3 (relative to F3)
const WHEEL := Vector3(-2.0, 0, -12.0)
const PANEL := Vector3(2.0, 0, -12.0)
const SHORTCUT := Vector3(2.5, 0, 2.0)
const DRAIN := Vector3(3.0, 0, -1.0)         # Depth 3: Ethan drains the flooded passage
const DRAIN_GATE := Vector3(0.0, 0, -3.5)    # flooded-passage gate (antechamber → vault)

var _cleared := false
var _enemies_cleared := false
var _rubble_cleared := false
var _hatch_progress := 0
var _badge_used := false
var _badge_taken := false
var _key_taken := false
var _photo_taken := false
var _vault_forced := false
var _vault_hacked := false
var _vault_opened := false
var _drain_done := false
var _shortcut_open := false
var _spawned := 0
var _drain_wall: Node3D = null

var _cyrus = null
var _rubble: Node3D = null
var _blast_door: Node3D = null
var _badge_box: Node3D = null
var _key_box: Node3D = null
var _photo_box: Node3D = null
var _hatch_pips: Array = []
var _vault_stair = null      # Portal3D: D2→D3, locked until the hatch is hacked
var _shortcut_stair = null   # Portal3D: D3→D1, locked until the rusty key is used
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "underground"
	multi_room = true
	build_env(Color(0.04, 0.04, 0.05), Color(0.40, 0.40, 0.46), 0.4, 0.7)
	_depth1()
	_depth2()
	_depth3()
	_links()
	make_dialog()
	_build_hud()
	_cyrus = spawn_npc("bellows", F1 + CYRUS, 0.0)   # face the camera
	prop("res://assets/models/props/desk.glb", F1 + CYRUS + Vector3(0, 0, 1.0), 0.0)   # Cyrus's maintenance desk
	var p := spawn_duo([EVAN, ETHAN], F1 + Vector3(0.0, 0.1, 4.0))
	p.special_used.connect(_on_special)
	reframe_camera(F_D1.x, F_D1.y)
	_spawn_enemies()
	_restore()

# --- Depth 1: Maintenance (lobby + pump room) -------------------------------
func _depth1() -> void:
	set_theme(FLOOR_CONCRETE, WALL_CONCRETE)
	region_floor(F1 + Vector3(1, 0, -3), 32, 22, FLOOR_COL)
	room(F1, 12, 12, FLOOR_COL, WALL_COL, 2.9, ["s", "e", "n"], 3.0, false)            # lobby
	room(F1 + Vector3(11, 0, 0), 8, 10, FLOOR_COL, WALL_COL, 2.9, ["w"], 3.0, false)   # pump room
	room(F1 + Vector3(0, 0, -9.5), 5, 7, FLOOR_COL, WALL_COL, 2.9, ["s"], 3.0, false)  # stair alcove
	point_light(F1 + Vector3(0, 2.6, -2), Color(1.0, 0.8, 0.5), 1.8, 11.0)
	point_light(F1 + Vector3(11, 2.4, 0), Color(0.7, 0.85, 1.0), 1.4, 8.0)   # pump room work-lamp
	_ceiling_pipes(F1, 12.0)
	# pump room dressing + the security badge crate
	prop("res://assets/models/props/pump_machine.glb", F1 + Vector3(13.0, 0, -2.5), deg_to_rad(-90))  # pump (Prop Farm)
	prop("res://assets/models/props/pipe_cluster.glb", F1 + Vector3(13.5, 0, 1.5), deg_to_rad(-90))    # wall pipes
	prop("res://assets/models/props/barrel.glb", F1 + Vector3(8.5, 0, 3.5))
	_badge_box = box_mesh(Vector3(0.5, 0.5, 0.5), Color(0.5, 0.7, 0.9), F1 + BADGE + Vector3(0, 0.25, 0), 0.7)
	add_child(_badge_box)
	add_exit_portal(F1 + Vector3(0, 0, 6.3), Vector3(3, 3, 1.4))

# --- Depth 2: Junction (combat + the two gates) -----------------------------
func _depth2() -> void:
	set_theme(FLOOR_DIRT, WALL_STONE)
	region_floor(F2 + Vector3(0, 0, -4), 36, 24, FLOOR_COL)
	room(F2 + Vector3(0, 0, 1), 6, 8, FLOOR_COL, WALL_COL, 2.9, ["n"], 3.0, false)          # landing
	room(F2 + Vector3(0, 0, -9), 14, 10, FLOOR_COL, WALL_COL, 3.0, ["s", "w", "e"], 3.0, false)  # junction
	room(F2 + Vector3(-11, 0, -9), 8, 8, FLOOR_COL, WALL_COL, 2.9, ["e"], 3.0, false)       # west storeroom
	room(F2 + Vector3(11, 0, -9), 8, 8, FLOOR_COL, WALL_COL, 2.9, ["w", "n"], 3.0, false)   # hatch bay
	point_light(F2 + Vector3(0, 2.8, -9), Color(0.8, 0.85, 1.0), 1.6, 12.0)
	point_light(F2 + Vector3(-11, 2.4, -9), Color(1.0, 0.75, 0.4), 1.2, 7.0)
	point_light(F2 + Vector3(11, 2.4, -9), Color(0.6, 1.0, 0.7), 1.2, 7.0)
	_ceiling_pipes(F2 + Vector3(0, 0, -9), 14.0)
	prop("res://assets/models/props/pipe_cluster.glb", F2 + Vector3(-6.5, 0, -12.5), deg_to_rad(0))   # junction wall pipes
	prop("res://assets/models/props/pipe_cluster.glb", F2 + Vector3(6.5, 0, -12.5), deg_to_rad(0))
	_rubble_pile()
	_hatch()
	# west storeroom loot: the rusty key + a lore photo
	_key_box = box_mesh(Vector3(0.5, 0.45, 0.5), Color(0.6, 0.45, 0.2), F2 + KEY_LOOT + Vector3(0, 0.25, 0), 0.7)
	add_child(_key_box)
	_photo_box = box_mesh(Vector3(0.45, 0.35, 0.45), Color(0.7, 0.65, 0.5), F2 + PHOTO_LOOT + Vector3(0, 0.2, 0), 0.5)
	add_child(_photo_box)
	# dark alcoves to slip the patrol
	add_hiding_spot(F2 + Vector3(-5.0, 0, -5.5))
	add_hiding_spot(F2 + Vector3(5.0, 0, -5.5))

# --- Depth 3: The Sealed Vault ----------------------------------------------
func _depth3() -> void:
	set_theme(FLOOR_CONCRETE, WALL_STONE)
	region_floor(F3 + Vector3(0, 0, -4), 18, 24, FLOOR_COL)
	room(F3 + Vector3(0, 0, 1), 8, 8, FLOOR_COL, WALL_COL, 2.9, ["n"], 3.0, false)          # antechamber
	room(F3 + Vector3(0, 0, -9), 12, 10, FLOOR_COL, WALL_COL, 3.2, ["s"], 3.0, false)       # vault room
	# Ethan's drain: a flooded passage gate between antechamber and vault room, with a
	# valve wheel + a pool of "water" the player can't cross until it's pumped out.
	add_child(box_mesh(Vector3(3.0, 0.08, 2.0), Color(0.1, 0.22, 0.3), F3 + Vector3(0, 0.04, -3.5), 0.3))   # water pool
	prop("res://assets/models/props/valve_wheel.glb", F3 + DRAIN, 0.0)   # Ethan's drain valve (Prop Farm)
	_drain_wall = StaticBody3D.new()
	(_drain_wall as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var dcs := CollisionShape3D.new(); var dbs := BoxShape3D.new()
	dbs.size = Vector3(3.0, 2.6, 0.4); dcs.shape = dbs; dcs.position = Vector3(0, 1.3, 0)
	_drain_wall.add_child(dcs)
	for i: int in range(4):
		_drain_wall.add_child(box_mesh(Vector3(0.1, 2.4, 0.1), STEEL, Vector3(-1.1 + float(i) * 0.73, 1.2, 0)))
	_drain_wall.position = F3 + DRAIN_GATE
	add_child(_drain_wall)
	point_light(F3 + Vector3(0, 3.0, -9), Color(1.0, 0.7, 0.45), 1.8, 13.0)
	point_light(F3 + Vector3(0, 2.4, 1), Color(0.7, 0.8, 1.0), 1.2, 7.0)
	# the sealed blast door at the north wall of the vault room
	add_child(box_mesh(Vector3(0.5, 3.2, 0.5), STEEL, F3 + Vector3(-2.6, 1.6, -13.6)))  # jamb
	add_child(box_mesh(Vector3(0.5, 3.2, 0.5), STEEL, F3 + Vector3(2.6, 1.6, -13.6)))   # jamb
	_blast_door = StaticBody3D.new()
	(_blast_door as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(5.0, 3.0, 0.4); cs.shape = bs; cs.position = Vector3(0, 1.5, 0)
	_blast_door.add_child(cs)
	_blast_door.add_child(box_mesh(Vector3(5.0, 3.0, 0.4), Color(0.34, 0.36, 0.4), Vector3(0, 1.5, 0)))
	_blast_door.add_child(box_mesh(Vector3(4.2, 0.2, 0.5), STEEL.darkened(0.15), Vector3(0, 1.5, 0)))  # seam
	_blast_door.position = F3 + Vector3(0, 0, -13.6)
	add_child(_blast_door)
	# a Prop-Farm bank-vault safe standing in the room (the heist trophy)
	prop("res://assets/models/props/vault_door.glb", F3 + Vector3(4.2, 0, -12.0), deg_to_rad(150))
	# Evan's seized wheel (left) + Ethan's lock panel (right)
	prop("res://assets/models/props/valve_wheel.glb", F3 + WHEEL + Vector3(0, 0, -1.2), 0.0)  # Evan's wheel
	prop("res://assets/models/props/control_panel.glb", F3 + PANEL + Vector3(0, 0, -1.4), 0.0)  # Ethan's lock panel (Prop Farm)
	add_child(box_mesh(Vector3(0.5, 0.18, 0.05), Color(0.3, 0.9, 0.4), F3 + PANEL + Vector3(0, 1.3, -1.27), 1.0))  # panel light

# --- shared dressing --------------------------------------------------------
func _ceiling_pipes(center: Vector3, span: float) -> void:
	for z: float in [-3.0, 3.0]:
		var pipe := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.12; cm.bottom_radius = 0.12; cm.height = span
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.3, 0.28, 0.24); mat.metallic = 0.5
		cm.material = mat; pipe.mesh = cm; pipe.rotation.z = deg_to_rad(90)
		pipe.position = center + Vector3(0, 2.5, z)
		add_child(pipe)

func _rubble_pile() -> void:
	_rubble = StaticBody3D.new()
	(_rubble as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(2.0, 1.8, 3.0); cs.shape = bs; cs.position = Vector3(0, 0.9, 0)
	_rubble.add_child(cs)
	for i: int in range(9):
		var r := box_mesh(Vector3(0.7, 0.6, 0.7), STONE.darkened(randf() * 0.2),
			Vector3(randf_range(-0.7, 0.7), randf_range(0.3, 1.5), randf_range(-1.2, 1.2)))
		r.rotation = Vector3(randf(), randf(), randf())
		_rubble.add_child(r)
	_rubble.position = F2 + RUBBLE
	add_child(_rubble)

func _hatch() -> void:
	add_child(box_mesh(Vector3(1.6, 0.1, 1.6), Color(0.3, 0.3, 0.34), F2 + HATCH + Vector3(0, 0.06, 0)))
	add_child(box_mesh(Vector3(1.2, 0.25, 1.2), Color(0.4, 0.4, 0.45), F2 + HATCH + Vector3(0, 0.2, 0)))
	for i: int in range(HATCH_PRESSES_REQUIRED):
		var pip := box_mesh(Vector3(0.18, 0.06, 0.18), Color(0.8, 0.25, 0.2), F2 + HATCH + Vector3(-0.4 + float(i) * 0.4, 0.5, 0), 1.0)
		add_child(pip)
		_hatch_pips.append(pip)

func _links() -> void:
	# D1 ↔ D2 — open
	add_floor_link(
		F1 + Vector3(0, 0, -12.0), F1 + Vector3(0, 0.1, -9.0), F_D1,
		F2 + Vector3(0, 0, 4.5), F2 + Vector3(0, 0.1, 2.0), F_D2,
		STONE.lightened(0.1))
	# D2 ↔ D3 — the down-into-vault leg is locked until the hatch is hacked
	_vault_stair = add_floor_link(
		F2 + Vector3(8, 0, -13.0), F2 + Vector3(8, 0.1, -10.5), F_D2,
		F3 + Vector3(0, 0, 3.5), F3 + Vector3(0, 0.1, 1.0), F_D3,
		STEEL.darkened(0.1), true)
	# D3 → D1 — rusty-key maintenance-ladder shortcut (locked until the key is used)
	stairs_mesh(F3 + SHORTCUT + Vector3(0, 0, 0.5), STONE.lightened(0.1))
	_shortcut_stair = add_stairwell(F3 + SHORTCUT, Vector3(3, 3, 1.4), F1 + Vector3(0, 0.1, 3.0), F_D1.x, F_D1.y, true)
	add_child(box_mesh(Vector3(0.12, 1.4, 0.12), Color(0.7, 0.5, 0.2), F3 + SHORTCUT + Vector3(-0.7, 0.7, 0)))  # rusty gate post
	add_child(box_mesh(Vector3(0.12, 1.4, 0.12), Color(0.7, 0.5, 0.2), F3 + SHORTCUT + Vector3(0.7, 0.7, 0)))

func _spawn_enemies() -> void:
	# Lobby (Depth 1) is combat-free; the vault (Depth 3) is a puzzle finale. All
	# combat is the Depth 2 patrol. Skip it entirely if already cleared.
	if GameManager.get_level_flag(location_id, "enemies_cleared", false):
		return
	for spot: Vector3 in [F2 + Vector3(-2.0, 0.1, -9.0), F2 + Vector3(2.5, 0.1, -10.5)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(RUNNER, F2 + Vector3(0.0, 0.1, -6.0), "res://assets/models/enemies/runner.glb"); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_rubble_cleared = GameManager.get_level_flag(location_id, "rubble_cleared", false)
	_hatch_progress = int(GameManager.get_level_flag(location_id, "hatch_progress", 0))
	_badge_used = GameManager.get_level_flag(location_id, "badge_used", false)
	_badge_taken = GameManager.get_level_flag(location_id, "badge_taken", false)
	_key_taken = GameManager.get_level_flag(location_id, "key_taken", false)
	_photo_taken = GameManager.get_level_flag(location_id, "photo_taken", false)
	_vault_forced = GameManager.get_level_flag(location_id, "vault_forced", false)
	_vault_hacked = GameManager.get_level_flag(location_id, "vault_hacked", false)
	_vault_opened = GameManager.get_level_flag(location_id, "vault_opened", false)
	_drain_done = GameManager.get_level_flag(location_id, "drain_done", false)
	_shortcut_open = GameManager.get_level_flag(location_id, "shortcut_open", false)
	if _rubble_cleared: _clear_rubble(false)
	if _drain_done: _open_drain(false)
	_refresh_pips()
	if _hatch_progress >= HATCH_PRESSES_REQUIRED and _vault_stair != null: _vault_stair.locked = false
	if _badge_taken and _badge_box != null: _badge_box.queue_free(); _badge_box = null
	if _key_taken and _key_box != null: _key_box.queue_free(); _key_box = null
	if _photo_taken and _photo_box != null: _photo_box.queue_free(); _photo_box = null
	if _vault_opened: _open_vault(false)
	if _shortcut_open and _shortcut_stair != null: _shortcut_stair.locked = false
	if _all_done(): _win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	# Cyrus (D1 lobby)
	if near3(pp, F1 + CYRUS, REACH + 0.4): _talk_cyrus(char_name); return
	# loot crates
	if _badge_box != null and is_instance_valid(_badge_box) and near3(pp, F1 + BADGE, REACH):
		_grant_crate(char_name, BadgeItem, "badge_taken", _badge_box); _badge_box = null; return
	if _key_box != null and is_instance_valid(_key_box) and near3(pp, F2 + KEY_LOOT, REACH):
		_grant_crate(char_name, KeyItem, "key_taken", _key_box); _key_box = null; return
	if _photo_box != null and is_instance_valid(_photo_box) and near3(pp, F2 + PHOTO_LOOT, REACH):
		_grant_crate(char_name, PhotoItem, "photo_taken", _photo_box); _photo_box = null
		_hud_hint.text = "A faded photo of Uncle Doug -- he was here."; return
	# D2 west rubble — Evan
	if not _rubble_cleared and near3(pp, F2 + RUBBLE, REACH + 0.8):
		if char_name == "Evan":
			_rubble_cleared = true
			GameManager.set_level_flag(location_id, "rubble_cleared", true)
			_clear_rubble(true)
			_hud_hint.text = "Evan heaves the rubble aside -- the west storeroom is open."
			Audio.play("special")
		else:
			_hud_hint.text = "The rubble's too heavy -- Evan can force it."
		return
	# D2 east hatch — Ethan (security badge auto-fills one pip)
	if _hatch_progress < HATCH_PRESSES_REQUIRED and near3(pp, F2 + HATCH, REACH):
		if char_name == "Ethan":
			_hack_hatch()
		else:
			_hud_hint.text = "The hatch needs Ethan's hacking passes."
		return
	# D3 flooded-passage drain — Ethan (gates the vault room)
	if not _drain_done and near3(pp, F3 + DRAIN, REACH):
		if char_name == "Ethan":
			_drain_done = true
			GameManager.set_level_flag(location_id, "drain_done", true)
			_open_drain(true)
			_hud_hint.text = "Ethan reroutes the pump valves -- the passage drains and the gate lifts to the vault."
			Audio.play("special")
		else:
			_hud_hint.text = "The passage is flooded -- Ethan can reroute the pumps to drain it."
		return
	# D3 vault — Evan wheel + Ethan panel
	if not _vault_opened and near3(pp, F3 + WHEEL, REACH):
		if char_name == "Evan" and not _vault_forced:
			_vault_forced = true; GameManager.set_level_flag(location_id, "vault_forced", true)
			_hud_hint.text = "Evan wrenches the seized wheel a full turn."
			Audio.play("special"); _check_vault()
		elif char_name != "Evan":
			_hud_hint.text = "The wheel's seized solid -- Evan can force it."
		return
	if not _vault_opened and near3(pp, F3 + PANEL, REACH):
		if char_name == "Ethan" and not _vault_hacked:
			_vault_hacked = true; GameManager.set_level_flag(location_id, "vault_hacked", true)
			_hud_hint.text = "Ethan spoofs the lock panel -- bolts retract on his side."
			Audio.play("special"); _check_vault()
		elif char_name != "Ethan":
			_hud_hint.text = "The lock panel needs Ethan's hack."
		return
	# D3 rusty-key shortcut gate
	if not _shortcut_open and near3(pp, F3 + SHORTCUT, REACH + 0.4):
		if _party_has(KeyItem.id):
			_shortcut_open = true; GameManager.set_level_flag(location_id, "shortcut_open", true)
			if _shortcut_stair != null: _shortcut_stair.locked = false
			_hud_hint.text = "The rusty key turns -- a maintenance ladder back to the surface opens."
			Audio.play("special")
		else:
			_hud_hint.text = "A locked maintenance gate -- it needs a rusty key."
		return

func _grant_crate(char_name: String, item: ItemData, flag: String, box: Node3D) -> void:
	GameManager.grant_item(char_name, item.id)
	GameManager.set_level_flag(location_id, flag, true)
	if box != null and is_instance_valid(box):
		box.queue_free()
	_hud_hint.text = "Picked up: %s" % item.display_name
	Audio.play("special")

func _hack_hatch() -> void:
	# the security badge (from the D1 pump room) auto-fills one pip on the first pass
	if not _badge_used and _party_has(BadgeItem.id):
		_badge_used = true
		GameManager.consume_item(_holder(BadgeItem.id), BadgeItem.id)
		GameManager.set_level_flag(location_id, "badge_used", true)
		_hatch_progress += 1
		_hud_hint.text = "Security badge accepted -- one pip auto-fills."
	_hatch_progress = min(_hatch_progress + 1, HATCH_PRESSES_REQUIRED)
	GameManager.set_level_flag(location_id, "hatch_progress", _hatch_progress)
	_refresh_pips()
	if _hatch_progress >= HATCH_PRESSES_REQUIRED:
		if _vault_stair != null: _vault_stair.locked = false
		_hud_hint.text = "Hatch hacked! The stairs down to the vault unlock."
	else:
		_hud_hint.text = "Hatch hack: pass %d of %d." % [_hatch_progress, HATCH_PRESSES_REQUIRED]
	Audio.play("special")

func _open_drain(animate: bool) -> void:
	(_drain_wall as StaticBody3D).collision_layer = 0
	if animate:
		create_tween().tween_property(_drain_wall, "position:y", F3.y - 3.0, 0.6)
	else:
		_drain_wall.position.y = F3.y - 3.0

func _check_vault() -> void:
	if _vault_forced and _vault_hacked and not _vault_opened:
		_vault_opened = true
		GameManager.set_level_flag(location_id, "vault_opened", true)
		GameManager.grant_item(player.active_name(), FlashlightItem.id)
		_open_vault(true)

func _open_vault(animate: bool) -> void:
	if animate:
		var tw := create_tween()
		tw.tween_property(_blast_door, "position:y", 3.4, 0.9)
		tw.tween_callback(func() -> void: (_blast_door as StaticBody3D).collision_layer = 0)
		_cyrus_says_deep()
	else:
		_blast_door.position.y += 3.4
		(_blast_door as StaticBody3D).collision_layer = 0

func _cyrus_says_deep() -> void:
	var tree := {"start": {"lines": [
		"The vault grinds open. Inside: a cot, cold coffee, and Doug's jacket on a hook.",
		"\"He was held here, alright,\" Cyrus's voice crackles over the tunnel intercom. \"Recently, too. You're close now.\""]}}
	open_dialog("Cyrus", Color(0.4, 0.38, 0.32), tree, player.active_name())

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

func _party_has(id: String) -> bool:
	return _holder(id) != ""

func _holder(id: String) -> String:
	var names: Array = player.duo_names() if player.has_method("duo_names") else []
	for n: String in names:
		if GameManager.has_item(n, id):
			return n
	return ""

func _talk_cyrus(char_name: String) -> void:
	var tree: Dictionary
	if _all_done():
		tree = {"start": {"lines": ["\"Vault's open and the tunnels are clear. Whatever's down there, you found it. Good work.\""]}}
	elif _rubble_cleared or _hatch_progress > 0 or _vault_forced or _vault_hacked:
		tree = {"start": {"lines": [
			"\"West rubble's Evan's job, east hatch is Ethan's. Once that hatch is open, the stairs down to the old vault unlock.\"",
			"\"Find a badge in the pump room -- it'll save you a pass on the hatch.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"Cyrus -- I keep these tunnels running. A patrol moved in and I've not been down past the junction since.\"",
			"\"Two ways on from the junction: west passage is blocked by rubble Evan can shift; east hatch needs Ethan to hack it. Grab the security badge from the pump room first -- it auto-fills a pip.\"",
			"\"The vault's the deepest point. Takes both of them to crack -- and mind that patrol.\""]}}
	open_dialog("Cyrus", Color(0.4, 0.38, 0.32), tree, char_name)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _all_done() -> bool:
	return _enemies_cleared and _rubble_cleared and _hatch_progress >= HATCH_PRESSES_REQUIRED and _vault_opened

func _build_hud() -> void:
	build_default_hud()
	_hud_goal = hud_goal; _hud_hint = hud_toast; _hud_banner = hud_ribbon

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
		bits.append("vault " + ("OK" if _vault_opened else "..."))
		_hud_goal.text = "Down to the vault: clear the patrol, Evan forces the west rubble, Ethan hacks the east hatch, then crack the vault (Evan + Ethan). (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
	if not _cleared and _all_done():
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "TUNNELS CLEARED!\nDoug's trail goes deeper."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
