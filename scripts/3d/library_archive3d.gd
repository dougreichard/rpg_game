extends Level3D
## The Public Library & Archive (3D) — Erin + Ethan. Ms. Priswick guards the
## Restricted Stacks; Erin fast-talks past her (choice dialog) or a library card
## bypasses the desk. Once past, Ethan hacks the archive terminal. A ranged Sentry
## (placeholder: a still grunt) holds the back stacks with grunts.

const ERIN := preload("res://data/characters/erin.tres")
const ETHAN := preload("res://data/characters/ethan.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const SENTRY := preload("res://data/enemies/sentry.tres")
const LibraryCardItem: ItemData = preload("res://data/items/library_card.tres")

const FLOOR_COL := Color(0.24, 0.20, 0.16)
const WALL_COL := Color(0.32, 0.26, 0.20)
const WOOD := Color(0.34, 0.22, 0.13)
const HALF_W := 8.0
const HALF_D := 8.5
const WALL_H := 3.6
const DESK_POS := Vector3(0.0, 0.0, 1.0)          # Priswick's checkpoint desk
const PRISWICK_POS := Vector3(0.0, 0.0, 0.2)
const TERMINAL_POS := Vector3(0.0, 0.0, -HALF_D + 1.6)   # archive terminal in the back stacks
const REACH := 2.2

var _cleared := false
var _enemies_cleared := false
var _librarian_talked := false
var _archive_hacked := false
var _spawned := 0
var _priswick = null
var _terminal_lights: Array = []
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "library"
	build_env(Color(0.06, 0.05, 0.04), Color(0.5, 0.44, 0.36), 0.55, 0.9)
	point_light(Vector3(0, 3.2, 3.0), Color(1.0, 0.88, 0.6), 2.0, 12.0)
	point_light(TERMINAL_POS + Vector3(0, 1.8, 0.6), Color(0.4, 0.8, 1.0), 1.6, 5.0)
	floor_box(HALF_W * 2.0 + 1.0, HALF_D * 2.0 + 1.0, FLOOR_COL)
	_walls()
	_reading_room()
	_checkpoint_desk()
	_stacks()
	_terminal()
	make_dialog()
	_build_hud()
	_priswick = spawn_npc("congregant_f", PRISWICK_POS, PI)
	var p := spawn_duo([ERIN, ETHAN], Vector3(0.0, 0.1, HALF_D - 1.5))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _walls() -> void:
	wall(Vector3(0, WALL_H * 0.5, -HALF_D), Vector3(HALF_W * 2.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(-HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(-HALF_W + 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(HALF_W - 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)

func _reading_room() -> void:
	# reading tables near the entrance
	for pos: Vector3 in [Vector3(-4.0, 0, 4.5), Vector3(4.0, 0, 4.5)]:
		prop("res://assets/models/props/table.glb", pos, 0.0)
		prop("res://assets/models/props/chair.glb", pos + Vector3(0, 0, 0.8), PI)

func _checkpoint_desk() -> void:
	# a long desk dividing reading room from the stacks, with a gap behind Priswick
	add_child(box_mesh(Vector3(3.0, 1.0, 0.7), WOOD, DESK_POS + Vector3(0, 0.5, 0)))
	add_child(box_mesh(Vector3(3.0, 0.1, 0.7), WOOD.lightened(0.1), DESK_POS + Vector3(0, 1.05, 0)))
	# side rails forcing players through the checkpoint
	wall(Vector3(-5.0, WALL_H * 0.5, DESK_POS.z), Vector3(6.0, WALL_H, 0.3), WALL_COL.darkened(0.1))
	wall(Vector3(5.0, WALL_H * 0.5, DESK_POS.z), Vector3(6.0, WALL_H, 0.3), WALL_COL.darkened(0.1))

func _stacks() -> void:
	# tall bookshelves forming aisles in the restricted stacks
	for x: float in [-5.0, -2.4, 2.4, 5.0]:
		for z: float in [-2.0, -4.5]:
			_bookshelf(Vector3(x, 0, z))

func _bookshelf(pos: Vector3) -> void:
	add_child(box_mesh(Vector3(1.6, 2.6, 0.5), WOOD.darkened(0.1), pos + Vector3(0, 1.3, 0)))
	for i: int in range(4):
		var y: float = 0.5 + float(i) * 0.6
		var hue := Color(0.5 + 0.3 * sin(pos.x + float(i)), 0.35, 0.3 + 0.2 * float(i % 2))
		add_child(box_mesh(Vector3(1.5, 0.12, 0.42), hue, pos + Vector3(0, y, 0.05)))

func _terminal() -> void:
	add_child(box_mesh(Vector3(1.0, 1.1, 0.7), Color(0.2, 0.2, 0.24), TERMINAL_POS + Vector3(0, 0.55, 0)))
	var screen := box_mesh(Vector3(0.9, 0.7, 0.06), Color(0.1, 0.3, 0.4), TERMINAL_POS + Vector3(0, 1.4, 0.32), 0.6)
	screen.rotation.x = deg_to_rad(-12)
	add_child(screen)
	for i: int in range(3):
		var pip := box_mesh(Vector3(0.18, 0.06, 0.06), Color(0.9, 0.3, 0.25), TERMINAL_POS + Vector3(-0.3 + float(i) * 0.3, 1.0, 0.36), 1.2)
		add_child(pip)
		_terminal_lights.append(pip)

func _spawn_enemies() -> void:
	for spot: Vector3 in [Vector3(-2.0, 0.1, -1.5), Vector3(3.0, 0.1, -3.0)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	# Sentry — holds the back stacks (ranged behaviour TODO; spawns as a still grunt)
	spawn_enemy(SENTRY, Vector3(-4.0, 0.1, -5.0), "res://assets/models/enemies/grunt.glb", 1.0, Color(0.6, 0.7, 0.9)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_librarian_talked = GameManager.get_level_flag(location_id, "librarian_talked", false)
	_archive_hacked = GameManager.get_level_flag(location_id, "archive_hacked", false)
	if _archive_hacked:
		_set_terminal_solved()
	if _enemies_cleared and _archive_hacked:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, PRISWICK_POS, REACH + 0.6):
		_talk_priswick(char_name); return
	if char_name == "Ethan" and not _archive_hacked and near3(pp, TERMINAL_POS, REACH):
		if _librarian_talked:
			_archive_hacked = true
			GameManager.set_level_flag(location_id, "archive_hacked", true)
			_set_terminal_solved()
			_hud_hint.text = "Ethan cracks the archive terminal — the sealed records open."
			Audio.play("special")
		else:
			_hud_hint.text = "The terminal logs access — get past Ms. Priswick first."
		return
	if not _archive_hacked and near3(pp, TERMINAL_POS, REACH):
		_hud_hint.text = "The archive terminal needs Ethan's hacking."

func _talk_priswick(char_name: String) -> void:
	if _librarian_talked:
		open_dialog("Ms. Priswick", Color(0.5, 0.45, 0.55),
			{"start": {"lines": ["\"I see you found what you needed. Please don't disturb the periodicals.\""]}}, char_name)
		return
	var has_card := GameManager.has_item("Erin", LibraryCardItem.id) or GameManager.has_item("Ethan", LibraryCardItem.id)
	if has_card:
		_librarian_talked = true
		GameManager.set_level_flag(location_id, "librarian_talked", true)
		open_dialog("Ms. Priswick", Color(0.5, 0.45, 0.55),
			{"start": {"lines": ["You flash a valid library card. \"...In order. The terminal is at the back. Be quiet.\""]}}, char_name)
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
				"Ms. Priswick studies her clipboard. \"...Academic. Yes. The terminal is at the back. Be quiet.\""],
			"effects": {"set_flag": "librarian_talked", "flag_value": true}},
		"need_card": {
			"lines": [
				"\"A valid library card is required. No exceptions.\"",
				"Perhaps look around the reading room first."],
			"effects": {"set_flag": "priswick_impression", "flag_value": "blocked"}},
	}
	open_dialog("Ms. Priswick", Color(0.5, 0.45, 0.55), tree, char_name)

func _set_terminal_solved() -> void:
	for pip in _terminal_lights:
		((pip as MeshInstance3D).mesh as BoxMesh).material.albedo_color = Color(0.3, 0.95, 0.4)
		((pip as MeshInstance3D).mesh as BoxMesh).material.emission = Color(0.3, 0.95, 0.4)

func _on_dialog_closed_default(effects: Array) -> void:
	super._on_dialog_closed_default(effects)
	# mirror the local flag so the gate updates immediately
	if GameManager.get_level_flag(location_id, "librarian_talked", false):
		_librarian_talked = true

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := make_hud_layer()
	_hud_goal = hud_label(cl, 24)
	_hud_goal.text = "Get Erin past Ms. Priswick, then Ethan hacks the archive terminal. (G interact, Tab swap)"
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
