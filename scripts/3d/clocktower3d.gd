extends Level3D
## The Clocktower (3D) — MULTI-FLOOR, first boss. Three floors, each its own region +
## rooms joined by stairwells (so the top-down camera sees one floor — it reads as
## climbing):
##   Floor 1 — Lobby (Hieronymus) + Workshop (spare-gear loot · Doug's pocket-watch ·
##             the optional weight-sequence cabinet → archive key)
##   Floor 2 — Landing + Gear Hall (Quinn repairs the escapement · grunts) → stairs up,
##             LOCKED until the gear turns
##   Floor 3 — Antechamber (Ben times the swinging pendulum to pass) + Belfry (Ben rings
##             the bells · clockwork Boss)
## Tile/stone surfaces, brass accents. Win = enemies down + gear repaired + bells played.

const QUINN := preload("res://data/characters/quinn.tres")
const BEN := preload("res://data/characters/ben.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const BOSS := preload("res://data/enemies/boss.tres")
const SpareGearItem: ItemData = preload("res://data/items/spare_clockwork_gear.tres")
const TuningForkItem: ItemData = preload("res://data/items/tuning_fork.tres")
const ArchiveKeyItem: ItemData = preload("res://data/items/archive_key.tres")
const WatchItem: ItemData = preload("res://data/items/doug_pocketwatch.tres")

# --- thematic surfaces (tile floor / stone walls / brass accents) ---
const TILE_FLOOR := "res://assets/art/tiles/synty_floor_tile.png"
const STONE_WALL := "res://assets/art/tiles/synty_wall_stone.png"
const FT := Color(0.82, 0.78, 0.66)
const WT := Color(0.74, 0.72, 0.66)
const STONE := Color(0.72, 0.70, 0.64)
const BRASS := Color(0.72, 0.6, 0.32)

const FG := 60.0                       # floor regions are this far apart in X
const F1 := Vector3(0, 0, 0)           # ground floor origin
const F2 := Vector3(FG, 0, 0)          # gear floor
const F3 := Vector3(FG * 2.0, 0, 0)    # belfry

# content positions (relative offsets added to floor origins)
const HIERO := Vector3(-2.5, 0, 0.5)         # F1 lobby
const LOOT := Vector3(0, 0, -13.0)           # F1 workshop: spare gear
const WATCH := Vector3(2.5, 0, -10.5)        # F1 workshop: Doug's pocket-watch
const WEIGHTS := [Vector3(-4.0, 0, -9.0), Vector3(-4.0, 0, -11.5), Vector3(-4.0, 0, -14.0)]  # F1 weight cranks
const GEARPOS := Vector3(-3.0, 0, -12.0)     # F2 gear hall
const PEND := Vector3(0, 0, -4.5)            # F3 antechamber→belfry pendulum gate
const BELLS := Vector3(3.0, 0, -16.0)        # F3 belfry
const REACH := 2.2

# camera framing per floor (dist, elev)
const F_LOBBY := Vector2(8.0, 50.0)
const F_GEAR := Vector2(9.5, 52.0)
const F_BELFRY := Vector2(13.0, 55.0)

const PULSE_SPEED := 2.2
const PULSE_OPEN := 0.7

var _cleared := false
var _enemies_cleared := false
var _gear_repaired := false
var _bells_played := false
var _loot_open := false
var _watch_taken := false
var _pend_stilled := false
var _weight_seq: Array = []
var _archive_open := false
var _spawned := 0
var _hiero = null
var _gear: Node3D = null
var _bells: Array = []
var _loot_box: Node3D = null
var _weight_flames: Array = []
var _pend_bob: Node3D = null
var _pend_gate: Node3D = null
var _stair2 = null        # gear floor -> belfry, locked until the gear turns
var _gate: Node3D = null
var _pulse: float = 0.0
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_pulse: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "clocktower"
	multi_room = true
	build_env(Color(0.05, 0.04, 0.04), Color(0.5, 0.42, 0.32), 0.5, 0.9)
	set_theme(TILE_FLOOR, STONE_WALL)
	_floor1()
	_floor2()
	_floor3()
	_links()
	make_dialog()
	_build_hud()
	_hiero = spawn_npc("aldric", F1 + HIERO, 0.0)   # face the camera
	prop("res://assets/models/props/desk.glb", F1 + HIERO + Vector3(0, 0, 1.0), 0.0)   # Hieronymus's workbench
	var p := spawn_duo([QUINN, BEN], F1 + Vector3(0, 0.1, 3.0))
	p.special_used.connect(_on_special)
	reframe_camera(F_LOBBY.x, F_LOBBY.y)
	_spawn_enemies()
	_restore()

# --- Floor 1: Lobby + Workshop ----------------------------------------------
func _floor1() -> void:
	region_floor(F1 + Vector3(0, 0, -5), 14, 24, FT)
	room(F1, 12, 12, FT, WT, 3.4, ["n", "s"], 3.0, false)                          # lobby walls
	room(F1 + Vector3(0, 0, -11), 10, 10, FT, WT, 3.0, ["s"], 3.0, false)          # workshop walls
	point_light(F1 + Vector3(0, 3.0, 0), Color(1.0, 0.85, 0.6), 2.2, 9.0)
	point_light(F1 + Vector3(0, 2.6, -11), Color(0.9, 0.85, 0.7), 1.6, 7.0)
	_loot_box = box_mesh(Vector3(0.7, 0.7, 0.7), Color(0.45, 0.32, 0.18), F1 + LOOT + Vector3(0, 0.35, 0))
	add_child(_loot_box)
	prop("res://assets/models/props/shelf.glb", F1 + Vector3(-3.5, 0, -14), deg_to_rad(90))
	prop("res://assets/models/props/barrel.glb", F1 + Vector3(3.5, 0, -14))
	prop("res://assets/models/props/clock_face.glb", F1 + Vector3(4.5, 0, 3.5), deg_to_rad(200))   # ornate display clock (lobby)
	# Doug's pocket-watch on a workbench (reused table prop) + its brass glint
	prop("res://assets/models/props/table.glb", F1 + WATCH, 0.0)
	add_child(box_mesh(Vector3(0.22, 0.06, 0.22), BRASS, F1 + WATCH + Vector3(0, 0.84, 0), 1.5))
	# weight-crank cabinet (optional archive key) — three winders + a numbered tag each
	for i: int in range(WEIGHTS.size()):
		add_child(box_mesh(Vector3(0.3, 1.1, 0.3), Color(0.3, 0.3, 0.34), F1 + WEIGHTS[i] + Vector3(0, 0.55, 0)))
		var glow := box_mesh(Vector3(0.34, 0.18, 0.34), Color(0.9, 0.7, 0.3), F1 + WEIGHTS[i] + Vector3(0, 1.18, 0), 2.0)
		glow.visible = false
		add_child(glow)
		_weight_flames.append(glow)
		_floating_label(str(i + 1), F1 + WEIGHTS[i] + Vector3(0, 1.5, 0), Color(0.9, 0.8, 0.4))
	add_exit_portal(F1 + Vector3(0, 0, 6.5), Vector3(3, 3, 1.4))

# --- Floor 2: Landing + Gear Hall -------------------------------------------
func _floor2() -> void:
	region_floor(F2 + Vector3(0, 0, -6.5), 16, 24, FT)
	room(F2, 8, 8, FT, WT, 3.0, ["n"], 3.0, false)                                 # landing
	room(F2 + Vector3(0, 0, -11), 14, 12, FT, WT, 3.6, ["s", "n"], 3.0, false)     # gear hall
	point_light(F2 + Vector3(0, 2.6, 0), Color(0.9, 0.85, 0.7), 1.6, 6.0)
	point_light(F2 + Vector3(0, 3.2, -11), Color(1.0, 0.8, 0.5), 2.6, 11.0)
	_gear_mechanism()
	_gate_door(F2 + Vector3(0, 0, -15.0))   # barred belfry stair (opens with the gear)

# --- Floor 3: Antechamber + Belfry ------------------------------------------
func _floor3() -> void:
	region_floor(F3 + Vector3(0, 0, -7.5), 18, 26, FT)
	room(F3, 8, 8, FT, WT, 3.0, ["n"], 3.0, false)                                 # antechamber
	room(F3 + Vector3(0, 0, -12), 16, 14, FT, WT, 4.2, ["s"], 3.0, false)          # belfry
	point_light(F3 + Vector3(0, 2.6, 0), Color(0.9, 0.85, 0.7), 1.4, 5.0)
	point_light(F3 + Vector3(0, 3.8, -12), Color(1.0, 0.8, 0.5), 2.8, 16.0)
	point_light(F3 + BELLS + Vector3(0, 2.5, 0), Color(1.0, 0.9, 0.6), 1.6, 6.0)
	_pendulum()
	_bell_rack()

func _links() -> void:
	add_floor_link(
		F1 + Vector3(0, 0, -15.5), F1 + Vector3(0, 0.1, -12.5), F_LOBBY,
		F2 + Vector3(0, 0, 3.5), F2 + Vector3(0, 0.1, 0.0), F_GEAR,
		STONE.lightened(0.05))
	_stair2 = add_floor_link(
		F2 + Vector3(0, 0, -16.5), F2 + Vector3(0, 0.1, -13.0), F_GEAR,
		F3 + Vector3(0, 0, 3.5), F3 + Vector3(0, 0.1, 0.0), F_BELFRY,
		STONE.lightened(0.05), true)
	var face := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 2.6; cm.bottom_radius = 2.6; cm.height = 0.2
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.85, 0.8, 0.65)
	mat.emission_enabled = true; mat.emission = Color(0.4, 0.35, 0.2); mat.emission_energy_multiplier = 0.4
	cm.material = mat; face.mesh = cm; face.rotation.x = deg_to_rad(90)
	face.position = F3 + Vector3(0, 2.8, -18.6)
	add_child(face)

func _floating_label(txt: String, pos: Vector3, col: Color) -> void:
	var l := Label3D.new()
	l.text = txt; l.font = UITheme.font(); l.font_size = 40; l.outline_size = 12
	l.modulate = col; l.outline_modulate = Color(0, 0, 0, 0.95)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true
	l.fixed_size = true; l.pixel_size = 0.001; l.position = pos
	add_child(l)

func _gear_mechanism() -> void:
	# Prop-Farm clockwork gear train as the hero backdrop; the primitive gears spin in front of
	# it (the "it's running" cue once Quinn repairs it).
	prop("res://assets/models/props/clock_gears.glb", F2 + GEARPOS + Vector3(0, 1.4, -1.0), 0.0)
	_gear = _make_gear(0.9, 16, BRASS)
	_gear.position = F2 + GEARPOS + Vector3(0, 0.6, 0); _gear.rotation.x = deg_to_rad(90)
	add_child(_gear)
	var g2 := _make_gear(0.55, 12, Color(0.55, 0.45, 0.28))
	g2.position = F2 + GEARPOS + Vector3(1.3, 0.4, 0.2); g2.rotation.x = deg_to_rad(90)
	add_child(g2)
	# a clockmaker's display pieces dressing the hall
	prop("res://assets/models/props/clock_pendulum.glb", F2 + GEARPOS + Vector3(4.5, 0, 1.5), deg_to_rad(-30))

func _make_gear(radius: float, teeth: int, col: Color) -> Node3D:
	var root := Node3D.new()
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = radius; cm.bottom_radius = radius; cm.height = 0.2
	var mat := StandardMaterial3D.new(); mat.albedo_color = col; mat.metallic = 0.6; mat.roughness = 0.4
	cm.material = mat; disc.mesh = cm; root.add_child(disc)
	for i: int in range(teeth):
		var a: float = TAU * float(i) / float(teeth)
		root.add_child(box_mesh(Vector3(0.16, 0.22, 0.2), col, Vector3(cos(a) * radius, 0, sin(a) * radius)))
	return root

# Swinging pendulum + a barred gate it blocks; Ben times the swing to still it.
func _pendulum() -> void:
	add_child(box_mesh(Vector3(0.12, 0.12, 4.6), BRASS.darkened(0.1), F3 + Vector3(0, 4.0, -4.5)))  # top rail
	_pend_bob = Node3D.new()
	_pend_bob.position = F3 + PEND + Vector3(0, 2.0, 0)
	add_child(_pend_bob)
	_pend_bob.add_child(box_mesh(Vector3(0.1, 2.0, 0.1), Color(0.4, 0.36, 0.3), Vector3(0, 1.0, 0)))  # rod
	var bob := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.4; cm.bottom_radius = 0.4; cm.height = 0.25
	var m := StandardMaterial3D.new(); m.albedo_color = BRASS; m.metallic = 0.7; m.roughness = 0.3
	cm.material = m; bob.mesh = cm; bob.rotation.x = deg_to_rad(90); bob.position = Vector3(0, 0, 0)
	_pend_bob.add_child(bob)
	# the barred gate behind the swing
	_pend_gate = StaticBody3D.new()
	(_pend_gate as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(3.2, 2.8, 0.3); cs.shape = bs; cs.position = Vector3(0, 1.4, 0)
	_pend_gate.add_child(cs)
	for i: int in range(4):
		_pend_gate.add_child(box_mesh(Vector3(0.12, 2.6, 0.12), BRASS, Vector3(-1.1 + float(i) * 0.73, 1.3, 0)))
	_pend_gate.position = F3 + PEND + Vector3(0, 0, -0.2)
	add_child(_pend_gate)

func _bell_rack() -> void:
	# Prop-Farm bronze tower bells as the belfry hero; the primitive bells (below) are the
	# playable set Ben rings in sequence.
	prop("res://assets/models/props/tower_bells.glb", F3 + BELLS + Vector3(0, 0, -1.2), 0.0)
	add_child(box_mesh(Vector3(3.2, 0.18, 0.18), Color(0.3, 0.22, 0.14), F3 + BELLS + Vector3(0, 2.8, 0)))
	for i: int in range(4):
		var x: float = -1.1 + float(i) * 0.75
		var bell := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.05; cm.bottom_radius = 0.32; cm.height = 0.6
		var mat := StandardMaterial3D.new(); mat.albedo_color = BRASS.darkened(0.15); mat.metallic = 0.7; mat.roughness = 0.35
		cm.material = mat; bell.mesh = cm; bell.position = F3 + BELLS + Vector3(x, 2.2, 0)
		add_child(bell); _bells.append(bell)

func _gate_door(pos: Vector3) -> void:
	_gate = StaticBody3D.new()
	(_gate as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(3.4, 2.8, 0.4); cs.shape = bs; cs.position = Vector3(0, 1.4, 0)
	_gate.add_child(cs)
	for i: int in range(5):
		_gate.add_child(box_mesh(Vector3(0.12, 2.6, 0.12), BRASS, Vector3(-1.3 + float(i) * 0.65, 1.3, 0)))
	_gate.add_child(box_mesh(Vector3(3.4, 0.3, 0.3), BRASS.darkened(0.1), Vector3(0, 2.7, 0)))
	_gate.position = pos
	add_child(_gate)

func _spawn_enemies() -> void:
	for spot: Vector3 in [F2 + Vector3(-2.0, 0.1, -10.0), F2 + Vector3(3.0, 0.1, -13.0)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(BOSS, F3 + Vector3(0, 0.1, -13.0), "res://assets/models/enemies/grunt.glb", 1.9, Color(0.55, 0.45, 0.3)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_gear_repaired = GameManager.get_level_flag(location_id, "gear_repaired", false)
	_bells_played = GameManager.get_level_flag(location_id, "bells_played", false)
	_watch_taken = GameManager.get_level_flag(location_id, "watch_taken", false)
	_pend_stilled = GameManager.get_level_flag(location_id, "pendulum_stilled", false)
	_archive_open = GameManager.get_level_flag(location_id, "archive_open", false)
	if _gear_repaired: _open_gate(false)
	if _bells_played: _light_bells()
	if _pend_stilled: _still_pendulum(false)
	if _archive_open:
		for f in _weight_flames: f.visible = true
	if GameManager.get_level_flag(location_id, "gear_loot_open", false):
		_loot_open = true; ((_loot_box.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = Color(0.3, 0.24, 0.16)
	if _enemies_cleared and _gear_repaired and _bells_played:
		_win(false)

# --- interaction -------------------------------------------------------------
func on_stair_locked() -> void:
	_hud_hint.text = "The way up is barred — get the great gear turning first."

func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, F1 + HIERO, REACH + 0.6):
		_talk_hiero(char_name); return
	if not _loot_open and near3(pp, F1 + LOOT, REACH):
		_loot_open = true
		GameManager.grant_item(char_name, SpareGearItem.id)
		GameManager.set_level_flag(location_id, "gear_loot_open", true)
		((_loot_box.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = Color(0.3, 0.24, 0.16)
		_hud_hint.text = "Found a spare clockwork gear."
		Audio.play("special"); return
	# Doug's pocket-watch (Quinn winds it)
	if not _watch_taken and near3(pp, F1 + WATCH, REACH):
		if char_name == "Quinn":
			_take_watch(char_name)
		else:
			_hud_hint.text = "A stopped pocket-watch — Quinn could wind it open."
		return
	# weight-crank sequence (optional → archive key)
	if not _archive_open:
		for i: int in range(WEIGHTS.size()):
			if near3(pp, F1 + WEIGHTS[i], REACH):
				_try_weight(char_name, i); return
	# gear escapement (Quinn)
	if char_name == "Quinn" and not _gear_repaired and near3(pp, F2 + GEARPOS, REACH):
		_gear_repaired = true
		GameManager.set_level_flag(location_id, "gear_repaired", true)
		_open_gate(true)
		_hud_hint.text = "Quinn re-seats the escapement — the gear turns and the belfry stair unbars."
		Audio.play("special"); return
	# pendulum timing (Ben) — opens the barred gate to the belfry
	if not _pend_stilled and near3(pp, F3 + PEND, REACH + 0.8):
		if char_name == "Ben":
			_try_pendulum()
		else:
			_hud_hint.text = "Time the swing — Ben can read the rhythm and still it."
		return
	# belfry bells (Ben)
	if char_name == "Ben" and not _bells_played and near3(pp, F3 + BELLS, REACH + 0.6):
		_bells_played = true
		GameManager.set_level_flag(location_id, "bells_played", true)
		_light_bells()
		GameManager.grant_item(char_name, TuningForkItem.id)
		_hud_hint.text = "Ben strikes the belfry sequence — the bells ring true. (Found a tuning fork)"
		Audio.play("special"); return
	if char_name != "Quinn" and not _gear_repaired and near3(pp, F2 + GEARPOS, REACH):
		_hud_hint.text = "The escapement needs Quinn's tools."
	elif char_name != "Ben" and not _bells_played and near3(pp, F3 + BELLS, REACH + 0.6):
		_hud_hint.text = "The bells need Ben's ear for pitch."

func _take_watch(char_name: String) -> void:
	_watch_taken = true
	GameManager.set_level_flag(location_id, "watch_taken", true)
	GameManager.grant_item(char_name, WatchItem.id)
	open_dialog("Doug's Pocket-Watch", Color(0.6, 0.5, 0.3),
		{"start": {"lines": [
			"Quinn winds the seized watch until it ticks. It's stopped at 11:54 -- and won't go past.",
			"The case-back is engraved in Doug's hand: \"Time keeps. -- the Marquee.\"",
			"Picked up: Doug's Pocket-Watch."]}}, char_name)
	Audio.play("special")

func _try_weight(char_name: String, i: int) -> void:
	if char_name != "Quinn":
		_hud_hint.text = "These weight cranks are stiff — Quinn's job."
		return
	if _weight_flames[i].visible:
		return
	if i == _weight_seq.size():
		_weight_seq.append(i)
		_weight_flames[i].visible = true
		Audio.play("special")
		if _weight_seq.size() == WEIGHTS.size():
			_archive_open = true
			GameManager.set_level_flag(location_id, "archive_open", true)
			GameManager.grant_item(char_name, ArchiveKeyItem.id)
			_hud_hint.text = "The weights settle in order; the cabinet clicks open — an archive key. (Found Archive Key)"
		else:
			_hud_hint.text = "Weight %d wound. They must go in order, lightest first." % (i + 1)
	else:
		_weight_seq.clear()
		for f in _weight_flames: f.visible = false
		_hud_hint.text = "The train slips — the weights reset. Wind them 1, 2, 3."

func _try_pendulum() -> void:
	if abs(sin(_pulse)) > PULSE_OPEN:
		_still_pendulum(true)
		GameManager.set_level_flag(location_id, "pendulum_stilled", true)
		_hud_hint.text = "Ben jams the escapement at the top of the swing — the pendulum locks and the gate lifts."
		Audio.play("special")
	else:
		_hud_hint.text = "Mistimed — wait for the bob to reach the far side, then strike."
		Audio.play("hurt")

func _still_pendulum(animate: bool) -> void:
	_pend_stilled = true
	(_pend_gate as StaticBody3D).collision_layer = 0
	if animate:
		create_tween().tween_property(_pend_gate, "position:y", F3.y - 3.0, 0.6)
	else:
		_pend_gate.position.y = F3.y - 3.0

func _open_gate(animate: bool) -> void:
	if _stair2 != null:
		_stair2.set("locked", false)
	if _gate == null:
		return
	if animate:
		create_tween().tween_property(_gate, "position:y", -3.0, 0.7)
	else:
		_gate.position.y = -3.0

func _light_bells() -> void:
	for bell in _bells:
		var m := (bell as MeshInstance3D).mesh as CylinderMesh
		m.material.albedo_color = Color(1.0, 0.85, 0.4)
		m.material.emission_enabled = true; m.material.emission = Color(1.0, 0.8, 0.3); m.material.emission_energy_multiplier = 0.8

func _talk_hiero(char_name: String) -> void:
	var tree: Dictionary
	if _enemies_cleared and _gear_repaired and _bells_played:
		tree = {"start": {"lines": ["\"Remarkable. Thirty years I couldn't silence that guardian. You've done it in one visit.\""]}}
	elif _gear_repaired or _bells_played:
		tree = {"start": {"lines": ["\"The gear floor, then the belfry above it — both need attention before the tower unlocks.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"The guardian woke when I tried to fix the gear floor myself. I'm afraid I'm more theorist than fighter.\"",
			"\"Up the stairs: Quinn, the escapement on the gear floor wants your tools — it unbars the belfry stair too. Ben, mind the great pendulum in the antechamber, and the bells up top want a pitch sequence.\"",
			"\"And do look at the workbench -- a friend left his pocket-watch here, long ago.\""]}}
	open_dialog("Hieronymus", Color(0.5, 0.45, 0.55), tree, char_name)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := build_default_hud()
	_hud_goal = hud_goal; _hud_hint = hud_toast; _hud_banner = hud_ribbon
	_hud_pulse = hud_label(cl, -110, 24, true); _hud_pulse.visible = false

func _process(d: float) -> void:
	super._process(d)
	if _gear_repaired and _gear != null:
		_gear.rotation.z += d * 0.8
	# pendulum swing + timing HUD
	if not _pend_stilled and _pend_bob != null:
		_pulse += d * PULSE_SPEED
		_pend_bob.rotation.z = sin(_pulse) * 0.7
		var near_pend: bool = player != null and is_instance_valid(player) and player.global_position.distance_to(F3 + PEND) < 7.0
		_hud_pulse.visible = near_pend
		if near_pend:
			var open: bool = abs(sin(_pulse)) > PULSE_OPEN
			_hud_pulse.text = "Pendulum: " + ("OPEN — strike now! (Ben)" if open else "swinging…")
	elif _hud_pulse.visible:
		_hud_pulse.visible = false
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
	if not _cleared:
		var bits := []
		bits.append("gear " + ("OK" if _gear_repaired else "..."))
		bits.append("bells " + ("OK" if _bells_played else "..."))
		bits.append("guardian " + ("OK" if _enemies_cleared else "..."))
		_hud_goal.text = "Climb the tower: Quinn fixes the gear (unbars the belfry stair), Ben times the pendulum + rings the bells, beat the guardian. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
	if not _cleared and _enemies_cleared and _gear_repaired and _bells_played:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""; _hud_pulse.visible = false
	_hud_banner.text = "THE TOWER WAKES!\nClocktower cleared."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
