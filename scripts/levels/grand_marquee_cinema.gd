extends Node2D

# Tile-mapped floor palette — rich theater red with gold accents (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.30, 0.21, 0.23)
const FLOOR_ACCENT_COLOR: Color = Color(0.72, 0.55, 0.28)
const FLOOR_COLS: int = 20
const FLOOR_ROWS: int = 12
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/enemies/Boss.tscn")

const PROJECTOR_POS := Vector2(220.0, 180.0)
const PROJECTOR_RADIUS: float = 64.0
const ORGAN_POS := Vector2(560.0, 180.0)
const ORGAN_RADIUS: float = 64.0

@onready var quinn: Player = $Players/Quinn
@onready var ben: Player = $Players/Ben
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel

var _spawned: bool = false
var _enemies_cleared: bool = false
var _projector_repaired: bool = false
var _organ_played: bool = false
var _cleared: bool = false
var _projector_sprite: Sprite2D
var _organ_sprite: Sprite2D

func _ready() -> void:
	_build_floor()
	GameManager.register_players(quinn, ben)
	hud.setup(quinn, ben)
	quinn.special_used.connect(_on_special_used)
	ben.special_used.connect(_on_special_used)
	_create_projector()
	_create_organ()
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
func _create_projector() -> void:
	_projector_sprite = Sprite2D.new()
	_projector_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.42, 0.32, 0.5), 48, 48)
	_projector_sprite.position = PROJECTOR_POS
	add_child(_projector_sprite)

func _create_organ() -> void:
	_organ_sprite = Sprite2D.new()
	_organ_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.5, 0.2, 0.24), 48, 56)
	_organ_sprite.position = ORGAN_POS
	add_child(_organ_sprite)

func _spawn() -> void:
	_add(GRUNT_SCENE, Vector2(180.0, 280.0))
	_add(GRUNT_SCENE, Vector2(460.0, 90.0))
	_add(BOSS_SCENE,  Vector2(320.0, 180.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	if char_name == "Quinn" and not _projector_repaired:
		if quinn.global_position.distance_to(PROJECTOR_POS) < PROJECTOR_RADIUS:
			_projector_repaired = true
			_projector_sprite.modulate = Color(0.4, 1.0, 0.5)
	elif char_name == "Ben" and not _organ_played:
		if ben.global_position.distance_to(ORGAN_POS) < ORGAN_RADIUS:
			_organ_played = true
			_organ_sprite.modulate = Color(0.4, 1.0, 0.5)

func _process(_delta: float) -> void:
	_update_hint()
	if _spawned and not _enemies_cleared and enemies.get_child_count() == 0:
		_enemies_cleared = true
	if _enemies_cleared and _projector_repaired and _organ_played and not _cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "THE FINAL REEL!\n\nThe house lights rise — and there, in the\nprojection booth, stands Uncle Doug.\n\nPress ENTER to continue"
		clear_label.visible = true
	if _cleared and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location("grand_marquee")
		get_tree().change_scene_to_file("res://scenes/ui/ResultScreen.tscn")

func _update_hint() -> void:
	if _cleared:
		hint_label.text = ""
	elif not _enemies_cleared:
		hint_label.text = "A guardian blocks the aisle, flanked by stagehands — fight through!"
	elif not _projector_repaired:
		hint_label.text = "Quinn: repair the projection equipment  [ approach it, press G ]"
	elif not _organ_played:
		hint_label.text = "Ben: play the house organ to calm the crowd  [ approach it, press G ]"
	else:
		hint_label.text = ""
