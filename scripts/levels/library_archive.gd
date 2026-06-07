extends Node2D

# Tile-mapped floor palette — parchment and old-wood tones (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.34, 0.30, 0.25)
const FLOOR_ACCENT_COLOR: Color = Color(0.58, 0.48, 0.32)
const FLOOR_COLS: int = 20
const FLOOR_ROWS: int = 12
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const SENTRY_SCENE: PackedScene = preload("res://scenes/enemies/Sentry.tscn")

const LIBRARIAN_POS := Vector2(220.0, 180.0)
const LIBRARIAN_RADIUS: float = 64.0
const TERMINAL_POS := Vector2(560.0, 180.0)
const TERMINAL_RADIUS: float = 64.0

@onready var erin: Player = $Players/Erin
@onready var ethan: Player = $Players/Ethan
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel

var _spawned: bool = false
var _enemies_cleared: bool = false
var _librarian_talked: bool = false
var _archive_hacked: bool = false
var _cleared: bool = false
var _librarian_sprite: Sprite2D
var _terminal_sprite: Sprite2D

func _ready() -> void:
	_build_floor()
	GameManager.register_players(erin, ethan)
	hud.setup(erin, ethan)
	erin.special_used.connect(_on_special_used)
	ethan.special_used.connect(_on_special_used)
	_create_librarian()
	_create_terminal()
	_spawn()


# Tile-mapped retro floor (Zelda-style two-tone grid), generated at runtime
# via PlaceholderArt to keep the original-IP guarantee — no imported tile art.
func _build_floor() -> void:
	var tile_map := TileMap.new()
	tile_map.name = "Floor"
	tile_map.tile_set = PlaceholderArt.make_level_tileset(FLOOR_BASE_COLOR, FLOOR_ACCENT_COLOR)
	add_child(tile_map)
	move_child(tile_map, 0)
	for x: int in range(FLOOR_COLS):
		for y: int in range(FLOOR_ROWS):
			var variant: Vector2i = FLOOR_TILE_ACCENT if (x + y) % FLOOR_ACCENT_PERIOD == 0 else FLOOR_TILE_PLAIN
			tile_map.set_cell(0, Vector2i(x, y), 0, variant)
func _create_librarian() -> void:
	_librarian_sprite = Sprite2D.new()
	_librarian_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.42, 0.34, 0.24), 36, 56)
	_librarian_sprite.position = LIBRARIAN_POS
	add_child(_librarian_sprite)

func _create_terminal() -> void:
	_terminal_sprite = Sprite2D.new()
	_terminal_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.24, 0.34, 0.4), 48, 40)
	_terminal_sprite.position = TERMINAL_POS
	add_child(_terminal_sprite)

func _spawn() -> void:
	_add(GRUNT_SCENE,  Vector2(380.0, 110.0))
	_add(SENTRY_SCENE, Vector2(460.0, 270.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	if char_name == "Erin" and not _librarian_talked:
		if erin.global_position.distance_to(LIBRARIAN_POS) < LIBRARIAN_RADIUS:
			_librarian_talked = true
			_librarian_sprite.modulate = Color(0.4, 1.0, 0.5)
	elif char_name == "Ethan" and not _archive_hacked:
		if ethan.global_position.distance_to(TERMINAL_POS) < TERMINAL_RADIUS:
			_archive_hacked = true
			_terminal_sprite.modulate = Color(0.4, 1.0, 0.5)

func _process(_delta: float) -> void:
	_update_hint()
	if _spawned and not _enemies_cleared and enemies.get_child_count() == 0:
		_enemies_cleared = true
	if _enemies_cleared and _librarian_talked and _archive_hacked and not _cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "ARCHIVE UNLOCKED!\n\nSealed records mention Uncle Doug.\n\nPress ENTER for the Map"
		clear_label.visible = true
	if _cleared and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location("library")
		get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")

func _update_hint() -> void:
	if _cleared:
		hint_label.text = ""
	elif not _enemies_cleared:
		hint_label.text = "Quiet but dangerous — deal with the guards before you're spotted!"
	elif not _librarian_talked:
		hint_label.text = "Erin: talk your way past the librarian  [ approach her, press G ]"
	elif not _archive_hacked:
		hint_label.text = "Ethan: hack the sealed archive terminal  [ approach it, press G ]"
	else:
		hint_label.text = ""
