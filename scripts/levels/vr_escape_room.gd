extends Node2D

# Tile-mapped floor palette — cool cyber-blue with glitchy cyan accents (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.21, 0.25, 0.32)
const FLOOR_ACCENT_COLOR: Color = Color(0.30, 0.65, 0.70)
const FLOOR_COLS: int = 20
const FLOOR_ROWS: int = 12
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const SENTRY_SCENE: PackedScene = preload("res://scenes/enemies/Sentry.tscn")

const GLITCH_POS := Vector2(220.0, 180.0)
const GLITCH_RADIUS: float = 64.0
const SYSTEM_POS := Vector2(560.0, 180.0)
const SYSTEM_RADIUS: float = 64.0

@onready var quinn: Player = $Players/Quinn
@onready var ethan: Player = $Players/Ethan
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel

var _spawned: bool = false
var _enemies_cleared: bool = false
var _glitch_repaired: bool = false
var _system_hacked: bool = false
var _cleared: bool = false
var _glitch_sprite: Sprite2D
var _system_sprite: Sprite2D

func _ready() -> void:
	_build_floor()
	GameManager.register_players(quinn, ethan)
	hud.setup(quinn, ethan)
	quinn.special_used.connect(_on_special_used)
	ethan.special_used.connect(_on_special_used)
	_create_glitch()
	_create_system()
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
func _create_glitch() -> void:
	_glitch_sprite = Sprite2D.new()
	_glitch_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.4, 0.2, 0.5), 48, 48)
	_glitch_sprite.position = GLITCH_POS
	add_child(_glitch_sprite)

func _create_system() -> void:
	_system_sprite = Sprite2D.new()
	_system_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.18, 0.42, 0.46), 48, 44)
	_system_sprite.position = SYSTEM_POS
	add_child(_system_sprite)

func _spawn() -> void:
	_add(GRUNT_SCENE,  Vector2(380.0, 110.0))
	_add(GRUNT_SCENE,  Vector2(180.0, 280.0))
	_add(SENTRY_SCENE, Vector2(440.0, 270.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	if char_name == "Quinn" and not _glitch_repaired:
		if quinn.global_position.distance_to(GLITCH_POS) < GLITCH_RADIUS:
			_glitch_repaired = true
			_glitch_sprite.modulate = Color(0.4, 1.0, 0.5)
	elif char_name == "Ethan" and not _system_hacked:
		if ethan.global_position.distance_to(SYSTEM_POS) < SYSTEM_RADIUS:
			_system_hacked = true
			_system_sprite.modulate = Color(0.4, 1.0, 0.5)

func _process(_delta: float) -> void:
	_update_hint()
	if _spawned and not _enemies_cleared and enemies.get_child_count() == 0:
		_enemies_cleared = true
	if _enemies_cleared and _glitch_repaired and _system_hacked and not _cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "SIMULATION EXITED!\n\nThe rules rewrite themselves — and a door opens.\n\nPress ENTER for the Map"
		clear_label.visible = true
	if _cleared and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location("vr_room")
		get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")

func _update_hint() -> void:
	if _cleared:
		hint_label.text = ""
	elif not _enemies_cleared:
		hint_label.text = "Corrupted enemies glitch through the room — clear them out!"
	elif not _glitch_repaired:
		hint_label.text = "Quinn: repair the broken physics glitch  [ approach it, press G ]"
	elif not _system_hacked:
		hint_label.text = "Ethan: hack the system to rewrite the rules  [ approach it, press G ]"
	else:
		hint_label.text = ""
