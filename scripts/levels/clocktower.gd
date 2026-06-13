extends Node2D

const LOCATION_ID: String = "clocktower"

# Tile-mapped floor palette  --  aged stone with brass-gear accents (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.32, 0.30, 0.27)
const FLOOR_ACCENT_COLOR: Color = Color(0.62, 0.52, 0.28)
const FLOOR_COLS: int = 11
const FLOOR_ROWS: int = 19
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/enemies/Boss.tscn")
const HidingSpotScript: Script = preload("res://scripts/systems/hiding_spot.gd")
const HIDING_SPOT_POS := Vector2(560.0, 380.0)

const GEAR_POS := Vector2(340.0, 320.0)
const GEAR_RADIUS: float = 64.0
const BELL_POS := Vector2(440.0, 120.0)
const BELL_RADIUS: float = 64.0

# Collectibles: sheet music (needed to solve the bell sequence) and a tuning
# fork  --  either one is sufficient to unlock the belfry gate; without both, Ben
# has no way to identify the correct pitch sequence  --  see CLAUDE.md
# "Collectibles & Inventory".
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const SheetMusicItem: ItemData = preload("res://data/items/sheet_music_page.tres")
const TuningForkItem: ItemData = preload("res://data/items/tuning_fork.tres")
const MUSIC_LOOT_POS := Vector2(360.0, 400.0)
const FORK_LOOT_POS  := Vector2(510.0, 160.0)
const LOOT_FLAG_KEYS := ["music_loot_open", "fork_loot_open"]

# Doorway: the level's entrance/exit  --  see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo spawns beside it on the ground-floor landing;
# walking away and back exits to the overworld at any time, cleared or not.
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(440.0, 560.0)

const DialogBoxScript: Script    = preload("res://scripts/ui/dialog_box.gd")
const DialogTreeScript: Script   = preload("res://scripts/systems/dialog_tree.gd")
const SpeechBubbleScript: Script = preload("res://scripts/systems/speech_bubble.gd")

const HIERONYMUS_BUBBLE_MIN  : float = 7.0
const HIERONYMUS_BUBBLE_MAX  : float = 14.0
const HIERONYMUS_BUBBLE_DUR  : float = 3.5
const HIERONYMUS_BUBBLE_LINES: Array[String] = [
	"The bells haven't rung in years.",
	"Time moves strangely in a stopped clock.",
	"I know that sequence... or I did, once.",
]

const HIERONYMUS_COLOR := Color(0.44, 0.39, 0.35)
const HIERONYMUS_POS := Vector2(280.0, 500.0)
const HIERONYMUS_RADIUS: float = 64.0
static var HIERONYMUS_INTRO_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"The guardian woke when I tried to fix the gear floor myself. I'm afraid I'm more theorist than fighter.\"",
	"\"Quinn — the escapement on the gear floor needs your tools. Ben, the belfry bells want a pitch sequence; check my notes or the tuning fork up there.\""
])
static var HIERONYMUS_REMINDER_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"The gear mechanism and the belfry bells both need attention before the tower unlocks.\""
])
static var HIERONYMUS_AFTER_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"Remarkable. Thirty years I couldn't silence that guardian. You've done it in one visit.\""
])

# Multi-room layout bounding box  --  a vertical shaft of three stacked floors
# (landing -> gear floor -> bell tower), connected by stairwell gaps. Feeds
# the camera's pan limits  --  see CLAUDE.md "Doorways, camera-follow & multi-
# room levels". Recompute if the wall layout changes.
const CAMERA_LIMIT_LEFT: int = 264
const CAMERA_LIMIT_TOP: int = 24
const CAMERA_LIMIT_RIGHT: int = 616
const CAMERA_LIMIT_BOTTOM: int = 616
const CAMERA_SMOOTHING_SPEED: float = 5.0

@onready var camera: Camera2D = $Camera2D
@onready var quinn: Player = $Players/Quinn
@onready var ben: Player = $Players/Ben
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel

var _spawned: bool = false
var _enemies_cleared: bool = false
var _gear_repaired: bool = false
var _bells_played: bool = false
var _cleared: bool = false
var _gear_sprite: Sprite2D
var _bell_sprite: Sprite2D
var _loot_boxes: Array = []
var _doorway = null
var _hieronymus_sprite: AnimatedSprite2D
var _hieronymus_bubble        = null
var _hieronymus_bubble_timer: float = 0.0
var _dialog_box = null
var _hieronymus_met: bool = false

func _ready() -> void:
	_build_floor()
	_build_walls()
	GameManager.register_players_with_preference(quinn, ben)
	hud.setup(quinn, ben)
	quinn.special_used.connect(_on_special_used)
	ben.special_used.connect(_on_special_used)
	_create_gear()
	_create_bells()
	_create_loot_boxes()
	_create_hiding_spot()
	_create_doorway()
	_create_hieronymus_npc()
	_setup_camera()
	_restore_progress()
	if not _cleared:
		Audio.play_music("boss")

# Camera follows the active character  --  see CLAUDE.md "Doorways,
# camera-follow & multi-room levels". Essential here: the tower's three
# stacked floors span far more vertical space than the 720px viewport shows
# at once, so the climb genuinely reveals itself floor by floor.
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
# left off: skip respawning a cleared floor and restore the gear/bell props'
# solved-state palettes.
func _restore_progress() -> void:
	_enemies_cleared = GameManager.get_level_flag(LOCATION_ID, "enemies_cleared", false)
	_gear_repaired = GameManager.get_level_flag(LOCATION_ID, "gear_repaired", false)
	_bells_played = GameManager.get_level_flag(LOCATION_ID, "bells_played", false)
	_hieronymus_met = GameManager.get_level_flag(LOCATION_ID, "hieronymus_met", false)
	if _gear_repaired:
		_gear_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _bells_played:
		_bell_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _enemies_cleared:
		_spawned = true
	else:
		_spawn()
	if _enemies_cleared and _gear_repaired and _bells_played:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "TOWER ASCENDED!\n\nThe clockwork guardian falls silent.\n\nPress ENTER for the Map"
		clear_label.visible = true

# Tile-mapped retro floor (Zelda-style two-tone grid), generated at runtime
# via PlaceholderArt to keep the original-IP guarantee  --  no imported tile art.
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

# Wall art: a Sprite2D per StaticBody2D wall, sized to its exact
# CollisionShape2D rect and textured via PlaceholderArt.make_wall_texture.
# Iterates whatever StaticBody2D children it finds  --  the stacked-floor shaft
# (landing/gear-floor/bell-tower, joined by stairwell-gap dividers) needed
# zero changes here, only more .tscn nodes.
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

func _create_gear() -> void:
	_gear_sprite = Sprite2D.new()
	_gear_sprite.texture = PlaceholderArt.make_gear_prop_texture(Color(0.4, 0.36, 0.22), 48, 48)
	_gear_sprite.position = GEAR_POS
	add_child(_gear_sprite)

func _create_bells() -> void:
	_bell_sprite = Sprite2D.new()
	_bell_sprite.texture = PlaceholderArt.make_bell_texture(Color(0.36, 0.3, 0.46), 40, 56)
	_bell_sprite.position = BELL_POS
	add_child(_bell_sprite)

# Stealth: a shadowed alcove the duo can duck into to let a patrol pass
# rather than fight through it  --  see CLAUDE.md "Stealth & awareness".
func _create_hiding_spot() -> void:
	var spot = HidingSpotScript.new()
	spot.position = HIDING_SPOT_POS
	add_child(spot)

func _create_loot_boxes() -> void:
	var music_box = LootBoxScript.new()
	music_box.setup(SheetMusicItem, MUSIC_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[0], false))
	add_child(music_box)
	_loot_boxes.append(music_box)

	var fork_box = LootBoxScript.new()
	fork_box.setup(TuningForkItem, FORK_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[1], false))
	add_child(fork_box)
	_loot_boxes.append(fork_box)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

func _create_hieronymus_npc() -> void:
	_hieronymus_sprite = AnimatedSprite2D.new()
	var loaded: SpriteFrames = SpriteLoader.try_load_npc("hieronymus")
	_hieronymus_sprite.sprite_frames = loaded if loaded != null else PlaceholderArt.make_player_frames(HIERONYMUS_COLOR, "")
	_hieronymus_sprite.scale = Vector2(SpriteLoader.NPC_SPRITE_SCALE, SpriteLoader.NPC_SPRITE_SCALE) if loaded != null else Vector2.ONE
	_hieronymus_sprite.play("idle")
	_hieronymus_sprite.position = HIERONYMUS_POS
	add_child(_hieronymus_sprite)
	_hieronymus_bubble = SpeechBubbleScript.new()
	_hieronymus_bubble.position = HIERONYMUS_POS + Vector2(0.0, -52.0)
	add_child(_hieronymus_bubble)
	_hieronymus_bubble_timer = randf_range(HIERONYMUS_BUBBLE_MIN, HIERONYMUS_BUBBLE_MAX)
	var dialog_layer := CanvasLayer.new()
	dialog_layer.layer = 19
	add_child(dialog_layer)
	_dialog_box = DialogBoxScript.new()
	dialog_layer.add_child(_dialog_box)
	_dialog_box.closed.connect(_on_hieronymus_dialog_closed)

func _talk_to_hieronymus() -> void:
	var p: Player = GameManager.active_player
	var tree: Dictionary
	if _cleared:
		tree = HIERONYMUS_AFTER_TREE
	elif not _hieronymus_met:
		tree = HIERONYMUS_INTRO_TREE
	else:
		tree = HIERONYMUS_REMINDER_TREE
	_dialog_box.open("Hieronymus", HIERONYMUS_COLOR, tree, "start", p.data.character_name)

func _on_hieronymus_dialog_closed(_effects: Array) -> void:
	if not _hieronymus_met:
		_hieronymus_met = true
		GameManager.set_level_flag(LOCATION_ID, "hieronymus_met", true)

func _spawn() -> void:
	_add(GRUNT_SCENE, Vector2(340.0, 520.0))
	_add(GRUNT_SCENE, Vector2(560.0, 260.0))
	_add(BOSS_SCENE, Vector2(440.0, 260.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	if _dialog_box.is_open():
		return
	var p: Player = quinn if char_name == "Quinn" else ben
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if p.global_position.distance_to(HIERONYMUS_POS) < HIERONYMUS_RADIUS:
		_talk_to_hieronymus()
		return
	if char_name == "Quinn" and not _gear_repaired:
		if quinn.global_position.distance_to(GEAR_POS) < GEAR_RADIUS:
			_gear_repaired = true
			_gear_sprite.modulate = Color(0.4, 1.0, 0.5)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "gear_repaired", true)
	elif char_name == "Ben" and not _bells_played:
		if ben.global_position.distance_to(BELL_POS) < BELL_RADIUS:
			var has_sequence: bool = GameManager.has_item("Ben", SheetMusicItem.id) or \
				GameManager.has_item("Quinn", SheetMusicItem.id) or \
				GameManager.has_item("Ben", TuningForkItem.id) or \
				GameManager.has_item("Quinn", TuningForkItem.id)
			if has_sequence:
				_bells_played = true
				_bell_sprite.modulate = Color(0.4, 1.0, 0.5)
				Audio.play("special")
				GameManager.set_level_flag(LOCATION_ID, "bells_played", true)
	elif GameManager.try_use_whistle():
		Audio.play("special")

func _process(delta: float) -> void:
	if is_instance_valid(_hieronymus_bubble) and not _dialog_box.is_open():
		_hieronymus_bubble_timer -= delta
		if _hieronymus_bubble_timer <= 0.0:
			_hieronymus_bubble_timer = randf_range(HIERONYMUS_BUBBLE_MIN, HIERONYMUS_BUBBLE_MAX)
			_hieronymus_bubble.show_text(
				HIERONYMUS_BUBBLE_LINES[randi() % HIERONYMUS_BUBBLE_LINES.size()],
				HIERONYMUS_BUBBLE_DUR)
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
	if is_instance_valid(GameManager.active_player):
		var active_pos: Vector2 = GameManager.active_player.global_position
		camera.global_position = active_pos
		if _doorway.check(active_pos):
			_exit_to_overworld()
			return
	_update_hint()
	if _spawned and not _enemies_cleared and enemies.get_child_count() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(LOCATION_ID, "enemies_cleared", true)
	if _enemies_cleared and _gear_repaired and _bells_played and not _cleared:
		_cleared = true
		Audio.play("puzzle_complete")
		Audio.play_music("victory")
		hint_label.text = ""
		clear_label.text = "TOWER ASCENDED!\n\nThe clockwork guardian falls silent.\n\nPress ENTER for the Map"
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

func _update_hint() -> void:
	if _cleared:
		hint_label.text = ""
	elif not _enemies_cleared:
		hint_label.text = "Patrols guard the stairs — talk to Hieronymus, then clear a path  [ press G ]"
	elif not _gear_repaired:
		hint_label.text = "Quinn: repair the gear mechanism  [ approach it, press G ]"
	elif not _bells_played:
		var has_sequence: bool = GameManager.has_item("Ben", SheetMusicItem.id) or \
			GameManager.has_item("Quinn", SheetMusicItem.id) or \
			GameManager.has_item("Ben", TuningForkItem.id) or \
			GameManager.has_item("Quinn", TuningForkItem.id)
		if has_sequence:
			hint_label.text = "Ben: play the pitch sequence at the belfry  [ approach it, press G ]"
		else:
			hint_label.text = "Ben: find the sheet music or tuning fork to identify the bell sequence"
	else:
		hint_label.text = ""
