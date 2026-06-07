extends Node2D

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/Runner.tscn")

const FLOOR_BASE_COLOR: Color = Color(0.32, 0.29, 0.27)
const FLOOR_ACCENT_COLOR: Color = Color(0.6, 0.48, 0.22)
const FLOOR_COLS: int = 20
const FLOOR_ROWS: int = 12
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

@onready var quinn: Player = $Players/Quinn
@onready var erin: Player = $Players/Erin
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel

var _spawned: bool = false
var _cleared: bool = false

func _ready() -> void:
	_build_floor()
	GameManager.register_players(quinn, erin)
	hud.setup(quinn, erin)
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

func _spawn() -> void:
	_add(GRUNT_SCENE,  Vector2(480.0, 110.0))
	_add(GRUNT_SCENE,  Vector2(560.0, 190.0))
	_add(GRUNT_SCENE,  Vector2(490.0, 270.0))
	_add(RUNNER_SCENE, Vector2(540.0, 140.0))
	_add(RUNNER_SCENE, Vector2(450.0, 260.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _process(_delta: float) -> void:
	if _spawned and not _cleared and enemies.get_child_count() == 0:
		_cleared = true
		clear_label.text = "WORKSHOP CLEARED!\n\nPress ENTER for the Church"
		clear_label.visible = true
	if _cleared and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location("pipe_organ_works")
		get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")
