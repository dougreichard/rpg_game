extends Level3D
## Bellows & Sons Pipe Organ Works — first fully migrated level: 3D environment +
## combat + the organ-repair puzzle + loot + Mr. Bellows' dialog + secret passage.
## Reuses the 2D logic systems unchanged (GameManager items/flags, DialogBox,
## DialogTree). Active-duo SWAP (Quinn/Erin) lets Erin fast-talk the tuning key.

const LOCATION_ID := "pipe_organ_works"
const QUINN := preload("res://data/characters/quinn.tres")
const ERIN := preload("res://data/characters/erin.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const RUNNER := preload("res://data/enemies/runner.tres")
const BrassPipeItem: ItemData = preload("res://data/items/brass_organ_pipe.tres")
const TuningKeyItem: ItemData = preload("res://data/items/tuning_key.tres")
const SpareGearItem: ItemData = preload("res://data/items/spare_clockwork_gear.tres")
# DialogBox is provided by Level3D (make_dialog/open_dialog/dialog_input).

const FLOOR_COL := Color(0.30, 0.27, 0.24)
const WALL_COL := Color(0.40, 0.37, 0.34)
const HALL_W := 9.0
const HALL_D := 7.0
const WALL_H := 3.2
const ORGAN_POS := Vector3(0.0, 0.0, -HALL_D + 1.4)
const BELLOWS_POS := Vector3(-HALL_W + 2.2, 0.0, 4.4)
const LEVER_POS := Vector3(HALL_W - 0.6, 0.0, -4.5)
const PIPE_LOOT_POS := Vector3(HALL_W - 2.4, 0.0, -2.6)
const SECRET_LOOT_POS := Vector3(HALL_W - 1.2, 0.0, -6.0)
const REACH := 2.0

var _organ_node: MeshInstance3D = null
var _organ_repaired := false
var _secret_revealed := false
var _cleared := false
var _spawned := 0
var _loot: Array = []          # {pos, item, owner, flag, opened, node, hidden}
var _secret_wall: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = LOCATION_ID
	build_env(Color(0.10, 0.10, 0.12), Color(0.55, 0.50, 0.44), 0.5, 1.0)
	point_light(Vector3(0, 3.0, -3.0), Color(1.0, 0.85, 0.6), 3.0, 12.0)
	point_light(Vector3(-6.5, 2.6, 4.0), Color(0.9, 0.85, 0.7), 1.6, 7.0)
	floor_box(HALL_W * 2.0 + 1.0, HALL_D * 2.0 + 1.0, FLOOR_COL)
	_walls()
	_organ()
	_dressing()
	_loot_crate(PIPE_LOOT_POS, BrassPipeItem, "pipe_loot_open", false)
	_loot_crate(SECRET_LOOT_POS, SpareGearItem, "gear_loot_open", true)  # behind the secret wall
	_lever()
	_bellows()
	make_dialog()
	_build_hud()
	var p := spawn_duo([QUINN, ERIN], Vector3(0.0, 0.1, HALL_D - 1.5))
	p.special_used.connect(_on_special)
	for spot in [Vector3(-2.5, 0.1, -1.0), Vector3(3.0, 0.1, 0.0)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(RUNNER, Vector3(0.5, 0.1, -3.0), "res://assets/models/enemies/runner.glb"); _spawned += 1
	# restore persisted progress
	_organ_repaired = GameManager.get_level_flag(LOCATION_ID, "organ_repaired", false)
	if _organ_repaired:
		_organ_node.material_override = _glow_mat()

func _walls() -> void:
	wall(Vector3(0, WALL_H * 0.5, -HALL_D), Vector3(HALL_W * 2.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(-HALL_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALL_D * 2.0), WALL_COL)
	wall(Vector3(HALL_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALL_D * 2.0), WALL_COL)
	wall(Vector3(-HALL_W + 2.5, WALL_H * 0.5, HALL_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(HALL_W - 2.5, WALL_H * 0.5, HALL_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(-HALL_W + 3.0, WALL_H * 0.5, 2.5), Vector3(0.4, WALL_H, 4.0), WALL_COL)
	# secret wall (closes off the SW corner closet) — slides away on the lever
	_secret_wall = StaticBody3D.new()
	(_secret_wall as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(3.0, WALL_H, 0.4); cs.shape = bs
	_secret_wall.add_child(cs)
	_secret_wall.add_child(box_mesh(Vector3(3.0, WALL_H, 0.4), WALL_COL, Vector3.ZERO))
	_secret_wall.position = Vector3(HALL_W - 1.5, WALL_H * 0.5, -5.0)
	add_child(_secret_wall)

func _organ() -> void:
	var base_z := ORGAN_POS.z - 0.2
	var brass := Color(0.72, 0.6, 0.32); var wood := Color(0.34, 0.22, 0.14)
	add_child(box_mesh(Vector3(5.0, 2.2, 0.6), wood, Vector3(0, 1.1, base_z - 0.4)))
	for i: int in range(11):
		var x: float = -2.0 + float(i) * 0.4
		var h: float = 1.4 + 0.9 * sin(float(i) * 0.9) + (0.6 if i % 2 == 0 else 0.0)
		var pipe := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.14; cm.bottom_radius = 0.14; cm.height = h
		var mat := StandardMaterial3D.new()
		mat.albedo_color = brass; mat.metallic = 0.6; mat.roughness = 0.35
		cm.material = mat
		pipe.mesh = cm
		pipe.position = Vector3(x, 1.4 + h * 0.5, base_z)
		add_child(pipe)
	add_child(box_mesh(Vector3(2.4, 0.5, 0.7), wood, Vector3(0, 0.9, base_z + 0.7)))
	_organ_node = box_mesh(Vector3(2.2, 0.08, 0.4), Color(0.92, 0.9, 0.85), Vector3(0, 1.16, base_z + 0.75))
	add_child(_organ_node)

func _dressing() -> void:
	prop("res://assets/models/props/shelf.glb", Vector3(HALL_W - 0.8, 0, -0.5), deg_to_rad(-90))
	prop("res://assets/models/props/barrel.glb", Vector3(HALL_W - 1.4, 0, 3.5))
	prop("res://assets/models/props/barrel.glb", Vector3(HALL_W - 2.1, 0, 3.7))

func _loot_crate(pos: Vector3, item: ItemData, flag: String, hidden: bool) -> void:
	var box := box_mesh(Vector3(0.7, 0.7, 0.7), Color(0.45, 0.32, 0.18), pos + Vector3(0, 0.35, 0))
	add_child(box)
	var opened: bool = GameManager.get_level_flag(LOCATION_ID, flag, false)
	if opened:
		(box.mesh as BoxMesh).material.albedo_color = Color(0.30, 0.24, 0.16)
	box.visible = not hidden or _secret_revealed
	_loot.append({"pos": pos, "item": item, "flag": flag, "opened": opened, "node": box, "hidden": hidden})

func _lever() -> void:
	add_child(box_mesh(Vector3(0.2, 0.7, 0.2), Color(0.3, 0.3, 0.34), LEVER_POS + Vector3(-0.2, 0.9, 0)))
	add_child(box_mesh(Vector3(0.1, 0.4, 0.1), Color(0.8, 0.2, 0.2), LEVER_POS + Vector3(-0.2, 1.3, 0)))

func _bellows() -> void:
	var ps: PackedScene = load("res://assets/models/characters/bellows.glb")
	if ps != null:
		var m := ps.instantiate()
		m.position = BELLOWS_POS
		m.rotation.y = deg_to_rad(90)
		var ap := _find_anim_in(m)
		if ap != null and ap.has_animation("idle"):
			ap.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
			ap.play("idle")
		add_child(m)
	prop("res://assets/models/props/desk.glb", BELLOWS_POS + Vector3(0, 0, -0.8), deg_to_rad(90))

func _find_anim_in(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer: return n
	for c in n.get_children():
		var r := _find_anim_in(c)
		if r != null: return r
	return null

# --- interaction (mirrors the 2D _on_special_used ladder) --------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	for crate in _loot:
		if not crate["opened"] and crate["node"].visible and _near(pp, crate["pos"]):
			GameManager.grant_item(char_name, crate["item"].id)
			GameManager.set_level_flag(LOCATION_ID, crate["flag"], true)
			crate["opened"] = true
			(crate["node"].mesh as BoxMesh).material.albedo_color = Color(0.30, 0.24, 0.16)
			_hud_hint.text = "Picked up: %s" % crate["item"].display_name
			Audio.play("special")
			return
	if char_name == "Quinn" and not _secret_revealed and _near(pp, LEVER_POS):
		_reveal_secret()
		return
	if _near(pp, BELLOWS_POS):
		_talk_bellows(char_name)
		return
	if char_name == "Quinn" and not _organ_repaired and _near(pp, ORGAN_POS):
		if _has_parts():
			_organ_repaired = true
			_organ_node.material_override = _glow_mat()
			GameManager.set_level_flag(LOCATION_ID, "organ_repaired", true)
			Audio.play("special")
			_hud_hint.text = "The organ breathes again!"
		else:
			_hud_hint.text = "The organ needs its brass pipe and tuning key."

func _near(a: Vector3, b: Vector3) -> bool:
	return Vector2(a.x - b.x, a.z - b.z).length() < REACH

func _has_parts() -> bool:
	var pipe := GameManager.has_item("Quinn", BrassPipeItem.id) or GameManager.has_item("Erin", BrassPipeItem.id)
	var key := GameManager.has_item("Quinn", TuningKeyItem.id) or GameManager.has_item("Erin", TuningKeyItem.id)
	return pipe and key

func _reveal_secret() -> void:
	_secret_revealed = true
	GameManager.set_level_flag(LOCATION_ID, "secret_revealed", true)
	var tw := create_tween()
	tw.tween_property(_secret_wall, "position:y", -WALL_H, 0.6)  # sink the wall
	for crate in _loot:
		if crate["hidden"]:
			crate["node"].visible = true
	_hud_hint.text = "A hidden parts closet opens behind the workshop."
	Audio.play("special")

func _glow_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.4, 1.0, 0.5)
	m.emission_enabled = true; m.emission = Color(0.3, 1.0, 0.45); m.emission_energy_multiplier = 1.5
	return m

# --- Mr. Bellows dialog ------------------------------------------------------
func _talk_bellows(char_name: String) -> void:
	var given: bool = GameManager.get_level_flag(LOCATION_ID, "tuning_key_given", false)
	var tree: Dictionary
	if given:
		tree = {"start": {"lines": [
			"\"Get that organ fixed, and there might be a place for you both here permanently.\""]}}
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
	GameManager.set_level_flag(LOCATION_ID, "manager_met", true)
	open_dialog("Mr. Bellows", Color(0.35, 0.4, 0.32), tree, char_name)

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := CanvasLayer.new(); add_child(cl)
	_hud_goal = _label(cl, 24, HORIZONTAL_ALIGNMENT_CENTER, 22)
	_hud_goal.text = "Clear the workshop, find the parts, repair the organ. (G interact, Tab swap)"
	_hud_hint = _label(cl, -60, HORIZONTAL_ALIGNMENT_CENTER, 22); _hud_hint.anchor_top = 1.0; _hud_hint.anchor_bottom = 1.0
	_hud_banner = _label(cl, 0, HORIZONTAL_ALIGNMENT_CENTER, 40); _hud_banner.anchor_top = 0.5; _hud_banner.anchor_bottom = 0.5
	_hud_banner.visible = false

func _label(cl: CanvasLayer, y: float, align: int, size: int) -> Label:
	var l := Label.new()
	l.anchor_left = 0.0; l.anchor_right = 1.0; l.offset_top = y; l.offset_bottom = y + 50
	l.horizontal_alignment = align
	l.add_theme_font_override("font", UITheme.font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", UITheme.CREAM)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	cl.add_child(l)
	return l

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

func _process(_d: float) -> void:
	super._process(_d)
	var alive := 0
	for c in get_children():
		if c is CharacterBody3D and c.get_script() == EnemyScript:
			alive += 1
	if not _cleared and _spawned > 0 and alive == 0 and _organ_repaired:
		_cleared = true
		GameManager.set_level_flag(LOCATION_ID, "enemies_cleared", true)
		GameManager.complete_location(LOCATION_ID)
		_hud_goal.text = ""; _hud_hint.text = ""
		_hud_banner.text = "WORKSHOP CLEARED!"
		_hud_banner.visible = true
		Audio.play("puzzle_complete")
