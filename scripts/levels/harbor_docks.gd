extends Node2D

# Tile-mapped floor palette — weathered dock planking with sea-blue accents (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.28, 0.31, 0.33)
const FLOOR_ACCENT_COLOR: Color = Color(0.45, 0.55, 0.50)
const FLOOR_COLS: int = 20
const FLOOR_ROWS: int = 12
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/Runner.tscn")
const AnimalCompanionScript: Script = preload("res://scripts/systems/animal_companion.gd")

const CONTAINER_POS := Vector2(560.0, 180.0)
const CONTAINER_RADIUS: float = 64.0
const CALVIN_COLOR := Color(0.96, 0.96, 0.92)
const CALVIN_COOLDOWN: float = 2.5

var _calvin_cooldown_timer: float = 0.0

@onready var quinn: Player = $Players/Quinn
@onready var evan: Player = $Players/Evan
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel

var _spawned: bool = false
var _enemies_cleared: bool = false
var _container_moved: bool = false
var _cleared: bool = false
var _container_sprite: Sprite2D

func _ready() -> void:
	_build_floor()
	GameManager.register_players(quinn, evan)
	hud.setup(quinn, evan)
	evan.special_used.connect(_on_special_used)
	_create_container()
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
func _create_container() -> void:
	_container_sprite = Sprite2D.new()
	_container_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.5, 0.36, 0.16), 56, 48)
	_container_sprite.position = CONTAINER_POS
	add_child(_container_sprite)

func _spawn() -> void:
	_add(GRUNT_SCENE,  Vector2(220.0, 110.0))
	_add(GRUNT_SCENE,  Vector2(440.0, 280.0))
	_add(RUNNER_SCENE, Vector2(320.0, 180.0))
	_add(RUNNER_SCENE, Vector2(160.0, 270.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	if char_name != "Evan":
		return
	if not _container_moved and evan.global_position.distance_to(CONTAINER_POS) < CONTAINER_RADIUS:
		_container_moved = true
		_container_sprite.modulate = Color(0.4, 1.0, 0.5)
		_container_sprite.position += Vector2(80.0, 0.0)
	elif _calvin_cooldown_timer == 0.0:
		_summon_calvin()

func _summon_calvin() -> void:
	var target: Enemy = _nearest_enemy(evan.global_position)
	if target == null:
		return
	var calvin = AnimalCompanionScript.new()
	calvin.setup(evan, target, CALVIN_COLOR)
	add_child(calvin)
	_calvin_cooldown_timer = CALVIN_COOLDOWN

func _nearest_enemy(from_pos: Vector2) -> Enemy:
	var nearest: Enemy = null
	var nearest_dist: float = INF
	for child in enemies.get_children():
		if child is Enemy and is_instance_valid(child):
			var d: float = from_pos.distance_to(child.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = child
	return nearest

func _process(delta: float) -> void:
	_calvin_cooldown_timer = maxf(_calvin_cooldown_timer - delta, 0.0)
	_update_hint()
	if _spawned and not _enemies_cleared and enemies.get_child_count() == 0:
		_enemies_cleared = true
	if _enemies_cleared and _container_moved and not _cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "DOCKS SECURED!\n\nA shipment manifest names Uncle Doug.\n\nPress ENTER for the Map"
		clear_label.visible = true
	if _cleared and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location("harbor_docks")
		get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")

func _update_hint() -> void:
	if _cleared:
		hint_label.text = ""
	elif not _enemies_cleared:
		hint_label.text = "Dock workers and smugglers are closing in — clear them out!  [ Evan: press G to call Calvin to stagger a foe ]"
	elif not _container_moved:
		hint_label.text = "Evan: shove the cargo container off the crane controls  [ approach it, press G ]"
	else:
		hint_label.text = ""
