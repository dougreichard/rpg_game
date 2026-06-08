extends Node2D

const LOCATION_ID: String = "zip_line"

# Tile-mapped floor palette — outdoor park green with sun-bleached accents (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.27, 0.33, 0.26)
const FLOOR_ACCENT_COLOR: Color = Color(0.55, 0.50, 0.30)
const FLOOR_COLS: int = 30
const FLOOR_ROWS: int = 17
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/Runner.tscn")
const HidingSpotScript: Script = preload("res://scripts/systems/hiding_spot.gd")
const HIDING_SPOT_POS := Vector2(540.0, 440.0)

const PANEL_POS := Vector2(540.0, 320.0)
const PANEL_RADIUS: float = 64.0
const RELEASE_POS := Vector2(860.0, 280.0)
const RELEASE_RADIUS: float = 64.0

const PULSE_PERIOD: float = 1.4
const PULSE_GOOD_WINDOW: float = 0.28
const RING_RADIUS: float = 30.0
const MISS_LOCKOUT: float = 0.4

# Collectibles: guard whistle (collectible-only this pass — usable-item distraction
# mechanic is a future follow-up) and arcade token (junk — embossed with a defunct
# arcade's logo, no arcade machine in the game) — see CLAUDE.md "Collectibles & Inventory".
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const GuardWhistleItem: ItemData = preload("res://data/items/guard_whistle.tres")
const ArcadeTokenItem: ItemData  = preload("res://data/items/arcade_token.tres")
const WHISTLE_LOOT_POS := Vector2(280.0, 460.0)
const TOKEN_LOOT_POS   := Vector2(820.0, 200.0)
const LOOT_FLAG_KEYS   := ["whistle_loot_open", "token_loot_open"]

# Doorway: the level's entrance/exit — see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo spawns beside it on the Landing platform;
# walking away and back exits to the overworld at any time, cleared or not.
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(160.0, 490.0)

# Multi-room layout bounding box — a literal chain of VERTICAL PLATFORMS
# linked by zip-line crossings, matching "lines connect platforms at
# different heights": a low Landing platform (entry) -> a mid-height
# Mid Platform (Ethan's control panel) -> a tall High Platform (Ben's
# release mechanism), each successive platform extending further north —
# the "staircase" reads as ascension even in a top-down 2D frame. Two
# narrow Bridge corridors (the zip-line crossings themselves) connect them
# through a shared opening band (y: 390-470). Feeds the camera's pan limits
# — see CLAUDE.md "Doorways, camera-follow & multi-room levels". Recompute
# if the wall layout changes. CAMERA_LIMIT_TOP derives from the High
# Platform's north wall (the tallest structure, so the binding constraint).
const CAMERA_LIMIT_LEFT: int = 24
const CAMERA_LIMIT_TOP: int = 164
const CAMERA_LIMIT_RIGHT: int = 936
const CAMERA_LIMIT_BOTTOM: int = 536
const CAMERA_SMOOTHING_SPEED: float = 5.0

@onready var camera: Camera2D = $Camera2D
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
var _loot_boxes: Array = []
var _doorway = null

var _pulse_timer: float = 0.0
var _release_lockout: float = 0.0
var _miss_flash: float = 0.0

func _ready() -> void:
	_build_floor()
	_build_walls()
	GameManager.register_players(ethan, ben)
	hud.setup(ethan, ben)
	ethan.special_used.connect(_on_special_used)
	ben.special_used.connect(_on_special_used)
	_create_panel()
	_create_release()
	_create_loot_boxes()
	_create_hiding_spot()
	_create_doorway()
	_setup_camera()
	_restore_progress()

# Camera follows the active character — see CLAUDE.md "Doorways,
# camera-follow & multi-room levels".
func _setup_camera() -> void:
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = CAMERA_SMOOTHING_SPEED
	camera.limit_left = CAMERA_LIMIT_LEFT
	camera.limit_top = CAMERA_LIMIT_TOP
	camera.limit_right = CAMERA_LIMIT_RIGHT
	camera.limit_bottom = CAMERA_LIMIT_BOTTOM

# Mid-level progress restoration — see CLAUDE.md "Doorways, camera-follow &
# multi-room levels". Reads back exactly the booleans this level already
# tracks locally, so re-entering after a Doorway exit picks up where the duo
# left off: skip respawning a cleared floor and restore the panel/release
# props' solved-state palettes (the timing-gate ring simply stops drawing
# once _release_timed is true, same as it does mid-session).
func _restore_progress() -> void:
	_enemies_cleared = GameManager.get_level_flag(LOCATION_ID, "enemies_cleared", false)
	_panel_hacked = GameManager.get_level_flag(LOCATION_ID, "panel_hacked", false)
	_release_timed = GameManager.get_level_flag(LOCATION_ID, "release_timed", false)
	if _panel_hacked:
		_panel_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _release_timed:
		_release_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _enemies_cleared:
		_spawned = true
	else:
		_spawn()
	if _enemies_cleared and _panel_hacked and _release_timed:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "LINES RECONNECTED!\n\nFrom the high platform, a familiar silhouette.\n\nPress ENTER for the Map"
		clear_label.visible = true

# Tile-mapped retro floor (Zelda-style two-tone grid), generated at runtime
# via PlaceholderArt to keep the original-IP guarantee — no imported tile art.
# Wall art: a Sprite2D per StaticBody2D wall, sized to its exact
# CollisionShape2D rect and textured via PlaceholderArt.make_wall_texture — a
# darker stone tone of the floor's base color, so the room reads as a bordered
# space instead of walls-on-a-void (matches the tile-floor visual-style pass;
# generated at runtime, no imported wall art, original-IP guarantee intact).
# Iterates whatever StaticBody2D children it finds — the three-platform,
# two-bridge layout (20 wall segments) needed zero changes here, only more
# .tscn nodes.
func _build_walls() -> void:
	var wall_color: Color = FLOOR_BASE_COLOR.darkened(0.35)
	for wall in $Walls.get_children():
		if not wall is StaticBody2D:
			continue
		var shape: CollisionShape2D = wall.get_node("CollisionShape2D")
		var rect: RectangleShape2D = shape.shape
		var sprite := Sprite2D.new()
		sprite.texture = PlaceholderArt.make_wall_texture(wall_color, int(rect.size.x), int(rect.size.y))
		wall.add_child(sprite)

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

func _create_loot_boxes() -> void:
	var whistle_box = LootBoxScript.new()
	whistle_box.setup(GuardWhistleItem, WHISTLE_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[0], false))
	add_child(whistle_box)
	_loot_boxes.append(whistle_box)

	var token_box = LootBoxScript.new()
	token_box.setup(ArcadeTokenItem, TOKEN_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[1], false))
	add_child(token_box)
	_loot_boxes.append(token_box)

# Stealth: a shadowed alcove on the Mid Platform — the crossroads every
# patrol crossing between the lower and upper lines must pass through, so
# ducking in here to let one go by is meaningful regardless of which
# direction the duo is headed — see CLAUDE.md "Stealth & awareness".
func _create_hiding_spot() -> void:
	var spot = HidingSpotScript.new()
	spot.position = HIDING_SPOT_POS
	add_child(spot)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

func _spawn() -> void:
	_add(RUNNER_SCENE, Vector2(180.0, 420.0))
	_add(GRUNT_SCENE,  Vector2(460.0, 300.0))
	_add(RUNNER_SCENE, Vector2(860.0, 350.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	var p: Player = ethan if char_name == "Ethan" else ben
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if char_name == "Ethan" and not _panel_hacked:
		if ethan.global_position.distance_to(PANEL_POS) < PANEL_RADIUS:
			_panel_hacked = true
			_panel_sprite.modulate = Color(0.4, 1.0, 0.5)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "panel_hacked", true)
	elif char_name == "Ben" and not _release_timed:
		if ben.global_position.distance_to(RELEASE_POS) < RELEASE_RADIUS and _release_lockout <= 0.0:
			if _pulse_timer >= PULSE_PERIOD - PULSE_GOOD_WINDOW:
				_release_timed = true
				_release_sprite.modulate = Color(0.4, 1.0, 0.5)
				Audio.play("special")
				GameManager.set_level_flag(LOCATION_ID, "release_timed", true)
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
	if is_instance_valid(GameManager.active_player):
		var active_pos: Vector2 = GameManager.active_player.global_position
		camera.global_position = active_pos
		if _doorway.check(active_pos):
			_exit_to_overworld()
			return
	if _spawned and not _enemies_cleared and enemies.get_child_count() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(LOCATION_ID, "enemies_cleared", true)
	if _enemies_cleared and _panel_hacked and _release_timed and not _cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "LINES RECONNECTED!\n\nFrom the high platform, a familiar silhouette.\n\nPress ENTER for the Map"
		clear_label.visible = true
	if _cleared and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location(LOCATION_ID)
		get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")

# Doorway-triggered exit — distinct from the clear-overlay's "press ENTER"
# exit above. Per the established pattern, the duo can walk out at any time,
# cleared or not; complete_location is idempotent, so calling it here when
# already cleared never double-grants.
func _exit_to_overworld() -> void:
	if _cleared:
		GameManager.complete_location(LOCATION_ID)
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
		hint_label.text = "The patrol hasn't clocked you yet — thread a path between their routes, or clear them before reactivating the lines"
	elif not _panel_hacked:
		hint_label.text = "Ethan: reactivate the broken zip line control panel on the Mid Platform  [ approach it, press G ]"
	elif not _release_timed:
		hint_label.text = "Ben: from the High Platform, watch the pulsing ring — press G when it glows green at its peak"
	else:
		hint_label.text = ""
