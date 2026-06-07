extends Node2D

# Tile-mapped floor palette — dark, earthy maintenance-tunnel tones (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.20, 0.20, 0.19)
const FLOOR_ACCENT_COLOR: Color = Color(0.38, 0.35, 0.28)
const FLOOR_COLS: int = 20
const FLOOR_ROWS: int = 12
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/Runner.tscn")

const RUBBLE_POS := Vector2(220.0, 180.0)
const RUBBLE_RADIUS: float = 64.0
const HATCH_POS := Vector2(560.0, 180.0)
const HATCH_RADIUS: float = 64.0
const HATCH_PRESSES_REQUIRED: int = 3
const PIP_RADIUS: float = 5.0
const PIP_SPACING: float = 16.0
const PIP_OFFSET_Y: float = -38.0
const PIP_FLASH_DURATION: float = 0.3

@onready var evan: Player = $Players/Evan
@onready var ethan: Player = $Players/Ethan
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel

var _spawned: bool = false
var _enemies_cleared: bool = false
var _rubble_cleared: bool = false
var _hatch_hacked: bool = false
var _cleared: bool = false
var _rubble_sprite: Sprite2D
var _hatch_sprite: Sprite2D

var _hatch_progress: int = 0
var _pip_flash: float = 0.0

func _ready() -> void:
	_build_floor()
	GameManager.register_players(evan, ethan)
	hud.setup(evan, ethan)
	evan.special_used.connect(_on_special_used)
	ethan.special_used.connect(_on_special_used)
	_create_rubble()
	_create_hatch()
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
func _create_rubble() -> void:
	_rubble_sprite = Sprite2D.new()
	_rubble_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.34, 0.3, 0.28), 60, 44)
	_rubble_sprite.position = RUBBLE_POS
	add_child(_rubble_sprite)

func _create_hatch() -> void:
	_hatch_sprite = Sprite2D.new()
	_hatch_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.26, 0.32, 0.36), 44, 44)
	_hatch_sprite.position = HATCH_POS
	add_child(_hatch_sprite)

func _spawn() -> void:
	_add(GRUNT_SCENE,  Vector2(380.0, 110.0))
	_add(GRUNT_SCENE,  Vector2(180.0, 280.0))
	_add(RUNNER_SCENE, Vector2(440.0, 270.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	if char_name == "Evan" and not _rubble_cleared:
		if evan.global_position.distance_to(RUBBLE_POS) < RUBBLE_RADIUS:
			_rubble_cleared = true
			_rubble_sprite.modulate = Color(0.4, 1.0, 0.5)
	elif char_name == "Ethan" and not _hatch_hacked:
		if ethan.global_position.distance_to(HATCH_POS) < HATCH_RADIUS:
			_hatch_progress += 1
			_pip_flash = PIP_FLASH_DURATION
			Audio.play("hit")
			if _hatch_progress >= HATCH_PRESSES_REQUIRED:
				_hatch_hacked = true
				_hatch_sprite.modulate = Color(0.4, 1.0, 0.5)
				Audio.play("special")

func _process(delta: float) -> void:
	_update_hint()
	_pip_flash = maxf(_pip_flash - delta, 0.0)
	queue_redraw()
	if _spawned and not _enemies_cleared and enemies.get_child_count() == 0:
		_enemies_cleared = true
	if _enemies_cleared and _rubble_cleared and _hatch_hacked and not _cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "TUNNELS MAPPED!\n\nA hidden route opens between locations.\n\nPress ENTER for the Map"
		clear_label.visible = true
	if _cleared and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location("underground")
		get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")

func _draw() -> void:
	if _hatch_hacked:
		return
	var start_x: float = HATCH_POS.x - PIP_SPACING * float(HATCH_PRESSES_REQUIRED - 1) * 0.5
	for i in range(HATCH_PRESSES_REQUIRED):
		var pip_pos := Vector2(start_x + PIP_SPACING * float(i), HATCH_POS.y + PIP_OFFSET_Y)
		var filled: bool = i < _hatch_progress
		var color: Color = Color(0.4, 1.0, 0.5, 0.9) if filled else Color(0.7, 0.7, 0.7, 0.5)
		if filled and i == _hatch_progress - 1 and _pip_flash > 0.0:
			color = Color(1.0, 1.0, 1.0, 0.95)
		draw_circle(pip_pos, PIP_RADIUS, color)
		draw_arc(pip_pos, PIP_RADIUS, 0.0, TAU, 16, Color(0.1, 0.1, 0.1, 0.6), 1.5)

func _update_hint() -> void:
	if _cleared:
		hint_label.text = ""
	elif not _enemies_cleared:
		hint_label.text = "Patrols echo through the dark — clear the corridor!"
	elif not _rubble_cleared:
		hint_label.text = "Evan: force the blocked passage open  [ approach the rubble, press G ]"
	elif not _hatch_hacked:
		hint_label.text = "Ethan: the lock needs %d hacking passes — approach it and press G repeatedly (%d/%d so far)" % [HATCH_PRESSES_REQUIRED, _hatch_progress, HATCH_PRESSES_REQUIRED]
	else:
		hint_label.text = ""
