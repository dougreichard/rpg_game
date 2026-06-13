extends Node2D

const LOCATION_ID: String = "underground"

# Tile-mapped floor palette  --  dark, earthy maintenance-tunnel tones (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.20, 0.20, 0.19)
const FLOOR_ACCENT_COLOR: Color = Color(0.38, 0.35, 0.28)
const FLOOR_COLS: int = 30
const FLOOR_ROWS: int = 17
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
# Synty 2.5D tunnels (see docs/synty_2_5d_art_plan.md): concrete floor +
# stone-block walls; Construction rubble + Office ducting/cable billboards.
const SYNTY_FLOOR: String = "res://assets/art/tiles/synty_floor_concrete.png"
const SYNTY_WALL: String = "res://assets/art/tiles/synty_wall_stone.png"
const RUBBLE_BILLBOARD: String = "res://assets/art/synty/props/rubble.png"
# [name, x, y, on-screen height px] maintenance-tunnel dressing.
const TUNNEL_PROPS: Array = [
	["dirt_pile", 250, 470, 30],
	["cable_tray", 480, 230, 30],
	["ducting", 650, 240, 40],
	["barrel", 200, 490, 50],
	["brick_stack", 770, 480, 44],
	["server", 560, 480, 52],
]
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/Runner.tscn")
const HidingSpotScript: Script = preload("res://scripts/systems/hiding_spot.gd")
const TwinkleScript: Script = preload("res://scripts/systems/twinkle_companion.gd")
const GuineaPigScript: Script = preload("res://scripts/systems/guinea_pig_companion.gd")
const GUINEA_PIG_COOLDOWN: float = 8.0
# Frosty  --  Evan's general-purpose combat distractor (see CLAUDE.md "Evan's Animals").
# Priority over Twinkle: when enemies are still alive, Evan's away-from-rubble
# Special sends Frosty to stagger; once the floor is clear, Twinkle's noise
# burst is the useful tool for drawing any lingering investigators.
const AnimalCompanionScript: Script = preload("res://scripts/systems/animal_companion.gd")
const FROSTY_COLOR := Color(0.95, 0.95, 0.95)
const FROSTY_COOLDOWN: float = 3.0

const HIDING_SPOT_POS := Vector2(480.0, 280.0)
const TWINKLE_COOLDOWN: float = 3.0

const RUBBLE_POS := Vector2(80.0, 288.0)
const RUBBLE_RADIUS: float = 64.0
const HATCH_POS := Vector2(880.0, 288.0)
const HATCH_RADIUS: float = 64.0
const HATCH_PRESSES_REQUIRED: int = 3

# Collectibles:
# - pocket_lantern: ALWAYS VISIBLE loot box in the junction chamber. Picking it
#   up reveals the two dark loot boxes hidden in the tunnels  --  the
#   "reveals hidden loot boxes in the dark Underground Tunnels" mechanic from
#   CLAUDE.md "Collectibles & Inventory".
# - rusty_key / security_badge: DARK loot boxes, hidden (visible=false) until
#   the lantern is held. The duo must find the lantern first to light the way.
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const DarknessOverlayScript: Script = preload("res://scripts/systems/dark_overlay.gd")
const RustyKeyItem: ItemData      = preload("res://data/items/rusty_key.tres")
const SecurityBadgeItem: ItemData = preload("res://data/items/security_badge.tres")
const PocketLanternItem: ItemData = preload("res://data/items/pocket_lantern.tres")
const FannysBottleItem: ItemData  = preload("res://data/items/fannys_bottle.tres")
const KEY_LOOT_POS    := Vector2(560.0, 330.0)
const BADGE_LOOT_POS  := Vector2(820.0, 350.0)
const LANTERN_LOOT_POS := Vector2(300.0, 240.0)
# Fanny's bottle: hidden at the very tip of the west-tunnel dead end, behind
# Evan's rubble. Dark AND gated by rubble being cleared -- no hint is ever
# shown for it. Both conditions must be met before it becomes visible.
const FANNY_LOOT_POS  := Vector2(52.0, 288.0)
# Persistence flags  --  kept separate so the restore logic stays readable.
const LANTERN_LOOT_FLAG: String  = "lantern_loot_open"
const DARK_LOOT_FLAG_KEYS := ["key_loot_open", "badge_loot_open"]
const FANNY_LOOT_FLAG: String    = "fanny_loot_open"
const PIP_RADIUS: float = 5.0
const PIP_SPACING: float = 16.0
const PIP_OFFSET_Y: float = -38.0
const PIP_FLASH_DURATION: float = 0.3

# Doorway: the level's entrance/exit  --  see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo spawns beside it in the south entry corridor;
# walking away and back exits to the overworld at any time, cleared or not.
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DialogBoxScript: Script    = preload("res://scripts/ui/dialog_box.gd")
const DialogTreeScript: Script   = preload("res://scripts/systems/dialog_tree.gd")
const SpeechBubbleScript: Script = preload("res://scripts/systems/speech_bubble.gd")

const CYRUS_BUBBLE_MIN  : float = 7.0
const CYRUS_BUBBLE_MAX  : float = 14.0
const CYRUS_BUBBLE_DUR  : float = 3.5
const CYRUS_BUBBLE_LINES: Array[String] = [
	"These tunnels haven't been mapped properly in years.",
	"That hatch has been jammed since Tuesday.",
	"Water's running somewhere it shouldn't be.",
]

const CYRUS_COLOR := Color(0.31, 0.39, 0.55)
const CYRUS_POS := Vector2(350.0, 430.0)
const CYRUS_RADIUS: float = 64.0
static var CYRUS_INTRO_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"Cyrus — I maintain these tunnels. Or I did before the patrol showed up.\"",
	"\"West passage has rubble Evan can force open. East side there's a locked hatch — Ethan will need a few passes at it. And grab the lantern from the junction first — it's dark in there.\""
])
static var CYRUS_REMINDER_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"West rubble needs Evan, east hatch needs Ethan's hacking passes — and keep that lantern close.\""
])
static var CYRUS_AFTER_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"Both passages clear. I'll get maintenance back in here properly now. Good work.\""
])

# Shortcut door  --  in the junction chamber, on the north wall. Opened once with
# the rusty_key (consumed on use); exits to the overworld immediately without
# needing to clear enemies or hack the hatch  --  the "hidden route" payoff the
# CLAUDE.md spec describes for this location.
const SHORTCUT_DOOR_POS := Vector2(480.0, 238.0)
const SHORTCUT_DOOR_RADIUS: float = 52.0

const DOORWAY_POS := Vector2(480.0, 500.0)

# Multi-room layout bounding box  --  a literal BRANCHING MAZE matching "dark
# maze of maintenance tunnels": a south entry corridor opens onto a central
# junction chamber, which forks into a west tunnel (dead-ending at Evan's
# rubble) and an east tunnel (dead-ending at Ethan's hatch). Feeds the
# camera's pan limits and the darkness overlay's world_rect  --  see CLAUDE.md
# "Doorways, camera-follow & multi-room levels". Recompute if the wall layout
# changes. Note the unusually high CAMERA_LIMIT_TOP (184, not the standard
# locations' 24): the maze's northernmost wall (the junction chamber's north
# face) sits well below the room's nominal top  --  there's no content above it,
# so the camera shouldn't pan there.
const CAMERA_LIMIT_LEFT: int = 24
const CAMERA_LIMIT_TOP: int = 184
const CAMERA_LIMIT_RIGHT: int = 936
const CAMERA_LIMIT_BOTTOM: int = 536
const CAMERA_SMOOTHING_SPEED: float = 5.0

@onready var camera: Camera2D = $Camera2D
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
var _shortcut_door_sprite: Sprite2D
# Always-visible loot box (the lantern itself).
var _loot_boxes: Array = []
# Dark loot boxes: hidden until the pocket lantern is held.
var _dark_loot_boxes: Array = []
var _dark_revealed: bool = false
# Fanny's bottle: dark AND gated by rubble_cleared -- its own reveal flag.
var _fanny_loot_box = null
var _fanny_revealed: bool = false
var _darkness: Node2D = null
var _doorway = null
var _cyrus_sprite: AnimatedSprite2D
var _cyrus_bubble        = null
var _cyrus_bubble_timer: float = 0.0
var _dialog_box = null
var _cyrus_met: bool = false

var _hatch_progress: int = 0
var _pip_flash: float = 0.0
var _twinkle_cooldown_timer: float = 0.0
var _frosty_cooldown_timer: float = 0.0
var _guinea_pig_cooldown_timer: float = 0.0

var _cd_scale: float = 1.0

func _ready() -> void:
	_build_floor()
	_build_walls()
	PlaceholderArt.add_mood_light(self, LOCATION_ID)
	GameManager.register_players_with_preference(evan, ethan)
	hud.setup(evan, ethan)
	_cd_scale = GameManager.companion_cooldown_scale()
	evan.special_used.connect(_on_special_used)
	ethan.special_used.connect(_on_special_used)
	_create_rubble()
	_create_hatch()
	_create_shortcut_door()
	_create_loot_boxes()
	_create_hiding_spot()
	_create_doorway()
	_create_cyrus_npc()
	_create_darkness_overlay()
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
# multi-room levels". Reads back exactly the booleans (and the hatch's
# in-progress pip count  --  partial hacking progress is worth preserving for
# a multi-step gate, not just the final pass/fail) this level already tracks
# locally, so re-entering after a Doorway exit picks up where the duo left
# off: skip respawning a cleared floor and restore the rubble's cleared
# palette plus the hatch's pip progress/hacked palette.
func _restore_progress() -> void:
	_enemies_cleared = GameManager.get_level_flag(LOCATION_ID, "enemies_cleared", false)
	_rubble_cleared = GameManager.get_level_flag(LOCATION_ID, "rubble_cleared", false)
	_hatch_hacked = GameManager.get_level_flag(LOCATION_ID, "hatch_hacked", false)
	_hatch_progress = GameManager.get_level_flag(LOCATION_ID, "hatch_progress", 0)
	_cyrus_met = GameManager.get_level_flag(LOCATION_ID, "cyrus_met", false)
	# Security badge pre-fills the first hatch pip if either character holds one
	# and no progress has been made yet  --  see CLAUDE.md "Collectibles & Inventory".
	if not _hatch_hacked and _hatch_progress == 0:
		if GameManager.has_item("Evan", SecurityBadgeItem.id) or GameManager.has_item("Ethan", SecurityBadgeItem.id):
			_hatch_progress = 1
			GameManager.set_level_flag(LOCATION_ID, "hatch_progress", 1)
	if _rubble_cleared:
		_rubble_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _hatch_hacked:
		_hatch_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _enemies_cleared:
		_spawned = true
	else:
		_spawn()
	# Dark loot boxes: reveal immediately if the lantern is already held
	# (e.g. re-entering after a prior visit where it was picked up).
	_dark_revealed = _has_lantern()
	for box in _dark_loot_boxes:
		if is_instance_valid(box):
			box.visible = _dark_revealed
	# Fanny's bottle: needs lantern AND rubble cleared.
	_fanny_revealed = _has_lantern() and _rubble_cleared
	if is_instance_valid(_fanny_loot_box):
		_fanny_loot_box.visible = _fanny_revealed
	if _enemies_cleared and _rubble_cleared and _hatch_hacked:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "TUNNELS MAPPED!\n\nA hidden route opens between locations.\n\nPress ENTER for the Map"
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
# Iterates whatever StaticBody2D children it finds  --  the branching-maze
# layout (16 wall segments forming a corridor/junction/two-tunnel network)
# needed zero changes here, only more .tscn nodes.
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

func _create_rubble() -> void:
	_rubble_sprite = Sprite2D.new()
	if not _apply_synty_billboard(_rubble_sprite, RUBBLE_BILLBOARD, 44.0):
		_rubble_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.34, 0.3, 0.28), 60, 44)
	_rubble_sprite.position = RUBBLE_POS
	add_child(_rubble_sprite)
	# Maintenance-tunnel dressing (Construction + Office billboards).
	for p: Array in TUNNEL_PROPS:
		var spr := Sprite2D.new()
		if _apply_synty_billboard(spr, "res://assets/art/synty/props/%s.png" % p[0], float(p[3])):
			spr.position = Vector2(float(p[1]), float(p[2]))
			add_child(spr)

func _create_shortcut_door() -> void:
	_shortcut_door_sprite = Sprite2D.new()
	if not _apply_synty_billboard(_shortcut_door_sprite, "res://assets/art/synty/props/door.png", 48.0):
		_shortcut_door_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.38, 0.28, 0.22), 32, 48)
	_shortcut_door_sprite.position = SHORTCUT_DOOR_POS
	add_child(_shortcut_door_sprite)

func _create_hatch() -> void:
	_hatch_sprite = Sprite2D.new()
	if not _apply_synty_billboard(_hatch_sprite, "res://assets/art/synty/props/hatch.png", 30.0):
		_hatch_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.26, 0.32, 0.36), 44, 44)
	_hatch_sprite.position = HATCH_POS
	add_child(_hatch_sprite)

# Stealth: a shadowed alcove sitting in the junction chamber  --  the crossroads
# every patrol must pass through, so ducking in here to let one go by is
# always a meaningful choice regardless of which tunnel the duo is heading for.
func _create_hiding_spot() -> void:
	var spot = HidingSpotScript.new()
	spot.position = HIDING_SPOT_POS
	add_child(spot)

func _create_loot_boxes() -> void:
	# The pocket lantern is always visible -- placed in the lit junction chamber
	# so the duo can find it without needing light first.
	var lantern_box = LootBoxScript.new()
	lantern_box.setup(PocketLanternItem, LANTERN_LOOT_POS,
			GameManager.get_level_flag(LOCATION_ID, LANTERN_LOOT_FLAG, false))
	add_child(lantern_box)
	_loot_boxes.append(lantern_box)

	# The rusty key and security badge are hidden in the dark.  Visibility is set
	# after _restore_progress() checks whether the lantern is held.
	var key_box = LootBoxScript.new()
	key_box.setup(RustyKeyItem, KEY_LOOT_POS,
			GameManager.get_level_flag(LOCATION_ID, DARK_LOOT_FLAG_KEYS[0], false))
	add_child(key_box)
	_dark_loot_boxes.append(key_box)

	var badge_box = LootBoxScript.new()
	badge_box.setup(SecurityBadgeItem, BADGE_LOOT_POS,
			GameManager.get_level_flag(LOCATION_ID, DARK_LOOT_FLAG_KEYS[1], false))
	add_child(badge_box)
	_dark_loot_boxes.append(badge_box)

	# Fanny's bottle: kept out of _dark_loot_boxes so _reveal_dark_boxes() doesn't
	# expose it prematurely -- it needs BOTH lantern AND rubble cleared.
	_fanny_loot_box = LootBoxScript.new()
	_fanny_loot_box.setup(FannysBottleItem, FANNY_LOOT_POS,
			GameManager.get_level_flag(LOCATION_ID, FANNY_LOOT_FLAG, false))
	_fanny_loot_box.visible = false
	add_child(_fanny_loot_box)

# Darkness overlay: world-space dark rect with a player-centered glow.
# z_index = 50 puts it above all Node2D world content (floor/walls/enemies/
# players at z=0) but below any CanvasLayer (HUD etc.).
func _create_darkness_overlay() -> void:
	_darkness = DarknessOverlayScript.new()
	_darkness.z_index = 50
	# Extend the rect 200px beyond the camera limits in every direction so
	# the overlay still covers the full viewport when the camera is near an edge.
	_darkness.world_rect = Rect2(
			CAMERA_LIMIT_LEFT - 200, CAMERA_LIMIT_TOP - 200,
			CAMERA_LIMIT_RIGHT - CAMERA_LIMIT_LEFT + 400,
			CAMERA_LIMIT_BOTTOM - CAMERA_LIMIT_TOP + 400)
	add_child(_darkness)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

func _create_cyrus_npc() -> void:
	_cyrus_sprite = AnimatedSprite2D.new()
	var loaded: SpriteFrames = SpriteLoader.try_load_npc("cyrus")
	_cyrus_sprite.sprite_frames = loaded if loaded != null else PlaceholderArt.make_player_frames(CYRUS_COLOR, "")
	_cyrus_sprite.scale = Vector2(SpriteLoader.NPC_SPRITE_SCALE, SpriteLoader.NPC_SPRITE_SCALE) if loaded != null else Vector2.ONE
	_cyrus_sprite.play("idle")
	_cyrus_sprite.position = CYRUS_POS
	add_child(_cyrus_sprite)
	_cyrus_bubble = SpeechBubbleScript.new()
	_cyrus_bubble.position = CYRUS_POS + Vector2(0.0, -52.0)
	add_child(_cyrus_bubble)
	_cyrus_bubble_timer = randf_range(CYRUS_BUBBLE_MIN, CYRUS_BUBBLE_MAX)
	var dialog_layer := CanvasLayer.new()
	dialog_layer.layer = 19
	add_child(dialog_layer)
	_dialog_box = DialogBoxScript.new()
	dialog_layer.add_child(_dialog_box)
	_dialog_box.closed.connect(_on_cyrus_dialog_closed)

func _talk_to_cyrus() -> void:
	var p: Player = GameManager.active_player
	var tree: Dictionary
	if _cleared:
		tree = CYRUS_AFTER_TREE
	elif not _cyrus_met:
		tree = CYRUS_INTRO_TREE
	else:
		tree = CYRUS_REMINDER_TREE
	_dialog_box.open("Cyrus", CYRUS_COLOR, tree, "start", p.data.character_name)

func _on_cyrus_dialog_closed(_effects: Array) -> void:
	if not _cyrus_met:
		_cyrus_met = true
		GameManager.set_level_flag(LOCATION_ID, "cyrus_met", true)

# Returns true if either member of the active duo is holding the pocket lantern.
func _has_lantern() -> bool:
	return GameManager.has_item("Evan", PocketLanternItem.id) or \
			GameManager.has_item("Ethan", PocketLanternItem.id)

# Called once when the lantern is first picked up: reveals the dark loot boxes
# and plays a discovery cue.
func _reveal_dark_boxes() -> void:
	_dark_revealed = true
	for box in _dark_loot_boxes:
		if is_instance_valid(box):
			box.visible = true
	Audio.play("special")

# Stealth: Evan's Special, used away from the rubble, sends Frosty charging at
# the nearest enemy or (when the floor is clear) Twinkle off to bark as a
# distraction  --  cooldown-gated (see CLAUDE.md "Evan's Animals").
func _summon_frosty(target: Enemy) -> void:
	var frosty = AnimalCompanionScript.new()
	frosty.setup(evan, target, FROSTY_COLOR, "frosty")
	add_child(frosty)
	_frosty_cooldown_timer = FROSTY_COOLDOWN * _cd_scale
	GameManager.companion_summoned.emit("frosty")

func _nearest_enemy(from_pos: Vector2):
	var living: Array = []
	for child in enemies.get_children():
		if child is Enemy and is_instance_valid(child):
			living.append(child)
	if living.is_empty():
		return null
	living.sort_custom(func(a, b): return from_pos.distance_to(a.global_position) < from_pos.distance_to(b.global_position))
	return living[0]

func _summon_guinea_pigs() -> void:
	var gp = GuineaPigScript.new()
	gp.setup(evan.global_position, evan.facing)
	add_child(gp)
	_guinea_pig_cooldown_timer = GUINEA_PIG_COOLDOWN * _cd_scale
	GameManager.companion_summoned.emit("guinea_pigs")

func _summon_twinkle() -> void:
	var twinkle = TwinkleScript.new()
	twinkle.setup(evan, evan.facing)
	add_child(twinkle)
	_twinkle_cooldown_timer = TWINKLE_COOLDOWN * _cd_scale
	GameManager.companion_summoned.emit("twinkle")

func _spawn() -> void:
	_add(GRUNT_SCENE,  Vector2(480.0, 260.0))
	_add(GRUNT_SCENE,  Vector2(180.0, 288.0))
	_add(RUNNER_SCENE, Vector2(820.0, 288.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	if _dialog_box.is_open():
		return
	var p: Player = evan if char_name == "Evan" else ethan
	if p.global_position.distance_to(CYRUS_POS) < CYRUS_RADIUS:
		_talk_to_cyrus()
		return
	# Always-visible loot boxes (pocket lantern).
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LANTERN_LOOT_FLAG, true)
			return
	# Dark loot boxes (rusty key, security badge)  --  only openable once revealed.
	if _dark_revealed:
		for i in _dark_loot_boxes.size():
			if _dark_loot_boxes[i].try_open(char_name, p.global_position):
				GameManager.set_level_flag(LOCATION_ID, DARK_LOOT_FLAG_KEYS[i], true)
				return
	# Fanny's bottle  --  only openable when both lantern is held and rubble cleared.
	if _fanny_revealed and is_instance_valid(_fanny_loot_box):
		if _fanny_loot_box.try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, FANNY_LOOT_FLAG, true)
			return
	# Rusty key shortcut door  --  usable by either character in the duo
	if p.global_position.distance_to(SHORTCUT_DOOR_POS) < SHORTCUT_DOOR_RADIUS:
		if GameManager.has_item("Evan", RustyKeyItem.id) or GameManager.has_item("Ethan", RustyKeyItem.id):
			var holder: String = "Evan" if GameManager.has_item("Evan", RustyKeyItem.id) else "Ethan"
			GameManager.consume_item(holder, RustyKeyItem.id)
			_shortcut_door_sprite.modulate = Color(0.4, 1.0, 0.5)
			Audio.play("special")
			_exit_to_overworld()
			return
		else:
			hint_label.text = "This door is locked  --  find the rusty key"
			Audio.play("hit")
			return
	if char_name == "Evan":
		if not _rubble_cleared and evan.global_position.distance_to(RUBBLE_POS) < RUBBLE_RADIUS:
			_rubble_cleared = true
			_rubble_sprite.modulate = Color(0.4, 1.0, 0.5)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "rubble_cleared", true)
		elif _frosty_cooldown_timer == 0.0:
			var target = _nearest_enemy(evan.global_position)
			if target != null:
				_summon_frosty(target)
			elif _twinkle_cooldown_timer == 0.0:
				_summon_twinkle()
			elif _guinea_pig_cooldown_timer == 0.0:
				_summon_guinea_pigs()
	elif char_name == "Ethan" and not _hatch_hacked:
		if ethan.global_position.distance_to(HATCH_POS) < HATCH_RADIUS:
			_hatch_progress += 1
			_pip_flash = PIP_FLASH_DURATION
			Audio.play("hit")
			GameManager.set_level_flag(LOCATION_ID, "hatch_progress", _hatch_progress)
			if _hatch_progress >= HATCH_PRESSES_REQUIRED:
				_hatch_hacked = true
				_hatch_sprite.modulate = Color(0.4, 1.0, 0.5)
				Audio.play("special")
				GameManager.set_level_flag(LOCATION_ID, "hatch_hacked", true)
	elif GameManager.try_use_whistle():
		Audio.play("special")

func _process(delta: float) -> void:
	_pip_flash = maxf(_pip_flash - delta, 0.0)
	_twinkle_cooldown_timer = maxf(_twinkle_cooldown_timer - delta, 0.0)
	_frosty_cooldown_timer = maxf(_frosty_cooldown_timer - delta, 0.0)
	_guinea_pig_cooldown_timer = maxf(_guinea_pig_cooldown_timer - delta, 0.0)
	queue_redraw()
	if is_instance_valid(_cyrus_bubble) and not _dialog_box.is_open():
		_cyrus_bubble_timer -= delta
		if _cyrus_bubble_timer <= 0.0:
			_cyrus_bubble_timer = randf_range(CYRUS_BUBBLE_MIN, CYRUS_BUBBLE_MAX)
			_cyrus_bubble.show_text(
				CYRUS_BUBBLE_LINES[randi() % CYRUS_BUBBLE_LINES.size()],
				CYRUS_BUBBLE_DUR)
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
	# Darkness overlay: update position and light state each frame.
	if is_instance_valid(_darkness):
		var lit: bool = _has_lantern()
		_darkness.has_light = lit
		_darkness.darkness_alpha = 0.38 if lit else 0.82
		if is_instance_valid(GameManager.active_player):
			_darkness.light_pos = GameManager.active_player.global_position
		_darkness.queue_redraw()
		# Reveal dark loot boxes the first time the lantern is held.
		if not _dark_revealed and lit:
			_reveal_dark_boxes()
		# Fanny's bottle: reveal the moment BOTH conditions are first met.
		if not _fanny_revealed and lit and _rubble_cleared:
			_fanny_revealed = true
			if is_instance_valid(_fanny_loot_box):
				_fanny_loot_box.visible = true
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
	if _enemies_cleared and _rubble_cleared and _hatch_hacked and not _cleared:
		_cleared = true
		Audio.play("puzzle_complete")
		Audio.play_music("victory")
		hint_label.text = ""
		clear_label.text = "TUNNELS MAPPED!\n\nA hidden route opens between locations.\n\nPress ENTER for the Map"
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
		hint_label.text = "Patrols haven't spotted you — talk to Cyrus, then sneak past or strike  [ Evan: press G for Frosty or Twinkle ]"
	elif not _has_lantern():
		hint_label.text = "Find the pocket lantern in the junction chamber to light the tunnels"
	elif not _rubble_cleared:
		hint_label.text = "Evan: force the west passage open  [ approach rubble, press G ]"
	elif not _hatch_hacked:
		hint_label.text = "Ethan: hack the east hatch — %d/%d passes  [ approach it, press G ]" % [_hatch_progress, HATCH_PRESSES_REQUIRED]
	else:
		hint_label.text = ""
