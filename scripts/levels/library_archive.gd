extends Node2D

const LOCATION_ID: String = "library"

# Tile-mapped floor palette  --  parchment and old-wood tones (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.34, 0.30, 0.25)
const FLOOR_ACCENT_COLOR: Color = Color(0.58, 0.48, 0.32)
const FLOOR_COLS: int = 30
const FLOOR_ROWS: int = 17
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
# Synty 2.5D library (see docs/synty_2_5d_art_plan.md): marble floor + brick
# walls; Town bookshelves + Office book stacks. Terminal = Synty monitor.
const SYNTY_FLOOR: String = "res://assets/art/tiles/synty_floor_marble.png"
const SYNTY_WALL: String = "res://assets/art/tiles/synty_wall_brick.png"
const TERMINAL_BILLBOARD: String = "res://assets/art/synty/props/monitor.png"
# [name, x, y, on-screen height px] archive dressing (stacks against the walls).
const LIBRARY_PROPS: Array = [
	["bookshelf", 110, 210, 66],
	["bookshelf", 198, 210, 66],
	["bookshelf", 762, 210, 66],
	["bookshelf", 850, 210, 66],
	["book_group", 430, 470, 20],
	["chair", 300, 430, 38],
	["plant", 150, 480, 40],
]
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const SENTRY_SCENE: PackedScene = preload("res://scenes/enemies/Sentry.tscn")
const HidingSpotScript: Script = preload("res://scripts/systems/hiding_spot.gd")
const HIDING_SPOT_POS := Vector2(120.0, 470.0)

# Guinea pigs  --  Erin's crowd-cover companion (see CLAUDE.md "Evan's Animals"):
# a skittish herd that scatters from her position and floods the reading room,
# drawing every guard's gaze toward the chaos. Cooldown-gated summon.
const GuineaPigSwarmScript: Script = preload("res://scripts/systems/guinea_pig_swarm.gd")
const GUINEA_PIG_COOLDOWN: float = 5.0

# The librarian's desk: graduated from a purely cosmetic sprite-recolor to a
# literal StaticBody2D collider sealing the narrow checkpoint into the
# Restricted Stacks  --  the FOURTH cosmetic-to-collider upgrade of the rollout
# (Iron & Strings' barbell, Recording Studio's booth door, Harbor & Docks'
# container), making "Erin...talks her way past a strict librarian to access
# restricted stacks" (this location's own spec line) mechanically true: the
# stacks are physically inaccessible until Erin handles the desk. Its
# clear-animation is a fourth distinct flavor  --  a parallel scale-down + fade
# (`create_tween()`), reading as "she packs up her desk and steps aside",
# distinct from the gym's horizontal slide, the studio's vertical slide, and
# the docks' hoist-and-swing.
const LIBRARIAN_POS := Vector2(280.0, 340.0)
const LIBRARIAN_RADIUS: float = 64.0
const LIBRARIAN_DESK_SCALE_TARGET := Vector2(0.25, 0.25)

const TERMINAL_POS := Vector2(700.0, 340.0)
const TERMINAL_RADIUS: float = 64.0

# Collectibles: library card (lets Ethan bypass the librarian desk that normally
# only Erin can handle) and a skeleton key (junk  --  "doesn't fit anything I've
# tried")  --  see CLAUDE.md "Collectibles & Inventory".
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const LibraryCardItem: ItemData = preload("res://data/items/library_card.tres")
const SkeletonKeyItem: ItemData = preload("res://data/items/skeleton_key.tres")
const CARD_LOOT_POS   := Vector2(240.0, 250.0)
const KEY_LOOT_POS    := Vector2(780.0, 250.0)
const LOOT_FLAG_KEYS  := ["card_loot_open", "key_loot_open"]

# Doorway: the level's entrance/exit  --  see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo spawns beside it in the reading room; walking
# away and back exits to the overworld at any time, cleared or not.
const DialogBoxScript: Script = preload("res://scripts/ui/dialog_box.gd")
const DialogTreeScript: Script = preload("res://scripts/systems/dialog_tree.gd")

const PRISWICK_COLOR := Color(0.42, 0.50, 0.62)

const PRISWICK_INTRO_TREE: Dictionary = {
	"start": {
		"lines": ["\"The Restricted Stacks are closed. Valid library card required.\""],
		"choices": [
			{"text": "\"Academic research on local history.\" (Erin fast-talks)", "best_with": "Erin",
				"next": "erin_wins", "next_alt": "need_card"},
			{"text": "\"We need access to the sealed records.\"", "next": "need_card"},
		]
	},
	"erin_wins": {
		"lines": [
			"Erin: \"Hi — we're doing research on local history. Completely academic.\"",
			"Ms. Priswick studies her clipboard. \"...Academic. Yes. The terminal is at the back. Be quiet.\"",
		],
		"effects": {"set_flag": "priswick_impression", "flag_value": "stepped_aside"}
	},
	"need_card": {
		"lines": [
			"\"A valid library card is required. No exceptions.\"",
			"Perhaps look around the reading room first.",
		],
		"effects": {"set_flag": "priswick_impression", "flag_value": "blocked"}
	}
}

static var PRISWICK_AFTER_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"I see you found what you needed. Please don't disturb the periodicals.\"",
])

const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(120.0, 340.0)

# Multi-room layout bounding box (reading room -> checkpoint -> Restricted
# Stacks). Feeds the camera's pan limits  --  see CLAUDE.md "Doorways,
# camera-follow & multi-room levels". Recompute if the wall layout changes.
const CAMERA_LIMIT_LEFT: int = 24
const CAMERA_LIMIT_TOP: int = 144
const CAMERA_LIMIT_RIGHT: int = 936
const CAMERA_LIMIT_BOTTOM: int = 536
const CAMERA_SMOOTHING_SPEED: float = 5.0

@onready var camera: Camera2D = $Camera2D
@onready var erin: Player = $Players/Erin
@onready var ethan: Player = $Players/Ethan
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel
@onready var _librarian_desk: StaticBody2D = $LibrarianDesk

var _spawned: bool = false
var _enemies_cleared: bool = false
var _librarian_talked: bool = false
var _archive_hacked: bool = false
var _cleared: bool = false
var _desk_shape: CollisionShape2D
var _desk_sprite: Sprite2D
var _terminal_sprite: Sprite2D
var _librarian_sprite: AnimatedSprite2D
var _loot_boxes: Array = []
var _doorway = null
var _dialog_box = null
var _guinea_pig_cooldown_timer: float = 0.0

var _cd_scale: float = 1.0
func _ready() -> void:
	_build_floor()
	_build_walls()
	PlaceholderArt.add_mood_light(self, LOCATION_ID)
	GameManager.register_players_with_preference(erin, ethan)
	hud.setup(erin, ethan)
	_cd_scale = GameManager.companion_cooldown_scale()
	erin.special_used.connect(_on_special_used)
	ethan.special_used.connect(_on_special_used)
	_create_librarian_desk()
	_create_terminal()
	_create_loot_boxes()
	_create_hiding_spot()
	_create_doorway()
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
# left off: skip respawning a cleared floor and restore the desk's
# stepped-aside state plus the terminal's hacked palette.
func _restore_progress() -> void:
	_enemies_cleared = GameManager.get_level_flag(LOCATION_ID, "enemies_cleared", false)
	_librarian_talked = GameManager.get_level_flag(LOCATION_ID, "librarian_talked", false)
	_archive_hacked = GameManager.get_level_flag(LOCATION_ID, "archive_hacked", false)
	if _librarian_talked:
		_step_aside_librarian(false)
	if _archive_hacked:
		_terminal_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _enemies_cleared:
		_spawned = true
	else:
		_spawn()
	if _enemies_cleared and _librarian_talked and _archive_hacked:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "ARCHIVE UNLOCKED!\n\nSealed records mention Uncle Doug.\n\nPress ENTER for the Map"
		clear_label.visible = true

# Tile-mapped retro floor (Zelda-style two-tone grid), generated at runtime
# via PlaceholderArt to keep the original-IP guarantee  --  no imported tile art.
func _build_floor() -> void:
	var tile_map := TileMap.new()
	tile_map.name = "Floor"
	tile_map.tile_set = PlaceholderArt.make_synty_floor_tileset(SYNTY_FLOOR)
	add_child(tile_map)
	move_child(tile_map, 0)
	tile_map.position = Vector2(CAMERA_LIMIT_LEFT, CAMERA_LIMIT_TOP)
	for x: int in range(FLOOR_COLS):
		for y: int in range(FLOOR_ROWS):
			var variant: Vector2i = FLOOR_TILE_ACCENT if (x + y) % FLOOR_ACCENT_PERIOD == 0 else FLOOR_TILE_PLAIN
			tile_map.set_cell(0, Vector2i(x, y), 0, variant)

# Wall art: a Sprite2D per StaticBody2D wall, sized to its exact
# CollisionShape2D rect and textured via PlaceholderArt.make_wall_texture.
# Iterates whatever StaticBody2D children it finds  --  the reading-room/
# checkpoint/stacks layout needed zero changes here, only more .tscn nodes
# (the LibrarianDesk is a sibling of $Walls, not a child, so it keeps its own
# bespoke maroon-leather texture instead of the generic brick pattern).
func _build_walls() -> void:
	var wall_tex: Texture2D = PlaceholderArt.make_synty_wall_tile(SYNTY_WALL)
	for wall in $Walls.get_children():
		if not wall is StaticBody2D:
			continue
		var shape: CollisionShape2D = wall.get_node("CollisionShape2D")
		var rect: RectangleShape2D = shape.shape
		PlaceholderArt.add_synty_wall_faces(wall, rect.size, wall_tex)

func _apply_synty_billboard(spr: Sprite2D, path: String, target_h: float) -> bool:
	if not ResourceLoader.exists(path):
		return false
	var tex: Texture2D = load(path)
	spr.texture = tex
	spr.offset = Vector2(0.0, -tex.get_height() / 2.0)
	spr.scale = Vector2.ONE * (target_h / float(tex.get_height()))
	return true

# Grabs the .tscn-placed LibrarianDesk body's collider and dresses it with a
# maroon-leather bordered-rectangle texture  --  visually distinct from the
# parchment-toned walls (reads as a checkpoint counter, not masonry).
func _create_librarian_desk() -> void:
	_desk_shape = _librarian_desk.get_node("CollisionShape2D")
	_desk_sprite = Sprite2D.new()
	_desk_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.42, 0.18, 0.2), 48, 40)
	_librarian_desk.add_child(_desk_sprite)
	# Librarian character sprite — stands at the desk in idle until talked down
	_librarian_sprite = AnimatedSprite2D.new()
	var loaded: SpriteFrames = SpriteLoader.try_load_npc("librarian")
	_librarian_sprite.sprite_frames = loaded if loaded != null else PlaceholderArt.make_player_frames(Color(0.48, 0.55, 0.60), "")
	_librarian_sprite.scale = Vector2(SpriteLoader.NPC_SPRITE_SCALE, SpriteLoader.NPC_SPRITE_SCALE) if loaded != null else Vector2.ONE
	_librarian_sprite.play("idle")
	_librarian_sprite.position = LIBRARIAN_POS + Vector2(0.0, -16.0)  # just above desk
	add_child(_librarian_sprite)
	var dialog_layer := CanvasLayer.new()
	dialog_layer.layer = 19
	add_child(dialog_layer)
	_dialog_box = DialogBoxScript.new()
	dialog_layer.add_child(_dialog_box)
	_dialog_box.closed.connect(_on_priswick_dialog_closed)

func _step_aside_librarian(animate: bool) -> void:
	_desk_shape.disabled = true
	if animate:
		if is_instance_valid(_librarian_sprite) and _librarian_sprite.sprite_frames.has_animation("step_aside"):
			_librarian_sprite.play("step_aside")
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_desk_sprite, "scale", LIBRARIAN_DESK_SCALE_TARGET, 0.6)
		tween.tween_property(_desk_sprite, "modulate:a", 0.0, 0.6)
		tween.tween_property(_librarian_sprite, "position:x", LIBRARIAN_POS.x + 80.0, 0.7)
	else:
		_desk_sprite.scale = LIBRARIAN_DESK_SCALE_TARGET
		_desk_sprite.modulate.a = 0.0
		if is_instance_valid(_librarian_sprite):
			_librarian_sprite.position.x = LIBRARIAN_POS.x + 80.0

func _create_terminal() -> void:
	_terminal_sprite = Sprite2D.new()
	if not _apply_synty_billboard(_terminal_sprite, TERMINAL_BILLBOARD, 30.0):
		_terminal_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.24, 0.34, 0.4), 48, 40)
	_terminal_sprite.position = TERMINAL_POS
	add_child(_terminal_sprite)
	# Archive dressing: bookshelves, book stacks, chair, plant (Synty billboards).
	for p: Array in LIBRARY_PROPS:
		var spr := Sprite2D.new()
		if _apply_synty_billboard(spr, "res://assets/art/synty/props/%s.png" % p[0], float(p[3])):
			spr.position = Vector2(float(p[1]), float(p[2]))
			add_child(spr)

# Stealth: a shadowed alcove the duo can duck into to let a patrol pass
# rather than fight through it  --  see CLAUDE.md "Stealth & awareness".
func _create_hiding_spot() -> void:
	var spot = HidingSpotScript.new()
	spot.position = HIDING_SPOT_POS
	add_child(spot)

func _create_loot_boxes() -> void:
	var card_box = LootBoxScript.new()
	card_box.setup(LibraryCardItem, CARD_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[0], false))
	add_child(card_box)
	_loot_boxes.append(card_box)

	var key_box = LootBoxScript.new()
	key_box.setup(SkeletonKeyItem, KEY_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[1], false))
	add_child(key_box)
	_loot_boxes.append(key_box)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

func _spawn() -> void:
	_add(GRUNT_SCENE,  Vector2(220.0, 280.0))
	_add(SENTRY_SCENE, Vector2(560.0, 360.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _talk_to_priswick(char_name: String) -> void:
	var p: Player = erin if char_name == "Erin" else ethan
	var tree: Dictionary = PRISWICK_AFTER_TREE if _librarian_talked else PRISWICK_INTRO_TREE
	Audio.play("ui_select")
	_dialog_box.open("Ms. Priswick", PRISWICK_COLOR, tree, "start", p.data.character_name)

func _on_priswick_dialog_closed(effects: Array) -> void:
	for fx: Dictionary in effects:
		if fx.has("set_flag"):
			GameManager.set_level_flag(LOCATION_ID, fx["set_flag"], fx.get("flag_value", true))
	if GameManager.get_level_flag(LOCATION_ID, "priswick_impression", "") == "stepped_aside" and not _librarian_talked:
		_librarian_talked = true
		_step_aside_librarian(true)
		Audio.play("special")
		GameManager.set_level_flag(LOCATION_ID, "librarian_talked", true)

func _on_special_used(char_name: String) -> void:
	if _dialog_box.is_open():
		return
	var p: Player = erin if char_name == "Erin" else ethan
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if char_name == "Ethan" and not _archive_hacked and ethan.global_position.distance_to(TERMINAL_POS) < TERMINAL_RADIUS:
		_archive_hacked = true
		_terminal_sprite.modulate = Color(0.4, 1.0, 0.5)
		Audio.play("special")
		GameManager.set_level_flag(LOCATION_ID, "archive_hacked", true)
		return
	if p.global_position.distance_to(LIBRARIAN_POS) < LIBRARIAN_RADIUS:
		if not _librarian_talked and (GameManager.has_item("Erin", LibraryCardItem.id) or GameManager.has_item("Ethan", LibraryCardItem.id)):
			_librarian_talked = true
			_step_aside_librarian(true)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "librarian_talked", true)
		else:
			_talk_to_priswick(char_name)
		return
	if char_name == "Erin" and _guinea_pig_cooldown_timer == 0.0:
		_summon_guinea_pigs()
	elif GameManager.try_use_whistle():
		Audio.play("special")

func _summon_guinea_pigs() -> void:
	var swarm = GuineaPigSwarmScript.new()
	swarm.setup(erin)
	add_child(swarm)
	_guinea_pig_cooldown_timer = GUINEA_PIG_COOLDOWN * _cd_scale

func _process(delta: float) -> void:
	_guinea_pig_cooldown_timer = maxf(_guinea_pig_cooldown_timer - delta, 0.0)
	GameManager.set_dialog_active(_dialog_box.is_open())
	if _dialog_box.is_open():
		if _dialog_box.is_choice_mode():
			if Input.is_action_just_pressed("move_up"):
				_dialog_box.move_choice_cursor(-1)
			elif Input.is_action_just_pressed("move_down"):
				_dialog_box.move_choice_cursor(1)
			elif Input.is_action_just_pressed("ui_accept"):
				_dialog_box.select_choice()
		elif Input.is_action_just_pressed("ui_accept"):
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
	if _enemies_cleared and _librarian_talked and _archive_hacked and not _cleared:
		_cleared = true
		Audio.play("puzzle_complete")
		Audio.play_music("victory")
		hint_label.text = ""
		clear_label.text = "ARCHIVE UNLOCKED!\n\nSealed records mention Uncle Doug.\n\nPress ENTER for the Map"
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
		hint_label.text = "Talk to Ms. Priswick at the desk for help  [ Erin: G to release guinea pigs ]"
	elif not _librarian_talked:
		hint_label.text = "Talk to Ms. Priswick at the desk  [ approach, press G ]"
	elif not _archive_hacked:
		hint_label.text = "Ethan: hack the sealed archive terminal  [ approach it, press G ]"
	else:
		hint_label.text = ""
