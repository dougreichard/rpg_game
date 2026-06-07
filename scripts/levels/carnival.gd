extends Node2D

# Tile-mapped floor palette — festive midway purple with gold accents (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.34, 0.29, 0.33)
const FLOOR_ACCENT_COLOR: Color = Color(0.78, 0.55, 0.24)
const FLOOR_COLS: int = 20
const FLOOR_ROWS: int = 12
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/Brute.tscn")

const RIDE_POS := Vector2(220.0, 180.0)
const RIDE_RADIUS: float = 64.0
const BACKSTAGE_POS := Vector2(560.0, 180.0)
const BACKSTAGE_RADIUS: float = 64.0

@onready var quinn: Player = $Players/Quinn
@onready var erin: Player = $Players/Erin
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel

var _spawned: bool = false
var _enemies_cleared: bool = false
var _ride_repaired: bool = false
var _backstage_talked: bool = false
var _cleared: bool = false
var _ride_sprite: Sprite2D
var _guard_sprite: Sprite2D

func _ready() -> void:
	_build_floor()
	GameManager.register_players(quinn, erin)
	hud.setup(quinn, erin)
	quinn.special_used.connect(_on_special_used)
	erin.special_used.connect(_on_special_used)
	_create_ride()
	_create_backstage()
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
func _create_ride() -> void:
	_ride_sprite = Sprite2D.new()
	_ride_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.55, 0.32, 0.18), 56, 56)
	_ride_sprite.position = RIDE_POS
	add_child(_ride_sprite)

func _create_backstage() -> void:
	_guard_sprite = Sprite2D.new()
	_guard_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.5, 0.18, 0.4), 36, 56)
	_guard_sprite.position = BACKSTAGE_POS
	add_child(_guard_sprite)

func _spawn() -> void:
	_add(GRUNT_SCENE, Vector2(380.0, 110.0))
	_add(GRUNT_SCENE, Vector2(180.0, 280.0))
	_add(BRUTE_SCENE, Vector2(440.0, 270.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	if char_name == "Quinn" and not _ride_repaired:
		if quinn.global_position.distance_to(RIDE_POS) < RIDE_RADIUS:
			_ride_repaired = true
			_ride_sprite.modulate = Color(0.4, 1.0, 0.5)
	elif char_name == "Erin" and not _backstage_talked:
		if erin.global_position.distance_to(BACKSTAGE_POS) < BACKSTAGE_RADIUS:
			_backstage_talked = true
			_guard_sprite.modulate = Color(0.4, 1.0, 0.5)

func _process(_delta: float) -> void:
	_update_hint()
	if _spawned and not _enemies_cleared and enemies.get_child_count() == 0:
		_enemies_cleared = true
	if _enemies_cleared and _ride_repaired and _backstage_talked and not _cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "MIDWAY CLEARED!\n\nBackstage, a poster shows Uncle Doug's face.\n\nPress ENTER for the Map"
		clear_label.visible = true
	if _cleared and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location("carnival")
		get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")

func _update_hint() -> void:
	if _cleared:
		hint_label.text = ""
	elif not _enemies_cleared:
		hint_label.text = "Carnies and strongmen are causing a scene — clear the midway!"
	elif not _ride_repaired:
		hint_label.text = "Quinn: repair the broken ride  [ approach it, press G ]"
	elif not _backstage_talked:
		hint_label.text = "Erin: talk your way past the backstage guard  [ approach him, press G ]"
	else:
		hint_label.text = ""
