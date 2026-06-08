extends Node2D

const LOCATION_ID: String = "underground"

# Tile-mapped floor palette — dark, earthy maintenance-tunnel tones (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.20, 0.20, 0.19)
const FLOOR_ACCENT_COLOR: Color = Color(0.38, 0.35, 0.28)
const FLOOR_COLS: int = 30
const FLOOR_ROWS: int = 17
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/Runner.tscn")
const HidingSpotScript: Script = preload("res://scripts/systems/hiding_spot.gd")
const TwinkleScript: Script = preload("res://scripts/systems/twinkle_companion.gd")
# Frosty — Evan's general-purpose combat distractor (see CLAUDE.md "Evan's Animals").
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

# Collectibles: rusty key (unlocks the junction shortcut door — see below),
# security badge (pre-fills one hatch pip if held on entry — CLAUDE.md:
# "auto-fills one pip of Ethan's hatch hack"), pocket lantern (collectible-only
# this pass) — see CLAUDE.md "Collectibles & Inventory".
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const RustyKeyItem: ItemData     = preload("res://data/items/rusty_key.tres")
const SecurityBadgeItem: ItemData = preload("res://data/items/security_badge.tres")
const PocketLanternItem: ItemData = preload("res://data/items/pocket_lantern.tres")
const KEY_LOOT_POS    := Vector2(560.0, 330.0)
const BADGE_LOOT_POS  := Vector2(820.0, 350.0)
const LANTERN_LOOT_POS := Vector2(300.0, 240.0)
const LOOT_FLAG_KEYS  := ["key_loot_open", "badge_loot_open", "lantern_loot_open"]
const PIP_RADIUS: float = 5.0
const PIP_SPACING: float = 16.0
const PIP_OFFSET_Y: float = -38.0
const PIP_FLASH_DURATION: float = 0.3

# Doorway: the level's entrance/exit — see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo spawns beside it in the south entry corridor;
# walking away and back exits to the overworld at any time, cleared or not.
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
# Shortcut door — in the junction chamber, on the north wall. Opened once with
# the rusty_key (consumed on use); exits to the overworld immediately without
# needing to clear enemies or hack the hatch — the "hidden route" payoff the
# CLAUDE.md spec describes for this location.
const SHORTCUT_DOOR_POS := Vector2(480.0, 238.0)
const SHORTCUT_DOOR_RADIUS: float = 52.0

const DOORWAY_POS := Vector2(480.0, 500.0)

# Multi-room layout bounding box — a literal BRANCHING MAZE matching "dark
# maze of maintenance tunnels": a south entry corridor opens onto a central
# junction chamber, which forks into a west tunnel (dead-ending at Evan's
# rubble) and an east tunnel (dead-ending at Ethan's hatch). Feeds the
# camera's pan limits — see CLAUDE.md "Doorways, camera-follow & multi-room
# levels". Recompute if the wall layout changes. Note the unusually high
# CAMERA_LIMIT_TOP (184, not the standard locations' 24): the maze's
# northernmost wall (the junction chamber's north face) sits well below the
# room's nominal top — there's no content above it, so the camera shouldn't
# pan there.
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
var _loot_boxes: Array = []
var _doorway = null

var _hatch_progress: int = 0
var _pip_flash: float = 0.0
var _twinkle_cooldown_timer: float = 0.0
var _frosty_cooldown_timer: float = 0.0

var _cd_scale: float = 1.0
func _ready() -> void:
	_build_floor()
	_build_walls()
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
# multi-room levels". Reads back exactly the booleans (and the hatch's
# in-progress pip count — partial hacking progress is worth preserving for
# a multi-step gate, not just the final pass/fail) this level already tracks
# locally, so re-entering after a Doorway exit picks up where the duo left
# off: skip respawning a cleared floor and restore the rubble's cleared
# palette plus the hatch's pip progress/hacked palette.
func _restore_progress() -> void:
	_enemies_cleared = GameManager.get_level_flag(LOCATION_ID, "enemies_cleared", false)
	_rubble_cleared = GameManager.get_level_flag(LOCATION_ID, "rubble_cleared", false)
	_hatch_hacked = GameManager.get_level_flag(LOCATION_ID, "hatch_hacked", false)
	_hatch_progress = GameManager.get_level_flag(LOCATION_ID, "hatch_progress", 0)
	# Security badge pre-fills the first hatch pip if either character holds one
	# and no progress has been made yet — see CLAUDE.md "Collectibles & Inventory".
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
	if _enemies_cleared and _rubble_cleared and _hatch_hacked:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "TUNNELS MAPPED!\n\nA hidden route opens between locations.\n\nPress ENTER for the Map"
		clear_label.visible = true

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
# Iterates whatever StaticBody2D children it finds — the branching-maze
# layout (16 wall segments forming a corridor/junction/two-tunnel network)
# needed zero changes here, only more .tscn nodes.
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

func _create_rubble() -> void:
	_rubble_sprite = Sprite2D.new()
	_rubble_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.34, 0.3, 0.28), 60, 44)
	_rubble_sprite.position = RUBBLE_POS
	add_child(_rubble_sprite)

func _create_shortcut_door() -> void:
	_shortcut_door_sprite = Sprite2D.new()
	_shortcut_door_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.38, 0.28, 0.22), 32, 48)
	_shortcut_door_sprite.position = SHORTCUT_DOOR_POS
	add_child(_shortcut_door_sprite)

func _create_hatch() -> void:
	_hatch_sprite = Sprite2D.new()
	_hatch_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.26, 0.32, 0.36), 44, 44)
	_hatch_sprite.position = HATCH_POS
	add_child(_hatch_sprite)

# Stealth: a shadowed alcove sitting in the junction chamber — the crossroads
# every patrol must pass through, so ducking in here to let one go by is
# always a meaningful choice regardless of which tunnel the duo is heading for.
func _create_hiding_spot() -> void:
	var spot = HidingSpotScript.new()
	spot.position = HIDING_SPOT_POS
	add_child(spot)

func _create_loot_boxes() -> void:
	var key_box = LootBoxScript.new()
	key_box.setup(RustyKeyItem, KEY_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[0], false))
	add_child(key_box)
	_loot_boxes.append(key_box)

	var badge_box = LootBoxScript.new()
	badge_box.setup(SecurityBadgeItem, BADGE_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[1], false))
	add_child(badge_box)
	_loot_boxes.append(badge_box)

	var lantern_box = LootBoxScript.new()
	lantern_box.setup(PocketLanternItem, LANTERN_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[2], false))
	add_child(lantern_box)
	_loot_boxes.append(lantern_box)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

# Stealth: Evan's Special, used away from the rubble, sends Twinkle trotting
# off to bark — a noise burst (GameManager.emit_noise) that lures patrolling
# or investigating guards toward her racket and away from the duo's actual
# position (cooldown-gated so it can't be spammed every frame).
func _summon_frosty(target: Enemy) -> void:
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

func _summon_twinkle() -> void:
	var twinkle = TwinkleScript.new()
	twinkle.setup(evan, evan.facing)
	add_child(twinkle)
	_twinkle_cooldown_timer = TWINKLE_COOLDOWN * _cd_scale

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
	var p: Player = evan if char_name == "Evan" else ethan
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	# Rusty key shortcut door — usable by either character in the duo
	if p.global_position.distance_to(SHORTCUT_DOOR_POS) < SHORTCUT_DOOR_RADIUS:
		if GameManager.has_item("Evan", RustyKeyItem.id) or GameManager.has_item("Ethan", RustyKeyItem.id):
			var holder: String = "Evan" if GameManager.has_item("Evan", RustyKeyItem.id) else "Ethan"
			GameManager.consume_item(holder, RustyKeyItem.id)
			_shortcut_door_sprite.modulate = Color(0.4, 1.0, 0.5)
			Audio.play("special")
			_exit_to_overworld()
			return
		else:
			hint_label.text = "This door is locked — find the rusty key"
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
	queue_redraw()
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
		hint_label.text = ""
		clear_label.text = "TUNNELS MAPPED!\n\nA hidden route opens between locations.\n\nPress ENTER for the Map"
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
		hint_label.text = "Patrols haven't spotted you — sneak past or strike first  [ Evan: press G away from the rubble — sends Frosty charging at the nearest guard (enemies nearby) or Twinkle off barking to lure patrols away (no enemies in range) ]"
	elif not _rubble_cleared:
		hint_label.text = "Evan: force the blocked passage open — west tunnel  [ approach the rubble, press G ]"
	elif not _hatch_hacked:
		hint_label.text = "Ethan: the lock needs %d hacking passes — east tunnel, approach it and press G repeatedly (%d/%d so far)" % [HATCH_PRESSES_REQUIRED, _hatch_progress, HATCH_PRESSES_REQUIRED]
	else:
		hint_label.text = ""
