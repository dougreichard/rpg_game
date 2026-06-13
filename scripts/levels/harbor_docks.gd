extends Node2D

const LOCATION_ID: String = "harbor_docks"

# Tile-mapped floor palette  --  weathered dock planking with sea-blue accents (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.28, 0.31, 0.33)
const FLOOR_ACCENT_COLOR: Color = Color(0.45, 0.55, 0.50)
const FLOOR_COLS: int = 30
const FLOOR_ROWS: int = 17
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4
# Synty 2.5D docks (see docs/synty_2_5d_art_plan.md): concrete floor + walls;
# Construction cargo billboards. The shipping container is the puzzle Evan hoists.
const SYNTY_FLOOR: String = "res://assets/art/tiles/synty_floor_concrete.png"
const SYNTY_WALL: String = "res://assets/art/tiles/synty_wall_concrete.png"
const CONTAINER_BILLBOARD: String = "res://assets/art/synty/props/container.png"
# [name, x, y, on-screen height px] dock dressing.
const HARBOR_PROPS: Array = [
	["crate_stack", 200, 470, 50],
	["pallet_stack", 830, 480, 42],
	["crate_large", 160, 210, 44],
	["barrel", 480, 480, 48],
]

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/Runner.tscn")
const HidingSpotScript: Script = preload("res://scripts/systems/hiding_spot.gd")
const HIDING_SPOT_POS := Vector2(350.0, 460.0)
const AnimalCompanionScript: Script = preload("res://scripts/systems/animal_companion.gd")

# The cargo container: graduated from a purely cosmetic sprite-shift to a
# literal StaticBody2D collider sealing the gap into the crane platform  -- 
# same cosmetic-to-literal upgrade as Iron & Strings' barbell and Recording
# Studio's booth door, making "Evan moves heavy freight to clear paths or
# trigger crane mechanisms" (this location's spec line) mechanically true.
# Its clear-animation is a hoist-and-swing  --  position arcs up and sideways
# while it rotates, reading as the crane winching it off and out of the way  -- 
# a third distinct flavor alongside Iron & Strings' horizontal slide and
# Recording Studio's vertical slide (same disable-collider-then-animate shape).
const CONTAINER_POS := Vector2(670.0, 152.0)
const CONTAINER_RADIUS: float = 64.0
const CONTAINER_HOIST_OFFSET := Vector2(50.0, -170.0)
const CONTAINER_HOIST_ROTATION: float = 0.5

const CALVIN_COLOR := Color(0.96, 0.96, 0.92)
const COOLIDGE_COLOR := Color(0.90, 0.88, 0.80)
const CALVIN_COOLDOWN: float = 2.5

# Maze crates: purely cosmetic-but-collidable cargo crates scattered through
# the yard  --  literalizes "cargo container maze is good brawler terrain" from
# this location's spec as actual obstacles to route combat and movement
# around, distinct from the wood-tone brick walls (their own bespoke crate
# texture, siblings of $Walls so _build_walls()'s generic brick pass skips them).
const MAZE_CRATE_COLOR := Color(0.5, 0.36, 0.16)

# Collectibles: crowbar (Quinn's alternate route to shift the container  --  with
# it she doesn't need Evan), crane crank handle (functional, future hookup),
# and a faded treasure map (junk)  --  see CLAUDE.md "Collectibles & Inventory".
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const CrowbarItem: ItemData       = preload("res://data/items/crowbar.tres")
const CrankHandleItem: ItemData   = preload("res://data/items/crane_crank_handle.tres")
const TreasureMapItem: ItemData   = preload("res://data/items/faded_treasure_map.tres")
# Otis (see npc_dialog/otis.md) sends the duo here looking for his brass
# compass -- a quest fetch-item, tucked in alongside the location's other
# yard loot boxes.
const BrassCompassItem: ItemData  = preload("res://data/items/brass_compass.tres")
const CROWBAR_LOOT_POS  := Vector2(840.0, 200.0)
const CRANK_LOOT_POS    := Vector2(230.0, 200.0)
const TREEMAP_LOOT_POS  := Vector2(450.0, 460.0)
const COMPASS_LOOT_POS  := Vector2(600.0, 350.0)
const LOOT_FLAG_KEYS    := ["crowbar_loot_open", "crank_loot_open", "treemap_loot_open", "compass_loot_open"]

# Doorway: the level's entrance/exit  --  see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo spawns beside it on the pier; walking away and
# back exits to the overworld at any time, cleared or not.
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(140.0, 340.0)

const DialogBoxScript: Script    = preload("res://scripts/ui/dialog_box.gd")
const DialogTreeScript: Script   = preload("res://scripts/systems/dialog_tree.gd")
const SpeechBubbleScript: Script = preload("res://scripts/systems/speech_bubble.gd")

const VIKTOR_BUBBLE_MIN  : float = 7.0
const VIKTOR_BUBBLE_MAX  : float = 14.0
const VIKTOR_BUBBLE_DUR  : float = 3.5
const VIKTOR_BUBBLE_LINES: Array[String] = [
	"Every crate gets checked. No exceptions.",
	"Something came through here that wasn't on the manifest.",
	"I run a tight dock.",
]

const VIKTOR_COLOR := Color(0.96, 0.51, 0.14)
const VIKTOR_POS := Vector2(220.0, 460.0)
const VIKTOR_RADIUS: float = 64.0
static var VIKTOR_INTRO_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"Harbourmaster Viktor. Pier's been overrun — smugglers moved in with a suspicious manifest.\"",
	"\"That cargo container is blocking crane access. Evan can shift it bare-handed. If you're short-handed, there's a crowbar somewhere in the yard.\""
])
static var VIKTOR_REMINDER_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"That container's still blocking the crane platform — Evan or a crowbar will shift it.\""
])
static var VIKTOR_AFTER_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"Manifest confirms it — Doug's name is on that shipment. You'll want to follow that lead.\""
])

# Multi-room layout bounding box (pier -> container-maze yard -> crane
# platform, sealed by the cargo container). Feeds the camera's pan limits  -- 
# see CLAUDE.md "Doorways, camera-follow & multi-room levels". Recompute if
# the wall layout changes.
const CAMERA_LIMIT_LEFT: int = 24
const CAMERA_LIMIT_TOP: int = 24
const CAMERA_LIMIT_RIGHT: int = 936
const CAMERA_LIMIT_BOTTOM: int = 536
const CAMERA_SMOOTHING_SPEED: float = 5.0

@onready var camera: Camera2D = $Camera2D
@onready var quinn: Player = $Players/Quinn
@onready var evan: Player = $Players/Evan
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel
@onready var _container: StaticBody2D = $Container

var _calvin_cooldown_timer: float = 0.0

var _spawned: bool = false
var _enemies_cleared: bool = false
var _container_moved: bool = false
var _cleared: bool = false
var _container_shape: CollisionShape2D
var _container_sprite: Sprite2D
var _loot_boxes: Array = []
var _doorway = null
var _viktor_sprite: AnimatedSprite2D
var _viktor_bubble        = null
var _viktor_bubble_timer: float = 0.0
var _dialog_box = null
var _viktor_met: bool = false

var _cd_scale: float = 1.0
func _ready() -> void:
	_build_floor()
	_build_walls()
	PlaceholderArt.add_mood_light(self, LOCATION_ID)
	GameManager.register_players_with_preference(quinn, evan)
	hud.setup(quinn, evan)
	_cd_scale = GameManager.companion_cooldown_scale()
	quinn.special_used.connect(_on_special_used)
	evan.special_used.connect(_on_special_used)
	_create_container()
	_create_maze_crates()
	_create_loot_boxes()
	_create_hiding_spot()
	_create_doorway()
	_create_viktor_npc()
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
# left off: skip respawning a cleared floor and restore the container's
# hoisted-away state (collider disabled, sprite already off to the side).
func _restore_progress() -> void:
	_enemies_cleared = GameManager.get_level_flag(LOCATION_ID, "enemies_cleared", false)
	_container_moved = GameManager.get_level_flag(LOCATION_ID, "container_moved", false)
	_viktor_met = GameManager.get_level_flag(LOCATION_ID, "viktor_met", false)
	if _container_moved:
		_move_container(false)
	if _enemies_cleared:
		_spawned = true
	else:
		_spawn()
	if _enemies_cleared and _container_moved:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "DOCKS SECURED!\n\nA shipment manifest names Uncle Doug.\n\nPress ENTER for the Map"
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
# Iterates whatever StaticBody2D children it finds  --  the pier/yard/platform
# layout needed zero changes here, only more .tscn nodes (the Container and
# maze crates are siblings of $Walls, not children, so they keep their own
# bespoke cargo-brown textures instead of the generic brick pattern).
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

# Grabs the .tscn-placed Container body's collider and dresses it with a
# cargo-brown bordered-rectangle texture  --  visually distinct from the
# sea-stone walls (reads as freight blocking a doorway, not masonry).
func _create_container() -> void:
	_container_shape = _container.get_node("CollisionShape2D")
	_container_sprite = Sprite2D.new()
	if not _apply_synty_billboard(_container_sprite, CONTAINER_BILLBOARD, 52.0):
		_container_sprite.texture = PlaceholderArt.make_gate_texture(MAZE_CRATE_COLOR, 300, 16)
	_container.add_child(_container_sprite)
	# Dock dressing (Construction cargo billboards).
	for p: Array in HARBOR_PROPS:
		var spr := Sprite2D.new()
		if _apply_synty_billboard(spr, "res://assets/art/synty/props/%s.png" % p[0], float(p[3])):
			spr.position = Vector2(float(p[1]), float(p[2]))
			add_child(spr)

func _move_container(animate: bool) -> void:
	_container_shape.disabled = true
	if animate:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_container_sprite, "position", CONTAINER_HOIST_OFFSET, 0.7)
		tween.tween_property(_container_sprite, "rotation", CONTAINER_HOIST_ROTATION, 0.7)
	else:
		_container_sprite.position = CONTAINER_HOIST_OFFSET
		_container_sprite.rotation = CONTAINER_HOIST_ROTATION

# Grabs the .tscn-placed maze-crate bodies and dresses them with the same
# cargo-brown texture as the container  --  they read as part of the same
# shipment, scattered obstacles that turn the yard into the "container maze"
# this location's spec calls for, distinct from the bordering brick walls.
func _create_maze_crates() -> void:
	for crate_name in ["MazeCrateA", "MazeCrateB"]:
		var crate: StaticBody2D = get_node(crate_name)
		var shape: CollisionShape2D = crate.get_node("CollisionShape2D")
		var rect: RectangleShape2D = shape.shape
		var sprite := Sprite2D.new()
		sprite.texture = PlaceholderArt.make_gate_texture(MAZE_CRATE_COLOR, int(rect.size.x), int(rect.size.y))
		crate.add_child(sprite)

# Stealth: a shadowed alcove the duo can duck into to let a patrol pass
# rather than fight through it  --  see CLAUDE.md "Stealth & awareness".
func _create_hiding_spot() -> void:
	var spot = HidingSpotScript.new()
	spot.position = HIDING_SPOT_POS
	add_child(spot)

func _create_loot_boxes() -> void:
	var crowbar_box = LootBoxScript.new()
	crowbar_box.setup(CrowbarItem, CROWBAR_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[0], false))
	add_child(crowbar_box)
	_loot_boxes.append(crowbar_box)

	var crank_box = LootBoxScript.new()
	crank_box.setup(CrankHandleItem, CRANK_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[1], false))
	add_child(crank_box)
	_loot_boxes.append(crank_box)

	var treemap_box = LootBoxScript.new()
	treemap_box.setup(TreasureMapItem, TREEMAP_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[2], false))
	add_child(treemap_box)
	_loot_boxes.append(treemap_box)

	var compass_box = LootBoxScript.new()
	compass_box.setup(BrassCompassItem, COMPASS_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[3], false))
	add_child(compass_box)
	_loot_boxes.append(compass_box)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

func _create_viktor_npc() -> void:
	_viktor_sprite = AnimatedSprite2D.new()
	if not PlaceholderArt.apply_npc_billboard(_viktor_sprite, "viktor"):
		var loaded: SpriteFrames = SpriteLoader.try_load_npc("viktor")
		_viktor_sprite.sprite_frames = loaded if loaded != null else PlaceholderArt.make_player_frames(VIKTOR_COLOR, "")
		_viktor_sprite.scale = Vector2(SpriteLoader.NPC_SPRITE_SCALE, SpriteLoader.NPC_SPRITE_SCALE) if loaded != null else Vector2.ONE
	_viktor_sprite.play("idle")
	_viktor_sprite.position = VIKTOR_POS
	add_child(_viktor_sprite)
	_viktor_bubble = SpeechBubbleScript.new()
	_viktor_bubble.position = VIKTOR_POS + Vector2(0.0, -52.0)
	add_child(_viktor_bubble)
	_viktor_bubble_timer = randf_range(VIKTOR_BUBBLE_MIN, VIKTOR_BUBBLE_MAX)
	var dialog_layer := CanvasLayer.new()
	dialog_layer.layer = 19
	add_child(dialog_layer)
	_dialog_box = DialogBoxScript.new()
	dialog_layer.add_child(_dialog_box)
	_dialog_box.closed.connect(_on_viktor_dialog_closed)

func _talk_to_viktor() -> void:
	var p: Player = GameManager.active_player
	var tree: Dictionary
	if _cleared:
		tree = VIKTOR_AFTER_TREE
	elif not _viktor_met:
		tree = VIKTOR_INTRO_TREE
	else:
		tree = VIKTOR_REMINDER_TREE
	_dialog_box.open("Viktor", VIKTOR_COLOR, tree, "start", p.data.character_name)

func _on_viktor_dialog_closed(_effects: Array) -> void:
	if not _viktor_met:
		_viktor_met = true
		GameManager.set_level_flag(LOCATION_ID, "viktor_met", true)

func _spawn() -> void:
	_add(GRUNT_SCENE,  Vector2(380.0, 250.0))
	_add(GRUNT_SCENE,  Vector2(820.0, 300.0))
	_add(RUNNER_SCENE, Vector2(650.0, 460.0))
	_add(RUNNER_SCENE, Vector2(550.0, 220.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	if _dialog_box.is_open():
		return
	var p: Player = quinn if char_name == "Quinn" else evan
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if p.global_position.distance_to(VIKTOR_POS) < VIKTOR_RADIUS:
		_talk_to_viktor()
		return
	if char_name == "Evan":
		if not _container_moved and evan.global_position.distance_to(CONTAINER_POS) < CONTAINER_RADIUS:
			_container_moved = true
			_move_container(true)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "container_moved", true)
		elif _calvin_cooldown_timer == 0.0:
			_summon_calvin_and_coolidge()
	elif char_name == "Quinn" and not _container_moved:
		if quinn.global_position.distance_to(CONTAINER_POS) < CONTAINER_RADIUS:
			if GameManager.has_item("Quinn", CrowbarItem.id) or GameManager.has_item("Evan", CrowbarItem.id):
				_container_moved = true
				_move_container(true)
				Audio.play("special")
				GameManager.set_level_flag(LOCATION_ID, "container_moved", true)

# Calvin and Coolidge are brothers who are always summoned and fight as a pair
# (see CLAUDE.md's animal companion roster)  --  Calvin (combat charger) takes the
# nearest foe, Coolidge (puzzle mover, but happy to back his brother in a brawl)
# takes the next-nearest, or doubles up on Calvin's target if there's only one.
	elif GameManager.try_use_whistle():
		Audio.play("special")
func _summon_calvin_and_coolidge() -> void:
	var targets: Array = _nearest_enemies(evan.global_position, 2)
	if targets.is_empty():
		return
	var calvin = AnimalCompanionScript.new()
	calvin.setup(evan, targets[0], CALVIN_COLOR, "calvin_and_coolidge")
	add_child(calvin)
	var coolidge = AnimalCompanionScript.new()
	coolidge.setup(evan, targets[1] if targets.size() > 1 else targets[0], COOLIDGE_COLOR, "calvin_and_coolidge")
	add_child(coolidge)
	_calvin_cooldown_timer = CALVIN_COOLDOWN * _cd_scale
	GameManager.companion_summoned.emit("calvin_coolidge")

func _nearest_enemies(from_pos: Vector2, count: int) -> Array:
	var living: Array = []
	for child in enemies.get_children():
		if child is Enemy and is_instance_valid(child):
			living.append(child)
	living.sort_custom(func(a, b): return from_pos.distance_to(a.global_position) < from_pos.distance_to(b.global_position))
	return living.slice(0, count)

func _process(delta: float) -> void:
	_calvin_cooldown_timer = maxf(_calvin_cooldown_timer - delta, 0.0)
	if is_instance_valid(_viktor_bubble) and not _dialog_box.is_open():
		_viktor_bubble_timer -= delta
		if _viktor_bubble_timer <= 0.0:
			_viktor_bubble_timer = randf_range(VIKTOR_BUBBLE_MIN, VIKTOR_BUBBLE_MAX)
			_viktor_bubble.show_text(
				VIKTOR_BUBBLE_LINES[randi() % VIKTOR_BUBBLE_LINES.size()],
				VIKTOR_BUBBLE_DUR)
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
	if _enemies_cleared and _container_moved and not _cleared:
		_cleared = true
		Audio.play("puzzle_complete")
		Audio.play_music("victory")
		hint_label.text = ""
		clear_label.text = "DOCKS SECURED!\n\nA shipment manifest names Uncle Doug.\n\nPress ENTER for the Map"
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
		hint_label.text = "Dock workers patrol the yard — talk to Viktor, then clear them out  [ Evan: press G to call Calvin & Coolidge ]"
	elif not _container_moved:
		hint_label.text = "Evan: shove the cargo container off the crane controls  [ approach it, press G ]"
	else:
		hint_label.text = ""
