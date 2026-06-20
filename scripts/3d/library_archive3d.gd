extends Level3D
## The Public Library & Archive (3D) — Erin + Ethan. Multi-room: a combat-free READING
## ROOM (Ms. Priswick's checkpoint + exit), then the RESTRICTED STACKS (Grunts + a
## ranged Sentry; bookshelves + hiding spots) holding the archive terminal and a locked
## stack. Erin fast-talks past Priswick (or a library card) to drop the checkpoint gate;
## Ethan hacks the archive terminal (reveals Doug's borrowed file); the locked stack
## opens with the Clocktower archive key OR Ethan's catalog cipher → a VR override chip.
## Carpet/wood surfaces, deep-green trim. Win = stacks cleared + archive hacked.

const ERIN := preload("res://data/characters/erin.tres")
const ETHAN := preload("res://data/characters/ethan.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const SENTRY := preload("res://data/enemies/sentry.tres")
const LibraryCardItem: ItemData = preload("res://data/items/library_card.tres")
const ArchiveKeyItem: ItemData = preload("res://data/items/archive_key.tres")
const ChipItem: ItemData = preload("res://data/items/vr_override_chip.tres")
const CheckoutCardItem: ItemData = preload("res://data/items/doug_checkout_card.tres")

# --- thematic surfaces (carpet / wood / deep-green trim) ---
const FLOOR_CARPET := "res://assets/art/tiles/synty_floor_carpet.png"
const FLOOR_TILE := "res://assets/art/tiles/synty_floor_tile.png"
const WALL_WOOD := "res://assets/art/tiles/synty_wall_wood.png"
const FT_READ := Color(0.78, 0.66, 0.58)
const WT_READ := Color(0.72, 0.58, 0.4)
const FT_STACK := Color(0.74, 0.70, 0.62)
const CORNER_COL := Color(0.12, 0.25, 0.15)   # solid deep-green trim
const WOOD := Color(0.34, 0.22, 0.13)

const WALL_H := 3.6
const REACH := 2.2

# Enlarged: reading room 18x12 @ z+13, restricted stacks 20x18 @ z-7, joined by a 5m corridor.
const READ_C := Vector3(0, 0, 13.0)
const PRISWICK_POS := Vector3(0.0, 0.0, 9.0)
const CHECK_GATE := Vector3(0.0, 0.0, 6.5)
const STACK_C := Vector3(0, 0, -7.0)
const TERMINAL_POS := Vector3(0.0, 0.0, -15.0)
const CATALOG_POS := Vector3(-8.0, 0.0, -5.0)
const LOCKSTACK_POS := Vector3(8.0, 0.0, -13.0)

var _cleared := false
var _enemies_cleared := false
var _librarian_talked := false
var _archive_hacked := false
var _catalog_done := false
var _stack_open := false
var _spawned := 0
var _priswick = null
var _check_wall: Node3D = null
var _terminal_lights: Array = []
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "library"
	multi_room = true
	build_env(Color(0.06, 0.05, 0.04), Color(0.5, 0.44, 0.36), 0.55, 0.9)
	point_light(READ_C + Vector3(0, 3.2, 0), Color(1.0, 0.88, 0.6), 2.0, 12.0)
	point_light(TERMINAL_POS + Vector3(0, 1.8, 0.6), Color(0.4, 0.8, 1.0), 1.6, 5.0)
	point_light(STACK_C + Vector3(0, 3.0, 0), Color(0.9, 0.85, 0.7), 1.8, 13.0)
	_rooms()
	_reading_room()
	_stacks()
	_terminal()
	_catalog()
	add_hiding_spot(Vector3(-5.0, 0, -11.0))   # between the stacks
	add_hiding_spot(Vector3(5.0, 0, -11.0))
	make_dialog()
	_build_hud()
	_priswick = spawn_npc("congregant_f", PRISWICK_POS, PI)
	add_exit_portal(READ_C + Vector3(0, 0, 6.0), Vector3(3, 3, 1.4))
	var p := spawn_duo([ERIN, ETHAN], READ_C + Vector3(0.0, 0.1, 1.5))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _rooms() -> void:
	# Reading room — carpet, wood walls (combat-free). South vestibule = exit;
	# the north checkpoint is sealed until Priswick is satisfied.
	set_theme(FLOOR_CARPET, WALL_WOOD)
	room(READ_C, 18, 12, FT_READ, WT_READ, WALL_H, ["n", "s"], 4.0, true)
	corridor(READ_C + Vector3(0, 0, 6.0), "s", 2.0, FT_READ, WT_READ, 4.0, WALL_H, true, CORNER_COL)
	corridor(READ_C + Vector3(0, 0, -6.0), "n", 5.0, FT_READ, WT_READ, 4.0, WALL_H, true, CORNER_COL)  # → stacks
	_check_wall = _gate_panel(CHECK_GATE, WALL_H)
	# Restricted stacks — tile floor, wood walls. Combat.
	set_theme(FLOOR_TILE, WALL_WOOD)
	room(STACK_C, 20, 18, FT_STACK, WT_READ, WALL_H, ["s"], 4.0, true)

func _gate_panel(pos: Vector3, h: float) -> Node3D:
	var size := Vector3(4.0, h, 0.4)   # doorway runs along X (panel thin in Z)
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = size; cs.shape = bs; cs.position = Vector3(0, h * 0.5, 0)
	sb.add_child(cs); sb.add_child(box_mesh(size, WT_READ, Vector3(0, h * 0.5, 0), 0.0, wall_tex))
	sb.position = pos
	add_child(sb)
	return sb

func _reading_room() -> void:
	for pos: Vector3 in [READ_C + Vector3(-5.0, 0, 1.5), READ_C + Vector3(5.0, 0, 1.5), READ_C + Vector3(-5.0, 0, -2.0), READ_C + Vector3(5.0, 0, -2.0)]:
		prop("res://assets/models/props/table.glb", pos, 0.0)
		prop("res://assets/models/props/chair.glb", pos + Vector3(0, 0, 0.8), PI)
	prop("res://assets/models/props/shelf.glb", READ_C + Vector3(-8.0, 0, -1.0), deg_to_rad(90))   # wall shelves
	prop("res://assets/models/props/shelf.glb", READ_C + Vector3(8.0, 0, -1.0), deg_to_rad(-90))
	# Priswick's checkpoint desk, just south of the gate
	add_child(box_mesh(Vector3(3.0, 1.0, 0.7), WOOD, PRISWICK_POS + Vector3(0, 0.5, 0.7)))
	add_child(box_mesh(Vector3(3.0, 0.1, 0.7), WOOD.lightened(0.1), PRISWICK_POS + Vector3(0, 1.05, 0.7)))

func _stacks() -> void:
	# rows of real bookshelves (reuse shelf.glb) flanking a central aisle — clear of the
	# terminal (0,-15), catalog (-8,-5) and locked stack (8,-13).
	for x: float in [-6.5, -3.5, 3.5, 6.5]:
		for z: float in [-9.5, -12.5]:
			prop("res://assets/models/props/shelf.glb", Vector3(x, 0, z), PI if x > 0 else 0.0)

func _terminal() -> void:
	# Prop-Farm microfilm/archive terminal (Ethan hacks it); keep the status pips on top
	prop("res://assets/models/props/archive_terminal.glb", TERMINAL_POS, 0.0)
	for i: int in range(3):
		var pip := box_mesh(Vector3(0.16, 0.05, 0.05), Color(0.9, 0.3, 0.25), TERMINAL_POS + Vector3(-0.3 + float(i) * 0.3, 1.2, 0.4), 1.2)
		add_child(pip)
		_terminal_lights.append(pip)

func _catalog() -> void:
	# Prop-Farm card-catalog cabinet (Ethan's cipher) + the locked-stack cage
	prop("res://assets/models/props/card_catalog.glb", CATALOG_POS, deg_to_rad(90))
	# locked-stack cage bars
	for i: int in range(5):
		add_child(box_mesh(Vector3(0.08, 2.4, 0.08), Color(0.4, 0.42, 0.3), LOCKSTACK_POS + Vector3(-0.8 + float(i) * 0.4, 1.2, 0.7)))

func _spawn_enemies() -> void:
	for spot: Vector3 in [Vector3(-2.0, 0.1, -1.5), Vector3(3.0, 0.1, -3.0)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(SENTRY, Vector3(-4.0, 0.1, -7.0), "res://assets/models/enemies/grunt.glb", 1.0, Color(0.6, 0.7, 0.9)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_librarian_talked = GameManager.get_level_flag(location_id, "librarian_talked", false)
	_archive_hacked = GameManager.get_level_flag(location_id, "archive_hacked", false)
	_catalog_done = GameManager.get_level_flag(location_id, "catalog_done", false)
	_stack_open = GameManager.get_level_flag(location_id, "stack_open", false)
	if _librarian_talked: _drop_gate(false)
	if _archive_hacked: _set_terminal_solved()
	if _enemies_cleared and _archive_hacked:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, PRISWICK_POS, REACH + 0.6):
		_talk_priswick(char_name); return
	# archive terminal hack (Ethan) — reveals Doug's file
	if char_name == "Ethan" and not _archive_hacked and near3(pp, TERMINAL_POS, REACH):
		if _librarian_talked:
			_hack_archive(char_name)
		else:
			_hud_hint.text = "The terminal logs access — get past Ms. Priswick first."
		return
	if not _archive_hacked and near3(pp, TERMINAL_POS, REACH):
		_hud_hint.text = "The archive terminal needs Ethan's hacking."; return
	# catalog cipher (Ethan) — alternative way to crack the locked stack
	if char_name == "Ethan" and not _catalog_done and not _stack_open and near3(pp, CATALOG_POS, REACH):
		_catalog_done = true
		GameManager.set_level_flag(location_id, "catalog_done", true)
		_hud_hint.text = "Ethan cross-references the catalog — the restricted-stack call number resolves."
		Audio.play("special"); return
	# locked stack — archive key (item) OR the catalog cipher → VR override chip
	if not _stack_open and near3(pp, LOCKSTACK_POS, REACH):
		var has_key := GameManager.has_item("Erin", ArchiveKeyItem.id) or GameManager.has_item("Ethan", ArchiveKeyItem.id)
		if has_key or _catalog_done:
			_open_stack(char_name, has_key)
		else:
			_hud_hint.text = "The restricted stack is caged — needs the archive key, or Ethan cracks the catalog."
		return

func _talk_priswick(char_name: String) -> void:
	if _librarian_talked:
		open_dialog("Ms. Priswick", Color(0.5, 0.45, 0.55),
			{"start": {"lines": ["\"I see you found what you needed. Please don't disturb the periodicals.\""]}}, char_name)
		return
	var has_card := GameManager.has_item("Erin", LibraryCardItem.id) or GameManager.has_item("Ethan", LibraryCardItem.id)
	if has_card:
		_librarian_talked = true
		GameManager.set_level_flag(location_id, "librarian_talked", true)
		_drop_gate(true)
		open_dialog("Ms. Priswick", Color(0.5, 0.45, 0.55),
			{"start": {"lines": ["You flash a valid library card. \"...In order. The stacks are open. Be quiet.\""]}}, char_name)
		return
	var tree := {
		"start": {
			"lines": ["\"The Restricted Stacks are closed. Valid library card required.\""],
			"choices": [
				{"text": "\"Academic research on local history.\" (Erin fast-talks)", "best_with": "Erin",
					"next": "erin_wins", "next_alt": "need_card"},
				{"text": "\"We need access to the sealed records.\"", "next": "need_card"}]},
		"erin_wins": {
			"lines": [
				"Erin: \"Hi -- we're doing research on local history. Completely academic.\"",
				"Ms. Priswick studies her clipboard. \"...Academic. Yes. The stacks are open. Be quiet.\""],
			"effects": {"set_flag": "librarian_talked", "flag_value": true}},
		"need_card": {
			"lines": [
				"\"A valid library card is required. No exceptions.\"",
				"Perhaps look around the reading room first."],
			"effects": {"set_flag": "priswick_impression", "flag_value": "blocked"}},
	}
	open_dialog("Ms. Priswick", Color(0.5, 0.45, 0.55), tree, char_name)

func _hack_archive(char_name: String) -> void:
	_archive_hacked = true
	GameManager.set_level_flag(location_id, "archive_hacked", true)
	_set_terminal_solved()
	GameManager.grant_item(char_name, CheckoutCardItem.id)
	open_dialog("Archive Terminal", Color(0.3, 0.5, 0.6),
		{"start": {"lines": [
			"Ethan peels back the access logs. The sealed records bloom open.",
			"One file is flagged in Doug's name -- his checkout card, and his last request:",
			"\"Grand Marquee -- projection schematics.\" He was studying the old picture house.",
			"Picked up: Doug's Checkout Card."]}}, char_name)
	Audio.play("special")

func _open_stack(char_name: String, by_key: bool) -> void:
	_stack_open = true
	GameManager.set_level_flag(location_id, "stack_open", true)
	GameManager.grant_item(char_name, ChipItem.id)
	var how := "The archive key turns the cage lock" if by_key else "Ethan's resolved call number springs the cage"
	_hud_hint.text = "%s — inside, a VR override chip and a duplicate of Doug's file. (Found VR Override Chip)" % how
	Audio.play("special")

func _drop_gate(animate: bool) -> void:
	(_check_wall as StaticBody3D).collision_layer = 0
	if animate:
		create_tween().tween_property(_check_wall, "position:y", -WALL_H, 0.6)
	else:
		_check_wall.position.y = -WALL_H

func _set_terminal_solved() -> void:
	for pip in _terminal_lights:
		((pip as MeshInstance3D).mesh as BoxMesh).material.albedo_color = Color(0.3, 0.95, 0.4)
		((pip as MeshInstance3D).mesh as BoxMesh).material.emission = Color(0.3, 0.95, 0.4)

func _on_dialog_closed_default(effects: Array) -> void:
	super._on_dialog_closed_default(effects)
	if GameManager.get_level_flag(location_id, "librarian_talked", false) and not _librarian_talked:
		_librarian_talked = true
		_drop_gate(true)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := make_hud_layer()
	_hud_goal = hud_label(cl, 24)
	_hud_goal.text = "Get Erin past Ms. Priswick, clear the stacks, then Ethan hacks the archive terminal. (G interact, Tab swap)"
	_hud_hint = hud_label(cl, -70, 22, true)
	_hud_banner = hud_label(cl, 0, 40); _hud_banner.anchor_top = 0.5; _hud_banner.anchor_bottom = 0.5
	_hud_banner.visible = false

func _process(d: float) -> void:
	super._process(d)
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
		_hud_hint.text = "Stacks clear. Finish at the archive terminal."
	if not _cleared and _enemies_cleared and _archive_hacked:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "ARCHIVE OPENED!\nThe sealed records are yours."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
