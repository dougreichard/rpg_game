extends Node2D

const LOCATION_ID: String = "vr_room"

# Tile-mapped floor palette  --  cool cyber-blue with glitchy cyan accents (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.21, 0.25, 0.32)
const FLOOR_ACCENT_COLOR: Color = Color(0.30, 0.65, 0.70)
const FLOOR_COLS: int = 25
const FLOOR_ROWS: int = 17
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

# Themed-stage floor overlays  --  each painted as its own TileMap, ON TOP of the
# base "Boot Chamber" cyber-blue grid, over only that stage's cell footprint
# (see _paint_stage_floor). This makes "Each stage can have a distinct visual
# theme (medieval, space, underwater, etc.)"  --  this location's CLAUDE.md
# spec line  --  literally true at the tile level: stepping through the corridor
# threshold into a stage visibly recolors the floor underfoot, not just a prop.
const STAGE_ALPHA_BASE_COLOR: Color = Color(0.34, 0.27, 0.17)
const STAGE_ALPHA_ACCENT_COLOR: Color = Color(0.62, 0.50, 0.28)
const STAGE_ALPHA_COL_RANGE := Vector2i(13, 22)
const STAGE_ALPHA_ROW_RANGE := Vector2i(6, 17)

const STAGE_BETA_BASE_COLOR: Color = Color(0.14, 0.32, 0.36)
const STAGE_BETA_ACCENT_COLOR: Color = Color(0.30, 0.64, 0.62)
const STAGE_BETA_COL_RANGE := Vector2i(13, 24)
const STAGE_BETA_ROW_RANGE := Vector2i(1, 6)

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const SENTRY_SCENE: PackedScene = preload("res://scenes/enemies/Sentry.tscn")
const HidingSpotScript: Script = preload("res://scripts/systems/hiding_spot.gd")
const HIDING_SPOT_POS := Vector2(470.0, 260.0)

# Lizard  --  Evan's vertical-traversal scout (see CLAUDE.md "Evan's Animals"):
# climbs to the bypass panel above the system console and trips the circuit,
# providing an alternate route to _system_hacked without standing at the
# console directly. Summoned by Ethan when away from the console (mirrors the
# William & Mary alternate-route pattern from The Drop).
const LizardScript: Script = preload("res://scripts/systems/lizard_companion.gd")
const BYPASS_PANEL_POS := Vector2(630.0, 48.0)
const LIZARD_COOLDOWN: float = 4.0

const GLITCH_POS := Vector2(560.0, 370.0)
const GLITCH_RADIUS: float = 64.0
const SYSTEM_POS := Vector2(590.0, 110.0)
const SYSTEM_RADIUS: float = 64.0

# Collectibles: VR override chip (collectible-only this pass  --  stage-skip mechanic
# is a future follow-up) and a Bies charm (collectible-only  --  stat buff hook not
# yet implemented)  --  see CLAUDE.md "Collectibles & Inventory".
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const VrOverrideChipItem: ItemData = preload("res://data/items/vr_override_chip.tres")
const BiesCharmItem: ItemData      = preload("res://data/items/bies_charm.tres")
const CHIP_LOOT_POS  := Vector2(160.0, 360.0)
const CHARM_LOOT_POS := Vector2(680.0, 120.0)
const LOOT_FLAG_KEYS := ["chip_loot_open", "charm_loot_open"]

# Doorway: the level's entrance/exit  --  see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo spawns beside it in the Boot Chamber; walking
# away and back exits to the overworld at any time, cleared or not.
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(170.0, 490.0)

# Multi-room layout bounding box  --  a literal chain of THEMED CORRUPTED-STAGE
# ZONES off a central "Boot Chamber": the duo spawns in a neutral cyber-blue
# boot room, threads east through Corridor1 into Stage Alpha (a glitched
# "medieval" simulation  --  warm stone/amber, Quinn's physics-glitch repair),
# then north through Corridor2 into Stage Beta (a glitched "underwater"
# simulation  --  teal/aqua, Ethan's system console). Each crossing is a literal
# palette change underfoot  --  "distinct visual theme... without breaking the
# overall aesthetic" (this location's CLAUDE.md spec line) made structural,
# not just decorative. Feeds the camera's pan limits  --  see CLAUDE.md
# "Doorways, camera-follow & multi-room levels". Recompute if the wall layout
# changes. CAMERA_LIMIT_TOP derives from Stage Beta's north wall (the
# northernmost structure, so the binding constraint).
const CAMERA_LIMIT_LEFT: int = 24
const CAMERA_LIMIT_TOP: int = 24
const CAMERA_LIMIT_RIGHT: int = 776
const CAMERA_LIMIT_BOTTOM: int = 536
const CAMERA_SMOOTHING_SPEED: float = 5.0

@onready var camera: Camera2D = $Camera2D
@onready var quinn: Player = $Players/Quinn
@onready var ethan: Player = $Players/Ethan
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel

var _spawned: bool = false
var _enemies_cleared: bool = false
var _glitch_repaired: bool = false
var _system_hacked: bool = false
var _cleared: bool = false
var _glitch_sprite: Sprite2D
var _system_sprite: Sprite2D
var _loot_boxes: Array = []
var _doorway = null
var _lizard_cooldown_timer: float = 0.0
var _cd_scale: float = 1.0

func _ready() -> void:
	_build_floor()
	_build_walls()
	GameManager.register_players_with_preference(quinn, ethan)
	hud.setup(quinn, ethan)
	quinn.special_used.connect(_on_special_used)
	ethan.special_used.connect(_on_special_used)
	_cd_scale = GameManager.companion_cooldown_scale()
	_create_glitch()
	_create_system()
	_create_loot_boxes()
	_create_hiding_spot()
	_create_doorway()
	_setup_camera()
	_restore_progress()

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
# left off: skip respawning a cleared floor and restore both stage props'
# solved-state palettes.
func _restore_progress() -> void:
	_enemies_cleared = GameManager.get_level_flag(LOCATION_ID, "enemies_cleared", false)
	_glitch_repaired = GameManager.get_level_flag(LOCATION_ID, "glitch_repaired", false)
	_system_hacked = GameManager.get_level_flag(LOCATION_ID, "system_hacked", false)
	if _glitch_repaired:
		_glitch_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _system_hacked:
		_system_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _enemies_cleared:
		_spawned = true
	else:
		_spawn()
	if _enemies_cleared and _glitch_repaired and _system_hacked:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "SIMULATION EXITED!\n\nThe rules rewrite themselves  --  and a door opens.\n\nPress ENTER for the Map"
		clear_label.visible = true

# Tile-mapped retro floor (Zelda-style two-tone grid), generated at runtime
# via PlaceholderArt to keep the original-IP guarantee  --  no imported tile art.
# Wall art: a Sprite2D per StaticBody2D wall, sized to its exact
# CollisionShape2D rect and textured via PlaceholderArt.make_wall_texture  --  a
# darker stone tone of the floor's base color, so the room reads as a bordered
# space instead of walls-on-a-void (matches the tile-floor visual-style pass;
# generated at runtime, no imported wall art, original-IP guarantee intact).
# Iterates whatever StaticBody2D children it finds  --  the Boot Chamber +
# two-corridor + two-stage layout (20 wall segments) needed zero changes here,
# only more .tscn nodes.
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
	_paint_stage_floor("FloorStageAlpha", STAGE_ALPHA_BASE_COLOR, STAGE_ALPHA_ACCENT_COLOR, STAGE_ALPHA_COL_RANGE, STAGE_ALPHA_ROW_RANGE)
	_paint_stage_floor("FloorStageBeta", STAGE_BETA_BASE_COLOR, STAGE_BETA_ACCENT_COLOR, STAGE_BETA_COL_RANGE, STAGE_BETA_ROW_RANGE)

# A themed-stage floor patch  --  its own TileMap/TileSet pair (own palette),
# painted only over its stage's cell footprint and added ON TOP of the base
# Boot Chamber grid (added after `move_child(tile_map, 0)`, so it naturally
# layers above). Where it paints nothing, the base grid shows through  -- 
# exactly the "tiles outside room footprints simply sit behind walls,
# invisible" precedent, just inverted to "patch on top" instead of "grid
# underneath."
func _paint_stage_floor(map_name: String, base_color: Color, accent_color: Color, col_range: Vector2i, row_range: Vector2i) -> void:
	var tile_map := TileMap.new()
	tile_map.name = map_name
	tile_map.tile_set = PlaceholderArt.make_level_tileset(base_color, accent_color)
	add_child(tile_map)
	for x: int in range(col_range.x, col_range.y):
		for y: int in range(row_range.x, row_range.y):
			var variant: Vector2i = FLOOR_TILE_ACCENT if (x + y) % FLOOR_ACCENT_PERIOD == 0 else FLOOR_TILE_PLAIN
			tile_map.set_cell(0, Vector2i(x, y), 0, variant)

# Stage Alpha  --  the glitched "medieval" simulation. A castle-stone gate prop
# whose physics keep misbehaving; Quinn comments on the mechanical logic and
# repairs it (his established mechanical-repair angle, here applied to a
# simulated rather than physical machine).
func _create_glitch() -> void:
	_glitch_sprite = Sprite2D.new()
	_glitch_sprite.texture = PlaceholderArt.make_gear_prop_texture(Color(0.4, 0.2, 0.5), 48, 48)
	_glitch_sprite.position = GLITCH_POS
	add_child(_glitch_sprite)

# Stage Beta  --  the glitched "underwater" simulation. A corrupted control
# console Ethan reads the code underneath to hack and rewrite.
func _create_system() -> void:
	_system_sprite = Sprite2D.new()
	_system_sprite.texture = PlaceholderArt.make_console_texture(Color(0.18, 0.42, 0.46), 48, 44)
	_system_sprite.position = SYSTEM_POS
	add_child(_system_sprite)

func _create_loot_boxes() -> void:
	var chip_box = LootBoxScript.new()
	chip_box.setup(VrOverrideChipItem, CHIP_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[0], false))
	add_child(chip_box)
	_loot_boxes.append(chip_box)

	var charm_box = LootBoxScript.new()
	charm_box.setup(BiesCharmItem, CHARM_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[1], false))
	add_child(charm_box)
	_loot_boxes.append(charm_box)

# Stealth: a shadowed alcove at the Stage Alpha junction  --  every patrol
# crossing between the Boot Chamber and Stage Beta must pass through here, so
# ducking in to let one go by is meaningful regardless of which stage the duo
# is headed toward  --  see CLAUDE.md "Stealth & awareness".
func _create_hiding_spot() -> void:
	var spot = HidingSpotScript.new()
	spot.position = HIDING_SPOT_POS
	add_child(spot)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

func _spawn() -> void:
	_add(GRUNT_SCENE,  Vector2(170.0, 420.0))
	_add(GRUNT_SCENE,  Vector2(500.0, 460.0))
	_add(SENTRY_SCENE, Vector2(700.0, 90.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	var p: Player = quinn if char_name == "Quinn" else ethan
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if char_name == "Quinn" and not _glitch_repaired:
		if quinn.global_position.distance_to(GLITCH_POS) < GLITCH_RADIUS:
			_glitch_repaired = true
			_glitch_sprite.modulate = Color(0.4, 1.0, 0.5)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "glitch_repaired", true)
	elif char_name == "Ethan" and not _system_hacked:
		if ethan.global_position.distance_to(SYSTEM_POS) < SYSTEM_RADIUS:
			_system_hacked = true
			_system_sprite.modulate = Color(0.4, 1.0, 0.5)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "system_hacked", true)
		elif _lizard_cooldown_timer == 0.0:
			_summon_lizard()
	elif GameManager.try_use_whistle():
		Audio.play("special")

func _summon_lizard() -> void:
	var lizard = LizardScript.new()
	lizard.setup(ethan, BYPASS_PANEL_POS)
	lizard.target_reached.connect(_on_lizard_bypass)
	add_child(lizard)
	_lizard_cooldown_timer = LIZARD_COOLDOWN * _cd_scale
	Audio.play("special")

func _on_lizard_bypass() -> void:
	if _system_hacked:
		return
	_system_hacked = true
	_system_sprite.modulate = Color(0.4, 1.0, 0.5)
	Audio.play("special")
	GameManager.set_level_flag(LOCATION_ID, "system_hacked", true)

func _process(delta: float) -> void:
	_lizard_cooldown_timer = maxf(_lizard_cooldown_timer - delta, 0.0)
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
	if _enemies_cleared and _glitch_repaired and _system_hacked and not _cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "SIMULATION EXITED!\n\nThe rules rewrite themselves  --  and a door opens.\n\nPress ENTER for the Map"
		clear_label.visible = true
	if _cleared and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location(LOCATION_ID)
		TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")

# Doorway-triggered exit  --  distinct from the clear-overlay's "press ENTER"
# exit above. Per the established pattern, the duo can walk out at any time,
# cleared or not; complete_location is idempotent, so calling it here when
# already cleared never double-grants.
func _exit_to_overworld() -> void:
	if _cleared:
		GameManager.complete_location(LOCATION_ID)
	TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")

func _update_hint() -> void:
	if _cleared:
		hint_label.text = ""
	elif not _enemies_cleared:
		hint_label.text = "The glitched patrols loop their routes, unaware  --  slip through the gaps, or short them out before the system notices"
	elif not _glitch_repaired:
		hint_label.text = "Quinn: in the medieval-glitch stage, repair the broken physics  [ approach it, press G ]"
	elif not _system_hacked:
		hint_label.text = "Ethan: in the underwater-glitch stage, hack the system to rewrite the rules  [ approach it, press G ]"
	else:
		hint_label.text = ""
