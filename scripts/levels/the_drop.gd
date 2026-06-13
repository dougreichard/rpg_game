extends Node2D

const LOCATION_ID: String = "the_drop"

# Tile-mapped floor palette  --  sandy landing-site tones (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.36, 0.34, 0.30)
const FLOOR_ACCENT_COLOR: Color = Color(0.58, 0.40, 0.30)
const FLOOR_COLS: int = 18
const FLOOR_ROWS: int = 17
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
# Synty 2.5D drop zone (see docs/synty_2_5d_art_plan.md): dirt clearing + wood
# fence; a grove of Synty trees/bushes. Landing wreckage = Synty rubble.
const SYNTY_FLOOR: String = "res://assets/art/tiles/synty_floor_dirt.png"
const SYNTY_WALL: String = "res://assets/art/tiles/synty_wall_wood.png"
const LANDING_BILLBOARD: String = "res://assets/art/synty/props/rubble.png"
# [name, x, y, on-screen height px] grove dressing.
const DROP_PROPS: Array = [
	["tree_01", 110, 210, 72],
	["tree_pine", 470, 175, 78],
	["tree_01", 500, 470, 68],
	["bush_01", 150, 470, 26],
	["bush_01", 360, 490, 26],
]
const FLOOR_ACCENT_PERIOD: int = 4

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/Runner.tscn")
const BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/Brute.tscn")
const HidingSpotScript: Script = preload("res://scripts/systems/hiding_spot.gd")
const HIDING_SPOT_POS := Vector2(460.0, 460.0)
const ScoutPairScript: Script = preload("res://scripts/systems/scout_pair_companion.gd")
# Frosty  --  Evan's general-purpose combat distractor (see CLAUDE.md "Evan's Animals").
# Priority over William & Mary: when the ground crew is still up, Evan's away-from-
# landing Special sends Frosty to stagger; once the floor is clear, the puzzle
# companion slot opens to William & Mary's two-point landing-brace move.
const AnimalCompanionScript: Script = preload("res://scripts/systems/animal_companion.gd")
const FROSTY_COLOR := Color(0.95, 0.95, 0.95)
const FROSTY_COOLDOWN: float = 3.0

const CHUTE_POS := Vector2(360.0, 110.0)
const CHUTE_RADIUS: float = 64.0
const LANDING_POS := Vector2(340.0, 330.0)
const LANDING_RADIUS: float = 64.0

const WILLIAM_TARGET_POS := Vector2(290.0, 330.0)
const MARY_TARGET_POS := Vector2(390.0, 330.0)
const WILLIAM_COLOR := Color(0.82, 0.78, 0.72)
const MARY_COLOR := Color(0.70, 0.62, 0.56)
const SCOUT_PAIR_COOLDOWN: float = 4.0

# Collectibles: lucky rabbit's foot keychain (junk  --  "does nothing for the
# rabbits or anyone", an exact joke fit given William & Mary appear here) and
# Evan's movie ticket  --  see CLAUDE.md "Collectibles & Inventory".
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const RabbitFootItem: ItemData  = preload("res://data/items/rabbits_foot_keychain.tres")
const TicketEvanItem: ItemData  = preload("res://data/items/ticket_evan.tres")
const FOOT_LOOT_POS   := Vector2(430.0, 380.0)
const TICKET_LOOT_POS := Vector2(200.0, 140.0)
const LOOT_FLAG_KEYS  := ["foot_loot_open", "ticket_loot_open"]

# Doorway: the level's entrance/exit  --  see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo touches down right beside it in the Touchdown
# Clearing; walking away and back exits to the overworld at any time, cleared
# or not.
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(160.0, 490.0)

const DialogBoxScript: Script    = preload("res://scripts/ui/dialog_box.gd")
const DialogTreeScript: Script   = preload("res://scripts/systems/dialog_tree.gd")
const SpeechBubbleScript: Script = preload("res://scripts/systems/speech_bubble.gd")

const RIO_BUBBLE_MIN  : float = 7.0
const RIO_BUBBLE_MAX  : float = 14.0
const RIO_BUBBLE_DUR  : float = 3.5
const RIO_BUBBLE_LINES: Array[String] = [
	"That marquee sign... it's pointing somewhere.",
	"I've seen stranger landings.",
	"Place used to be busier than this.",
]

const RIO_COLOR := Color(0.31, 0.39, 0.20)
const RIO_POS := Vector2(500.0, 430.0)
const RIO_RADIUS: float = 64.0
static var RIO_INTRO_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"Rio. I was crew until I saw the manifest — I'm not their problem anymore.\"",
	"\"Evan: that wreckage has to move before we get out. Ethan: the chute release jammed on impact — hack it in the snag grove north of here.\""
])
static var RIO_REMINDER_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"Evan clears the wreckage, Ethan hacks the jammed chute release — both needed.\""
])
static var RIO_AFTER_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"That's our way out. The marquee sign I saw before the drop — it had his name on it. Move.\""
])

# Multi-room layout bounding box  --  a literal AERIAL-DESCENT-TO-GROUND-PHASE
# layout matching this location's two-phase spec ("a kinetic aerial descent,
# then a standard brawler ground phase"): the duo touches down in a wide
# Touchdown Clearing (south  --  Doorway, spawn, the wreckage Evan must clear or
# send William & Mary to brace), a narrow Corridor (the very gap that wreckage
# blocks) leads north to the Snag Grove (the parachute's jammed release,
# tangled in branches  --  Ethan's hack). The wreckage physically gates the path
# OUT of the clearing toward "a marquee in the distance"  --  the spec's intel
# payoff  --  making "the landing zone is locked until the right character steers
# to it" a literal chokepoint rather than a flavor line. Feeds the camera's
# pan limits  --  see CLAUDE.md "Doorways, camera-follow & multi-room levels".
# Recompute if the wall layout changes.
const CAMERA_LIMIT_LEFT: int = 24
const CAMERA_LIMIT_TOP: int = 24
const CAMERA_LIMIT_RIGHT: int = 576
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
var _chute_hacked: bool = false
var _landing_cleared: bool = false
var _cleared: bool = false
var _chute_sprite: Sprite2D
var _landing_sprite: Sprite2D
var _loot_boxes: Array = []
var _doorway = null

var _william = null
var _mary = null
var _scout_pair_cooldown_timer: float = 0.0
var _frosty_cooldown_timer: float = 0.0
var _rio_sprite: AnimatedSprite2D
var _rio_bubble        = null
var _rio_bubble_timer: float = 0.0
var _dialog_box = null
var _rio_met: bool = false

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
	_create_chute()
	_create_landing()
	_create_loot_boxes()
	_create_hiding_spot()
	_create_doorway()
	_create_rio_npc()
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
# left off: skip respawning a cleared floor and restore both prop palettes
# (the William & Mary scout pair is a transient mid-session aid  --  it doesn't
# need to survive a re-entry, only the _landing_cleared outcome it produces).
func _restore_progress() -> void:
	_enemies_cleared = GameManager.get_level_flag(LOCATION_ID, "enemies_cleared", false)
	_chute_hacked = GameManager.get_level_flag(LOCATION_ID, "chute_hacked", false)
	_landing_cleared = GameManager.get_level_flag(LOCATION_ID, "landing_cleared", false)
	_rio_met = GameManager.get_level_flag(LOCATION_ID, "rio_met", false)
	if _chute_hacked:
		_chute_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _landing_cleared:
		_landing_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _enemies_cleared:
		_spawned = true
	else:
		_spawn()
	if _enemies_cleared and _chute_hacked and _landing_cleared:
		_cleared = true
		hint_label.text = ""
		clear_label.text = "TOUCHDOWN!\n\nA hostile ground crew scatters  --  and a marquee\nin the distance bears Uncle Doug's name.\n\nPress ENTER for the Map"
		clear_label.visible = true

# Tile-mapped retro floor (Zelda-style two-tone grid), generated at runtime
# via PlaceholderArt to keep the original-IP guarantee  --  no imported tile art.
# Wall art: a Sprite2D per StaticBody2D wall, sized to its exact
# CollisionShape2D rect and textured via PlaceholderArt.make_wall_texture  --  a
# darker stone tone of the floor's base color, so the room reads as a bordered
# space instead of walls-on-a-void (matches the tile-floor visual-style pass;
# generated at runtime, no imported wall art, original-IP guarantee intact).
# Iterates whatever StaticBody2D children it finds  --  the Touchdown Clearing +
# Corridor + Snag Grove layout (12 wall segments) needed zero changes here,
# only more .tscn nodes.
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

func _create_chute() -> void:
	_chute_sprite = Sprite2D.new()
	_chute_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.5, 0.42, 0.18), 44, 56)
	_chute_sprite.position = CHUTE_POS
	add_child(_chute_sprite)

func _create_landing() -> void:
	_landing_sprite = Sprite2D.new()
	if not _apply_synty_billboard(_landing_sprite, LANDING_BILLBOARD, 46.0):
		_landing_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.4, 0.4, 0.44), 56, 48)
	_landing_sprite.position = LANDING_POS
	add_child(_landing_sprite)
	# Grove dressing (reused Synty tree/bush billboards).
	for p: Array in DROP_PROPS:
		var spr := Sprite2D.new()
		if _apply_synty_billboard(spr, "res://assets/art/synty/props/%s.png" % p[0], float(p[3])):
			spr.position = Vector2(float(p[1]), float(p[2]))
			add_child(spr)

func _create_loot_boxes() -> void:
	var foot_box = LootBoxScript.new()
	foot_box.setup(RabbitFootItem, FOOT_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[0], false))
	add_child(foot_box)
	_loot_boxes.append(foot_box)

	var ticket_box = LootBoxScript.new()
	ticket_box.setup(TicketEvanItem, TICKET_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[1], false))
	add_child(ticket_box)
	_loot_boxes.append(ticket_box)

# Stealth: a shadowed thicket in the Touchdown Clearing's far corner  --  the
# ground crew's patrol loop crosses right by it, so ducking in to let one pass
# is a real option before committing to the brawl  --  see CLAUDE.md "Stealth &
# awareness".
func _create_hiding_spot() -> void:
	var spot = HidingSpotScript.new()
	spot.position = HIDING_SPOT_POS
	add_child(spot)

func _create_rio_npc() -> void:
	_rio_sprite = AnimatedSprite2D.new()
	if not PlaceholderArt.apply_npc_billboard(_rio_sprite, "rio"):
		var loaded: SpriteFrames = SpriteLoader.try_load_npc("rio")
		_rio_sprite.sprite_frames = loaded if loaded != null else PlaceholderArt.make_player_frames(RIO_COLOR, "")
		_rio_sprite.scale = Vector2(SpriteLoader.NPC_SPRITE_SCALE, SpriteLoader.NPC_SPRITE_SCALE) if loaded != null else Vector2.ONE
	_rio_sprite.play("idle")
	_rio_sprite.position = RIO_POS
	add_child(_rio_sprite)
	_rio_bubble = SpeechBubbleScript.new()
	_rio_bubble.position = RIO_POS + Vector2(0.0, -52.0)
	add_child(_rio_bubble)
	_rio_bubble_timer = randf_range(RIO_BUBBLE_MIN, RIO_BUBBLE_MAX)
	var dialog_layer := CanvasLayer.new()
	dialog_layer.layer = 19
	add_child(dialog_layer)
	_dialog_box = DialogBoxScript.new()
	dialog_layer.add_child(_dialog_box)
	_dialog_box.closed.connect(_on_rio_dialog_closed)

func _talk_to_rio() -> void:
	var p: Player = GameManager.active_player
	var tree: Dictionary
	if _cleared:
		tree = RIO_AFTER_TREE
	elif not _rio_met:
		tree = RIO_INTRO_TREE
	else:
		tree = RIO_REMINDER_TREE
	_dialog_box.open("Rio", RIO_COLOR, tree, "start", p.data.character_name)

func _on_rio_dialog_closed(_effects: Array) -> void:
	if not _rio_met:
		_rio_met = true
		GameManager.set_level_flag(LOCATION_ID, "rio_met", true)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

# William & Mary  --  an alternate way to clear the landing site: Evan's Special,
# used away from the wreckage, calls in the rabbit pair instead of muscling it
# himself (his "works with animals" strength, same as he flexes via Calvin &
# Coolidge elsewhere). They scurry to flanking gaps either side of the wreck  -- 
# squeezing through where Evan can't fit  --  and brace it from both sides at
# once; only holding BOTH points simultaneously frees the landing site, the
# "two-point puzzle a single companion can't solve" from their CLAUDE.md spec.
func _summon_scout_pair() -> void:
	_william = ScoutPairScript.new()
	_william.setup(evan.global_position, WILLIAM_TARGET_POS, WILLIAM_COLOR)
	add_child(_william)
	_mary = ScoutPairScript.new()
	_mary.setup(evan.global_position, MARY_TARGET_POS, MARY_COLOR)
	add_child(_mary)
	_scout_pair_cooldown_timer = SCOUT_PAIR_COOLDOWN * _cd_scale
	GameManager.companion_summoned.emit("william_mary")

func _check_scout_pair_holding() -> void:
	if _landing_cleared or _william == null or _mary == null:
		return
	if not is_instance_valid(_william) or not is_instance_valid(_mary):
		_william = null
		_mary = null
		return
	if _william.is_holding and _mary.is_holding:
		_landing_cleared = true
		_landing_sprite.modulate = Color(0.4, 1.0, 0.5)
		Audio.play("special")
		GameManager.set_level_flag(LOCATION_ID, "landing_cleared", true)

func _spawn() -> void:
	_add(GRUNT_SCENE,  Vector2(200.0, 380.0))
	_add(RUNNER_SCENE, Vector2(450.0, 110.0))
	_add(BRUTE_SCENE,  Vector2(460.0, 380.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _on_special_used(char_name: String) -> void:
	if _dialog_box.is_open():
		return
	var p: Player = evan if char_name == "Evan" else ethan
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if p.global_position.distance_to(RIO_POS) < RIO_RADIUS:
		_talk_to_rio()
		return
	if char_name == "Ethan" and not _chute_hacked:
		if ethan.global_position.distance_to(CHUTE_POS) < CHUTE_RADIUS:
			_chute_hacked = true
			_chute_sprite.modulate = Color(0.4, 1.0, 0.5)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "chute_hacked", true)
	elif char_name == "Evan":
		if not _landing_cleared and evan.global_position.distance_to(LANDING_POS) < LANDING_RADIUS:
			_landing_cleared = true
			_landing_sprite.modulate = Color(0.4, 1.0, 0.5)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "landing_cleared", true)
		elif _frosty_cooldown_timer == 0.0:
			var target = _nearest_enemy(evan.global_position)
			if target != null:
				_summon_frosty(target)
			elif not _landing_cleared and _scout_pair_cooldown_timer == 0.0 and _william == null and _mary == null:
				_summon_scout_pair()
	elif GameManager.try_use_whistle():
		Audio.play("special")

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

func _process(delta: float) -> void:
	_scout_pair_cooldown_timer = maxf(_scout_pair_cooldown_timer - delta, 0.0)
	_frosty_cooldown_timer = maxf(_frosty_cooldown_timer - delta, 0.0)
	_check_scout_pair_holding()
	if is_instance_valid(_rio_bubble) and not _dialog_box.is_open():
		_rio_bubble_timer -= delta
		if _rio_bubble_timer <= 0.0:
			_rio_bubble_timer = randf_range(RIO_BUBBLE_MIN, RIO_BUBBLE_MAX)
			_rio_bubble.show_text(
				RIO_BUBBLE_LINES[randi() % RIO_BUBBLE_LINES.size()],
				RIO_BUBBLE_DUR)
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
	if _enemies_cleared and _chute_hacked and _landing_cleared and not _cleared:
		_cleared = true
		Audio.play("puzzle_complete")
		Audio.play_music("victory")
		hint_label.text = ""
		clear_label.text = "TOUCHDOWN!\n\nA hostile ground crew scatters  --  and a marquee\nin the distance bears Uncle Doug's name.\n\nPress ENTER for the Map"
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
		hint_label.text = "Ground crew nearby — talk to Rio, then take them out  [ Evan: press G for Frosty ]"
	elif not _landing_cleared:
		hint_label.text = "Evan: clear the wreckage  [ approach it, press G — or press G elsewhere for William & Mary ]"
	elif not _chute_hacked:
		hint_label.text = "Ethan: hack the jammed chute release in the snag grove  [ approach it, press G ]"
	else:
		hint_label.text = ""
