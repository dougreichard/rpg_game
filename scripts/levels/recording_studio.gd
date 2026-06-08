extends Node2D

const LOCATION_ID: String = "recording_studio"

# Tile-mapped floor palette — warm wood/acoustic-foam tones (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.32, 0.27, 0.24)
const FLOOR_ACCENT_COLOR: Color = Color(0.55, 0.40, 0.30)
const FLOOR_COLS: int = 28
const FLOOR_ROWS: int = 17
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/Runner.tscn")
const HidingSpotScript: Script = preload("res://scripts/systems/hiding_spot.gd")
const HIDING_SPOT_POS := Vector2(340.0, 460.0)

const CONSOLE_POS := Vector2(580.0, 340.0)
const CONSOLE_RADIUS: float = 64.0

# Collectibles: Ethan's ticket (found inside the booth where he's freed —
# parallel to Ben/cage) and junk headphone cable — see CLAUDE.md "Collectibles
# & Inventory".
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const TicketEthanItem: ItemData    = preload("res://data/items/ticket_ethan.tres")
const HeadphoneCableItem: ItemData = preload("res://data/items/tangled_headphone_cable.tres")
const TICKET_LOOT_POS  := Vector2(640.0, 100.0)
const CABLE_LOOT_POS   := Vector2(160.0, 440.0)
const LOOT_FLAG_KEYS   := ["ticket_loot_open", "cable_loot_open"]

# Doorway: the level's entrance/exit — see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo spawns beside it in the lobby; walking away
# and back exits to the overworld at any time, cleared or not.
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(140.0, 340.0)

# The booth door: a soundproof glass barrier sealing Ethan inside the
# recording booth — "someone has scrambled the studio" played literally as a
# jammed access door. It's wired to the very soundboard Ben has to tune, so
# tuning the console (his Special, in range) both solves the puzzle gate AND
# slides the door up into the ceiling, freeing Ethan — one action, two
# payoffs, matching "Ben navigates the soundboard...to trigger doors and
# mechanisms" from this location's spec line. Same disable-collider-then-
# animate-sprite shape as Pipe Organ Works' secret passage and Iron & Strings'
# barbell, sliding vertically rather than fading or sliding horizontally —
# distinct flavor, same mechanism.
const BOOTH_DOOR_POS := Vector2(580.0, 152.0)
const BOOTH_DOOR_RADIUS: float = 64.0
const BOOTH_DOOR_SLIDE_OFFSET := Vector2(0.0, -120.0)
const ETHAN_PROP_POS := Vector2(580.0, 100.0)

# Multi-room layout bounding box (lobby -> control room -> sealed recording
# booth). Feeds the camera's pan limits — see CLAUDE.md "Doorways,
# camera-follow & multi-room levels". Recompute if the wall layout changes.
const CAMERA_LIMIT_LEFT: int = 24
const CAMERA_LIMIT_TOP: int = 24
const CAMERA_LIMIT_RIGHT: int = 896
const CAMERA_LIMIT_BOTTOM: int = 536
const CAMERA_SMOOTHING_SPEED: float = 5.0

@onready var camera: Camera2D = $Camera2D
@onready var quinn: Player = $Players/Quinn
@onready var ben: Player = $Players/Ben
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel
@onready var _booth_door: StaticBody2D = $BoothDoor

var _spawned: bool = false
var _enemies_cleared: bool = false
var _console_tuned: bool = false
var _cleared: bool = false
var _console_sprite: Sprite2D
var _booth_door_shape: CollisionShape2D
var _booth_door_sprite: Sprite2D
var _ethan_prop: Sprite2D
var _loot_boxes: Array = []
var _doorway = null

func _ready() -> void:
	_build_floor()
	_build_walls()
	GameManager.register_players_with_preference(quinn, ben)
	hud.setup(quinn, ben)
	quinn.special_used.connect(_on_special_used)
	ben.special_used.connect(_on_special_used)
	_create_console()
	_create_booth_door()
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
# left off: skip respawning a cleared floor and restore the console's tuned
# palette + the booth door's open state (and Ethan's revealed prop) instantly.
func _restore_progress() -> void:
	_enemies_cleared = GameManager.get_level_flag(LOCATION_ID, "enemies_cleared", false)
	_console_tuned = GameManager.get_level_flag(LOCATION_ID, "console_tuned", false)
	if _console_tuned:
		_console_sprite.modulate = Color(0.4, 1.0, 0.5)
		_open_booth_door(false)
	if _enemies_cleared:
		_spawned = true
	else:
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

# Wall art: a Sprite2D per StaticBody2D wall, sized to its exact
# CollisionShape2D rect and textured via PlaceholderArt.make_wall_texture.
# Iterates whatever StaticBody2D children it finds — the lobby/control-room/
# booth layout needed zero changes here, only more .tscn nodes (the BoothDoor
# is a sibling of $Walls, not a child, so it keeps its own bespoke glass-blue
# texture instead of the generic brick pattern).
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

func _create_console() -> void:
	_console_sprite = Sprite2D.new()
	_console_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.28, 0.24, 0.42), 56, 36)
	_console_sprite.position = CONSOLE_POS
	add_child(_console_sprite)

# Grabs the .tscn-placed BoothDoor body's collider and dresses it with a
# glass-blue bordered-rectangle texture — visually distinct from the wood-tone
# walls (reads as a soundproof studio door, not masonry). Also drops in
# Ethan's flavor prop, kept hidden behind the door until it's opened.
func _create_booth_door() -> void:
	_booth_door_shape = _booth_door.get_node("CollisionShape2D")
	_booth_door_sprite = Sprite2D.new()
	_booth_door_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.30, 0.55, 0.65), 200, 16)
	_booth_door.add_child(_booth_door_sprite)
	_ethan_prop = Sprite2D.new()
	_ethan_prop.texture = PlaceholderArt.make_gate_texture(Color(0.5, 0.45, 0.3), 32, 48)
	_ethan_prop.position = ETHAN_PROP_POS
	_ethan_prop.visible = _console_tuned
	add_child(_ethan_prop)

func _open_booth_door(animate: bool) -> void:
	_booth_door_shape.disabled = true
	_ethan_prop.visible = true
	if animate:
		var tween := create_tween()
		tween.tween_property(_booth_door_sprite, "position", BOOTH_DOOR_SLIDE_OFFSET, 0.6)
	else:
		_booth_door_sprite.position = BOOTH_DOOR_SLIDE_OFFSET

# Stealth: a shadowed alcove the duo can duck into to let a patrol pass
# rather than fight through it — see CLAUDE.md "Stealth & awareness".
func _create_hiding_spot() -> void:
	var spot = HidingSpotScript.new()
	spot.position = HIDING_SPOT_POS
	add_child(spot)

func _create_loot_boxes() -> void:
	var ticket_box = LootBoxScript.new()
	ticket_box.setup(TicketEthanItem, TICKET_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[0], false))
	add_child(ticket_box)
	_loot_boxes.append(ticket_box)

	var cable_box = LootBoxScript.new()
	cable_box.setup(HeadphoneCableItem, CABLE_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[1], false))
	add_child(cable_box)
	_loot_boxes.append(cable_box)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

func _spawn() -> void:
	_add(GRUNT_SCENE,  Vector2(380.0, 250.0))
	_add(GRUNT_SCENE,  Vector2(760.0, 420.0))
	_add(RUNNER_SCENE, Vector2(580.0, 460.0))
	_add(RUNNER_SCENE, Vector2(700.0, 250.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	var p: Player = quinn if char_name == "Quinn" else ben
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if char_name == "Ben" and not _console_tuned:
		if ben.global_position.distance_to(CONSOLE_POS) < CONSOLE_RADIUS:
			_console_tuned = true
			_console_sprite.modulate = Color(0.4, 1.0, 0.5)
			_open_booth_door(true)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "console_tuned", true)
	elif GameManager.try_use_whistle():
		Audio.play("special")

func _process(_delta: float) -> void:
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
	if _enemies_cleared and _console_tuned and not _cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "STUDIO CLEARED!\n\nEthan is found.\n\nPress ENTER for the Map"
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

func _update_hint() -> void:
	if _cleared:
		hint_label.text = ""
	elif not _enemies_cleared:
		hint_label.text = "The intruders are still patrolling, unaware — slip between their routes or take them down before they regroup"
	elif not _console_tuned:
		hint_label.text = "Ben: tune the soundboard by ear — it also runs the booth door  [ approach it, press G ]"
	else:
		hint_label.text = ""
