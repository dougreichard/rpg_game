extends Level3D
## The Clocktower (3D) — first MULTI-FLOOR level (dungeon-crawl prototype).
## Three floors, each their own region + multiple rooms, joined by stairwells
## (each floor lives apart in world space so the top-down camera only ever sees
## one floor — it reads as climbing):
##   Floor 1 — Lobby (Hieronymus · dialog) + Workshop (spare-gear loot) → stairs up
##   Floor 2 — Landing + Gear Hall (Quinn repairs the gear · puzzle + grunts · combat)
##             → stairs up, LOCKED until the gear turns
##   Floor 3 — Antechamber + Belfry (Ben rings the bells · puzzle + clockwork Boss · combat)
## Win = all enemies down + gear repaired + bells played.

const QUINN := preload("res://data/characters/quinn.tres")
const BEN := preload("res://data/characters/ben.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const BOSS := preload("res://data/enemies/boss.tres")
const SpareGearItem: ItemData = preload("res://data/items/spare_clockwork_gear.tres")

const FLOOR_COL := Color(0.24, 0.20, 0.16)
const WALL_COL := Color(0.33, 0.28, 0.22)
const STONE := Color(0.3, 0.26, 0.2)
const BRASS := Color(0.72, 0.6, 0.32)

const FG := 60.0                       # floor regions are this far apart in X
const F1 := Vector3(0, 0, 0)           # ground floor origin
const F2 := Vector3(FG, 0, 0)          # gear floor
const F3 := Vector3(FG * 2.0, 0, 0)    # belfry

# content positions (relative offsets added to floor origins)
const HIERO := Vector3(-2.5, 0, 0.5)         # F1 lobby
const LOOT := Vector3(0, 0, -13.0)           # F1 workshop
const GEARPOS := Vector3(-3.0, 0, -12.0)     # F2 gear hall
const BELLS := Vector3(3.0, 0, -16.0)        # F3 belfry
const REACH := 2.2

# camera framing per floor (dist, elev)
const F_LOBBY := Vector2(8.0, 50.0)
const F_GEAR := Vector2(9.5, 52.0)
const F_BELFRY := Vector2(13.0, 55.0)

var _cleared := false
var _enemies_cleared := false
var _gear_repaired := false
var _bells_played := false
var _loot_open := false
var _spawned := 0
var _hiero = null
var _gear: Node3D = null
var _bells: Array = []
var _loot_box: Node3D = null
var _stair2 = null        # gear floor -> belfry, locked until the gear turns
var _gate: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "clocktower"
	multi_room = true
	build_env(Color(0.05, 0.04, 0.04), Color(0.5, 0.42, 0.32), 0.5, 0.9)
	_floor1()
	_floor2()
	_floor3()
	make_dialog()
	_build_hud()
	_hiero = spawn_npc("aldric", F1 + HIERO, deg_to_rad(180))
	var p := spawn_duo([QUINN, BEN], F1 + Vector3(0, 0.1, 3.0))
	p.special_used.connect(_on_special)
	reframe_camera(F_LOBBY.x, F_LOBBY.y)
	_spawn_enemies()
	_restore()

# --- Floor 1: Lobby + Workshop ----------------------------------------------
func _floor1() -> void:
	region_floor(F1 + Vector3(0, 0, -5), 14, 24, FLOOR_COL)           # continuous floor
	room(F1, 12, 12, FLOOR_COL, WALL_COL, 3.4, ["n", "s"], 3.0, false)         # lobby walls
	room(F1 + Vector3(0, 0, -11), 10, 10, STONE, WALL_COL, 3.0, ["s"], 3.0, false)  # workshop walls
	point_light(F1 + Vector3(0, 3.0, 0), Color(1.0, 0.85, 0.6), 2.2, 9.0)
	point_light(F1 + Vector3(0, 2.6, -11), Color(0.9, 0.85, 0.7), 1.6, 7.0)
	_loot_box = box_mesh(Vector3(0.7, 0.7, 0.7), Color(0.45, 0.32, 0.18), F1 + LOOT + Vector3(0, 0.35, 0))
	add_child(_loot_box)
	prop("res://assets/models/props/shelf.glb", F1 + Vector3(-3.5, 0, -14), deg_to_rad(90))
	prop("res://assets/models/props/barrel.glb", F1 + Vector3(3.5, 0, -14))
	# exit door (south) back to the overworld; stairs UP at the workshop's north
	add_exit_portal(F1 + Vector3(0, 0, 6.5), Vector3(3, 3, 1.4))
	stairs_mesh(F1 + Vector3(0, 0, -15.0), STONE.lightened(0.05))
	add_stairwell(F1 + Vector3(0, 0, -15.5), Vector3(3, 3, 1.4), F2 + Vector3(0, 0.1, 0.0), F_GEAR.x, F_GEAR.y)

# --- Floor 2: Landing + Gear Hall -------------------------------------------
func _floor2() -> void:
	region_floor(F2 + Vector3(0, 0, -6.5), 16, 24, FLOOR_COL)
	room(F2, 8, 8, STONE, WALL_COL, 3.0, ["n"], 3.0, false)                       # landing
	room(F2 + Vector3(0, 0, -11), 14, 12, FLOOR_COL, WALL_COL, 3.6, ["s", "n"], 3.0, false)  # gear hall
	point_light(F2 + Vector3(0, 2.6, 0), Color(0.9, 0.85, 0.7), 1.6, 6.0)
	point_light(F2 + Vector3(0, 3.2, -11), Color(1.0, 0.8, 0.5), 2.6, 11.0)
	_gear_mechanism()
	# stairs DOWN to floor 1 (at the landing) and UP to the belfry (gated by the gear)
	stairs_mesh(F2 + Vector3(0, 0, 3.0), STONE.lightened(0.05))
	add_stairwell(F2 + Vector3(0, 0, 3.5), Vector3(3, 3, 1.4), F1 + Vector3(0, 0.1, -12.0), F_LOBBY.x, F_LOBBY.y)
	stairs_mesh(F2 + Vector3(0, 0, -16.0), STONE.lightened(0.05))
	_stair2 = add_stairwell(F2 + Vector3(0, 0, -16.5), Vector3(3, 3, 1.4), F3 + Vector3(0, 0.1, 0.0), F_BELFRY.x, F_BELFRY.y, true)
	_gate_door(F2 + Vector3(0, 0, -15.0))

# --- Floor 3: Antechamber + Belfry ------------------------------------------
func _floor3() -> void:
	region_floor(F3 + Vector3(0, 0, -7.5), 18, 26, FLOOR_COL)
	room(F3, 8, 8, STONE, WALL_COL, 3.0, ["n"], 3.0, false)                       # antechamber
	room(F3 + Vector3(0, 0, -12), 16, 14, FLOOR_COL, WALL_COL, 4.2, ["s"], 3.0, false)  # belfry
	point_light(F3 + Vector3(0, 2.6, 0), Color(0.9, 0.85, 0.7), 1.4, 5.0)
	point_light(F3 + Vector3(0, 3.8, -12), Color(1.0, 0.8, 0.5), 2.8, 16.0)
	point_light(F3 + BELLS + Vector3(0, 2.5, 0), Color(1.0, 0.9, 0.6), 1.6, 6.0)
	# stairs DOWN to the gear floor (at the antechamber)
	stairs_mesh(F3 + Vector3(0, 0, 3.0), STONE.lightened(0.05))
	add_stairwell(F3 + Vector3(0, 0, 3.5), Vector3(3, 3, 1.4), F2 + Vector3(0, 0.1, -12.0), F_GEAR.x, F_GEAR.y)
	_bell_rack()
	# clock-face on the belfry back wall
	var face := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 2.6; cm.bottom_radius = 2.6; cm.height = 0.2
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.85, 0.8, 0.65)
	mat.emission_enabled = true; mat.emission = Color(0.4, 0.35, 0.2); mat.emission_energy_multiplier = 0.4
	cm.material = mat; face.mesh = cm; face.rotation.x = deg_to_rad(90)
	face.position = F3 + Vector3(0, 2.8, -18.6)
	add_child(face)

func _gear_mechanism() -> void:
	_gear = _make_gear(0.9, 16, BRASS)
	_gear.position = F2 + GEARPOS + Vector3(0, 0.6, 0); _gear.rotation.x = deg_to_rad(90)
	add_child(_gear)
	var g2 := _make_gear(0.55, 12, Color(0.55, 0.45, 0.28))
	g2.position = F2 + GEARPOS + Vector3(1.3, 0.4, 0.2); g2.rotation.x = deg_to_rad(90)
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
	if _gear_repaired: _open_gate(false)
	if _bells_played: _light_bells()
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
	if char_name == "Quinn" and not _gear_repaired and near3(pp, F2 + GEARPOS, REACH):
		_gear_repaired = true
		GameManager.set_level_flag(location_id, "gear_repaired", true)
		_open_gate(true)
		_hud_hint.text = "Quinn re-seats the escapement — the gear turns and the belfry stair unbars."
		Audio.play("special"); return
	if char_name == "Ben" and not _bells_played and near3(pp, F3 + BELLS, REACH + 0.6):
		_bells_played = true
		GameManager.set_level_flag(location_id, "bells_played", true)
		_light_bells()
		_hud_hint.text = "Ben strikes the belfry sequence — the bells ring true."
		Audio.play("special"); return
	if char_name != "Quinn" and not _gear_repaired and near3(pp, F2 + GEARPOS, REACH):
		_hud_hint.text = "The escapement needs Quinn's tools."
	elif char_name != "Ben" and not _bells_played and near3(pp, F3 + BELLS, REACH + 0.6):
		_hud_hint.text = "The bells need Ben's ear for pitch."

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
			"\"Take the stairs up: Quinn, the escapement on the gear floor wants your tools — it also unbars the belfry stair. Ben, the bells at the top want a pitch sequence.\""]}}
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
		_hud_goal.text = "Climb the tower: Quinn fixes the gear (unbars the belfry stair), Ben rings the bells, beat the guardian. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
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
