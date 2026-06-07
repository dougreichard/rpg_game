extends Node2D

# Tile-mapped floor palette — sandy landing-site tones (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.36, 0.34, 0.30)
const FLOOR_ACCENT_COLOR: Color = Color(0.58, 0.40, 0.30)
const FLOOR_COLS: int = 20
const FLOOR_ROWS: int = 12
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/Runner.tscn")
const BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/Brute.tscn")

const CHUTE_POS := Vector2(220.0, 180.0)
const CHUTE_RADIUS: float = 64.0
const LANDING_POS := Vector2(560.0, 180.0)
const LANDING_RADIUS: float = 64.0

@onready var evan: Player = $Players/Evan
@onready var ethan: Player = $Players/Ethan
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel

var _spawned: bool = false
var _enemies_cleared: bool = false
var _chute_hacked: bool = false
var _landing_cleared: bool = false
var _cleared: bool = false
var _chute_sprite: Sprite2D
var _landing_sprite: Sprite2D

func _ready() -> void:
	_build_floor()
	GameManager.register_players(evan, ethan)
	hud.setup(evan, ethan)
	evan.special_used.connect(_on_special_used)
	ethan.special_used.connect(_on_special_used)
	_create_chute()
	_create_landing()
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
func _create_chute() -> void:
	_chute_sprite = Sprite2D.new()
	_chute_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.5, 0.42, 0.18), 44, 56)
	_chute_sprite.position = CHUTE_POS
	add_child(_chute_sprite)

func _create_landing() -> void:
	_landing_sprite = Sprite2D.new()
	_landing_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.4, 0.4, 0.44), 56, 48)
	_landing_sprite.position = LANDING_POS
	add_child(_landing_sprite)

func _spawn() -> void:
	_add(GRUNT_SCENE,  Vector2(380.0, 110.0))
	_add(RUNNER_SCENE, Vector2(180.0, 280.0))
	_add(BRUTE_SCENE,  Vector2(460.0, 270.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	if char_name == "Ethan" and not _chute_hacked:
		if ethan.global_position.distance_to(CHUTE_POS) < CHUTE_RADIUS:
			_chute_hacked = true
			_chute_sprite.modulate = Color(0.4, 1.0, 0.5)
	elif char_name == "Evan" and not _landing_cleared:
		if evan.global_position.distance_to(LANDING_POS) < LANDING_RADIUS:
			_landing_cleared = true
			_landing_sprite.modulate = Color(0.4, 1.0, 0.5)

func _process(_delta: float) -> void:
	_update_hint()
	if _spawned and not _enemies_cleared and enemies.get_child_count() == 0:
		_enemies_cleared = true
	if _enemies_cleared and _chute_hacked and _landing_cleared and not _cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "TOUCHDOWN!\n\nA hostile ground crew scatters — and a marquee\nin the distance bears Uncle Doug's name.\n\nPress ENTER for the Map"
		clear_label.visible = true
	if _cleared and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location("the_drop")
		get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")

func _update_hint() -> void:
	if _cleared:
		hint_label.text = ""
	elif not _enemies_cleared:
		hint_label.text = "The descent ends hard — a hostile ground crew rushes in!"
	elif not _chute_hacked:
		hint_label.text = "Ethan: hack the jammed chute release  [ approach it, press G ]"
	elif not _landing_cleared:
		hint_label.text = "Evan: clear the wreckage blocking the landing site  [ approach it, press G ]"
	else:
		hint_label.text = ""
