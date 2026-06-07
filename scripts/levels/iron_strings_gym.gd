extends Node2D

# Tile-mapped floor palette — gym-floor grey with iron-red accents (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.28, 0.26, 0.26)
const FLOOR_ACCENT_COLOR: Color = Color(0.62, 0.30, 0.26)
const FLOOR_COLS: int = 20
const FLOOR_ROWS: int = 12
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/Brute.tscn")

const BARBELL_POS := Vector2(560.0, 180.0)
const BARBELL_RADIUS: float = 64.0

@onready var quinn: Player = $Players/Quinn
@onready var evan: Player = $Players/Evan
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel

var _spawned: bool = false
var _enemies_cleared: bool = false
var _barbell_moved: bool = false
var _cleared: bool = false
var _barbell_sprite: Sprite2D

func _ready() -> void:
	_build_floor()
	GameManager.register_players(quinn, evan)
	hud.setup(quinn, evan)
	evan.special_used.connect(_on_special_used)
	_create_barbell()
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
func _create_barbell() -> void:
	_barbell_sprite = Sprite2D.new()
	_barbell_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.32, 0.32, 0.38), 64, 28)
	_barbell_sprite.position = BARBELL_POS
	add_child(_barbell_sprite)

func _spawn() -> void:
	_add(GRUNT_SCENE, Vector2(220.0, 110.0))
	_add(GRUNT_SCENE, Vector2(420.0, 270.0))
	_add(BRUTE_SCENE, Vector2(320.0, 180.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	if char_name == "Evan" and not _barbell_moved:
		if evan.global_position.distance_to(BARBELL_POS) < BARBELL_RADIUS:
			_barbell_moved = true
			_barbell_sprite.modulate = Color(0.35, 1.0, 0.4)
			_barbell_sprite.position += Vector2(0.0, -90.0)

func _process(_delta: float) -> void:
	_update_hint()
	if _spawned and not _enemies_cleared and enemies.get_child_count() == 0:
		_enemies_cleared = true
	if _enemies_cleared and _barbell_moved and not _cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "GYM CLEARED!\n\nBen is free.\n\nPress ENTER for the Map"
		clear_label.visible = true
	if _cleared and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location("iron_strings_gym")
		get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")

func _update_hint() -> void:
	if _cleared:
		hint_label.text = ""
	elif not _enemies_cleared:
		hint_label.text = "Clear the gym floor of bruisers!"
	elif not _barbell_moved:
		hint_label.text = "Evan: lift the barbell off Ben's cage  [ approach it, press G ]"
	else:
		hint_label.text = ""
