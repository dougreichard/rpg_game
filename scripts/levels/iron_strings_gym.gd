extends Node2D

const LOCATION_ID: String = "iron_strings_gym"

# Tile-mapped floor palette  --  gym-floor grey with iron-red accents (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.28, 0.26, 0.26)
const FLOOR_ACCENT_COLOR: Color = Color(0.62, 0.30, 0.26)
const FLOOR_COLS: int = 30
const FLOOR_ROWS: int = 17
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 1)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 1)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/Brute.tscn")
const HidingSpotScript: Script = preload("res://scripts/systems/hiding_spot.gd")
const HIDING_SPOT_POS := Vector2(420.0, 460.0)

# Frosty  --  Evan's Schnoodle, the general-purpose combat-distractor companion
# (see CLAUDE.md "Evan's Animals"): charges the nearest enemy, headbutts to
# stagger it, then returns to Evan's side. Cooldown-gated so it can't be
# spammed every frame  --  same summon pattern as Calvin & Coolidge at the docks.
const AnimalCompanionScript: Script = preload("res://scripts/systems/animal_companion.gd")
const FROSTY_COLOR := Color(0.95, 0.95, 0.95)
const FROSTY_COOLDOWN: float = 3.0

# Collectibles: Ben's ticket (found in the cage where he's freed  --  fitting) and
# an animal treat  --  see CLAUDE.md "Collectibles & Inventory".
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const TicketBenItem: ItemData    = preload("res://data/items/ticket_ben.tres")
const AnimalTreatItem: ItemData  = preload("res://data/items/animal_treat.tres")
const TICKET_LOOT_POS    := Vector2(700.0, 100.0)
const TREAT_LOOT_POS     := Vector2(130.0, 200.0)
const LOOT_FLAG_KEYS     := ["ticket_loot_open", "treat_loot_open"]

# Doorway: the level's entrance/exit  --  see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo spawns beside it in the locker room; walking
# away and back exits to the overworld at any time, cleared or not.
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(140.0, 340.0)

# The barbell: previously a purely cosmetic prop (a sprite that just changed
# color and nudged up). It's now a literal StaticBody2D blocking the doorway
# to Ben's cage alcove  --  Evan's Special disables its collider and slides the
# sprite aside, making "Evan's super strength moves heavy equipment to open
# paths" (this location's spec line) physical instead of decorative. Same
# disable-collider-then-animate-sprite shape as Pipe Organ Works' secret
# passage, just sliding rather than fading  --  distinct flavor, same mechanism.
const BARBELL_POS := Vector2(660.0, 152.0)
const BARBELL_RADIUS: float = 64.0
const BARBELL_SLIDE_OFFSET := Vector2(160.0, 0.0)

# Multi-room layout bounding box (locker room -> gym floor -> Ben's cage
# alcove). Feeds the camera's pan limits  --  see CLAUDE.md "Doorways,
# camera-follow & multi-room levels". Recompute if the wall layout changes.
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
@onready var _barbell: StaticBody2D = $Barbell

var _spawned: bool = false
var _enemies_cleared: bool = false
var _barbell_moved: bool = false
var _cleared: bool = false
var _barbell_shape: CollisionShape2D
var _barbell_sprite: Sprite2D
var _loot_boxes: Array = []
var _doorway = null
var _frosty_cooldown_timer: float = 0.0

var _cd_scale: float = 1.0
func _ready() -> void:
	_build_floor()
	_build_walls()
	GameManager.register_players_with_preference(quinn, evan)
	hud.setup(quinn, evan)
	_cd_scale = GameManager.companion_cooldown_scale()
	quinn.special_used.connect(_on_special_used)
	evan.special_used.connect(_on_special_used)
	_create_barbell()
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
# left off: skip respawning a cleared floor and restore the barbell's moved
# state (collider disabled, sprite slid aside).
func _restore_progress() -> void:
	_enemies_cleared = GameManager.get_level_flag(LOCATION_ID, "enemies_cleared", false)
	_barbell_moved = GameManager.get_level_flag(LOCATION_ID, "barbell_moved", false)
	if _barbell_moved:
		_move_barbell(false)
	if _enemies_cleared:
		_spawned = true
	else:
		_spawn()

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
# Iterates whatever StaticBody2D children it finds  --  the locker-room/gym-
# floor/cage-alcove layout needed zero changes here, only more .tscn nodes
# (the Barbell is a sibling of $Walls, not a child, so it keeps its own
# bespoke gym-equipment texture instead of the generic brick pattern).
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

# Grabs the .tscn-placed Barbell body's collider and dresses it with an
# iron-red bordered-rectangle texture  --  visually distinct from the brick
# walls (it reads as stacked gym equipment jammed in a doorway, not masonry).
func _create_barbell() -> void:
	_barbell_shape = _barbell.get_node("CollisionShape2D")
	_barbell_sprite = Sprite2D.new()
	_barbell_sprite.texture = PlaceholderArt.make_barbell_texture(FLOOR_ACCENT_COLOR, 200, 16)
	_barbell.add_child(_barbell_sprite)

func _move_barbell(animate: bool) -> void:
	_barbell_shape.disabled = true
	if animate:
		var tween := create_tween()
		tween.tween_property(_barbell_sprite, "position", BARBELL_SLIDE_OFFSET, 0.6)
	else:
		_barbell_sprite.position = BARBELL_SLIDE_OFFSET

# Stealth: a shadowed alcove the duo can duck into to let a patrol pass
# rather than fight through it  --  see CLAUDE.md "Stealth & awareness".
func _create_hiding_spot() -> void:
	var spot = HidingSpotScript.new()
	spot.position = HIDING_SPOT_POS
	add_child(spot)

func _create_loot_boxes() -> void:
	var ticket_box = LootBoxScript.new()
	ticket_box.setup(TicketBenItem, TICKET_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[0], false))
	add_child(ticket_box)
	_loot_boxes.append(ticket_box)

	var treat_box = LootBoxScript.new()
	treat_box.setup(AnimalTreatItem, TREAT_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[1], false))
	add_child(treat_box)
	_loot_boxes.append(treat_box)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

func _spawn() -> void:
	_add(GRUNT_SCENE, Vector2(500.0, 250.0))
	_add(GRUNT_SCENE, Vector2(760.0, 420.0))
	_add(BRUTE_SCENE, Vector2(620.0, 340.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	var p: Player = quinn if char_name == "Quinn" else evan
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if char_name == "Evan":
		if not _barbell_moved and evan.global_position.distance_to(BARBELL_POS) < BARBELL_RADIUS:
			_barbell_moved = true
			_move_barbell(true)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "barbell_moved", true)
		elif _frosty_cooldown_timer == 0.0:
			_summon_frosty()
	elif GameManager.try_use_whistle():
		Audio.play("special")

func _summon_frosty() -> void:
	var target = _nearest_enemy(evan.global_position)
	if target == null:
		return
	var frosty = AnimalCompanionScript.new()
	frosty.setup(evan, target, FROSTY_COLOR)
	add_child(frosty)
	_frosty_cooldown_timer = FROSTY_COOLDOWN * _cd_scale

func _nearest_enemy(from_pos: Vector2):
	var living: Array = []
	for child in enemies.get_children():
		if child is Enemy and is_instance_valid(child):
			living.append(child)
	if living.is_empty():
		return null
	living.sort_custom(func(a, b): return from_pos.distance_to(a.global_position) < from_pos.distance_to(b.global_position))
	return living[0]

func _process(delta: float) -> void:
	_frosty_cooldown_timer = maxf(_frosty_cooldown_timer - delta, 0.0)
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
	if _enemies_cleared and _barbell_moved and not _cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "GYM CLEARED!\n\nBen is free.\n\nPress ENTER for the Map"
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
		hint_label.text = "The bruisers haven't clocked you yet  --  pick them off (Evan: press G to send Frosty charging), or slip past to free Ben first"
	elif not _barbell_moved:
		hint_label.text = "Evan: shove the barbell rack off Ben's cage doorway  [ approach it, press G ]"
	else:
		hint_label.text = ""
