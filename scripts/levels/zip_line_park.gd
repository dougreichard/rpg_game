extends Node2D

# Tile-mapped floor palette — outdoor park green with sun-bleached accents (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.27, 0.33, 0.26)
const FLOOR_ACCENT_COLOR: Color = Color(0.55, 0.50, 0.30)
const FLOOR_COLS: int = 20
const FLOOR_ROWS: int = 12
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/Runner.tscn")

const PANEL_POS := Vector2(220.0, 180.0)
const PANEL_RADIUS: float = 64.0
const RELEASE_POS := Vector2(560.0, 180.0)
const RELEASE_RADIUS: float = 64.0

const PULSE_PERIOD: float = 1.4
const PULSE_GOOD_WINDOW: float = 0.28
const RING_RADIUS: float = 30.0
const MISS_LOCKOUT: float = 0.4

@onready var ethan: Player = $Players/Ethan
@onready var ben: Player = $Players/Ben
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel

var _spawned: bool = false
var _enemies_cleared: bool = false
var _panel_hacked: bool = false
var _release_timed: bool = false
var _cleared: bool = false
var _panel_sprite: Sprite2D
var _release_sprite: Sprite2D

var _pulse_timer: float = 0.0
var _release_lockout: float = 0.0
var _miss_flash: float = 0.0

func _ready() -> void:
	_build_floor()
	GameManager.register_players(ethan, ben)
	hud.setup(ethan, ben)
	ethan.special_used.connect(_on_special_used)
	ben.special_used.connect(_on_special_used)
	_create_panel()
	_create_release()
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
func _create_panel() -> void:
	_panel_sprite = Sprite2D.new()
	_panel_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.26, 0.4, 0.36), 44, 40)
	_panel_sprite.position = PANEL_POS
	add_child(_panel_sprite)

func _create_release() -> void:
	_release_sprite = Sprite2D.new()
	_release_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.42, 0.36, 0.18), 48, 36)
	_release_sprite.position = RELEASE_POS
	add_child(_release_sprite)

func _spawn() -> void:
	_add(GRUNT_SCENE,  Vector2(380.0, 110.0))
	_add(RUNNER_SCENE, Vector2(180.0, 280.0))
	_add(RUNNER_SCENE, Vector2(440.0, 270.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	if char_name == "Ethan" and not _panel_hacked:
		if ethan.global_position.distance_to(PANEL_POS) < PANEL_RADIUS:
			_panel_hacked = true
			_panel_sprite.modulate = Color(0.4, 1.0, 0.5)
	elif char_name == "Ben" and not _release_timed:
		if ben.global_position.distance_to(RELEASE_POS) < RELEASE_RADIUS and _release_lockout <= 0.0:
			if _pulse_timer >= PULSE_PERIOD - PULSE_GOOD_WINDOW:
				_release_timed = true
				_release_sprite.modulate = Color(0.4, 1.0, 0.5)
				Audio.play("special")
			else:
				_release_lockout = MISS_LOCKOUT
				_miss_flash = MISS_LOCKOUT
				Audio.play("hurt")

func _process(delta: float) -> void:
	_update_hint()
	_release_lockout = maxf(_release_lockout - delta, 0.0)
	_miss_flash = maxf(_miss_flash - delta, 0.0)
	if not _release_timed:
		_pulse_timer = fmod(_pulse_timer + delta, PULSE_PERIOD)
	queue_redraw()
	if _spawned and not _enemies_cleared and enemies.get_child_count() == 0:
		_enemies_cleared = true
	if _enemies_cleared and _panel_hacked and _release_timed and not _cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "LINES RECONNECTED!\n\nFrom the high platform, a familiar silhouette.\n\nPress ENTER for the Map"
		clear_label.visible = true
	if _cleared and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location("zip_line")
		get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")

func _draw() -> void:
	if _release_timed:
		return
	var pulse_fraction: float = _pulse_timer / PULSE_PERIOD
	var ring_color: Color = Color(0.95, 0.85, 0.3, 0.85)
	if pulse_fraction >= (PULSE_PERIOD - PULSE_GOOD_WINDOW) / PULSE_PERIOD:
		ring_color = Color(0.4, 1.0, 0.5, 0.9)
	if _miss_flash > 0.0:
		ring_color = Color(1.0, 0.3, 0.3, 0.9)
	draw_arc(RELEASE_POS, RING_RADIUS * pulse_fraction, 0.0, TAU, 32, ring_color, 4.0)
	draw_circle(RELEASE_POS, 4.0, ring_color)

func _update_hint() -> void:
	if _cleared:
		hint_label.text = ""
	elif not _enemies_cleared:
		hint_label.text = "Clear the platform before the lines can be reactivated!"
	elif not _panel_hacked:
		hint_label.text = "Ethan: reactivate the broken zip line control panel  [ approach it, press G ]"
	elif not _release_timed:
		hint_label.text = "Ben: watch the pulsing ring — press G when it glows green at its peak"
	else:
		hint_label.text = ""
