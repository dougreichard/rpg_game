extends Node2D

const LOCATION_ID: String = "old_parish_church"

# Tile-mapped floor palette  --  cool limestone with candlelit-stone accents.
const FLOOR_BASE_COLOR: Color = Color(0.60, 0.58, 0.52)
const FLOOR_ACCENT_COLOR: Color = Color(0.75, 0.72, 0.60)
const FLOOR_COLS: int = 25
const FLOOR_ROWS: int = 21
const FLOOR_TILE_PLAIN: Vector2i = Vector2i(0, 0)
const FLOOR_TILE_ACCENT: Vector2i = Vector2i(1, 0)
const FLOOR_ACCENT_PERIOD: int = 4
# Synty 2.5D interior (see docs/synty_2_5d_art_plan.md): cobblestone floor +
# stone-block walls; Town church-prop billboards.
const SYNTY_FLOOR: String = "res://assets/art/tiles/synty_floor_church.png"
const SYNTY_WALL: String = "res://assets/art/tiles/synty_wall_stone.png"
const PEW_BILLBOARD: String = "res://assets/art/synty/props/pew.png"
const ALTAR_BILLBOARD: String = "res://assets/art/synty/props/church_stand.png"
const CANDLE_BILLBOARD: String = "res://assets/art/synty/props/candles.png"

# Collectibles  --  see CLAUDE.md "Collectibles & Inventory".
const LootBoxScript: Script = preload("res://scripts/systems/loot_box.gd")
const TicketQuinnItem: ItemData = preload("res://data/items/ticket_quinn.tres")
const FadedPhotoItem: ItemData = preload("res://data/items/faded_photograph.tres")
const HandkerchiefItem: ItemData = preload("res://data/items/embroidered_handkerchief.tres")
const TICKET_LOOT_POS := Vector2(128.0, 300.0)
const PHOTO_LOOT_POS  := Vector2(680.0, 520.0)
const HANDKERCHIEF_LOOT_POS := Vector2(480.0, 460.0)
const LOOT_FLAG_KEYS  := ["ticket_loot_open", "photo_loot_open", "handkerchief_loot_open"]

# Doorway  --  see CLAUDE.md "Doorways, camera-follow & multi-room levels".
const DoorwayScript: Script = preload("res://scripts/systems/doorway.gd")
const DOORWAY_POS := Vector2(480.0, 600.0)

# Secret passage: a wall segment at the nave's altar end concealing the organ
# loft. Quinn presses Special near the hidden lever to reveal it.
const LEVER_POS := Vector2(480.0, 160.0)
const LEVER_RADIUS: float = 56.0
const ORGAN_PROP_POS := Vector2(480.0, 75.0)

# Nave furnishings.
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
	Color(0.75, 0.15, 0.15),
	Color(0.15, 0.35, 0.75),
	Color(0.85, 0.75, 0.15),
	Color(0.20, 0.55, 0.30),
]
const STAINED_GLASS_POSITIONS: Array[Vector2] = [
	Vector2(192.0, 190.0), Vector2(192.0, 410.0),
	Vector2(768.0, 200.0), Vector2(768.0, 400.0),
]

# Camera bounds (vestibule -> nave -> organ loft -> west side chapel).
const CAMERA_LIMIT_LEFT: int = 56
const CAMERA_LIMIT_TOP: int = 24
const CAMERA_LIMIT_RIGHT: int = 776
const CAMERA_LIMIT_BOTTOM: int = 656
const CAMERA_SMOOTHING_SPEED: float = 5.0

const DialogBoxScript: Script    = preload("res://scripts/ui/dialog_box.gd")
const DialogTreeScript: Script   = preload("res://scripts/systems/dialog_tree.gd")
const SpeechBubbleScript: Script = preload("res://scripts/systems/speech_bubble.gd")

# ── Choir Leader ─────────────────────────────────────────────────────────────
# A wandering NPC who patrols the nave aisles and periodically barks orders
# via a speech bubble. Non-interactive — purely atmospheric.
const CHOIR_LEADER_COLOR     := Color(0.48, 0.42, 0.58)
const CHOIR_LEADER_START_POS := Vector2(480.0, 350.0)
const CHOIR_LEADER_SPEED     : float = 55.0
const CHOIR_LEADER_IDLE_TIME : float = 2.2
const CHOIR_LEADER_YELL_MIN  : float = 5.0
const CHOIR_LEADER_YELL_MAX  : float = 11.0
const CHOIR_LEADER_YELL_TEXT : String = "Hands out of your pockets!"
const CHOIR_LEADER_BUBBLE_DUR: float = 3.0
const CHOIR_LEADER_BUBBLE_OFS := Vector2(0.0, -52.0)
# Waypoints keep the leader in the clear centre aisle between the pew columns.
const CHOIR_LEADER_WAYPOINTS : Array[Vector2] = [
	Vector2(480.0, 305.0),
	Vector2(375.0, 390.0),
	Vector2(580.0, 385.0),
	Vector2(480.0, 490.0),
]
const CHOIR_LEADER_QUIPS: Array[String] = [
	"Hands. Pockets. OUT. Am I clear?",
	"I can see you from here.",
	"Eyes forward! This is a house of worship!",
	"I said OUT of your pockets, not into mine.",
]

# ── Father Aldric ────────────────────────────────────────────────────────────
const ALDRIC_COLOR := Color(0.55, 0.5, 0.42)
const ALDRIC_POS := Vector2(560.0, 230.0)
const ALDRIC_RADIUS: float = 56.0

# Aldric's first-visit tree now assigns the congregation task and offers the
# organ-loft hint as a third choice so stuck players can always ask.
const FATHER_ALDRIC_TREE: Dictionary = {
	"start": {
		"lines": [
			"An older priest looks up from the altar candles.\nFather Aldric: \"Ah -- visitors. Not many of those lately, not since the organ went silent.\"",
			"\"A stranger came through some weeks ago and left my congregation quite unsettled. Would you be willing to speak with them? A kind word goes further than I can manage right now.\"",
		],
		"next": "ask",
	},
	"ask": {
		"lines": ["Father Aldric: \"Before you go -- anything I can help you with?\""],
		"choices": [
			{
				"text": "Quinn removes his hat. \"We'll speak with whoever needs it, Father.\"",
				"best_with": "Quinn",
				"next": "pleased",
				"next_alt": "amused",
			},
			{
				"text": "Erin: \"We're looking for that stranger. What exactly did he say?\"",
				"best_with": "Erin",
				"next": "erin_direct",
				"next_alt": "quinn_awkward",
			},
			{
				"text": "\"One more thing -- is there an organ loft somewhere in here?\"",
				"next": "organ_hint",
			},
		],
	},
	"pleased": {
		"lines": ["Father Aldric: \"A polite young man -- how refreshing. The congregation is scattered about the nave. I hope they'll open up to you.\""],
		"effects": {"set_flag": "father_aldric_impression", "flag_value": "good"},
	},
	"amused": {
		"lines": ["Father Aldric chuckles. \"Well, aren't you a surprise. They're about the nave -- I hope they'll talk.\""],
		"effects": {"set_flag": "father_aldric_impression", "flag_value": "good"},
	},
	"erin_direct": {
		"lines": [
			"Father Aldric stiffens slightly. \"...He came asking about old parish records. Quite insistent about it.\"",
			"He relents. \"My congregation saw more than I did. They're scattered about the nave -- see if they'll tell you what I can't.\"",
		],
		"effects": {"set_flag": "father_aldric_impression", "flag_value": "cool"},
	},
	"quinn_awkward": {
		"lines": [
			"Father Aldric blinks. \"...Yes, a stranger did come through. He left people uneasy.\"",
			"\"Perhaps speak with the congregation first -- they were closer to it than I was.\"",
		],
		"effects": {"set_flag": "father_aldric_impression", "flag_value": "good"},
	},
	"organ_hint": {
		"lines": [
			"Father Aldric glances toward the north wall of the nave.\n\"The loft was sealed long ago -- by a builder with a taste for secrets. Press close to the stones behind the altar itself. What feels like wall... isn't always wall.\"",
			"\"I hope the old instrument still has a voice. It's been too quiet in here for too long.\"",
		],
	},
}

# ── Congregation NPCs ─────────────────────────────────────────────────────────
# Two NPC open up to Quinn (elder, deacon), two to Erin (choir, caretaker),
# and two are red herrings (widow, confused elder). Wrong-character responses
# give a breadcrumb toward a different NPC rather than a flat refusal.
# NPC sprites reuse in-level NPC sheets from other locations.
const NPC_RADIUS: float = 56.0

const NPC_POSITIONS: Dictionary = {
	"elder":     Vector2(180.0, 450.0),  # west back pew
	"deacon":    Vector2(620.0, 260.0),  # east front, near altar
	"choir":     Vector2(620.0, 400.0),  # east mid-nave
	"caretaker": Vector2(180.0, 320.0),  # west mid, near chapel
	"widow":     Vector2(420.0, 300.0),  # center front  (red herring)
	"confused":  Vector2(420.0, 500.0),  # center back   (red herring)
}
const NPC_FLAG: Dictionary = {
	"elder": "quinn_npc1_done",  "deacon": "quinn_npc2_done",
	"choir": "erin_npc1_done",   "caretaker": "erin_npc2_done",
	"widow": "",                 "confused": "",
}
const NPC_RIGHT_CHAR: Dictionary = {
	"elder": "Quinn",  "deacon": "Quinn",
	"choir": "Erin",   "caretaker": "Erin",
	"widow": "",       "confused": "",
}
const NPC_DISPLAY_NAME: Dictionary = {
	"elder": "Parishioner",  "deacon": "Deacon",
	"choir": "Choir Member", "caretaker": "Caretaker",
	"widow": "Parishioner",  "confused": "Parishioner",
}
const NPC_COLOR: Dictionary = {
	"elder":     Color(0.60, 0.50, 0.40),
	"deacon":    Color(0.25, 0.28, 0.45),
	"choir":     Color(0.45, 0.55, 0.65),
	"caretaker": Color(0.40, 0.50, 0.38),
	"widow":     Color(0.28, 0.26, 0.30),
	"confused":  Color(0.62, 0.55, 0.42),
}
# Sprite sheets reused from other in-level NPCs. Empty string = PlaceholderArt.
const NPC_SPRITE_NAME: Dictionary = {
	"elder": "hieronymus",  "deacon": "viktor",
	"choir": "lena",        "caretaker": "cyrus",
	"widow": "rio",         "confused": "usher",
}

@onready var camera: Camera2D = $Camera2D
@onready var quinn: Player = $Players/Quinn
@onready var erin: Player  = $Players/Erin
@onready var hud: HUD      = $HUD
@onready var clear_label: Label = $ClearOverlay/ClearLabel
@onready var hint_label: Label  = $HintOverlay/HintLabel
@onready var _secret_wall: StaticBody2D = $Walls/SecretWall

# Congregation completion: two sub-flags per character; _quinn_done/_erin_done
# are computed properties so there is no separate persisted aggregate flag.
var _quinn_npc1_done: bool = false
var _quinn_npc2_done: bool = false
var _erin_npc1_done:  bool = false
var _erin_npc2_done:  bool = false

var _quinn_done: bool:
	get: return _quinn_npc1_done and _quinn_npc2_done

var _erin_done: bool:
	get: return _erin_npc1_done and _erin_npc2_done

var _secret_revealed: bool = false
var _aldric_sprite: AnimatedSprite2D
var _npc_sprites: Dictionary = {}   # npc_id -> AnimatedSprite2D
var _secret_wall_shape: CollisionShape2D
var _secret_wall_sprite: Sprite2D
var _organ_prop: Sprite2D
var _loot_boxes: Array = []
var _doorway = null
var _dialog_box = null

var _choir_leader: Node2D
var _choir_leader_bubble  # SpeechBubbleScript instance (untyped — no class_name)
var _cl_walking: bool = false
var _cl_target: Vector2 = Vector2.ZERO
var _cl_idle_timer: float = 0.0
var _cl_yell_timer: float = 0.0

func _ready() -> void:
	_build_floor()
	_build_walls()
	_build_props()
	GameManager.register_players_with_preference(quinn, erin)
	hud.setup(quinn, erin)
	quinn.special_used.connect(_on_special_used)
	erin.special_used.connect(_on_special_used)
	_create_secret_passage()
	_create_loot_boxes()
	_create_doorway()
	_create_father_aldric()
	_create_congregation()
	_create_choir_leader()
	_setup_camera()
	_restore_progress()
	if not clear_label.visible:
		Audio.play_music("combat")

func _setup_camera() -> void:
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = CAMERA_SMOOTHING_SPEED
	camera.limit_left = CAMERA_LIMIT_LEFT
	camera.limit_top = CAMERA_LIMIT_TOP
	camera.limit_right = CAMERA_LIMIT_RIGHT
	camera.limit_bottom = CAMERA_LIMIT_BOTTOM

func _restore_progress() -> void:
	_quinn_npc1_done = GameManager.get_level_flag(LOCATION_ID, "quinn_npc1_done", false)
	_quinn_npc2_done = GameManager.get_level_flag(LOCATION_ID, "quinn_npc2_done", false)
	_erin_npc1_done  = GameManager.get_level_flag(LOCATION_ID, "erin_npc1_done", false)
	_erin_npc2_done  = GameManager.get_level_flag(LOCATION_ID, "erin_npc2_done", false)
	_secret_revealed = GameManager.get_level_flag(LOCATION_ID, "secret_revealed", false)
	if _secret_revealed:
		_open_secret_passage(false)
	_update_aldric_animation()
	if _quinn_done and _erin_done:
		hint_label.text = ""
		clear_label.text = "PARISH CLEARED!\n\nPress ENTER for the Map"
		clear_label.visible = true

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

func _build_walls() -> void:
	var wall_tex: Texture2D = PlaceholderArt.make_synty_wall_tile(SYNTY_WALL)
	for wall in $Walls.get_children():
		if not wall is StaticBody2D:
			continue
		var shape: CollisionShape2D = wall.get_node("CollisionShape2D")
		var rect: RectangleShape2D = shape.shape
		PlaceholderArt.add_synty_wall_faces(wall, rect.size, wall_tex)

# Configure a Sprite2D as a feet-anchored Synty billboard scaled to target_w px.
# Returns false (leaving the sprite untouched) if the billboard PNG is missing,
# so callers fall back to the PlaceholderArt prop.
func _apply_synty_billboard(spr: Sprite2D, path: String, target_w: float) -> bool:
	if not ResourceLoader.exists(path):
		return false
	var tex: Texture2D = load(path)
	spr.texture = tex
	spr.offset = Vector2(0.0, -tex.get_height() / 2.0)
	var s: float = target_w / float(tex.get_width())
	spr.scale = Vector2(s, s)
	return true

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
	if not _apply_synty_billboard(sprite, PEW_BILLBOARD, PEW_SIZE.x):
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
	if not _apply_synty_billboard(sprite, ALTAR_BILLBOARD, ALTAR_SIZE.x + 12.0):
		sprite.texture = PlaceholderArt.make_altar_texture(int(ALTAR_SIZE.x), int(ALTAR_SIZE.y))
	body.add_child(sprite)
	add_child(body)

func _place_candle(pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	if not _apply_synty_billboard(sprite, CANDLE_BILLBOARD, 14.0):
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

func _create_secret_passage() -> void:
	_secret_wall_shape = _secret_wall.get_node("CollisionShape2D")
	for child in _secret_wall.get_children():
		if child is Sprite2D:
			_secret_wall_sprite = child
			break
	var lever := Sprite2D.new()
	if not _apply_synty_billboard(lever, "res://assets/art/synty/props/switch.png", 18.0):
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

# ── Father Aldric ─────────────────────────────────────────────────────────────

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
	_dialog_box.closed.connect(_on_dialog_closed)

# First visit: FATHER_ALDRIC_TREE (assigns congregation task + organ hint choice).
# Return visits: dynamically built tree reflecting stored impression, still
# offering the organ hint if the loft hasn't been revealed yet.
func _talk_to_father_aldric(char_name: String) -> void:
	var p: Player = quinn if char_name == "Quinn" else erin
	var impression: String = GameManager.get_level_flag(LOCATION_ID, "father_aldric_impression", "")
	var tree: Dictionary = FATHER_ALDRIC_TREE if impression == "" else _build_aldric_return_tree()
	Audio.play("ui_select")
	_dialog_box.open("Father Aldric", ALDRIC_COLOR, tree, "start", p.data.character_name)

func _build_aldric_return_tree() -> Dictionary:
	var impression: String = GameManager.get_level_flag(LOCATION_ID, "father_aldric_impression", "")
	var greeting: String = "Father Aldric: \"Back again? Good -- the pews are always open to you two.\"" \
		if impression == "good" \
		else "Father Aldric, without looking up: \"...Yes? Can I help you with something?\""
	if _secret_revealed:
		return DialogTreeScript.from_pages([greeting])
	return {
		"start": {
			"lines": [greeting],
			"choices": [
				{
					"text": "\"How do we reach the organ loft?\"",
					"next": "organ_hint",
				},
				{
					"text": "\"Just checking in, Father.\"",
					"next": "farewell",
				},
			],
		},
		"organ_hint": {
			"lines": [
				"He glances toward the north wall.\n\"Behind the altar stones -- press close to the wall at the nave's north end. What feels like solid stone... isn't.\"",
			],
			"next": "farewell",
		},
		"farewell": {
			"lines": ["Father Aldric nods and turns back to his candles."],
		},
	}

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

# ── Congregation NPCs ─────────────────────────────────────────────────────────

func _create_congregation() -> void:
	for npc_id: String in NPC_POSITIONS.keys():
		var sprite := AnimatedSprite2D.new()
		var sprite_name: String = NPC_SPRITE_NAME[npc_id]
		var color: Color = NPC_COLOR[npc_id]
		if sprite_name != "":
			var loaded: SpriteFrames = SpriteLoader.try_load_npc(sprite_name)
			if loaded != null:
				sprite.sprite_frames = loaded
				sprite.scale = Vector2(SpriteLoader.NPC_SPRITE_SCALE, SpriteLoader.NPC_SPRITE_SCALE)
			else:
				sprite.sprite_frames = PlaceholderArt.make_player_frames(color, "")
		else:
			sprite.sprite_frames = PlaceholderArt.make_player_frames(color, "")
		sprite.play("idle")
		sprite.position = NPC_POSITIONS[npc_id]
		add_child(sprite)
		_npc_sprites[npc_id] = sprite

func _talk_to_npc(npc_id: String, char_name: String) -> void:
	Audio.play("ui_select")
	_dialog_box.open(NPC_DISPLAY_NAME[npc_id], NPC_COLOR[npc_id],
		_get_npc_tree(npc_id, char_name), "start", char_name)

# Returns the appropriate dialog tree for a congregation NPC based on who is
# talking and whether the right-character conversation is already done.
func _get_npc_tree(npc_id: String, char_name: String) -> Dictionary:
	var flag: String = NPC_FLAG[npc_id]
	var already_done: bool = flag != "" and GameManager.get_level_flag(LOCATION_ID, flag, false)

	match npc_id:
		"elder":
			if already_done:
				return DialogTreeScript.from_pages(["Elder: \"You've given an old man more comfort than he's had in weeks. God bless you both.\""])
			if char_name == "Quinn":
				return {
					"start": {
						"lines": [
							"An old man looks up from his hymnal. Sixty years in this pew, at least.\nElder: \"You remind me of how folk used to come to church. Quiet. Respectful.\"",
							"\"There was a stranger here some weeks back. He sat right there -- \" he points to the back pew. \"Kept asking about the parish records. Seemed troubled.\"",
							"\"The deacon near the altar was there too. Stern man, but fair. He saw more than I did.\"",
						],
						"effects": {"set_flag": "quinn_npc1_done", "flag_value": true},
					},
				}
			else:
				return DialogTreeScript.from_pages([
					"The old man glances up from his hymnal, then gently back down.\nElder: \"I don't mean to be rude, dear -- but could you come back with your friend?\"",
				])

		"deacon":
			if already_done:
				return DialogTreeScript.from_pages(["Deacon: \"Glad I could help. This congregation depends on people like you.\""])
			if char_name == "Quinn":
				return {
					"start": {
						"lines": [
							"A stiff, formal man turns from the candles. He measures Quinn for a moment, then nods.\nDeacon: \"You carry yourself well. Unusual for visitors these days.\"",
							"\"That stranger -- he spoke with Father Aldric. I watched from here. He kept glancing at the north wall, above the altar. Like he knew something was up there.\"",
							"\"Whatever he was looking for... I hope you find it before something else does.\"",
						],
						"effects": {"set_flag": "quinn_npc2_done", "flag_value": true},
					},
				}
			else:
				return DialogTreeScript.from_pages([
					"The deacon turns, sizes up Erin in a glance.\nDeacon: \"I appreciate directness -- but not here, and not now.\"",
					"\"The choir member by the east pews might be more your speed.\"",
				])

		"choir":
			if already_done:
				return DialogTreeScript.from_pages(["Choir Member: \"Thank you. It helps to have someone who actually listens.\""])
			if char_name == "Erin":
				return {
					"start": {
						"lines": [
							"A young woman near the east pews looks up -- she's been uneasy for weeks.\nChoir Member: \"Finally. Someone who doesn't seem fine with all of this.\"",
							"\"Something happened the night that stranger came through. I heard it -- a sound in the walls, near the altar end. The caretaker works the west side, near the old chapel. He saw it.\"",
						],
						"effects": {"set_flag": "erin_npc1_done", "flag_value": true},
					},
				}
			else:
				return DialogTreeScript.from_pages([
					"The young woman looks up, then shakes her head gently.\nChoir Member: \"I appreciate the kind words. I really do.\"",
					"\"But I need someone who thinks something is actually wrong here -- not someone who's going to tell me it's fine.\"",
				])

		"caretaker":
			if already_done:
				return DialogTreeScript.from_pages(["Caretaker: \"I've said what I know. Glad it helps.\""])
			if char_name == "Erin":
				return {
					"start": {
						"lines": [
							"A practical man in work clothes looks up from near the chapel doorway.\nCaretaker: \"Right. You're the one actually asking questions. Good.\"",
							"\"I saw him. He went up toward the altar end of the nave and then -- gone. Didn't come back out the front. Like he found something up there that the rest of us don't know about.\"",
						],
						"effects": {"set_flag": "erin_npc2_done", "flag_value": true},
					},
				}
			else:
				return DialogTreeScript.from_pages([
					"The caretaker shrugs at Quinn's polite approach.\nCaretaker: \"No offence -- you seem like good people. But you look like you'd accept whatever I told you.\"",
					"\"Talk to someone who asks the hard questions. Shouldn't be hard to find.\"",
				])

		"widow":
			return DialogTreeScript.from_pages([
				"A woman in dark clothes sits motionless, head bowed.\nParishioner: \"I'm waiting for a sign.\"",
				"Her eyes don't meet yours. She doesn't seem to hear the next question.",
			])

		"confused":
			return DialogTreeScript.from_pages([
				"An elderly man turns at your approach, cupping one ear.\nParishioner: \"Eh? A dog, you say? Haven't seen any dogs in here since old Father Clement's spaniel, God rest him.\"",
				"\"The roof's been leaking since 1987, you know. Right above the third pew. Someone ought to do something about that.\"",
				"He nods firmly to himself and turns away.",
			])

	return DialogTreeScript.from_pages(["..."])

# ── Choir Leader ─────────────────────────────────────────────────────────────

func _create_choir_leader() -> void:
	_choir_leader = Node2D.new()
	_choir_leader.position = CHOIR_LEADER_START_POS

	var sprite := AnimatedSprite2D.new()
	var loaded: SpriteFrames = SpriteLoader.try_load_npc("aria")
	if loaded != null:
		sprite.sprite_frames = loaded
		sprite.scale = Vector2(SpriteLoader.NPC_SPRITE_SCALE, SpriteLoader.NPC_SPRITE_SCALE)
	else:
		sprite.sprite_frames = PlaceholderArt.make_player_frames(CHOIR_LEADER_COLOR, "")
	sprite.play("idle")
	_choir_leader.add_child(sprite)

	_choir_leader_bubble = SpeechBubbleScript.new()
	_choir_leader_bubble.position = CHOIR_LEADER_BUBBLE_OFS
	_choir_leader.add_child(_choir_leader_bubble)

	add_child(_choir_leader)

	_cl_target     = CHOIR_LEADER_WAYPOINTS[0]
	_cl_idle_timer = randf_range(1.5, 3.0)
	_cl_yell_timer = randf_range(CHOIR_LEADER_YELL_MIN, CHOIR_LEADER_YELL_MAX)
	_cl_walking    = false

func _update_choir_leader(delta: float) -> void:
	if not is_instance_valid(_choir_leader):
		return

	_cl_yell_timer -= delta
	if _cl_yell_timer <= 0.0:
		_cl_yell_timer = randf_range(CHOIR_LEADER_YELL_MIN, CHOIR_LEADER_YELL_MAX)
		_choir_leader_bubble.show_text(CHOIR_LEADER_YELL_TEXT, CHOIR_LEADER_BUBBLE_DUR)

	if not _cl_walking:
		_cl_idle_timer -= delta
		if _cl_idle_timer <= 0.0:
			_cl_target  = CHOIR_LEADER_WAYPOINTS[randi() % CHOIR_LEADER_WAYPOINTS.size()]
			_cl_walking = true
	else:
		var to_target: Vector2 = _cl_target - _choir_leader.position
		if to_target.length() < 3.0:
			_choir_leader.position = _cl_target
			_cl_walking    = false
			_cl_idle_timer = CHOIR_LEADER_IDLE_TIME
		else:
			_choir_leader.position += to_target.normalized() * CHOIR_LEADER_SPEED * delta

# ── Shared dialog closed handler ──────────────────────────────────────────────

# Applies any set_flag effects, refreshes the four congregation sub-flags
# (which may have just been set by a completed NPC conversation), then checks
# whether both characters have finished their two members.
func _on_dialog_closed(effects: Array) -> void:
	for fx: Dictionary in effects:
		if fx.has("set_flag"):
			GameManager.set_level_flag(LOCATION_ID, fx["set_flag"], fx.get("flag_value", true))
	_quinn_npc1_done = GameManager.get_level_flag(LOCATION_ID, "quinn_npc1_done", false)
	_quinn_npc2_done = GameManager.get_level_flag(LOCATION_ID, "quinn_npc2_done", false)
	_erin_npc1_done  = GameManager.get_level_flag(LOCATION_ID, "erin_npc1_done", false)
	_erin_npc2_done  = GameManager.get_level_flag(LOCATION_ID, "erin_npc2_done", false)
	_update_aldric_animation()
	if _quinn_done and _erin_done and not clear_label.visible:
		hint_label.text = ""
		clear_label.text = "PARISH CLEARED!\n\nPress ENTER for the Map"
		clear_label.visible = true
		Audio.play("puzzle_complete")
		Audio.play_music("victory")

# ── Input / game loop ─────────────────────────────────────────────────────────

func _talk_to_choir_leader() -> void:
	var tree: Dictionary = DialogTreeScript.from_pages(
		[CHOIR_LEADER_QUIPS[randi() % CHOIR_LEADER_QUIPS.size()]])
	Audio.play("ui_select")
	_dialog_box.open("Choir Director", CHOIR_LEADER_COLOR, tree, "start", "")

func _on_special_used(char_name: String) -> void:
	if _dialog_box.is_open():
		return
	var p: Player = quinn if char_name == "Quinn" else erin
	for i: int in _loot_boxes.size():
		if _loot_boxes[i].try_open(char_name, p.global_position):
			GameManager.set_level_flag(LOCATION_ID, LOOT_FLAG_KEYS[i], true)
			return
	if char_name == "Quinn" and not _secret_revealed and quinn.global_position.distance_to(LEVER_POS) < LEVER_RADIUS:
		_reveal_secret_passage()
		return
	if p.global_position.distance_to(ALDRIC_POS) < ALDRIC_RADIUS:
		_talk_to_father_aldric(char_name)
		return
	if is_instance_valid(_choir_leader) and \
			p.global_position.distance_to(_choir_leader.position) < NPC_RADIUS:
		_talk_to_choir_leader()
		return
	for npc_id: String in NPC_POSITIONS.keys():
		if p.global_position.distance_to(NPC_POSITIONS[npc_id]) < NPC_RADIUS:
			_talk_to_npc(npc_id, char_name)
			return
	if GameManager.try_use_whistle():
		Audio.play("special")

func _process(delta: float) -> void:
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
	_update_choir_leader(delta)
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
	if _quinn_done and not _erin_done:
		hint_label.text = "Swap to Erin [ TAB ] -- the congregation still has more to say"
		return
	if not _quinn_done and _erin_done:
		hint_label.text = "Swap to Quinn [ TAB ] -- some will only open up to her"
		return
	# Proximity prompt when near any NPC or Aldric.
	for npc_id: String in NPC_POSITIONS.keys():
		if active.global_position.distance_to(NPC_POSITIONS[npc_id]) < NPC_RADIUS + 40.0:
			hint_label.text = "Press G to speak"
			return
	if active.global_position.distance_to(ALDRIC_POS) < ALDRIC_RADIUS + 40.0:
		hint_label.text = "Press G to speak with Father Aldric"
		return
	hint_label.text = "Speak with the congregation -- someone here knew the stranger"
