extends Node2D

const LOCATION_ID: String = "carnival"

# Tile-mapped floor palette  --  festive midway purple with gold accents (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.34, 0.29, 0.33)
const FLOOR_ACCENT_COLOR: Color = Color(0.78, 0.55, 0.24)
const FLOOR_COLS: int = 30
const FLOOR_ROWS: int = 17
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 2)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 2)
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/Brute.tscn")
const HidingSpotScript: Script = preload("res://scripts/systems/hiding_spot.gd")
const HIDING_SPOT_POS := Vector2(150.0, 460.0)

# Guinea pigs  --  Erin's crowd-cover companion (see CLAUDE.md "Evan's Animals"):
# floods the midway with scurrying creatures, drawing every carnie's gaze as
# cover for the duo to slip through or set up a flanking attack.
const GuineaPigSwarmScript: Script = preload("res://scripts/systems/guinea_pig_swarm.gd")
const GUINEA_PIG_COOLDOWN: float = 5.0

const RIDE_POS := Vector2(380.0, 340.0)
const RIDE_RADIUS: float = 64.0

# Collectibles: backstage pass (lets Quinn bypass the curtain guard instead of
# requiring Erin), Erin's movie ticket, and a junk torn ticket stub  --  see
# CLAUDE.md "Collectibles & Inventory".
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const BackstagePassItem: ItemData  = preload("res://data/items/backstage_pass.tres")
const TicketErinItem: ItemData     = preload("res://data/items/ticket_erin.tres")
const TicketStubItem: ItemData     = preload("res://data/items/ticket_stub_torn.tres")
const PASS_LOOT_POS    := Vector2(250.0, 400.0)
const TICKET_LOOT_POS  := Vector2(550.0, 200.0)
const STUB_LOOT_POS    := Vector2(280.0, 460.0)
const LOOT_FLAG_KEYS   := ["pass_loot_open", "ticket_loot_open", "stub_loot_open"]

# The backstage gate: a curtain/rope barrier that graduated from a purely
# cosmetic guard sprite-recolor to a literal StaticBody2D collider sealing the
# only passage into the backstage alcove  --  the FIFTH cosmetic-to-collider
# upgrade of the rollout (Iron & Strings' barbell, Recording Studio's booth
# door, Harbor & Docks' container, Library & Archive's librarian's desk). Erin
# talks the guard down right at the curtain (`BACKSTAGE_POS` == the gate's own
# position)  --  one Special press both solves "Erin talks her way into the
# restricted backstage" (this location's spec line) AND physically raises the
# barrier, the same one-action-two-payoffs shape as the Recording Studio's
# console/door and the Library's desk/passage. Its clear-animation is a FIFTH
# distinct flavor  --  a parallel upward slide + vertical scale-to-near-zero via
# create_tween(), reading as a stage curtain hoisted up into the rigging  -- 
# distinct from the gym's horizontal slide, the studio's vertical slide, the
# docks' hoist-and-swing, and the library's scale-down+fade.
const BACKSTAGE_POS := Vector2(670.0, 152.0)
const BACKSTAGE_RADIUS: float = 64.0
const BACKSTAGE_GATE_RISE_OFFSET := Vector2(0.0, -90.0)
const BACKSTAGE_GATE_SCALE_TARGET := Vector2(1.0, 0.05)
const BACKSTAGE_GATE_COLOR := Color(0.5, 0.18, 0.4)
const DOUG_POSTER_COLOR := Color(0.75, 0.65, 0.5)
const DOUG_POSTER_POS := Vector2(670.0, 86.0)

# Doorway: the level's entrance/exit  --  see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo spawns beside it on the midway; walking away
# and back exits to the overworld at any time, cleared or not.
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(140.0, 340.0)

# Multi-room layout bounding box (open midway -> backstage alcove, sealed by
# the curtain gate). Feeds the camera's pan limits  --  see CLAUDE.md "Doorways,
# camera-follow & multi-room levels". Recompute if the wall layout changes.
const CAMERA_LIMIT_LEFT: int = 24
const CAMERA_LIMIT_TOP: int = 24
const CAMERA_LIMIT_RIGHT: int = 936
const CAMERA_LIMIT_BOTTOM: int = 536
const CAMERA_SMOOTHING_SPEED: float = 5.0

@onready var camera: Camera2D = $Camera2D
@onready var quinn: Player = $Players/Quinn
@onready var erin: Player = $Players/Erin
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel
@onready var _backstage_gate: StaticBody2D = $BackstageGate

var _spawned: bool = false
var _enemies_cleared: bool = false
var _ride_repaired: bool = false
var _backstage_talked: bool = false
var _cleared: bool = false
var _ride_sprite: Sprite2D
var _gate_shape: CollisionShape2D
var _gate_sprite: Sprite2D
var _guard_sprite: AnimatedSprite2D
var _doug_poster: Sprite2D
var _loot_boxes: Array = []
var _doorway = null
var _guinea_pig_cooldown_timer: float = 0.0

var _cd_scale: float = 1.0
func _ready() -> void:
	_build_floor()
	_build_walls()
	GameManager.register_players_with_preference(quinn, erin)
	hud.setup(quinn, erin)
	_cd_scale = GameManager.companion_cooldown_scale()
	quinn.special_used.connect(_on_special_used)
	erin.special_used.connect(_on_special_used)
	_create_ride()
	_create_backstage_gate()
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
# left off: skip respawning a cleared floor and restore the ride's repaired
# palette plus the curtain's raised state (collider disabled, sprite hoisted
# and flattened).
func _restore_progress() -> void:
	_enemies_cleared = GameManager.get_level_flag(LOCATION_ID, "enemies_cleared", false)
	_ride_repaired = GameManager.get_level_flag(LOCATION_ID, "ride_repaired", false)
	_backstage_talked = GameManager.get_level_flag(LOCATION_ID, "backstage_talked", false)
	if _ride_repaired:
		_ride_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _backstage_talked:
		_raise_curtain(false)
	if _enemies_cleared:
		_spawned = true
	else:
		_spawn()
	if _enemies_cleared and _ride_repaired and _backstage_talked:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "MIDWAY CLEARED!\n\nBackstage, a poster shows Uncle Doug's face.\n\nPress ENTER for the Map"
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
# Iterates whatever StaticBody2D children it finds  --  the midway/alcove layout
# needed zero changes here, only more .tscn nodes (the BackstageGate is a
# sibling of $Walls, not a child, so it keeps its own bespoke curtain-purple
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

func _create_ride() -> void:
	_ride_sprite = Sprite2D.new()
	_ride_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.55, 0.32, 0.18), 56, 56)
	_ride_sprite.position = RIDE_POS
	add_child(_ride_sprite)

# Grabs the .tscn-placed BackstageGate body's collider and dresses it with a
# curtain-purple bordered-rectangle texture  --  visually distinct from the
# midway's walls (reads as a velvet rope/curtain barrier, not masonry). A
# faded portrait poster sits behind it (always present, naturally hidden by
# the opaque curtain sprite until it rises)  --  the literal "poster shows Uncle
# Doug's face" the clear message promises, mirroring how the Recording
# Studio's booth door reveals an _ethan_prop on its slide.
func _create_backstage_gate() -> void:
	_gate_shape = _backstage_gate.get_node("CollisionShape2D")
	_gate_sprite = Sprite2D.new()
	_gate_sprite.texture = PlaceholderArt.make_gate_texture(BACKSTAGE_GATE_COLOR, 300, 16)
	_backstage_gate.add_child(_gate_sprite)
	# Carnival guard sprite — stands at the curtain in idle until talked down
	_guard_sprite = AnimatedSprite2D.new()
	var loaded: SpriteFrames = SpriteLoader.try_load_npc("carnival_guard")
	_guard_sprite.sprite_frames = loaded if loaded != null else PlaceholderArt.make_player_frames(Color(0.8, 0.2, 0.2), "")
	_guard_sprite.scale = Vector2(SpriteLoader.NPC_SPRITE_SCALE, SpriteLoader.NPC_SPRITE_SCALE) if loaded != null else Vector2.ONE
	_guard_sprite.play("idle")
	_guard_sprite.position = BACKSTAGE_POS + Vector2(0.0, 8.0)
	add_child(_guard_sprite)
	_doug_poster = Sprite2D.new()
	_doug_poster.texture = PlaceholderArt.make_gate_texture(DOUG_POSTER_COLOR, 32, 40)
	_doug_poster.position = DOUG_POSTER_POS
	add_child(_doug_poster)

func _raise_curtain(animate: bool) -> void:
	_gate_shape.disabled = true
	if animate:
		if is_instance_valid(_guard_sprite) and _guard_sprite.sprite_frames.has_animation("step_aside"):
			_guard_sprite.play("step_aside")
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_gate_sprite, "position", BACKSTAGE_GATE_RISE_OFFSET, 0.6)
		tween.tween_property(_gate_sprite, "scale", BACKSTAGE_GATE_SCALE_TARGET, 0.6)
		tween.tween_property(_guard_sprite, "position:x", BACKSTAGE_POS.x + 80.0, 0.7)
	else:
		_gate_sprite.position = BACKSTAGE_GATE_RISE_OFFSET
		_gate_sprite.scale = BACKSTAGE_GATE_SCALE_TARGET
		if is_instance_valid(_guard_sprite):
			_guard_sprite.position.x = BACKSTAGE_POS.x + 80.0
			_guard_sprite.modulate.a = 0.0

# Stealth: a shadowed alcove the duo can duck into to let a patrol pass
# rather than fight through it  --  see CLAUDE.md "Stealth & awareness".
func _create_hiding_spot() -> void:
	var spot = HidingSpotScript.new()
	spot.position = HIDING_SPOT_POS
	add_child(spot)

func _create_loot_boxes() -> void:
	var pass_box = LootBoxScript.new()
	pass_box.setup(BackstagePassItem, PASS_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[0], false))
	add_child(pass_box)
	_loot_boxes.append(pass_box)

	var ticket_box = LootBoxScript.new()
	ticket_box.setup(TicketErinItem, TICKET_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[1], false))
	add_child(ticket_box)
	_loot_boxes.append(ticket_box)

	var stub_box = LootBoxScript.new()
	stub_box.setup(TicketStubItem, STUB_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[2], false))
	add_child(stub_box)
	_loot_boxes.append(stub_box)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

func _spawn() -> void:
	_add(GRUNT_SCENE, Vector2(280.0, 250.0))
	_add(GRUNT_SCENE, Vector2(560.0, 420.0))
	_add(BRUTE_SCENE, Vector2(720.0, 460.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	var p: Player = quinn if char_name == "Quinn" else erin
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if char_name == "Quinn":
		if not _ride_repaired and quinn.global_position.distance_to(RIDE_POS) < RIDE_RADIUS:
			_ride_repaired = true
			_ride_sprite.modulate = Color(0.4, 1.0, 0.5)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "ride_repaired", true)
		elif not _backstage_talked and quinn.global_position.distance_to(BACKSTAGE_POS) < BACKSTAGE_RADIUS:
			if GameManager.has_item("Quinn", BackstagePassItem.id) or GameManager.has_item("Erin", BackstagePassItem.id):
				_backstage_talked = true
				_raise_curtain(true)
				Audio.play("special")
				GameManager.set_level_flag(LOCATION_ID, "backstage_talked", true)
	elif char_name == "Erin":
		if not _backstage_talked and erin.global_position.distance_to(BACKSTAGE_POS) < BACKSTAGE_RADIUS:
			_backstage_talked = true
			_raise_curtain(true)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "backstage_talked", true)
		elif _guinea_pig_cooldown_timer == 0.0:
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
	if _enemies_cleared and _ride_repaired and _backstage_talked and not _cleared:
		_cleared = true
		Audio.play("puzzle_complete")
		Audio.play_music("victory")
		hint_label.text = ""
		clear_label.text = "MIDWAY CLEARED!\n\nBackstage, a poster shows Uncle Doug's face.\n\nPress ENTER for the Map"
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
		hint_label.text = "The carnies haven't noticed you yet  --  work the midway quietly  [ Erin: press G to release the guinea pigs and flood the midway with chaos ]"
	elif not _ride_repaired:
		hint_label.text = "Quinn: repair the broken ride  [ approach it, press G ]"
	elif not _backstage_talked:
		hint_label.text = "Erin: talk your way past the curtain guard into the backstage  [ approach it, press G ]"
	else:
		hint_label.text = ""
