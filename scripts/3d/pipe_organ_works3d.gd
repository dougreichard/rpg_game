extends Level3D
## Bellows & Sons Pipe Organ Works (3D) — MULTI-FLOOR. The repair spans two floors:
##   Floor 1 — Workshop (Mr. Bellows · dialog → Erin fast-talks the tuning key; the
##             organ console Quinn repairs) + Storeroom (grunts · combat)
##   Floor 2 — Pipe Loft: the brass organ pipe (the second part) + a secret spare-gear
##             nook behind a lever (runners · combat)
## So you talk Bellows for the key downstairs, climb to the loft for the pipe, then
## come back down to repair the organ. Win = enemies cleared + organ repaired.

const QUINN := preload("res://data/characters/quinn.tres")
const ERIN := preload("res://data/characters/erin.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const RUNNER := preload("res://data/enemies/runner.tres")
const BrassPipeItem: ItemData = preload("res://data/items/brass_organ_pipe.tres")
const TuningKeyItem: ItemData = preload("res://data/items/tuning_key.tres")
const SpareGearItem: ItemData = preload("res://data/items/spare_clockwork_gear.tres")

const FLOOR_COL := Color(0.30, 0.27, 0.24)
const WALL_COL := Color(0.40, 0.37, 0.34)
const WOOD := Color(0.34, 0.22, 0.14)
const BRASS := Color(0.72, 0.6, 0.32)

const F1 := Vector3(0, 0, 0)             # workshop
const F2 := Vector3(60, 0, 0)            # pipe loft

const ORGAN := Vector3(-3.0, 0, -4.5)    # F1 workshop
const BELLOWS := Vector3(4.5, 0, -3.0)   # F1 workshop
const PIPE_LOOT := Vector3(-3.0, 0, -11.0)  # F2 pipe hall
const LEVER := Vector3(5.5, 0, -11.0)    # F2 pipe hall
const GEAR_LOOT := Vector3(0, 0, -20.0)  # F2 secret nook
const REACH := 2.2
const F_WORK := Vector2(8.5, 50.0)
const F_LOFT := Vector2(9.5, 52.0)

var _organ_node: MeshInstance3D = null
var _organ_repaired := false
var _secret_revealed := false
var _pipe_open := false
var _gear_open := false
var _cleared := false
var _enemies_cleared := false
var _spawned := 0
var _secret_wall: Node3D = null
var _pipe_box: Node3D = null
var _gear_box: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "pipe_organ_works"
	multi_room = true
	build_env(Color(0.10, 0.10, 0.12), Color(0.55, 0.50, 0.44), 0.5, 1.0)
	_floor1()
	_floor2()
	_links()
	make_dialog()
	_build_hud()
	spawn_npc("bellows", F1 + BELLOWS, deg_to_rad(180))
	var p := spawn_duo([QUINN, ERIN], F1 + Vector3(0, 0.1, 4.0))
	p.special_used.connect(_on_special)
	reframe_camera(F_WORK.x, F_WORK.y)
	_spawn_enemies()
	_restore()

# --- Floor 1: Workshop + Storeroom ------------------------------------------
func _floor1() -> void:
	region_floor(F1 + Vector3(4, 0, -3), 26, 22, FLOOR_COL)
	room(F1, 14, 12, FLOOR_COL, WALL_COL, 3.2, ["s", "e", "n"], 3.0, false)        # workshop
	room(F1 + Vector3(11, 0, 0), 8, 10, FLOOR_COL, WALL_COL, 3.2, ["w"], 3.0, false)  # storeroom
	room(F1 + Vector3(0, 0, -10), 5, 7, FLOOR_COL, WALL_COL, 3.2, ["s"], 3.0, false)  # stair alcove
	point_light(F1 + Vector3(0, 3.0, -2), Color(1.0, 0.85, 0.6), 2.6, 11.0)
	point_light(F1 + Vector3(11, 2.8, 0), Color(0.9, 0.85, 0.7), 1.8, 7.0)
	_organ()
	prop("res://assets/models/props/desk.glb", F1 + BELLOWS + Vector3(0, 0, -0.9), deg_to_rad(180))
	prop("res://assets/models/props/shelf.glb", F1 + Vector3(14.0, 0, -3.5), deg_to_rad(-90))
	prop("res://assets/models/props/barrel.glb", F1 + Vector3(12.5, 0, 3.0))
	prop("res://assets/models/props/barrel.glb", F1 + Vector3(13.4, 0, 3.4))
	add_exit_portal(F1 + Vector3(0, 0, 6.5), Vector3(3, 3, 1.4))

func _organ() -> void:
	var base_z: float = (F1 + ORGAN).z - 0.2
	var bx: float = (F1 + ORGAN).x
	add_child(box_mesh(Vector3(5.0, 2.2, 0.6), WOOD, Vector3(bx, 1.1, base_z - 0.4)))
	for i: int in range(11):
		var x: float = bx - 2.0 + float(i) * 0.4
		var h: float = 1.4 + 0.9 * sin(float(i) * 0.9) + (0.6 if i % 2 == 0 else 0.0)
		var pipe := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.14; cm.bottom_radius = 0.14; cm.height = h
		var mat := StandardMaterial3D.new(); mat.albedo_color = BRASS; mat.metallic = 0.6; mat.roughness = 0.35
		cm.material = mat; pipe.mesh = cm; pipe.position = Vector3(x, 1.4 + h * 0.5, base_z)
		add_child(pipe)
	add_child(box_mesh(Vector3(2.4, 0.5, 0.7), WOOD, Vector3(bx, 0.9, base_z + 0.7)))
	_organ_node = box_mesh(Vector3(2.2, 0.08, 0.4), Color(0.92, 0.9, 0.85), Vector3(bx, 1.16, base_z + 0.75))
	add_child(_organ_node)

# --- Floor 2: Pipe Loft + secret nook ---------------------------------------
func _floor2() -> void:
	region_floor(F2 + Vector3(0, 0, -9), 18, 30, FLOOR_COL)
	room(F2, 6, 8, FLOOR_COL, WALL_COL, 3.0, ["n"], 3.0, false)                    # landing
	room(F2 + Vector3(0, 0, -11), 14, 12, FLOOR_COL, WALL_COL, 4.0, ["s"], 3.0, false)  # pipe hall
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
	# the brass-pipe part (loot)
	_pipe_box = box_mesh(Vector3(0.7, 0.7, 0.7), Color(0.45, 0.32, 0.18), F2 + PIPE_LOOT + Vector3(0, 0.35, 0))
	add_child(_pipe_box)
	# secret lever + hidden nook with the spare gear
	add_child(box_mesh(Vector3(0.2, 0.7, 0.2), Color(0.3, 0.3, 0.34), F2 + LEVER + Vector3(0, 0.9, 0)))
	add_child(box_mesh(Vector3(0.1, 0.4, 0.1), Color(0.8, 0.2, 0.2), F2 + LEVER + Vector3(0, 1.3, 0)))
	room(F2 + Vector3(0, 0, -20), 6, 6, FLOOR_COL, WALL_COL, 2.8, ["s"], 2.5, false)  # nook
	_gear_box = box_mesh(Vector3(0.7, 0.7, 0.7), Color(0.45, 0.32, 0.18), F2 + GEAR_LOOT + Vector3(0, 0.35, 0))
	add_child(_gear_box)
	# wall sealing the nook (sinks on the lever)
	_secret_wall = StaticBody3D.new()
	(_secret_wall as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(6.0, 2.8, 0.4); cs.shape = bs; cs.position = Vector3(0, 1.4, 0)
	_secret_wall.add_child(cs); _secret_wall.add_child(box_mesh(Vector3(6.0, 2.8, 0.4), WALL_COL, Vector3(0, 1.4, 0)))
	_secret_wall.position = F2 + Vector3(0, 0, -17)
	add_child(_secret_wall)

func _links() -> void:
	add_floor_link(
		F1 + Vector3(0, 0, -12.0), F1 + Vector3(0, 0.1, -9.0), F_WORK,
		F2 + Vector3(0, 0, 3.5), F2 + Vector3(0, 0.1, 0.0), F_LOFT,
		WOOD.lightened(0.1))

func _spawn_enemies() -> void:
	# Lobby (the Workshop) is combat-free — all enemies are in the Storeroom / Pipe Loft.
	spawn_enemy(GRUNT, F1 + Vector3(9.5, 0.1, -2.0), "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(GRUNT, F1 + Vector3(12.5, 0.1, 2.0), "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(RUNNER, F2 + Vector3(-2.0, 0.1, -10.0), "res://assets/models/enemies/runner.glb"); _spawned += 1
	spawn_enemy(RUNNER, F2 + Vector3(3.0, 0.1, -13.0), "res://assets/models/enemies/runner.glb"); _spawned += 1

func _restore() -> void:
	_organ_repaired = GameManager.get_level_flag(location_id, "organ_repaired", false)
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_secret_revealed = GameManager.get_level_flag(location_id, "secret_revealed", false)
	_pipe_open = GameManager.get_level_flag(location_id, "pipe_loot_open", false)
	_gear_open = GameManager.get_level_flag(location_id, "gear_loot_open", false)
	if _organ_repaired: _organ_node.material_override = _glow_mat()
	if _secret_revealed: _secret_wall.position.y = -3.0; (_secret_wall as StaticBody3D).collision_layer = 0
	if _pipe_open: _dim(_pipe_box)
	if _gear_open: _dim(_gear_box)
	if _enemies_cleared and _organ_repaired:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if not _pipe_open and near3(pp, F2 + PIPE_LOOT, REACH):
		_pipe_open = true; _grant(BrassPipeItem, "pipe_loot_open", _pipe_box); return
	if _secret_revealed and not _gear_open and near3(pp, F2 + GEAR_LOOT, REACH):
		_gear_open = true; _grant(SpareGearItem, "gear_loot_open", _gear_box); return
	if char_name == "Quinn" and not _secret_revealed and near3(pp, F2 + LEVER, REACH):
		_reveal_secret(); return
	if near3(pp, F1 + BELLOWS, REACH + 0.6):
		_talk_bellows(char_name); return
	if char_name == "Quinn" and not _organ_repaired and near3(pp, F1 + ORGAN, REACH + 0.6):
		if _has_parts():
			_organ_repaired = true
			_organ_node.material_override = _glow_mat()
			GameManager.set_level_flag(location_id, "organ_repaired", true)
			_hud_hint.text = "The organ breathes again!"
			Audio.play("special")
		else:
			_hud_hint.text = "The organ needs its brass pipe (up in the loft) and tuning key (from Mr. Bellows)."

func _grant(item: ItemData, flag: String, box: Node3D) -> void:
	GameManager.grant_item(player.active_name(), item.id)
	GameManager.set_level_flag(location_id, flag, true)
	_dim(box)
	_hud_hint.text = "Picked up: %s" % item.display_name
	Audio.play("special")

func _dim(box: Node3D) -> void:
	((box.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = Color(0.30, 0.24, 0.16)

func _has_parts() -> bool:
	var pipe := GameManager.has_item("Quinn", BrassPipeItem.id) or GameManager.has_item("Erin", BrassPipeItem.id)
	var key := GameManager.has_item("Quinn", TuningKeyItem.id) or GameManager.has_item("Erin", TuningKeyItem.id)
	return pipe and key

func _reveal_secret() -> void:
	_secret_revealed = true
	GameManager.set_level_flag(location_id, "secret_revealed", true)
	create_tween().tween_property(_secret_wall, "position:y", -3.0, 0.6)
	(_secret_wall as StaticBody3D).collision_layer = 0
	_hud_hint.text = "A hidden parts closet opens at the back of the loft."
	Audio.play("special")

func _glow_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.4, 1.0, 0.5)
	m.emission_enabled = true; m.emission = Color(0.3, 1.0, 0.45); m.emission_energy_multiplier = 1.5
	return m

func _talk_bellows(char_name: String) -> void:
	var given: bool = GameManager.get_level_flag(location_id, "tuning_key_given", false)
	var tree: Dictionary
	if given:
		tree = {"start": {"lines": ["\"Get that organ fixed, and there might be a place for you both here permanently.\""]}}
	else:
		tree = {
			"start": {"lines": [
				"Mr. Bellows: \"This place is falling apart and the bellows haven't breathed right in months.\"",
				"\"If you can find my tuning key, I'd be obliged -- can't recall where I left the blasted thing.\""],
				"choices": [
					{"text": "Talk the tuning key out of him", "best_with": "Erin", "next": "give", "next_alt": "need_erin"}]},
			"give": {"lines": [
				"Erin: \"That key on your belt, Mr. Bellows -- the one your father gave you. Quinn needs it.\"",
				"He hands over a small brass tuning key, faintly confused."],
				"effects": {"grant_items": [TuningKeyItem.id], "set_flag": "tuning_key_given", "flag_value": true}},
			"need_erin": {"lines": ["\"Hmph. I don't hand that key to just anyone. Maybe your sharp-tongued friend can change my mind.\""]},
		}
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
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
	if not _cleared:
		var bits := []
		bits.append("key " + ("OK" if GameManager.get_level_flag(location_id, "tuning_key_given", false) else "..."))
		bits.append("pipe " + ("OK" if _pipe_open else "..."))
		bits.append("organ " + ("OK" if _organ_repaired else "..."))
		bits.append("workers " + ("OK" if _enemies_cleared else "..."))
		_hud_goal.text = "Get the tuning key (Bellows) + the brass pipe (loft, upstairs), repair the organ, clear the workers. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
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
