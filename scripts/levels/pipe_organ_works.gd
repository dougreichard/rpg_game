extends Node2D

const LOCATION_ID: String = "pipe_organ_works"

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/Runner.tscn")
const HidingSpotScript: Script = preload("res://scripts/systems/hiding_spot.gd")
const HIDING_SPOT_POS := Vector2(650.0, 460.0)

# Doorway: the level's entrance/exit  --  see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". Spawned beside it; walking away and back exits to the
# overworld at any time, cleared or not (see doorway.gd).
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(130.0, 300.0)

# Collectibles: the organ repair needs a scattered part  --  see CLAUDE.md
# "Collectibles & Inventory" (this is the prototype slice for that system).
# A third box (spare_clockwork_gear) waits in the secret parts closet behind
# the secret passage  --  see _create_secret_passage / _reveal_secret_passage.
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const BrassPipeItem: ItemData = preload("res://data/items/brass_organ_pipe.tres")
const BentSpoonItem: ItemData = preload("res://data/items/bent_spoon.tres")
const SpareGearItem: ItemData = preload("res://data/items/spare_clockwork_gear.tres")
const PIPE_LOOT_POS := Vector2(600.0, 90.0)
const SPOON_LOOT_POS := Vector2(1080.0, 470.0)
const SECRET_LOOT_POS := Vector2(1256.0, 260.0)
const LOOT_FLAG_KEYS := ["pipe_loot_open", "spoon_loot_open", "gear_loot_open"]

const ORGAN_POS := Vector2(840.0, 290.0)
const ORGAN_RADIUS: float = 64.0

# The secret passage: a wall segment (Walls/SecretWall) that looks identical
# to its neighbors but conceals the parts closet. Quinn presses Special near
# the hidden lever to disable its collider and fade its sprite, revealing the
# closet and its loot box  --  composes into the same proximity+Special gate
# template as the organ (_on_special_used's if/elif ladder).
const LEVER_POS := Vector2(1120.0, 260.0)
const LEVER_RADIUS: float = 56.0

# Multi-room layout bounding box (entry bay -> hallway -> main workshop ->
# secret closet)  --  feeds the camera's pan limits (see CLAUDE.md "Doorways,
# camera-follow & multi-room levels"). Recompute if the wall layout changes.
const CAMERA_LIMIT_LEFT: int = 24
const CAMERA_LIMIT_TOP: int = 24
const CAMERA_LIMIT_RIGHT: int = 1352
const CAMERA_LIMIT_BOTTOM: int = 536
const CAMERA_SMOOTHING_SPEED: float = 5.0

const FLOOR_BASE_COLOR: Color = Color(0.32, 0.29, 0.27)
const FLOOR_ACCENT_COLOR: Color = Color(0.6, 0.48, 0.22)
const FLOOR_COLS: int = 43
const FLOOR_ROWS: int = 17
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 1)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 1)
const FLOOR_ACCENT_PERIOD: int = 4

@onready var camera: Camera2D = $Camera2D
@onready var quinn: Player = $Players/Quinn
@onready var erin: Player = $Players/Erin
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel
@onready var _secret_wall: StaticBody2D = $Walls/SecretWall

var _spawned: bool = false
var _enemies_cleared: bool = false
var _organ_repaired: bool = false
var _secret_revealed: bool = false
var _cleared: bool = false
var _organ_sprite: Sprite2D
var _loot_boxes: Array = []
var _secret_wall_shape: CollisionShape2D
var _secret_wall_sprite: Sprite2D
var _doorway = null

func _ready() -> void:
	_build_floor()
	_build_walls()
	GameManager.register_players_with_preference(quinn, erin)
	hud.setup(quinn, erin)
	quinn.special_used.connect(_on_special_used)
	erin.special_used.connect(_on_special_used)
	_create_organ()
	_create_secret_passage()
	_create_loot_boxes()
	_create_hiding_spot()
	_create_doorway()
	_setup_camera()
	_restore_progress()

# Camera follows the active character  --  see CLAUDE.md "Doorways,
# camera-follow & multi-room levels". Smoothing makes the retarget on
# characters_swapped feel natural without any extra signal wiring; the pan
# limits keep the level's edges from ever showing past LEVEL_BOUNDS.
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
# left off: skip spawning a cleared floor, restore solved-state visuals, and
# pre-open any loot boxes already looted.
func _restore_progress() -> void:
	_enemies_cleared = GameManager.get_level_flag(LOCATION_ID, "enemies_cleared", false)
	_organ_repaired = GameManager.get_level_flag(LOCATION_ID, "organ_repaired", false)
	_secret_revealed = GameManager.get_level_flag(LOCATION_ID, "secret_revealed", false)
	if _organ_repaired:
		_organ_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _secret_revealed:
		_open_secret_passage(false)
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
# CollisionShape2D rect and textured via PlaceholderArt.make_wall_texture  --  a
# darker stone tone of the floor's base color, so the room reads as a bordered
# space instead of walls-on-a-void (matches the tile-floor visual-style pass;
# generated at runtime, no imported wall art, original-IP guarantee intact).
# Reused as-is for the new multi-room layout (entry bay, hallway, workshop,
# secret closet)  --  it iterates whatever StaticBody2D children it finds, so
# carving out more rooms needed zero changes here, only more .tscn nodes.
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

# Stealth: a shadowed alcove the duo can duck into to let a patrol pass
# rather than fight through it  --  see CLAUDE.md "Stealth & awareness".
func _create_hiding_spot() -> void:
	var spot = HidingSpotScript.new()
	spot.position = HIDING_SPOT_POS
	add_child(spot)

# The broken pipe organ Quinn repairs  --  gated on having found its missing
# part (BrassPipeItem) in one of the workshop's loot boxes.
func _create_organ() -> void:
	_organ_sprite = Sprite2D.new()
	_organ_sprite.texture = PlaceholderArt.make_organ_texture(Color(0.5, 0.4, 0.2), 52, 64)
	_organ_sprite.position = ORGAN_POS
	add_child(_organ_sprite)

# The hidden lever and the wall segment it opens  --  grabs the references
# _build_walls() already textured so _reveal_secret_passage can disable the
# collider and fade the sprite, revealing the closet behind it.
func _create_secret_passage() -> void:
	_secret_wall_shape = _secret_wall.get_node("CollisionShape2D")
	for child in _secret_wall.get_children():
		if child is Sprite2D:
			_secret_wall_sprite = child
			break
	var lever := Sprite2D.new()
	lever.texture = PlaceholderArt.make_gate_texture(Color(0.45, 0.45, 0.52), 16, 22)
	lever.position = LEVER_POS
	add_child(lever)

func _open_secret_passage(animate: bool) -> void:
	_secret_wall_shape.disabled = true
	if animate:
		var tween := create_tween()
		tween.tween_property(_secret_wall_sprite, "modulate:a", 0.0, 0.6)
	else:
		_secret_wall_sprite.modulate.a = 0.0
	for box in _loot_boxes:
		if box.position == SECRET_LOOT_POS:
			box.visible = true

func _reveal_secret_passage() -> void:
	_secret_revealed = true
	_open_secret_passage(true)
	Audio.play("special")
	GameManager.set_level_flag(LOCATION_ID, "secret_revealed", true)

# Collectibles vertical slice (see CLAUDE.md "Collectibles & Inventory"):
# two workshop-floor boxes (the organ's missing brass pipe, a junk/lore bent
# spoon) plus a third  --  spare_clockwork_gear  --  waiting in the secret closet,
# hidden (not just locked) until the passage is revealed so it can't be seen
# through the wall it sits behind.
func _create_loot_boxes() -> void:
	var pipe_box = LootBoxScript.new()
	pipe_box.setup(BrassPipeItem, PIPE_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[0], false))
	add_child(pipe_box)
	_loot_boxes.append(pipe_box)

	var spoon_box = LootBoxScript.new()
	spoon_box.setup(BentSpoonItem, SPOON_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[1], false))
	add_child(spoon_box)
	_loot_boxes.append(spoon_box)

	var gear_box = LootBoxScript.new()
	gear_box.setup(SpareGearItem, SECRET_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[2], false))
	gear_box.visible = GameManager.get_level_flag(LOCATION_ID, "secret_revealed", false)
	add_child(gear_box)
	_loot_boxes.append(gear_box)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

func _on_special_used(char_name: String) -> void:
	var p: Player = quinn if char_name == "Quinn" else erin
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if char_name == "Quinn" and not _secret_revealed and quinn.global_position.distance_to(LEVER_POS) < LEVER_RADIUS:
		_reveal_secret_passage()
		return
	if char_name == "Quinn" and not _organ_repaired and quinn.global_position.distance_to(ORGAN_POS) < ORGAN_RADIUS:
		if GameManager.has_item("Quinn", BrassPipeItem.id) or GameManager.has_item("Erin", BrassPipeItem.id):
			_organ_repaired = true
			_organ_sprite.modulate = Color(0.4, 1.0, 0.5)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "organ_repaired", true)
	elif GameManager.try_use_whistle():
		Audio.play("special")

func _spawn() -> void:
	_add(GRUNT_SCENE,  Vector2(700.0, 120.0))
	_add(GRUNT_SCENE,  Vector2(950.0, 300.0))
	_add(GRUNT_SCENE,  Vector2(700.0, 460.0))
	_add(RUNNER_SCENE, Vector2(1050.0, 150.0))
	_add(RUNNER_SCENE, Vector2(620.0, 380.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

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
	if _enemies_cleared and _organ_repaired and not _cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "WORKSHOP CLEARED!\n\nThe organ breathes again  --  and somewhere\nbehind it, a door creaks open.\n\nPress ENTER for the Church"
		clear_label.visible = true
	if _cleared and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location(LOCATION_ID)
		TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")

# Doorway-triggered exit  --  distinct from the clear-overlay's "press ENTER"
# exit above. Per the user's choice, the duo can walk out at any time, cleared
# or not; complete_location is idempotent, so calling it here when _cleared is
# already true (e.g. they cleared it, then walked out instead of pressing
# ENTER) never double-grants anything.
func _exit_to_overworld() -> void:
	if _cleared:
		GameManager.complete_location(LOCATION_ID)
	TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")

func _update_hint() -> void:
	if _cleared:
		hint_label.text = ""
	elif not _enemies_cleared:
		hint_label.text = "Workshop hands haven't clocked you yet  --  clear them out, and check the crates for loose parts"
	elif not _organ_repaired:
		hint_label.text = "Quinn: the organ is missing a part  --  find it in a crate, then approach the organ and press G to repair it"
	else:
		hint_label.text = ""
