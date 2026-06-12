extends Node2D

const LOCATION_ID: String = "old_parish_church"

# Tile-mapped floor palette  --  cool limestone with candlelit-stone accents,
# per locations/02_old_parish_church.md "Improved floor plan" (see CLAUDE.md
# "Tile-mapped floors"). _build_walls() derives the wall color from
# FLOOR_BASE_COLOR.darkened(0.35), so this single change re-tones the whole room.
const FLOOR_BASE_COLOR: Color = Color(0.60, 0.58, 0.52)
const FLOOR_ACCENT_COLOR: Color = Color(0.75, 0.72, 0.60)
const FLOOR_COLS: int = 25
const FLOOR_ROWS: int = 21
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4

const GATE_RADIUS: float = 64.0
const QUINN_GATE_POS := Vector2(260.0, 300.0)
const ERIN_GATE_POS  := Vector2(700.0, 300.0)

# Collectibles: Quinn's movie ticket (needed for the Cinema finale) and a lore
# photograph  --  see CLAUDE.md "Collectibles & Inventory". Both sit in the
# vestibule so the duo finds them on the way in or out.
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const TicketQuinnItem: ItemData = preload("res://data/items/ticket_quinn.tres")
const FadedPhotoItem: ItemData = preload("res://data/items/faded_photograph.tres")
# Penny (see npc_dialog/penny.md) sends the duo here looking for a
# handkerchief she dropped among the pews -- a quest fetch-item, tucked in
# alongside the location's other vestibule loot boxes.
const HandkerchiefItem: ItemData = preload("res://data/items/embroidered_handkerchief.tres")
const TICKET_LOOT_POS := Vector2(128.0, 300.0)
const PHOTO_LOOT_POS  := Vector2(680.0, 520.0)
const HANDKERCHIEF_LOOT_POS := Vector2(480.0, 460.0)
const LOOT_FLAG_KEYS  := ["ticket_loot_open", "photo_loot_open", "handkerchief_loot_open"]

# Doorway: the level's entrance/exit  --  see CLAUDE.md "Doorways, camera-follow
# & multi-room levels". The duo spawns beside it in the vestibule; walking
# away and back exits to the overworld at any time, cleared or not.
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(480.0, 600.0)

# Secret passage: a wall segment at the nave's altar end that looks identical
# to its neighbors but conceals a small organ loft  --  this location's spec
# line "may contain a pipe organ echoing the starting location" played as a
# quiet, optional lore discovery rather than a mechanical gate. Quinn presses
# Special near the hidden lever to disable the wall's collider and fade its
# sprite, revealing the loft and the organ prop inside.
const LEVER_POS := Vector2(480.0, 160.0)
const LEVER_RADIUS: float = 56.0
const ORGAN_PROP_POS := Vector2(480.0, 75.0)

# Decorative + collidable nave furnishings  --  see
# locations/02_old_parish_church.md "Visual props to add". Pews and the altar
# get a StaticBody2D (the established cosmetic-prop pattern, e.g. Iron &
# Strings' barbell) so the wide nave reads as furnished space the duo routes
# around via the clear center aisle; stained glass, candles, and the arch
# window are pure Sprite2D flourishes layered on top of the existing walls.
const PEW_COLOR: Color = Color(0.30, 0.20, 0.12)
const PEW_SIZE := Vector2(80.0, 18.0)
const WEST_PEW_X: float = 300.0
const EAST_PEW_X: float = 660.0
const PEW_ROW_Y: Array[float] = [389.0, 419.0, 449.0]

const ALTAR_POS := Vector2(480.0, 185.0)
const ALTAR_SIZE := Vector2(64.0, 24.0)
const CANDLE_POSITIONS: Array[Vector2] = [
	Vector2(450.0, 200.0), Vector2(480.0, 200.0), Vector2(510.0, 200.0),
]
const ARCH_WINDOW_POS := Vector2(400.0, 112.0)
const ARCH_WINDOW_SIZE := Vector2(48.0, 32.0)
const STAINED_GLASS_SIZE := Vector2(32.0, 64.0)
const STAINED_GLASS_COLORS: Array[Color] = [
	Color(0.75, 0.15, 0.15), # red
	Color(0.15, 0.35, 0.75), # blue
	Color(0.85, 0.75, 0.15), # gold
	Color(0.20, 0.55, 0.30), # green
]
const STAINED_GLASS_POSITIONS: Array[Vector2] = [
	Vector2(192.0, 190.0), Vector2(192.0, 410.0),
	Vector2(768.0, 200.0), Vector2(768.0, 400.0),
]

# Multi-room layout bounding box (vestibule -> nave -> hidden organ loft ->
# west side chapel)  --  feeds the camera's pan limits  --  see CLAUDE.md
# "Doorways, camera-follow & multi-room levels". Recompute if the wall layout
# changes.
const CAMERA_LIMIT_LEFT: int = 56
const CAMERA_LIMIT_TOP: int = 24
const CAMERA_LIMIT_RIGHT: int = 776
const CAMERA_LIMIT_BOTTOM: int = 656
const CAMERA_SMOOTHING_SPEED: float = 5.0

const DialogBoxScript: Script = preload("res://scripts/ui/dialog_box.gd")
const DialogTreeScript: Script = preload("res://scripts/systems/dialog_tree.gd")

# Father Aldric: a static NPC near the altar, clear of the BLUE/RED pillar
# radii and the secret-passage lever -- the first dialog-choice NPC, see
# CLAUDE.md "NPC dialog & quests" and scripts/systems/dialog_tree.gd. His
# reaction to the duo's first conversation depends on which character is
# active when the respectful-vs-blunt choice is made, and is remembered via
# level_progress -- a quiet, lore-only echo of the BLUE/RED pillar puzzle's
# "right character for the moment" theme.
const ALDRIC_COLOR := Color(0.55, 0.5, 0.42)
const ALDRIC_POS := Vector2(560.0, 230.0)
const ALDRIC_RADIUS: float = 56.0

const FATHER_ALDRIC_TREE: Dictionary = {
	"start": {
		"lines": [
			"An older priest looks up from the altar candles as you approach.\nFather Aldric: \"Ah -- visitors. We don't get many, these days, not since the organ went silent.\"",
		],
		"next": "ask",
	},
	"ask": {
		"lines": [
			"Father Aldric: \"Tell me, what brings you both to my nave?\"",
		],
		"choices": [
			{
				"text": "Quinn removes his hat. \"Just passing through, Father. Didn't mean to intrude.\"",
				"best_with": "Quinn",
				"next": "pleased",
				"next_alt": "amused",
			},
			{
				"text": "Erin: \"Looking for an old man named Doug. You seen him?\"",
				"best_with": "Erin",
				"next": "annoyed",
			},
		],
	},
	"pleased": {
		"lines": [
			"Father Aldric: \"A polite young man -- how refreshing. Sit a while, if you like; the pews could use the company.\"",
			"\"...Now that I think on it, an older fellow did sit right there in the back pew, some weeks past. Kept to himself, mostly. Haven't seen him since.\"",
		],
		"effects": {"set_flag": "father_aldric_impression", "flag_value": "good"},
	},
	"amused": {
		"lines": [
			"Father Aldric chuckles. \"Well, aren't you a surprise. Most folk barge in asking after lost relatives before they've even crossed the threshold.\"",
			"\"...Funny you should ask, though -- there WAS an older man here a while back. Quiet sort. Haven't seen him since, I'm afraid.\"",
		],
		"effects": {"set_flag": "father_aldric_impression", "flag_value": "good"},
	},
	"annoyed": {
		"lines": [
			"Father Aldric stiffens. \"...I beg your pardon? We're in the middle of vespers, miss.\"",
			"He turns back to his ledger without another word.",
		],
		"effects": {"set_flag": "father_aldric_impression", "flag_value": "cool"},
	},
}

static var ALDRIC_RETURN_GOOD_TREE: Dictionary = DialogTreeScript.from_pages([
	"Father Aldric: \"Back again? Good -- the pews are always open to you two.\"",
])
static var ALDRIC_RETURN_COOL_TREE: Dictionary = DialogTreeScript.from_pages([
	"Father Aldric, without looking up: \"...Yes? Can I help you with something?\"",
])

@onready var camera: Camera2D = $Camera2D
@onready var quinn: Player = $Players/Quinn
@onready var erin: Player  = $Players/Erin
@onready var hud: HUD      = $HUD
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label  = $HintOverlay/HintLabel
@onready var _secret_wall: StaticBody2D = $Walls/SecretWall

var _quinn_done: bool = false
var _erin_done: bool  = false
var _secret_revealed: bool = false
var _quinn_sprite: Sprite2D
var _erin_sprite: Sprite2D
var _aldric_sprite: AnimatedSprite2D
var _secret_wall_shape: CollisionShape2D
var _secret_wall_sprite: Sprite2D
var _organ_prop: Sprite2D
var _loot_boxes: Array = []
var _doorway = null
var _dialog_box = null

func _ready() -> void:
	_build_floor()
	_build_walls()
	_build_props()
	GameManager.register_players_with_preference(quinn, erin)
	hud.setup(quinn, erin)
	quinn.special_used.connect(_on_special_used)
	erin.special_used.connect(_on_special_used)
	_create_gates()
	_create_secret_passage()
	_create_loot_boxes()
	_create_doorway()
	_create_father_aldric()
	_setup_camera()
	_restore_progress()
	if not clear_label.visible:
		Audio.play_music("combat")

# Camera follows the active character  --  see CLAUDE.md "Doorways,
# camera-follow & multi-room levels". Smoothing makes the retarget on
# characters_swapped feel natural for free; the pan limits keep the church's
# edges from ever showing past its bounding box.
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
# left off: restore both pillars' solved palettes, the secret passage's open
# state, and the cleared overlay if both were already done.
func _restore_progress() -> void:
	_quinn_done = GameManager.get_level_flag(LOCATION_ID, "quinn_done", false)
	_erin_done = GameManager.get_level_flag(LOCATION_ID, "erin_done", false)
	_secret_revealed = GameManager.get_level_flag(LOCATION_ID, "secret_revealed", false)
	if _quinn_done:
		_quinn_sprite.modulate = Color(0.3, 1.0, 0.3)
	if _erin_done:
		_erin_sprite.modulate = Color(0.3, 1.0, 0.3)
	if _secret_revealed:
		_open_secret_passage(false)
	_update_aldric_animation()
	if _quinn_done and _erin_done:
		hint_label.text = ""
		clear_label.text = "PARISH CLEARED!\n\nPress ENTER for the Map"
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
# Iterates whatever StaticBody2D children it finds  --  the cross-shaped
# vestibule/nave/loft layout needed zero changes here, only more .tscn nodes.
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

# Nave furnishings  --  see locations/02_old_parish_church.md "Visual props
# to add". Pew rows flank the center aisle (both at the same x within their
# side, three rows stacked north-south); the altar sits at the north end
# below the secret-passage wall, with three lit candles in front of it;
# stained glass windows line the east/west nave walls and an arch window sits
# above the altar on the north wall  --  all pure PlaceholderArt, no imported
# assets.
func _build_props() -> void:
	for x: float in [WEST_PEW_X, EAST_PEW_X]:
		for y: float in PEW_ROW_Y:
			_place_pew(Vector2(x, y))
	_place_altar()
	for pos: Vector2 in CANDLE_POSITIONS:
		_place_candle(pos)
	for pos: Vector2 in STAINED_GLASS_POSITIONS:
		_place_stained_glass(pos)
	_place_arch_window()

func _place_pew(pos: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = PEW_SIZE
	shape.shape = rect
	body.add_child(shape)
	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderArt.make_pew_texture(PEW_COLOR, int(PEW_SIZE.x), int(PEW_SIZE.y))
	body.add_child(sprite)
	add_child(body)

func _place_altar() -> void:
	var body := StaticBody2D.new()
	body.position = ALTAR_POS
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = ALTAR_SIZE
	shape.shape = rect
	body.add_child(shape)
	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderArt.make_altar_texture(int(ALTAR_SIZE.x), int(ALTAR_SIZE.y))
	body.add_child(sprite)
	add_child(body)

func _place_candle(pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderArt.make_candle_texture(8, 24, true)
	sprite.position = pos
	add_child(sprite)

func _place_stained_glass(pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderArt.make_stained_glass_texture(
		int(STAINED_GLASS_SIZE.x), int(STAINED_GLASS_SIZE.y), STAINED_GLASS_COLORS)
	sprite.position = pos
	add_child(sprite)

func _place_arch_window() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderArt.make_arch_window_texture(
		int(ARCH_WINDOW_SIZE.x), int(ARCH_WINDOW_SIZE.y), STAINED_GLASS_COLORS[1])
	sprite.position = ARCH_WINDOW_POS
	add_child(sprite)

func _create_gates() -> void:
	_quinn_sprite = _gate(Color(0.3, 0.5, 0.9), QUINN_GATE_POS)
	_erin_sprite  = _gate(Color(0.9, 0.35, 0.1), ERIN_GATE_POS)

func _gate(color: Color, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = PlaceholderArt.make_gate_texture(color, 40, 64)
	s.position = pos
	add_child(s)
	return s

# The hidden lever and the wall segment it opens  --  grabs the references
# _build_walls() already textured so _reveal_secret_passage can disable the
# collider and fade the sprite, revealing the loft and the quiet pipe organ
# inside (pure lore/flavor here  --  no mechanical gate, just the spec's planted
# echo of the starting location).
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
	_organ_prop = Sprite2D.new()
	_organ_prop.texture = PlaceholderArt.make_gate_texture(Color(0.5, 0.4, 0.2), 48, 56)
	_organ_prop.position = ORGAN_PROP_POS
	_organ_prop.visible = _secret_revealed
	add_child(_organ_prop)

func _open_secret_passage(animate: bool) -> void:
	_secret_wall_shape.disabled = true
	_organ_prop.visible = true
	if animate:
		var tween := create_tween()
		tween.tween_property(_secret_wall_sprite, "modulate:a", 0.0, 0.6)
	else:
		_secret_wall_sprite.modulate.a = 0.0

func _reveal_secret_passage() -> void:
	_secret_revealed = true
	_open_secret_passage(true)
	Audio.play("special")
	GameManager.set_level_flag(LOCATION_ID, "secret_revealed", true)

func _create_loot_boxes() -> void:
	var ticket_box = LootBoxScript.new()
	ticket_box.setup(TicketQuinnItem, TICKET_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[0], false))
	add_child(ticket_box)
	_loot_boxes.append(ticket_box)

	var photo_box = LootBoxScript.new()
	photo_box.setup(FadedPhotoItem, PHOTO_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[1], false))
	add_child(photo_box)
	_loot_boxes.append(photo_box)

	var handkerchief_box = LootBoxScript.new()
	handkerchief_box.setup(HandkerchiefItem, HANDKERCHIEF_LOOT_POS, GameManager.get_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[2], false))
	add_child(handkerchief_box)
	_loot_boxes.append(handkerchief_box)

func _create_doorway() -> void:
	_doorway = DoorwayScript.new()
	_doorway.setup(DOORWAY_POS)
	add_child(_doorway)

# Father Aldric  --  see the FATHER_ALDRIC_TREE comment above. Stationary
# AnimatedSprite2D near the altar; _dialog_box is the same generic, reusable
# Control as overworld_map.gd's NPC dialog and pipe_organ_works.gd's Mr.
# Bellows (CLAUDE.md "NPC dialog & quests").
func _create_father_aldric() -> void:
	_aldric_sprite = AnimatedSprite2D.new()
	var loaded: SpriteFrames = SpriteLoader.try_load_npc("father_aldric")
	_aldric_sprite.sprite_frames = loaded if loaded != null else PlaceholderArt.make_player_frames(ALDRIC_COLOR, "")
	_aldric_sprite.scale = Vector2(SpriteLoader.NPC_SPRITE_SCALE, SpriteLoader.NPC_SPRITE_SCALE) if loaded != null else Vector2.ONE
	_aldric_sprite.play("idle")
	_aldric_sprite.position = ALDRIC_POS
	add_child(_aldric_sprite)

	var dialog_layer := CanvasLayer.new()
	dialog_layer.layer = 19
	add_child(dialog_layer)
	_dialog_box = DialogBoxScript.new()
	dialog_layer.add_child(_dialog_box)
	_dialog_box.closed.connect(_on_aldric_dialog_closed)

# First conversation walks FATHER_ALDRIC_TREE's choice (its outcome depends on
# which character is active, see resolve_choice); later visits show a short
# return tree reflecting the stored impression.
func _talk_to_father_aldric(char_name: String) -> void:
	var p: Player = quinn if char_name == "Quinn" else erin
	var impression: String = GameManager.get_level_flag(LOCATION_ID, "father_aldric_impression", "")
	var tree: Dictionary
	match impression:
		"good":
			tree = ALDRIC_RETURN_GOOD_TREE
		"cool":
			tree = ALDRIC_RETURN_COOL_TREE
		_:
			tree = FATHER_ALDRIC_TREE
	Audio.play("ui_select")
	_dialog_box.open("Father Aldric", ALDRIC_COLOR, tree, "start", p.data.character_name)

func _on_aldric_dialog_closed(effects: Array) -> void:
	for fx: Dictionary in effects:
		if fx.has("set_flag"):
			GameManager.set_level_flag(LOCATION_ID, fx["set_flag"], fx.get("flag_value", true))
	_update_aldric_animation()

func _update_aldric_animation() -> void:
	if not is_instance_valid(_aldric_sprite):
		return
	var impression: String = GameManager.get_level_flag(LOCATION_ID, "father_aldric_impression", "")
	match impression:
		"good":
			if _aldric_sprite.sprite_frames.has_animation("talk_pleased"):
				_aldric_sprite.play("talk_pleased")
		"cool":
			if _aldric_sprite.sprite_frames.has_animation("talk_amused"):
				_aldric_sprite.play("talk_amused")
		_:
			_aldric_sprite.play("idle")

func _on_special_used(char_name: String) -> void:
	if _dialog_box.is_open():
		return
	var p: Player = quinn if char_name == "Quinn" else erin
	for i in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if char_name == "Quinn" and not _secret_revealed and quinn.global_position.distance_to(LEVER_POS) < LEVER_RADIUS:
		_reveal_secret_passage()
		return
	if p.global_position.distance_to(ALDRIC_POS) < ALDRIC_RADIUS:
		_talk_to_father_aldric(char_name)
		return
	if char_name == "Quinn" and not _quinn_done:
		if quinn.global_position.distance_to(QUINN_GATE_POS) < GATE_RADIUS:
			_quinn_done = true
			_quinn_sprite.modulate = Color(0.3, 1.0, 0.3)
			GameManager.set_level_flag(LOCATION_ID, "quinn_done", true)
	elif char_name == "Erin" and not _erin_done:
		if erin.global_position.distance_to(ERIN_GATE_POS) < GATE_RADIUS:
			_erin_done = true
			_erin_sprite.modulate = Color(0.3, 1.0, 0.3)
			GameManager.set_level_flag(LOCATION_ID, "erin_done", true)
	if _quinn_done and _erin_done and not clear_label.visible:
		hint_label.text = ""
		clear_label.text = "PARISH CLEARED!\n\nPress ENTER for the Map"
		clear_label.visible = true
		Audio.play("puzzle_complete")
		Audio.play_music("victory")
	elif GameManager.try_use_whistle():
		Audio.play("special")

func _process(_delta: float) -> void:
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
	if is_instance_valid(GameManager.active_player):
		var active_pos: Vector2 = GameManager.active_player.global_position
		camera.global_position = active_pos
		if _doorway.check(active_pos):
			_exit_to_overworld()
			return
	_update_hint()
	if _quinn_done and _erin_done and Input.is_action_just_pressed("ui_accept"):
		GameManager.complete_location(LOCATION_ID)
		GameManager.last_location_id = LOCATION_ID
		TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")

# Doorway-triggered exit  --  distinct from the clear-overlay's "press ENTER"
# exit above. Per the established pattern, the duo can walk out at any time,
# cleared or not; complete_location is idempotent, so calling it here when
# already cleared never double-grants.
func _exit_to_overworld() -> void:
	if _quinn_done and _erin_done:
		GameManager.complete_location(LOCATION_ID)
	GameManager.last_location_id = LOCATION_ID
	TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")

func _update_hint() -> void:
	var active := GameManager.active_player
	if not is_instance_valid(active) or (_quinn_done and _erin_done):
		hint_label.text = ""
		return
	if active == quinn and not _quinn_done:
		var d: float = quinn.global_position.distance_to(QUINN_GATE_POS)
		hint_label.text = "Press G  --  Quinn's HA calms the congregation" if d < GATE_RADIUS + 48.0 \
						else "Quinn: cross the nave to the BLUE pillar  [ G to use HA ]"
	elif active == erin and not _erin_done:
		var d: float = erin.global_position.distance_to(ERIN_GATE_POS)
		hint_label.text = "Press G  --  Erin debates the gatekeeper" if d < GATE_RADIUS + 48.0 \
						else "Erin: cross the nave to the RED pillar  [ G to use Fast Talk ]"
	elif _quinn_done and not _erin_done:
		hint_label.text = "Swap to Erin [ TAB ]  →  cross to the RED pillar"
	elif not _quinn_done and _erin_done:
		hint_label.text = "Swap to Quinn [ TAB ]  →  cross to the BLUE pillar"
	else:
		hint_label.text = ""
