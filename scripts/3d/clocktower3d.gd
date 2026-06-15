extends Level3D
## The Clocktower (3D) — first MULTI-PHASE level (dungeon-crawl prototype).
## Rooms laid out north along -Z, connected by corridors, with room-aware camera
## framing on portals and a lobby exit portal:
##   Lobby (Hieronymus — dialog) → Gear Hall (Quinn repairs the gear + grunts —
##   puzzle + combat) → [gate opens once the gear turns] → Belfry (Ben rings the
##   bells + the clockwork Boss — puzzle + combat). Optional Crawlspace off the
##   Gear Hall (loot). Win = all enemies down + gear repaired + bells played.

const QUINN := preload("res://data/characters/quinn.tres")
const BEN := preload("res://data/characters/ben.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const BOSS := preload("res://data/enemies/boss.tres")
const SpareGearItem: ItemData = preload("res://data/items/spare_clockwork_gear.tres")

const FLOOR_COL := Color(0.24, 0.20, 0.16)
const WALL_COL := Color(0.33, 0.28, 0.22)
const COR_COL := Color(0.20, 0.17, 0.14)
const BRASS := Color(0.72, 0.6, 0.32)

# Room centres (climbing north along -Z)
const LOBBY := Vector3(0, 0, 0)
const COR1 := Vector3(0, 0, -9.5)
const GEAR := Vector3(0, 0, -20.0)
const CRAWL := Vector3(10.0, 0, -20.0)
const COR2 := Vector3(0, 0, -31.5)
const BELFRY := Vector3(0, 0, -45.0)

const HIERO_POS := Vector3(-2.5, 0, -1.5)
const GEAR_POS := Vector3(-3.0, 0, -20.0)
const LOOT_POS := Vector3(10.0, 0, -20.0)
const BELLS_POS := Vector3(3.0, 0, -50.0)
const GATE_POS := Vector3(0, 0, -31.0)
const REACH := 2.2

# camera framing per room (dist, elev)
const F_LOBBY := Vector2(7.5, 50.0)
const F_GEAR := Vector2(9.5, 52.0)
const F_BELFRY := Vector2(13.0, 55.0)

var _cleared := false
var _enemies_cleared := false
var _gear_repaired := false
var _bells_played := false
var _spawned := 0
var _hiero = null
var _gear: Node3D = null
var _bells: Array = []
var _gate: Node3D = null
var _loot_open := false
var _loot_box: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "clocktower"
	multi_room = true
	build_env(Color(0.05, 0.04, 0.04), Color(0.5, 0.42, 0.32), 0.5, 0.9)
	_build_rooms()
	_lights()
	_gear_mechanism()
	_bell_rack()
	_loot_crate()
	_gate_door()
	make_dialog()
	_build_hud()
	_hiero = spawn_npc("aldric", HIERO_POS, deg_to_rad(180))
	var p := spawn_duo([QUINN, BEN], LOBBY + Vector3(0, 0.1, 3.0))
	p.special_used.connect(_on_special)
	reframe_camera(F_LOBBY.x, F_LOBBY.y)
	_spawn_enemies()
	_restore()

func _build_rooms() -> void:
	room(LOBBY, 12, 10, FLOOR_COL, WALL_COL, 3.4, ["n", "s"])
	room(COR1, 4, 9, COR_COL, WALL_COL, 3.0, ["n", "s"])
	room(GEAR, 14, 12, FLOOR_COL, WALL_COL, 3.6, ["s", "n", "e"])
	room(CRAWL, 6, 6, COR_COL, WALL_COL, 2.6, ["w"])
	room(COR2, 4, 11, COR_COL, WALL_COL, 3.0, ["n", "s"])
	room(BELFRY, 16, 16, FLOOR_COL, WALL_COL, 4.2, ["s"])
	# clock-face disc on the belfry back wall
	var face := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 2.6; cm.bottom_radius = 2.6; cm.height = 0.2
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.85, 0.8, 0.65)
	mat.emission_enabled = true; mat.emission = Color(0.4, 0.35, 0.2); mat.emission_energy_multiplier = 0.4
	cm.material = mat; face.mesh = cm
	face.rotation.x = deg_to_rad(90); face.position = BELFRY + Vector3(0, 2.8, -7.6)
	add_child(face)
	# portals: exit at the lobby door, reframe on entering each main room
	add_exit_portal(LOBBY + Vector3(0, 0, 5.0), Vector3(3, 3, 1.4))
	add_room_portal(LOBBY + Vector3(0, 0, -4.5), Vector3(4, 3, 1.0), F_LOBBY.x, F_LOBBY.y)
	add_room_portal(GEAR + Vector3(0, 0, 5.5), Vector3(4, 3, 1.0), F_GEAR.x, F_GEAR.y)
	add_room_portal(BELFRY + Vector3(0, 0, 7.5), Vector3(4, 3, 1.0), F_BELFRY.x, F_BELFRY.y)

func _lights() -> void:
	point_light(LOBBY + Vector3(0, 3.0, 0), Color(1.0, 0.85, 0.6), 2.2, 9.0)
	point_light(GEAR + Vector3(0, 3.2, 0), Color(1.0, 0.8, 0.5), 2.6, 11.0)
	point_light(BELFRY + Vector3(0, 3.8, 0), Color(1.0, 0.8, 0.5), 2.8, 16.0)
	point_light(BELLS_POS + Vector3(0, 2.5, 0), Color(1.0, 0.9, 0.6), 1.6, 6.0)
	point_light(CRAWL + Vector3(0, 2.0, 0), Color(0.7, 0.8, 1.0), 1.2, 5.0)

func _gear_mechanism() -> void:
	_gear = _make_gear(0.9, 16, BRASS)
	_gear.position = GEAR_POS + Vector3(0, 0.6, 0); _gear.rotation.x = deg_to_rad(90)
	add_child(_gear)
	var g2 := _make_gear(0.55, 12, Color(0.55, 0.45, 0.28))
	g2.position = GEAR_POS + Vector3(1.3, 0.4, 0.2); g2.rotation.x = deg_to_rad(90)
	add_child(g2)

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

func _bell_rack() -> void:
	add_child(box_mesh(Vector3(3.2, 0.18, 0.18), Color(0.3, 0.22, 0.14), BELLS_POS + Vector3(0, 2.8, 0)))
	for i: int in range(4):
		var x: float = -1.1 + float(i) * 0.75
		var bell := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.05; cm.bottom_radius = 0.32; cm.height = 0.6
		var mat := StandardMaterial3D.new(); mat.albedo_color = BRASS.darkened(0.15); mat.metallic = 0.7; mat.roughness = 0.35
		cm.material = mat; bell.mesh = cm; bell.position = BELLS_POS + Vector3(x, 2.2, 0)
		add_child(bell); _bells.append(bell)

func _loot_crate() -> void:
	_loot_box = box_mesh(Vector3(0.7, 0.7, 0.7), Color(0.45, 0.32, 0.18), LOOT_POS + Vector3(0, 0.35, 0))
	add_child(_loot_box)

func _gate_door() -> void:
	_gate = StaticBody3D.new()
	(_gate as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(4.0, 3.0, 0.4); cs.shape = bs; cs.position = Vector3(0, 1.5, 0)
	_gate.add_child(cs)
	_gate.add_child(box_mesh(Vector3(4.0, 3.0, 0.4), Color(0.5, 0.3, 0.15), Vector3(0, 1.5, 0)))
	# brass bars on the gate
	for i: int in range(5):
		_gate.add_child(box_mesh(Vector3(0.1, 2.6, 0.1), BRASS, Vector3(-1.5 + float(i) * 0.75, 1.4, 0.1)))
	_gate.position = GATE_POS
	add_child(_gate)

func _spawn_enemies() -> void:
	for spot: Vector3 in [GEAR + Vector3(-2.0, 0.1, 2.0), GEAR + Vector3(3.0, 0.1, -1.5)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(BOSS, BELFRY + Vector3(0, 0.1, -1.0), "res://assets/models/enemies/grunt.glb", 1.9, Color(0.55, 0.45, 0.3)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_gear_repaired = GameManager.get_level_flag(location_id, "gear_repaired", false)
	_bells_played = GameManager.get_level_flag(location_id, "bells_played", false)
	if _gear_repaired: _open_gate(false)
	if _bells_played: _light_bells()
	if GameManager.get_level_flag(location_id, "gear_loot_open", false):
		_loot_open = true; ((_loot_box.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = Color(0.3, 0.24, 0.16)
	if _enemies_cleared and _gear_repaired and _bells_played:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, HIERO_POS, REACH + 0.6):
		_talk_hiero(char_name); return
	if not _loot_open and near3(pp, LOOT_POS, REACH):
		_loot_open = true
		GameManager.grant_item(char_name, SpareGearItem.id)
		GameManager.set_level_flag(location_id, "gear_loot_open", true)
		((_loot_box.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = Color(0.3, 0.24, 0.16)
		_hud_hint.text = "Found a spare clockwork gear."
		Audio.play("special"); return
	if char_name == "Quinn" and not _gear_repaired and near3(pp, GEAR_POS, REACH):
		_gear_repaired = true
		GameManager.set_level_flag(location_id, "gear_repaired", true)
		_open_gate(true)
		_hud_hint.text = "Quinn re-seats the escapement — the great gear turns and the belfry gate grinds open."
		Audio.play("special"); return
	if char_name == "Ben" and not _bells_played and near3(pp, BELLS_POS, REACH + 0.6):
		_bells_played = true
		GameManager.set_level_flag(location_id, "bells_played", true)
		_light_bells()
		_hud_hint.text = "Ben strikes the belfry sequence — the bells ring true."
		Audio.play("special"); return
	if char_name != "Quinn" and not _gear_repaired and near3(pp, GEAR_POS, REACH):
		_hud_hint.text = "The escapement needs Quinn's tools."
	elif char_name != "Ben" and not _bells_played and near3(pp, BELLS_POS, REACH + 0.6):
		_hud_hint.text = "The bells need Ben's ear for pitch."

func _open_gate(animate: bool) -> void:
	if animate:
		create_tween().tween_property(_gate, "position:y", -3.2, 0.7)
	else:
		_gate.position.y = -3.2
	(_gate as StaticBody3D).collision_layer = 0

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
		tree = {"start": {"lines": ["\"The gear floor above, then the belfry at the top — both need attention before the tower unlocks.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"The guardian woke when I tried to fix the gear floor myself. I'm afraid I'm more theorist than fighter.\"",
			"\"Up the stairs: Quinn, the escapement on the gear floor needs your tools and it'll open the belfry. Ben, the bells up top want a pitch sequence.\""]}}
	open_dialog("Hieronymus", Color(0.5, 0.45, 0.55), tree, char_name)

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
	if _gear_repaired and _gear != null:
		_gear.rotation.z += d * 0.8
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
	if not _cleared:
		var bits := []
		bits.append("gear " + ("OK" if _gear_repaired else "..."))
		bits.append("bells " + ("OK" if _bells_played else "..."))
		bits.append("guardian " + ("OK" if _enemies_cleared else "..."))
		_hud_goal.text = "Climb the tower: Quinn fixes the gear (opens the belfry), Ben rings the bells, beat the guardian. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
	if not _cleared and _enemies_cleared and _gear_repaired and _bells_played:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "THE TOWER WAKES!\nClocktower cleared."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
