extends Node2D

const LOCATION_ID: String = "zip_line"

# Tile-mapped floor palette  --  outdoor park green with sun-bleached accents (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.27, 0.33, 0.26)
const FLOOR_ACCENT_COLOR: Color = Color(0.55, 0.50, 0.30)
const FLOOR_COLS: int = 30
const FLOOR_ROWS: int = 17
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 3)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 3)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/Runner.tscn")
const HidingSpotScript: Script = preload("res://scripts/systems/hiding_spot.gd")
const HIDING_SPOT_POS := Vector2(540.0, 440.0)

# Lizard  --  alternate route to _panel_hacked: climbs the support pylon to
# the high-mounted access port, letting Ethan bypass standing at the panel
# directly (same William-&-Mary pattern from The Drop).
const LizardScript: Script = preload("res://scripts/systems/lizard_companion.gd")
const HIGH_ACCESS_POS := Vector2(540.0, 185.0)
const LIZARD_COOLDOWN: float = 4.0

const PANEL_POS := Vector2(540.0, 320.0)
const PANEL_RADIUS: float = 64.0
const RELEASE_POS := Vector2(860.0, 280.0)
const RELEASE_RADIUS: float = 64.0

const PULSE_PERIOD: float = 1.4
const PULSE_GOOD_WINDOW: float = 0.28
const RING_RADIUS: float = 30.0
const MISS_LOCKOUT: float = 0.4

# Collectibles: guard whistle (collectible-only this pass  --  usable-item distraction
# mechanic is a future follow-up) and arcade token (junk  --  embossed with a defunct
# arcade's logo, no arcade machine in the game)  --  see CLAUDE.md "Collectibles & Inventory".
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const GuardWhistleItem: ItemData = preload("res://data/items/guard_whistle.tres")
const ArcadeTokenItem: ItemData  = preload("res://data/items/arcade_token.tres")
const WHISTLE_LOOT_POS := Vector2(280.0, 460.0)
const TOKEN_LOOT_POS   := Vector2(820.0, 200.0)
const LOOT_FLAG_KEYS   := ["whistle_loot_open", "token_loot_open"]

# Doorway: the level's entrance/exit  --  see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo spawns beside it on the Landing platform;
# walking away and back exits to the overworld at any time, cleared or not.
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(160.0, 490.0)

const DialogBoxScript: Script    = preload("res://scripts/ui/dialog_box.gd")
const DialogTreeScript: Script   = preload("res://scripts/systems/dialog_tree.gd")
const SpeechBubbleScript: Script = preload("res://scripts/systems/speech_bubble.gd")

const LENA_BUBBLE_MIN  : float = 7.0
const LENA_BUBBLE_MAX  : float = 14.0
const LENA_BUBBLE_DUR  : float = 3.5
const LENA_BUBBLE_LINES: Array[String] = [
	"Nobody rides until the equipment's certified.",
	"Safety first. Then fun. In that order.",
	"I've cleared this course a hundred times.",
]

const LENA_COLOR := Color(0.16, 0.63, 0.59)
const LENA_POS := Vector2(220.0, 440.0)
const LENA_RADIUS: float = 64.0
static var LENA_INTRO_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"Safety briefing: all riders clip in. Someone cut the release power — lines are dead.\"",
	"\"Ethan: the control panel on the Mid Platform will restore power. Ben, once it's live the High Platform release opens a timed window — watch the ring and press G when it pulses green.\""
])
static var LENA_REMINDER_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"Ethan: control panel on the Mid Platform. Then Ben catches the timing window up top.\""
])
static var LENA_AFTER_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"Lines fully restored. Unusual technique on that timing window — but it worked.\""
])

# Multi-room layout bounding box  --  a literal chain of VERTICAL PLATFORMS
# linked by zip-line crossings, matching "lines connect platforms at
# different heights": a low Landing platform (entry) -> a mid-height
# Mid Platform (Ethan's control panel) -> a tall High Platform (Ben's
# release mechanism), each successive platform extending further north  -- 
# the "staircase" reads as ascension even in a top-down 2D frame. Two
# narrow Bridge corridors (the zip-line crossings themselves) connect them
# through a shared opening band (y: 390-470). Feeds the camera's pan limits
#  --  see CLAUDE.md "Doorways, camera-follow & multi-room levels". Recompute
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
var _lizard_cooldown_timer: float = 0.0
var _cd_scale: float = 1.0
var _lena_sprite: AnimatedSprite2D
var _lena_bubble        = null
var _lena_bubble_timer: float = 0.0
var _dialog_box = null
var _lena_met: bool = false

func _ready() -> void:
	_build_floor()
	_build_walls()
	GameManager.register_players_with_preference(ethan, ben)
	hud.setup(ethan, ben)
	ethan.special_used.connect(_on_special_used)
	ben.special_used.connect(_on_special_used)
	_cd_scale = GameManager.companion_cooldown_scale()
	_create_panel()
	_create_release()
	_create_loot_boxes()
	_create_hiding_spot()
	_create_doorway()
	_create_lena_npc()
	_setup_camera()
	_restore_progress()
	if not _cleared:
		Audio.play_music("combat")

# Camera follows the active character  --  see CLAUDE.md "Doorways,
# camera-follow & multi-room levels".
func _setup_camera() -> void:
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = CAMERA_SMOOTHING_SPEED
	camera.limit_left = CAMERA_LIMIT_LEFT
	camera.limit_top = CAMERA_LIMIT_TOP
	camera.limit_right = CAMERA_LIMIT_RIGHT
	camera.limit_bottom = CAMERA_LIMIT_BOTTOM

# Mid-level progress restoration  --  see CLAUDE.md "Doorways, camera-follow &
# multi-room levels". Reads back exactly the booleans this level already
# tracks locally, so re-entering after a Doorway exit picks up where the duo
# left off: skip respawning a cleared floor and restore the panel/release
# props' solved-state palettes (the timing-gate ring simply stops drawing
# once _release_timed is true, same as it does mid-session).
func _restore_progress() -> void:
	_enemies_cleared = GameManager.get_level_flag(LOCATION_ID, "enemies_cleared", false)
	_panel_hacked = GameManager.get_level_flag(LOCATION_ID, "panel_hacked", false)
	_release_timed = GameManager.get_level_flag(LOCATION_ID, "release_timed", false)
	_lena_met = GameManager.get_level_flag(LOCATION_ID, "lena_met", false)
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
# via PlaceholderArt to keep the original-IP guarantee  --  no imported tile art.
# Wall art: a Sprite2D per StaticBody2D wall, sized to its exact
# CollisionShape2D rect and textured via PlaceholderArt.make_wall_texture  --  a
# darker stone tone of the floor's base color, so the room reads as a bordered
# space instead of walls-on-a-void (matches the tile-floor visual-style pass;
# generated at runtime, no imported wall art, original-IP guarantee intact).
# Iterates whatever StaticBody2D children it finds  --  the three-platform,
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
	tile_map.tile_set = PlaceholderArt.make_hb_tileset()
	add_child(tile_map)
	move_child(tile_map, 0)
	tile_map.position = Vector2(CAMERA_LIMIT_LEFT, CAMERA_LIMIT_TOP)
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

# Stealth: a shadowed alcove on the Mid Platform  --  the crossroads every
# patrol crossing between the lower and upper lines must pass through, so
# ducking in here to let one go by is meaningful regardless of which
# direction the duo is headed  --  see CLAUDE.md "Stealth & awareness".
func _create_hiding_spot() -> void:
	var spot = HidingSpotScript.new()
	spot.position = HIDING_SPOT_POS
	add_child(spot)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

func _create_lena_npc() -> void:
	_lena_sprite = AnimatedSprite2D.new()
	var loaded: SpriteFrames = SpriteLoader.try_load_npc("lena")
	_lena_sprite.sprite_frames = loaded if loaded != null else PlaceholderArt.make_player_frames(LENA_COLOR, "")
	_lena_sprite.scale = Vector2(SpriteLoader.NPC_SPRITE_SCALE, SpriteLoader.NPC_SPRITE_SCALE) if loaded != null else Vector2.ONE
	_lena_sprite.play("idle")
	_lena_sprite.position = LENA_POS
	add_child(_lena_sprite)
	_lena_bubble = SpeechBubbleScript.new()
	_lena_bubble.position = LENA_POS + Vector2(0.0, -52.0)
	add_child(_lena_bubble)
	_lena_bubble_timer = randf_range(LENA_BUBBLE_MIN, LENA_BUBBLE_MAX)
	var dialog_layer := CanvasLayer.new()
	dialog_layer.layer = 19
	add_child(dialog_layer)
	_dialog_box = DialogBoxScript.new()
	dialog_layer.add_child(_dialog_box)
	_dialog_box.closed.connect(_on_lena_dialog_closed)

func _talk_to_lena() -> void:
	var p: Player = GameManager.active_player
	var tree: Dictionary
	if _cleared:
		tree = LENA_AFTER_TREE
	elif not _lena_met:
		tree = LENA_INTRO_TREE
	else:
		tree = LENA_REMINDER_TREE
	_dialog_box.open("Lena", LENA_COLOR, tree, "start", p.data.character_name)

func _on_lena_dialog_closed(_effects: Array) -> void:
	if not _lena_met:
		_lena_met = true
		GameManager.set_level_flag(LOCATION_ID, "lena_met", true)

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
	if _dialog_box.is_open():
		return
	var p: Player = ethan if char_name == "Ethan" else ben
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if p.global_position.distance_to(LENA_POS) < LENA_RADIUS:
		_talk_to_lena()
		return
	if char_name == "Ethan" and not _panel_hacked:
		if ethan.global_position.distance_to(PANEL_POS) < PANEL_RADIUS:
			_panel_hacked = true
			_panel_sprite.modulate = Color(0.4, 1.0, 0.5)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "panel_hacked", true)
		elif _lizard_cooldown_timer == 0.0:
			_summon_lizard()
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
	elif GameManager.try_use_whistle():
		Audio.play("special")

func _summon_lizard() -> void:
	var lizard = LizardScript.new()
	lizard.setup(ethan, HIGH_ACCESS_POS)
	lizard.target_reached.connect(_on_lizard_panel)
	add_child(lizard)
	_lizard_cooldown_timer = LIZARD_COOLDOWN * _cd_scale
	Audio.play("special")
	GameManager.companion_summoned.emit("lizard")

func _on_lizard_panel() -> void:
	if _panel_hacked:
		return
	_panel_hacked = true
	_panel_sprite.modulate = Color(0.4, 1.0, 0.5)
	Audio.play("special")
	GameManager.set_level_flag(LOCATION_ID, "panel_hacked", true)

func _process(delta: float) -> void:
	_lizard_cooldown_timer = maxf(_lizard_cooldown_timer - delta, 0.0)
	_release_lockout = maxf(_release_lockout - delta, 0.0)
	_miss_flash = maxf(_miss_flash - delta, 0.0)
	if not _release_timed:
		_pulse_timer = fmod(_pulse_timer + delta, PULSE_PERIOD)
	queue_redraw()
	if is_instance_valid(_lena_bubble) and not _dialog_box.is_open():
		_lena_bubble_timer -= delta
		if _lena_bubble_timer <= 0.0:
			_lena_bubble_timer = randf_range(LENA_BUBBLE_MIN, LENA_BUBBLE_MAX)
			_lena_bubble.show_text(
				LENA_BUBBLE_LINES[randi() % LENA_BUBBLE_LINES.size()],
				LENA_BUBBLE_DUR)
	GameManager.set_dialog_active(_dialog_box.is_open())
	if _dialog_box.is_open():
		if _dialog_box.is_choice_mode():
			if Input.is_action_just_pressed("move_up"):
				_dialog_box.move_choice_cursor(-1)
			elif Input.is_action_just_pressed("move_down"):
				_dialog_box.move_choice_cursor(1)
			elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
				_dialog_box.select_choice()
		elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
			_dialog_box.advance()
		return
	_update_hint()
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
		Audio.play("puzzle_complete")
		Audio.play_music("victory")
		hint_label.text = ""
		clear_label.text = "LINES RECONNECTED!\n\nFrom the high platform, a familiar silhouette.\n\nPress ENTER for the Map"
		clear_label.visible = true
	if _cleared and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location(LOCATION_ID)
		GameManager.last_location_id = LOCATION_ID
		TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")

# Doorway-triggered exit  --  distinct from the clear-overlay's "press ENTER"
# exit above. Per the established pattern, the duo can walk out at any time,
# cleared or not; complete_location is idempotent, so calling it here when
# already cleared never double-grants.
func _exit_to_overworld() -> void:
	if _cleared:
		GameManager.complete_location(LOCATION_ID)
	GameManager.last_location_id = LOCATION_ID
	TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")

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
		hint_label.text = "Patrol on site — talk to Lena, then clear them  [ press G to fight ]"
	elif not _panel_hacked:
		hint_label.text = "Ethan: hack the control panel on the Mid Platform  [ approach it, press G ]"
	elif not _release_timed:
		hint_label.text = "Ben: High Platform — press G when the pulsing ring glows green"
	else:
		hint_label.text = ""
