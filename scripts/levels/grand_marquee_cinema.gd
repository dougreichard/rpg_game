extends Node2D

const LOCATION_ID: String = "grand_marquee"

# Tile-mapped floor palette  --  rich theater red with gold accents (see CLAUDE.md "Tile-mapped floors")
const FLOOR_BASE_COLOR: Color = Color(0.30, 0.21, 0.23)
const FLOOR_ACCENT_COLOR: Color = Color(0.72, 0.55, 0.28)
const FLOOR_COLS: int = 20
const FLOOR_ROWS: int = 17
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4
# Synty 2.5D cinema (see docs/synty_2_5d_art_plan.md): carpet floor + walls;
# Office projector in the booth + couch seating. House organ stays PlaceholderArt.
const SYNTY_FLOOR: String = "res://assets/art/tiles/synty_floor_carpet.png"
const SYNTY_WALL: String = "res://assets/art/tiles/synty_wall_concrete.png"
const PROJECTOR_BILLBOARD: String = "res://assets/art/synty/props/projector.png"
# [name, x, y, on-screen height px] cinema dressing.
const CINEMA_PROPS: Array = [
	["couch", 270, 430, 40],
	["couch", 410, 430, 40],
	["plant", 110, 450, 40],
]

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/Grunt.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/enemies/Boss.tscn")
const HidingSpotScript: Script = preload("res://scripts/systems/hiding_spot.gd")
const HIDING_SPOT_POS := Vector2(540.0, 210.0)

const PROJECTOR_POS := Vector2(112.0, 260.0)
const PROJECTOR_RADIUS: float = 64.0
const ORGAN_POS := Vector2(400.0, 92.0)
const ORGAN_RADIUS: float = 64.0

# Collectibles: film reel is the "second item needed with the projector
# repair" per CLAUDE.md  --  wired as a hard gate on Quinn's projector puzzle
# (proximity + Special succeeds only if either character holds the reel).
# The 5-ticket check is the headline use case for the whole ticket system:
# all five character movie tickets must be held (across either duo member)
# for the level to be completable  --  see _has_all_tickets().
# See CLAUDE.md "Collectibles & Inventory".
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const FilmReelItem: ItemData   = preload("res://data/items/film_reel.tres")
const REEL_LOOT_POS := Vector2(185.0, 150.0)
const LOOT_FLAG_KEYS := ["reel_loot_open"]
const TicketQuinnItem: ItemData = preload("res://data/items/ticket_quinn.tres")
const TicketErinItem: ItemData  = preload("res://data/items/ticket_erin.tres")
const TicketEvanItem: ItemData  = preload("res://data/items/ticket_evan.tres")
const TicketBenItem: ItemData   = preload("res://data/items/ticket_ben.tres")
const TicketEthanItem: ItemData = preload("res://data/items/ticket_ethan.tres")

# Doorway: the level's entrance/exit  --  see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo arrives through the lobby; walking away and
# back exits at any time, cleared or not  --  see _exit_to_overworld for this
# finale location's destination branch (cleared -> ResultScreen, the endgame
# trigger; not yet cleared -> OverworldMap, the standard early-exit path).
const DialogBoxScript: Script = preload("res://scripts/ui/dialog_box.gd")
const DialogTreeScript: Script = preload("res://scripts/systems/dialog_tree.gd")
const SpeechBubbleScript: Script = preload("res://scripts/systems/speech_bubble.gd")

const USHER_BUBBLE_MIN  : float = 7.0
const USHER_BUBBLE_MAX  : float = 14.0
const USHER_BUBBLE_DUR  : float = 3.5
const USHER_BUBBLE_LINES: Array[String] = [
	"Tickets will be checked. All five.",
	"The cinema has standards, even now.",
	"I've been holding this door longer than I care to admit.",
]

const UNCLE_DOUG_COLOR := Color(0.70, 0.63, 0.48)
const UNCLE_DOUG_POS := Vector2(160.0, 260.0)  # PROJECTOR_POS + Vector2(48, 0)
const UNCLE_DOUG_RADIUS: float = 72.0

const UNCLE_DOUG_MEET_TREE: Dictionary = {
	"start": {
		"lines": ["\"I knew you'd find me. Took you long enough — I've been running this projector for three days.\""],
		"choices": [
			{"text": "\"What happened to you?\"", "next": "what_happened"},
			{"text": "\"We need to go. Now.\"", "next": "farewell"},
		]
	},
	"what_happened": {
		"lines": [
			"\"The Consortium locked me in here. They didn't want anyone to see what's on that reel.\"",
			"\"There's evidence of everything they've been doing. All of it. Right here.\"",
		],
		"next": "farewell"
	},
	"farewell": {
		"lines": ["\"Let's get out of here before they send more. I'll explain everything on the way.\""],
		"effects": {"set_flag": "doug_talked", "flag_value": true}
	}
}

const USHER_COLOR := Color(0.73, 0.11, 0.14)
const USHER_POS := Vector2(480.0, 420.0)
const USHER_RADIUS: float = 64.0

const USHER_INTRO_TREE: Dictionary = {
	"start": {
		"lines": [
			"\"Welcome to the Grand Marquee. I'm Cecil — chief usher.\" He sweeps his torch toward the lobby.",
			"\"Rough night for a visit. Something's very wrong backstage.\""
		],
		"choices": [
			{"text": "\"What's blocking the backstage?\"",       "next": "guardian_hint"},
			{"text": "\"Is the projection booth still open?\"", "next": "booth_hint"},
		]
	},
	"guardian_hint": {
		"lines": [
			"\"Machinery's gone haywire in the aisle. Whatever it is, it's been stopping everyone from getting through.\"",
			"\"Clear that and the whole theatre's yours.\""
		],
		"effects": {"set_flag": "usher_met", "flag_value": true}
	},
	"booth_hint": {
		"lines": [
			"\"West corridor, up the stairs. Projector's untouched — whoever was running it cleared out in a hurry.\"",
			"\"Equipment's still in there if you need it.\""
		],
		"effects": {"set_flag": "usher_met", "flag_value": true}
	}
}

static var USHER_REMINDER_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"Still out here. The backstage won't be safe until you clear that aisle — whatever's in there isn't friendly.\""
])

static var USHER_CLEARED_TREE: Dictionary = DialogTreeScript.from_pages([
	"\"Quite a performance.\" Cecil straightens his pillbox hat.",
	"\"West corridor for the booth, if you still need it. I hope you find whoever you're looking for.\""
])

const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(400.0, 490.0)

# Multi-room layout bounding box  --  a literal HUB-AND-WINGS layout matching
# this location's spec ("Backstage, projection booth, balcony, and lobby are
# distinct zones"): a Lobby (south, entry  --  the duo's arrival point) opens
# north into the Backstage, the central combat floor where the cinema's
# guardian Boss "holds the aisle" squarely across the only path forward  -- 
# which in turn opens west into the Projection Booth (Quinn's repair) and
# north into the Balcony (Ben's house organ, literally elevated above the
# stage it overlooks, the way the spec frames it as a place that "manipulates
# the crowd" from above). All three connections between zones are open
# passages  --  gaps in shared walls, not corridors  --  so the hub-and-spoke shape
# mirrors how the spec singles out Backstage as the throughline the other
# three named zones branch from. Feeds the camera's pan limits  --  see
# CLAUDE.md "Doorways, camera-follow & multi-room levels". Recompute if the
# wall layout changes.
const CAMERA_LIMIT_LEFT: int = 24
const CAMERA_LIMIT_TOP: int = 24
const CAMERA_LIMIT_RIGHT: int = 616
const CAMERA_LIMIT_BOTTOM: int = 536
const CAMERA_SMOOTHING_SPEED: float = 5.0

@onready var camera: Camera2D = $Camera2D
@onready var quinn: Player = $Players/Quinn
@onready var ben: Player = $Players/Ben
@onready var hud: HUD = $HUD
@onready var enemies: Node2D = $Enemies
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label = $HintOverlay/HintLabel

var _spawned: bool = false
var _enemies_cleared: bool = false
var _projector_repaired: bool = false
var _organ_played: bool = false
var _cleared: bool = false
var _projector_sprite: Sprite2D
var _organ_sprite: Sprite2D
var _uncle_doug_sprite: AnimatedSprite2D
var _loot_boxes: Array = []
var _doorway = null
var _dialog_box = null
var _doug_talked: bool = false
var _usher_sprite: AnimatedSprite2D
var _usher_bubble        = null
var _usher_bubble_timer: float = 0.0
var _usher_met: bool = false

func _ready() -> void:
	_build_floor()
	_build_walls()
	PlaceholderArt.add_mood_light(self, LOCATION_ID)
	GameManager.register_players_with_preference(quinn, ben)
	hud.setup(quinn, ben)
	quinn.special_used.connect(_on_special_used)
	ben.special_used.connect(_on_special_used)
	_create_projector()
	_create_usher_npc()
	_create_organ()
	_create_loot_boxes()
	_create_hiding_spot()
	_create_doorway()
	_setup_camera()
	_restore_progress()
	if not _cleared:
		Audio.play_music("boss")

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
# tracks locally, so re-entering after a Doorway exit (before the duo has
# found Uncle Doug) picks up where they left off: skip respawning a cleared
# floor and restore both prop palettes.
func _restore_progress() -> void:
	_enemies_cleared = GameManager.get_level_flag(LOCATION_ID, "enemies_cleared", false)
	_projector_repaired = GameManager.get_level_flag(LOCATION_ID, "projector_repaired", false)
	_organ_played = GameManager.get_level_flag(LOCATION_ID, "organ_played", false)
	if _projector_repaired:
		_projector_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _organ_played:
		_organ_sprite.modulate = Color(0.4, 1.0, 0.5)
	if _enemies_cleared:
		_spawned = true
	else:
		_spawn()
	_doug_talked = GameManager.get_level_flag(LOCATION_ID, "doug_talked", false)
	_usher_met = GameManager.get_level_flag(LOCATION_ID, "usher_met", false)
	if _enemies_cleared and _projector_repaired and _organ_played and _has_all_tickets():
		_cleared = true
		hint_label.text = ""
		if is_instance_valid(_uncle_doug_sprite):
			_uncle_doug_sprite.visible = true
			if _uncle_doug_sprite.sprite_frames.has_animation("wave"):
				_uncle_doug_sprite.play("wave")
		if _doug_talked:
			clear_label.text = "THE FINAL REEL!\n\nThe house lights rise  --  and there, in the\nprojection booth, stands Uncle Doug.\n\nPress ENTER to continue"
			clear_label.visible = true
		else:
			hint_label.text = "Talk to Uncle Doug in the projection booth  [ approach, press G ]"

# Tile-mapped retro floor (Zelda-style two-tone grid), generated at runtime
# via PlaceholderArt to keep the original-IP guarantee  --  no imported tile art.
# Wall art: a Sprite2D per StaticBody2D wall, sized to its exact
# CollisionShape2D rect and textured via PlaceholderArt.make_wall_texture  --  a
# darker stone tone of the floor's base color, so the room reads as a bordered
# space instead of walls-on-a-void (matches the tile-floor visual-style pass;
# generated at runtime, no imported wall art, original-IP guarantee intact).
# Iterates whatever StaticBody2D children it finds  --  the Lobby + Backstage +
# Booth + Balcony hub-and-wings layout (12 wall segments) needed zero changes
# here, only more .tscn nodes.
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

func _create_projector() -> void:
	_projector_sprite = Sprite2D.new()
	if not _apply_synty_billboard(_projector_sprite, PROJECTOR_BILLBOARD, 40.0):
		_projector_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.42, 0.32, 0.5), 48, 48)
	_projector_sprite.position = PROJECTOR_POS
	add_child(_projector_sprite)
	# Cinema dressing (couch seating + plant).
	for p: Array in CINEMA_PROPS:
		var spr := Sprite2D.new()
		if _apply_synty_billboard(spr, "res://assets/art/synty/props/%s.png" % p[0], float(p[3])):
			spr.position = Vector2(float(p[1]), float(p[2]))
			add_child(spr)
	# Uncle Doug — hidden until the level is cleared; appears in the booth
	_uncle_doug_sprite = AnimatedSprite2D.new()
	var loaded: SpriteFrames = SpriteLoader.try_load_npc("uncle_doug")
	_uncle_doug_sprite.sprite_frames = loaded if loaded != null else PlaceholderArt.make_player_frames(Color(0.70, 0.63, 0.48), "")
	_uncle_doug_sprite.scale = Vector2(SpriteLoader.NPC_SPRITE_SCALE, SpriteLoader.NPC_SPRITE_SCALE) if loaded != null else Vector2.ONE
	_uncle_doug_sprite.play("idle")
	_uncle_doug_sprite.position = PROJECTOR_POS + Vector2(48.0, 0.0)
	_uncle_doug_sprite.visible = false
	add_child(_uncle_doug_sprite)
	var dialog_layer := CanvasLayer.new()
	dialog_layer.layer = 19
	add_child(dialog_layer)
	_dialog_box = DialogBoxScript.new()
	dialog_layer.add_child(_dialog_box)
	_dialog_box.closed.connect(_on_dialog_closed)

func _create_organ() -> void:
	_organ_sprite = Sprite2D.new()
	_organ_sprite.texture = PlaceholderArt.make_gate_texture(Color(0.5, 0.2, 0.24), 48, 56)
	_organ_sprite.position = ORGAN_POS
	add_child(_organ_sprite)

# Stealth: a shadowed alcove tucked in the Backstage's far corner  --  clear of
# both puzzle-prop gate radii and the Boss's guard position, along the
# stagehands' patrol loop, so ducking in to let one pass before committing to
# the climactic fight is a real option  --  see CLAUDE.md "Stealth & awareness".
func _create_hiding_spot() -> void:
	var spot = HidingSpotScript.new()
	spot.position = HIDING_SPOT_POS
	add_child(spot)

func _create_loot_boxes() -> void:
	var reel_box = LootBoxScript.new()
	reel_box.setup(FilmReelItem, REEL_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[0], false))
	add_child(reel_box)
	_loot_boxes.append(reel_box)

# The headline ticket gate  --  all five character movie tickets must be held
# (across the active duo) to complete the Cinema  --  see CLAUDE.md
# "Collectibles & Inventory" for the full ticket system.
func _has_all_tickets() -> bool:
	var characters: Array = ["Quinn", "Erin", "Evan", "Ben", "Ethan"]
	var items: Array = [TicketQuinnItem, TicketErinItem, TicketEvanItem, TicketBenItem, TicketEthanItem]
	for i in characters.size():
		var held: bool = false
		for char_name in characters:
			if GameManager.has_item(char_name, items[i].id):
				held = true
				break
		if not held:
			return false
	return true

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

func _spawn() -> void:
	_add(GRUNT_SCENE, Vector2(260.0, 200.0))
	_add(GRUNT_SCENE, Vector2(540.0, 320.0))
	_add(BOSS_SCENE,  Vector2(400.0, 300.0))
	_spawned = true

func _add(scene: PackedScene, pos: Vector2) -> void:
	var e: Enemy = scene.instantiate()
	e.position = pos
	enemies.add_child(e)

func _create_usher_npc() -> void:
	_usher_sprite = AnimatedSprite2D.new()
	var loaded: SpriteFrames = SpriteLoader.try_load_npc("usher")
	_usher_sprite.sprite_frames = loaded if loaded != null else PlaceholderArt.make_player_frames(USHER_COLOR, "")
	_usher_sprite.scale = Vector2(SpriteLoader.NPC_SPRITE_SCALE, SpriteLoader.NPC_SPRITE_SCALE) if loaded != null else Vector2.ONE
	_usher_sprite.play("idle")
	_usher_sprite.position = USHER_POS
	add_child(_usher_sprite)
	_usher_bubble = SpeechBubbleScript.new()
	_usher_bubble.position = USHER_POS + Vector2(0.0, -52.0)
	add_child(_usher_bubble)
	_usher_bubble_timer = randf_range(USHER_BUBBLE_MIN, USHER_BUBBLE_MAX)

func _talk_to_usher(char_name: String) -> void:
	Audio.play("ui_select")
	var tree: Dictionary
	if _cleared:
		tree = USHER_CLEARED_TREE
	elif not _usher_met:
		tree = USHER_INTRO_TREE
	else:
		tree = USHER_REMINDER_TREE
	_dialog_box.open("Cecil", USHER_COLOR, tree, "start", char_name)

func _talk_to_uncle_doug(char_name: String) -> void:
	var p: Player = quinn if char_name == "Quinn" else ben
	Audio.play("ui_select")
	_dialog_box.open("Uncle Doug", UNCLE_DOUG_COLOR, UNCLE_DOUG_MEET_TREE, "start", p.data.character_name)

func _on_dialog_closed(effects: Array) -> void:
	for fx: Dictionary in effects:
		if fx.has("set_flag"):
			GameManager.set_level_flag(LOCATION_ID, fx["set_flag"], fx.get("flag_value", true))
	if GameManager.get_level_flag(LOCATION_ID, "usher_met", false) and not _usher_met:
		_usher_met = true
	if GameManager.get_level_flag(LOCATION_ID, "doug_talked", false) and not _doug_talked:
		_doug_talked = true
		hint_label.text = ""
		clear_label.text = "THE FINAL REEL!\n\nThe house lights rise  --  and there, in the\nprojection booth, stands Uncle Doug.\n\nPress ENTER to continue"
		clear_label.visible = true

func _on_special_used(char_name: String) -> void:
	if _dialog_box.is_open():
		return
	var p: Player = quinn if char_name == "Quinn" else ben
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if p.global_position.distance_to(USHER_POS) < USHER_RADIUS:
		_talk_to_usher(char_name)
		return
	if _cleared and not _doug_talked and p.global_position.distance_to(UNCLE_DOUG_POS) < UNCLE_DOUG_RADIUS:
		_talk_to_uncle_doug(char_name)
		return
	if char_name == "Quinn" and not _projector_repaired:
		if quinn.global_position.distance_to(PROJECTOR_POS) < PROJECTOR_RADIUS:
			if GameManager.has_item("Quinn", FilmReelItem.id) or GameManager.has_item("Ben", FilmReelItem.id):
				_projector_repaired = true
				_projector_sprite.modulate = Color(0.4, 1.0, 0.5)
				Audio.play("special")
				GameManager.set_level_flag(LOCATION_ID, "projector_repaired", true)
	elif char_name == "Ben" and not _organ_played:
		if ben.global_position.distance_to(ORGAN_POS) < ORGAN_RADIUS:
			_organ_played = true
			_organ_sprite.modulate = Color(0.4, 1.0, 0.5)
			Audio.play("special")
			GameManager.set_level_flag(LOCATION_ID, "organ_played", true)
	elif GameManager.try_use_whistle():
		Audio.play("special")

func _process(delta: float) -> void:
	if is_instance_valid(_usher_bubble) and not _dialog_box.is_open():
		_usher_bubble_timer -= delta
		if _usher_bubble_timer <= 0.0:
			_usher_bubble_timer = randf_range(USHER_BUBBLE_MIN, USHER_BUBBLE_MAX)
			_usher_bubble.show_text(
				USHER_BUBBLE_LINES[randi() % USHER_BUBBLE_LINES.size()],
				USHER_BUBBLE_DUR)
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
	if _enemies_cleared and _projector_repaired and _organ_played and _has_all_tickets() and not _cleared:
		_cleared = true
		Audio.play("puzzle_complete")
		Audio.play_music("victory")
		hint_label.text = "Talk to Uncle Doug in the projection booth  [ approach, press G ]"
		if is_instance_valid(_uncle_doug_sprite):
			_uncle_doug_sprite.visible = true
			if _uncle_doug_sprite.sprite_frames.has_animation("wave"):
				_uncle_doug_sprite.play("wave")
	if _cleared and _doug_talked and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location(LOCATION_ID)
		TransitionManager.change_scene("res://scenes/ui/ResultScreen.tscn")

# Doorway-triggered exit  --  distinct from the clear-overlay's "press ENTER"
# exit above, and adapted for this finale location: a CLEARED exit must lead
# to the same endgame ResultScreen the overlay does (this is the climax  -- 
# there's no "back to the overworld" once Uncle Doug is found in the booth),
# while an early exit (not yet cleared) returns to the overworld exactly like
# every other location's Doorway. complete_location is idempotent, so calling
# it here when already completed via the overlay never double-grants.
func _exit_to_overworld() -> void:
	if _cleared:
		GameManager.complete_location(LOCATION_ID)
		TransitionManager.change_scene("res://scenes/ui/ResultScreen.tscn")
	else:
		GameManager.last_location_id = LOCATION_ID
		TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")

func _update_hint() -> void:
	if _cleared:
		return  # hint is managed by the clear/doug-talk flow; don't overwrite it
	elif not _enemies_cleared:
		hint_label.text = "A guardian holds the aisle, flanked by patrolling stagehands  --  find your opening and fight through!"
	elif not _projector_repaired:
		var has_reel: bool = GameManager.has_item("Quinn", FilmReelItem.id) or GameManager.has_item("Ben", FilmReelItem.id)
		if has_reel:
			hint_label.text = "Quinn: in the projection booth, repair the equipment  [ approach it, press G ]"
		else:
			hint_label.text = "Quinn: the projector is missing its film reel  --  check the crates in the projection booth"
	elif not _organ_played:
		hint_label.text = "Ben: up on the balcony, play the house organ to calm the crowd  [ approach it, press G ]"
	elif not _has_all_tickets():
		hint_label.text = "The box office won't open without all five tickets  --  the whole team's admissions are required"
	else:
		hint_label.text = ""
