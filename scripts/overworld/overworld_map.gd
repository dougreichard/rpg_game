extends Node2D

# Overworld map — see locations/00_overworld_map.md for the full design doc.
# A 40x19 tile grid (1280x608px, matching the playable area above the UI
# band) rendered with the shared PlaceholderArt.make_hb_tileset() across
# three TileMap layers: grass, roads, buildings. The active/standby duo
# walks the town with overworld_player.gd; a few town_npc.gd wanderers add
# life. Walking up to a building's door tile and pressing interact launches
# that location (replacing the old cursor-based selection).

const TILE: int = 32
# The original 40x19 layout (LOCS anchors, NPC homes, etc.) is placed inside a
# larger padded grid via MAP_OFFSET, giving room for the camera to scroll
# around the town like a level's camera-follow instead of showing it all at
# once.
const MAP_OFFSET: Vector2i = Vector2i(10, 8)
const GRID_COLS: int = 40 + MAP_OFFSET.x * 2
const GRID_ROWS: int = 19 + MAP_OFFSET.y * 2
const INTERACT_RADIUS: float = 48.0
const NPC_INTERACT_RADIUS: float = 40.0
const CAMERA_SMOOTHING_SPEED: float = 5.0

# Quest state lives in GameManager.level_progress under this pseudo-location
# id, the same get/set_level_flag pattern every level uses for its own
# progress -- see CLAUDE.md "NPC dialog & quests".
const TOWN_ID: String = "town"

const PlayerScript: Script = preload("res://scripts/overworld/overworld_player.gd")
const NpcScript: Script = preload("res://scripts/overworld/town_npc.gd")
const DialogBoxScript: Script = preload("res://scripts/ui/dialog_box.gd")

const CHAR_DATA: Dictionary = {
	"Quinn": preload("res://data/characters/quinn.tres"),
	"Erin": preload("res://data/characters/erin.tres"),
	"Evan": preload("res://data/characters/evan.tres"),
	"Ben": preload("res://data/characters/ben.tres"),
	"Ethan": preload("res://data/characters/ethan.tres"),
}

# Terrain rows in PlaceholderArt.make_hb_tileset() (8 rows x 12 cols, 32x32)
const T_STONE: int = 0
const T_WORKSHOP: int = 1
const T_WOOD: int = 2
const T_OUTDOOR: int = 3
const T_TUNNEL: int = 4
const T_DOCK: int = 5
const T_CARPET: int = 6
const T_CYBER: int = 7

const GRASS_TILE: Vector2i = Vector2i(4, T_OUTDOOR)
const GRASS_ACCENT_TILE: Vector2i = Vector2i(2, T_OUTDOOR)
const GRASS_ACCENT_PERIOD: int = 5
const ROAD_TILE: Vector2i = Vector2i(0, T_STONE)
# zip_line / the_drop share the OUTDOOR row with grass — use distinct columns
# so their building footprints read as built structures, not more lawn.
const OUTDOOR_BUILDING_TILES: Array = [Vector2i(5, T_OUTDOOR), Vector2i(8, T_OUTDOOR)]

const LOCS: Array = [
	{
		"id": "pipe_organ_works", "name": "Bellows & Sons Pipe Organ Works",
		"short": "Organ\nWorks", "scene": "res://scenes/levels/PipeOrganWorks.tscn",
		"anchor": Vector2i(3, 15), "size": Vector2i(4, 3), "terrain_row": T_WORKSHOP,
		"requires": "", "icon": "gear", "duo": ["Quinn", "Erin"],
	},
	{
		"id": "old_parish_church", "name": "The Old Parish Church",
		"short": "Parish\nChurch", "scene": "res://scenes/levels/OldParishChurch.tscn",
		"anchor": Vector2i(9, 12), "size": Vector2i(4, 3), "terrain_row": T_STONE,
		"requires": "pipe_organ_works", "icon": "arch", "duo": ["Quinn", "Erin"],
	},
	{
		"id": "iron_strings_gym", "name": "Iron & Strings Gym",
		"short": "Gym", "scene": "res://scenes/levels/IronStringsGym.tscn",
		"anchor": Vector2i(15, 11), "size": Vector2i(4, 3), "terrain_row": T_WORKSHOP,
		"requires": "old_parish_church", "icon": "dumbbell", "duo": ["Quinn", "Evan"],
	},
	{
		"id": "recording_studio", "name": "The Recording Studio",
		"short": "Studio", "scene": "res://scenes/levels/RecordingStudio.tscn",
		"anchor": Vector2i(21, 12), "size": Vector2i(4, 3), "terrain_row": T_WOOD,
		"requires": "iron_strings_gym", "icon": "note", "duo": ["Quinn", "Ben"],
	},
	{
		"id": "clocktower", "name": "The Clocktower",
		"short": "Clock-\ntower", "scene": "res://scenes/levels/Clocktower.tscn",
		"anchor": Vector2i(19, 4), "size": Vector2i(3, 4), "terrain_row": T_STONE,
		"requires": "recording_studio", "icon": "clock", "duo": ["Quinn", "Ben"],
	},
	{
		"id": "harbor_docks", "name": "The Harbor & Docks",
		"short": "Harbor\n& Docks", "scene": "res://scenes/levels/HarborDocks.tscn",
		"anchor": Vector2i(27, 14), "size": Vector2i(5, 3), "terrain_row": T_DOCK,
		"requires": "recording_studio", "icon": "anchor", "duo": ["Quinn", "Evan"],
	},
	{
		"id": "library", "name": "The Public Library & Archive",
		"short": "Library", "scene": "res://scenes/levels/LibraryArchive.tscn",
		"anchor": Vector2i(12, 4), "size": Vector2i(4, 3), "terrain_row": T_STONE,
		"requires": "recording_studio", "icon": "book", "duo": ["Erin", "Ethan"],
	},
	{
		"id": "carnival", "name": "The Carnival & Fairground",
		"short": "Carnival", "scene": "res://scenes/levels/Carnival.tscn",
		"anchor": Vector2i(25, 6), "size": Vector2i(5, 4), "terrain_row": T_WOOD,
		"requires": "recording_studio", "icon": "star", "duo": ["Quinn", "Erin"],
	},
	{
		"id": "underground", "name": "The Underground Tunnels",
		"short": "Tunnels", "scene": "res://scenes/levels/UndergroundTunnels.tscn",
		"anchor": Vector2i(20, 15), "size": Vector2i(4, 3), "terrain_row": T_TUNNEL,
		"requires": "recording_studio", "icon": "tunnel", "duo": ["Evan", "Ethan"],
	},
	{
		"id": "zip_line", "name": "Zip Line Park",
		"short": "Zip Line\nPark", "scene": "res://scenes/levels/ZipLinePark.tscn",
		"anchor": Vector2i(30, 8), "size": Vector2i(4, 3), "terrain_row": T_OUTDOOR,
		"requires": "recording_studio", "icon": "zipline", "duo": ["Ethan", "Ben"],
	},
	{
		"id": "vr_room", "name": "VR Escape Room",
		"short": "VR Room", "scene": "res://scenes/levels/VrEscapeRoom.tscn",
		"anchor": Vector2i(24, 3), "size": Vector2i(4, 3), "terrain_row": T_CYBER,
		"requires": "recording_studio", "icon": "hex", "duo": ["Quinn", "Ethan"],
	},
	{
		"id": "the_drop", "name": "The Drop",
		"short": "The\nDrop", "scene": "res://scenes/levels/TheDrop.tscn",
		"anchor": Vector2i(8, 3), "size": Vector2i(4, 3), "terrain_row": T_OUTDOOR,
		"requires": "vr_room", "icon": "chevron", "duo": ["Evan", "Ethan"],
	},
	{
		"id": "grand_marquee", "name": "The Grand Marquee Cinema",
		"short": "Grand\nMarquee", "scene": "res://scenes/levels/GrandMarqueeCinema.tscn",
		"anchor": Vector2i(17, 0), "size": Vector2i(5, 4), "terrain_row": T_CARPET,
		"requires": "the_drop", "icon": "film", "duo": ["Quinn", "Ben"],
	},
]

const CONNECTIONS: Array = [
	["pipe_organ_works", "old_parish_church"],
	["old_parish_church", "iron_strings_gym"],
	["iron_strings_gym", "recording_studio"],
	["recording_studio", "clocktower"],
	["recording_studio", "harbor_docks"],
	["clocktower", "library"],
	["clocktower", "carnival"],
	["clocktower", "vr_room"],
	["library", "underground"],
	["harbor_docks", "zip_line"],
	["carnival", "zip_line"],
	["vr_room", "the_drop"],
	["the_drop", "grand_marquee"],
	["vr_room", "grand_marquee"],
]

# Townsfolk, homed on open grass between the buildings (verified clear of
# every footprint in LOCS above). Each is a quest-giver -- see CLAUDE.md
# "NPC dialog & quests" -- whose `quest_id` indexes into QUESTS below.
const NPC_DATA: Array = [
	{"home": Vector2i(5, 10), "name": "Gus", "color": Color(0.60, 0.55, 0.48), "quest_id": "gus"},
	{"home": Vector2i(16, 5), "name": "Moira", "color": Color(0.50, 0.58, 0.55), "quest_id": "moira"},
	{"home": Vector2i(28, 11), "name": "Reggie", "color": Color(0.58, 0.50, 0.60), "quest_id": "reggie"},
	{"home": Vector2i(14, 16), "name": "Fanny", "color": Color(0.62, 0.60, 0.45), "quest_id": "fanny"},
	{"home": Vector2i(8, 13), "name": "Penny", "color": Color(0.85, 0.55, 0.65), "quest_id": "penny"},
	{"home": Vector2i(33, 15), "name": "Otis", "color": Color(0.40, 0.55, 0.70), "quest_id": "otis"},
]

# Each quest asks for one (already-placed, mostly pre-existing junk/lore)
# collectible and -- if `give_item` is non-empty -- hands back a reward item
# on turn-in. Dialog is paged (each entry is shown until the player presses
# ui_accept again); use "\n" for a second line. State machine per quest is
# not_started -> active -> complete, persisted via
# GameManager.get/set_level_flag(TOWN_ID, "quest_<id>", ...).
const QUESTS: Dictionary = {
	"gus": {
		"want_item": "bent_spoon", "give_item": "",
		"intro": [
			"Gus: Eh? Oh, it's you two.\nHaven't seen strangers 'round\nhere in ages.",
			"Gus: Say -- you didn't happen\nto find an old bent spoon in\nthat organ workshop, did you?",
			"Gus: Silly thing to miss, I\nknow. But it was Doug's -- he\nused it to tap pipe seams.",
			"Gus: If you spot it, bring it\nback. I'd consider it a favor\nbetween friends.",
		],
		"reminder": [
			"Gus: Still keeping an eye out\nfor that bent spoon? Workshop\nfloor, probably, knowing Doug.",
		],
		"turn_in": [
			"Gus: That's it! That's Doug's\nold tapping spoon, bent from\nyears of pipe work.",
			"Gus: Thank you. He'd want\nsomeone to have it who'd\nremember what it was for.",
			"Gus: He used to say a pipe\norgan's only as good as the\nhands that tune it. Miss him.",
		],
		"after": [
			"Gus: Thanks again for that\nspoon. Keeps me thinking\nabout the old days.",
		],
	},
	"moira": {
		"want_item": "skeleton_key", "give_item": "",
		"intro": [
			"Moira: Oh! Hello, dears. You\nlook like you're headed\nsomewhere important.",
			"Moira: If your travels take you\nthrough the Library, keep an\neye out for an old skeleton key.",
			"Moira: I lent it to a friend ages\nago and never got it back.\nHaven't seen him since, either.",
			"Moira: Funny -- it doesn't open\nanything anymore. But I'd\nlike it back all the same.",
		],
		"reminder": [
			"Moira: Still no luck with that\nskeleton key? It's probably\ngathering dust in the stacks.",
		],
		"turn_in": [
			"Moira: You found it! Oh, thank\nyou. I haven't held this in\nyears.",
			"Moira: ...Wait. Look here, on\nthe bow -- someone scratched a\nlittle 'D.' into the metal.",
			"Moira: That's HIS mark. The\nfriend I lent it to. Doug\nalways signed his things.",
			"Moira: He must have tried every\nlock in town with this before\ngiving up. Typical Doug.",
			"Moira: Wherever he's gotten to,\nI hope he's all right. Thank\nyou for bringing this home.",
		],
		"after": [
			"Moira: Strange, holding Doug's\nkey again. Made me think of\nhim all day. Thank you.",
		],
	},
	"reggie": {
		"want_item": "arcade_token", "give_item": "",
		"intro": [
			"Reggie: Hey hey! You two look\nlike you can keep a secret.",
			"Reggie: Years back, me and a\nfella named Doug built an\narcade cabinet from scratch.",
			"Reggie: Never finished it -- Doug\nhad the only token that fit\nthe coin slot. Custom-made!",
			"Reggie: If you ever spot a token\nwith a logo that doesn't match\nANY arcade you know... that's it.",
			"Reggie: Bring it here, would you?\nI think I finally know where\nthe cabinet's hiding.",
		],
		"reminder": [
			"Reggie: Keep your eyes peeled\nfor that one-of-a-kind arcade\ntoken, yeah? You'll know it.",
		],
		"turn_in": [
			"Reggie: THAT'S IT! That's Doug's\ntoken! I'd know that goofy\nlogo anywhere.",
			"Reggie: He had it cast special,\nsaid 'so nobody else can ever\nplay MY high score.'",
			"Reggie: With this, I bet I can\nget that old cabinet running\nagain. For old time's sake.",
			"Reggie: ...And maybe, just maybe,\nit'll tell us something about\nwhere he went. Thanks, you two.",
		],
		"after": [
			"Reggie: Still tinkering with that\ncabinet. One of these days,\nI'll get it humming again.",
		],
	},
	"fanny": {
		"want_item": "fannys_bottle", "give_item": "",
		"intro": [
			"Fanny: Oh, hello. You'll have to\nexcuse me -- I've been a bit\nout of sorts lately.",
			"Fanny: I lost a little bottle of\nmine somewhere in those awful\ntunnels. F.B., it's marked.",
			"Fanny: Lavender scent. My\nfavorite. I've looked\neverywhere I dare to go.",
			"Fanny: If you're brave enough to\nsearch down there, I'd be so\ngrateful to have it back.",
		],
		"reminder": [
			"Fanny: Still no sign of my\nlittle bottle? It's dark down\nthere -- you may need a light.",
		],
		"turn_in": [
			"Fanny: You found it! Oh, thank\ngoodness. I thought I'd lost\nit for good.",
			"Fanny: Doug gave me this, you\nknow. The day before he\ndisappeared.",
			"Fanny: He said, 'Hang onto this,\nFanny -- something to remember\nme by, just in case.'",
			"Fanny: I didn't think much of it\nat the time. Now I wonder if\nhe knew something was coming.",
			"Fanny: Thank you for finding it.\nIt means more to me than you\ncould know.",
		],
		"after": [
			"Fanny: I keep that bottle close\nnow. Thank you again for\nbringing it back to me.",
		],
	},
	"penny": {
		"want_item": "embroidered_handkerchief", "give_item": "stitched_patch",
		"intro": [
			"Penny: Hiya! You two look like\nyou get around. Mind doing me\na favor?",
			"Penny: I was mending an old\nhandkerchief for a customer --\nan embroidered 'D,' very fancy.",
			"Penny: I dropped it somewhere in\nthe Old Parish Church on my way\nto deliver it. So clumsy!",
			"Penny: The customer was a sweet\nold fellow named Doug. Haven't\nseen him to apologize, even.",
			"Penny: If you find it among the\npews, I'd be ever so grateful.\nI'll make it worth your while!",
		],
		"reminder": [
			"Penny: Any luck with that\nhandkerchief? Should be\nsomewhere around the pews.",
		],
		"turn_in": [
			"Penny: You found it! Oh, thank\nyou! I felt awful about losing\nMr. Doug's handkerchief.",
			"Penny: Here -- I made this little\npatch for whoever found it. A\ngear, since Doug loved his tools.",
			"Penny: Sew it on somewhere\nnobody will notice. It's small,\nbut it's something.",
			"Penny: If you do see Doug around,\ntell him I'm sorry -- and that\nI'll mend it properly this time.",
		],
		"after": [
			"Penny: Still hoping to track down\nMr. Doug and finish that\nmending properly. Thanks again.",
		],
	},
	"otis": {
		"want_item": "brass_compass", "give_item": "sailors_knot_bracelet",
		"intro": [
			"Otis: Well now, fresh faces!\nDon't get many of those down\nby the docks these days.",
			"Otis: Say -- you wouldn't have\nspotted an old brass compass\nlying around the harbor, eh?",
			"Otis: Lost it in all the cargo\nshuffle. Hasn't pointed north\nright in years, but it's mine.",
			"Otis: Engraved on the back: 'To\nO.' -- that's me, Otis. Gift\nfrom an old friend.",
			"Otis: Find it for me and I'll tie\nyou up a proper sailor's knot.\nGood luck charm, that.",
		],
		"reminder": [
			"Otis: Still keeping an eye out\nfor my compass? Probably buried\nunder cargo somewhere.",
		],
		"turn_in": [
			"Otis: Ha! There it is. Knew it\nhad to be down here\nsomewhere.",
			"Otis: 'To O., so you always find\nyour way home.' Doug gave me\nthis, years back.",
			"Otis: Funny thing to give a\nsailor whose home IS the docks.\nBut that was Doug.",
			"Otis: Said everybody needs a way\nback, even if they don't know\nthey're lost yet.",
			"Otis: Here -- a sailor's knot,\nlike I promised. Tie it on.\nMight bring you luck, too.",
		],
		"after": [
			"Otis: That compass still doesn't\npoint north. But it points\nhome. Good enough for me.",
		],
	},
}

var _id_to_idx: Dictionary = {}
var _loc_pos: Array = []   # Vector2 pixel center per location, parallel to LOCS
var _loc_door: Array = []  # Vector2i door tile per location, parallel to LOCS
var _nearby_idx: int = -1
var _npcs: Array = []      # parallel to NPC_DATA
var _nearby_npc_idx: int = -1
var _font: Font
var _name_label: Label
var _status_label: Label
var _dialog_box = null
var _active_player = null
var _standby_player = null

@onready var camera: Camera2D = $Camera2D


# LOCS anchors are authored against the original 40x19 layout; offset them
# into the padded GRID_COLS x GRID_ROWS grid.
func _anchor(loc: Dictionary) -> Vector2i:
	return Vector2i(loc["anchor"]) + MAP_OFFSET


func _ready() -> void:
	Audio.play_music("overworld")
	_font = ThemeDB.fallback_font
	for i in LOCS.size():
		var loc: Dictionary = LOCS[i]
		_id_to_idx[loc["id"]] = i
		var anchor: Vector2i = _anchor(loc)
		var size: Vector2i = loc["size"]
		_loc_pos.append(Vector2((anchor.x + size.x / 2.0) * TILE, (anchor.y + size.y / 2.0) * TILE))
		_loc_door.append(Vector2i(anchor.x + size.x / 2, mini(anchor.y + size.y, GRID_ROWS - 1)))
	_build_floor()
	_build_building_colliders()
	_build_ui()
	_setup_camera()
	_spawn_duo()
	_spawn_npcs()
	_update_info()


# Camera follows the active duo member within the full padded grid, the same
# position_smoothing + limit_* pattern every level's _setup_camera() uses.
func _setup_camera() -> void:
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = CAMERA_SMOOTHING_SPEED
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = GRID_COLS * TILE
	camera.limit_bottom = GRID_ROWS * TILE

# Three-layer TileMap: grass (0), roads (1), buildings (2) — all drawn from
# the shared PlaceholderArt.make_hb_tileset() atlas, source_id 0.
func _build_floor() -> void:
	var tile_map := TileMap.new()
	tile_map.name = "Floor"
	tile_map.tile_set = PlaceholderArt.make_hb_tileset()
	add_child(tile_map)
	move_child(tile_map, 0)
	tile_map.add_layer(1)
	tile_map.add_layer(2)

	for x: int in GRID_COLS:
		for y: int in GRID_ROWS:
			var tile: Vector2i = GRASS_ACCENT_TILE if (x * 7 + y * 13) % GRASS_ACCENT_PERIOD == 0 else GRASS_TILE
			tile_map.set_cell(0, Vector2i(x, y), 0, tile)

	for conn: Array in CONNECTIONS:
		var ai: int = _id_to_idx.get(conn[0], -1)
		var bi: int = _id_to_idx.get(conn[1], -1)
		if ai < 0 or bi < 0:
			continue
		_paint_road(tile_map, _loc_door[ai], _loc_door[bi])

	for i: int in LOCS.size():
		_paint_building(tile_map, i)

# Orthogonal L-shaped road: horizontal run from a along a's row to b's column,
# then vertical run down/up b's column to b. Roads sit on layer 1, buildings
# on layer 2 painted afterward, so any road tile under a building footprint
# is simply covered — no routing-around-buildings logic needed.
func _paint_road(tile_map: TileMap, a: Vector2i, b: Vector2i) -> void:
	var x: int = a.x
	while true:
		tile_map.set_cell(1, Vector2i(x, a.y), 0, ROAD_TILE)
		if x == b.x:
			break
		x += signi(b.x - a.x)
	var y: int = a.y
	while true:
		tile_map.set_cell(1, Vector2i(b.x, y), 0, ROAD_TILE)
		if y == b.y:
			break
		y += signi(b.y - a.y)

func _paint_building(tile_map: TileMap, idx: int) -> void:
	var loc: Dictionary = LOCS[idx]
	var anchor: Vector2i = _anchor(loc)
	var size: Vector2i = loc["size"]
	var tiles: Array = OUTDOOR_BUILDING_TILES if loc["terrain_row"] == T_OUTDOOR else \
			[Vector2i(0, loc["terrain_row"]), Vector2i(1, loc["terrain_row"])]
	for x: int in range(anchor.x, anchor.x + size.x):
		for y: int in range(anchor.y, anchor.y + size.y):
			var tile: Vector2i = tiles[1] if (x + y) % 3 == 0 else tiles[0]
			tile_map.set_cell(2, Vector2i(x, y), 0, tile)

# One StaticBody2D per building footprint so the duo can't walk through them —
# the door tile (one row below the footprint) is left clear for entry.
func _build_building_colliders() -> void:
	var holder := Node2D.new()
	holder.name = "BuildingColliders"
	add_child(holder)
	for loc: Dictionary in LOCS:
		var anchor: Vector2i = _anchor(loc)
		var size: Vector2i = loc["size"]
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(size.x * TILE, size.y * TILE)
		shape.shape = rect
		body.add_child(shape)
		body.position = Vector2((anchor.x + size.x / 2.0) * TILE, (anchor.y + size.y / 2.0) * TILE)
		holder.add_child(body)

# Active character is player-controlled (move_* inputs); standby follows a
# short distance behind, mirroring the in-level standby's "follow / hold"
# behavior. The pair is the first two of GameManager.unlocked_characters —
# the same roster order a fresh level would default to.
func _spawn_duo() -> void:
	var names: Array = GameManager.unlocked_characters
	var active_name: String = String(names[0]).capitalize() if names.size() > 0 else "Quinn"
	var standby_name: String = String(names[1]).capitalize() if names.size() > 1 else "Erin"
	# Spawn at the door of whichever location the duo last left (set by that
	# level's _exit_to_overworld), so re-entering the overworld picks up where
	# they left off instead of always starting at Pipe Organ Works.
	var spawn_idx: int = _id_to_idx.get(GameManager.last_location_id, _id_to_idx["pipe_organ_works"])
	var spawn: Vector2 = Vector2(_loc_door[spawn_idx]) * TILE + Vector2(TILE / 2.0, TILE / 2.0)

	_active_player = PlayerScript.new()
	add_child(_active_player)
	_active_player.setup(_load_player_frames(active_name))
	_active_player.global_position = spawn
	_active_player.mode = PlayerScript.Mode.ACTIVE

	_standby_player = PlayerScript.new()
	add_child(_standby_player)
	_standby_player.setup(_load_player_frames(standby_name))
	_standby_player.global_position = spawn + Vector2(-TILE, 0.0)
	_standby_player.mode = PlayerScript.Mode.FOLLOW

# Same SpriteLoader-with-PlaceholderArt-fallback pattern as player.gd, so the
# overworld duo matches the sprite sheets used in-level instead of always
# falling back to placeholder art.
func _load_player_frames(character_name: String) -> SpriteFrames:
	var loaded: SpriteFrames = SpriteLoader.try_load_player(character_name)
	if loaded != null:
		return loaded
	return PlaceholderArt.make_player_frames(CHAR_DATA[character_name].sprite_color, character_name)

func _spawn_npcs() -> void:
	for i: int in NPC_DATA.size():
		var data: Dictionary = NPC_DATA[i]
		var npc = NpcScript.new()
		add_child(npc)
		var home: Vector2 = Vector2(Vector2i(data["home"]) + MAP_OFFSET) * TILE + Vector2(TILE / 2.0, TILE / 2.0)
		npc.setup(PlaceholderArt.make_player_frames(data["color"], ""), home, data["name"], data["quest_id"])
		_npcs.append(npc)

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)

	var title := Label.new()
	title.text = "HUNKLE BUNKLE"
	title.position = Vector2(0.0, 8.0)
	title.size = Vector2(1280.0, 44.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
	canvas.add_child(title)

	var map_sub := Label.new()
	map_sub.text = "TOWN"
	map_sub.position = Vector2(0.0, 50.0)
	map_sub.size = Vector2(1280.0, 26.0)
	map_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_sub.add_theme_font_size_override("font_size", 16)
	map_sub.add_theme_color_override("font_color", Color(0.55, 0.5, 0.75))
	canvas.add_child(map_sub)

	var panel := ColorRect.new()
	panel.color = Color(0.0, 0.0, 0.0, 0.75)
	panel.position = Vector2(0.0, 608.0)
	panel.size = Vector2(1280.0, 112.0)
	canvas.add_child(panel)

	_name_label = Label.new()
	_name_label.position = Vector2(0.0, 614.0)
	_name_label.size = Vector2(1280.0, 46.0)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 24)
	_name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	canvas.add_child(_name_label)

	_status_label = Label.new()
	_status_label.position = Vector2(0.0, 658.0)
	_status_label.size = Vector2(1280.0, 28.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", Color(0.68, 0.68, 0.7))
	canvas.add_child(_status_label)

	var hint := Label.new()
	hint.text = "Move: WASD / Arrows / Stick     Swap duo: Tab     Enter / Talk: Enter / F"
	hint.position = Vector2(0.0, 690.0)
	hint.size = Vector2(1280.0, 24.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.38, 0.38, 0.42))
	canvas.add_child(hint)

	_dialog_box = DialogBoxScript.new()
	canvas.add_child(_dialog_box)

func _update_info() -> void:
	if _nearby_idx < 0:
		_name_label.text = "Hunkle Bunkle"
		_name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		_status_label.text = "Walk up to a building and press Enter / F to enter"
		return
	var loc: Dictionary = LOCS[_nearby_idx]
	_name_label.text = loc["name"]
	if _is_completed(_nearby_idx):
		_status_label.text = "Completed   --   Press Enter to revisit"
		_name_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.45))
	elif _is_unlocked(_nearby_idx):
		if loc["scene"] == "":
			_status_label.text = "Unlocked   --   Coming soon"
		else:
			_status_label.text = "Unlocked   --   Press Enter to play"
		_name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		var req: String = loc["requires"]
		var req_idx: int = _id_to_idx.get(req, -1)
		var req_name: String = LOCS[req_idx]["name"] if req_idx >= 0 else req
		_status_label.text = "Locked   --   Complete \"" + req_name + "\" first"
		_name_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))

func _is_unlocked(idx: int) -> bool:
	var req: String = LOCS[idx]["requires"]
	return req == "" or req in GameManager.completed_locations

func _is_completed(idx: int) -> bool:
	return LOCS[idx]["id"] in GameManager.completed_locations

func _process(_delta: float) -> void:
	if is_instance_valid(_standby_player):
		_standby_player.follow_target = _active_player.global_position - _active_player.facing * (TILE * 0.9)
	if is_instance_valid(_active_player):
		camera.global_position = _active_player.global_position
	_update_nearby()
	_update_nearby_npc()
	if Input.is_action_just_pressed("swap") and not _dialog_box.is_open():
		_swap_duo()
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
		if _dialog_box.is_open():
			_dialog_box.advance()
		elif _nearby_npc_idx >= 0:
			_talk_to_npc(_nearby_npc_idx)
		else:
			_launch()
	queue_redraw()

# Whichever building's door tile the active character is standing closest to
# (within INTERACT_RADIUS) becomes the "nearby" location — replaces the old
# cursor-based selection entirely.
func _update_nearby() -> void:
	var prev: int = _nearby_idx
	_nearby_idx = -1
	var best_dist: float = INTERACT_RADIUS
	for i: int in LOCS.size():
		var door_px: Vector2 = Vector2(_loc_door[i]) * TILE + Vector2(TILE / 2.0, TILE / 2.0)
		var d: float = _active_player.global_position.distance_to(door_px)
		if d < best_dist:
			best_dist = d
			_nearby_idx = i
	if _nearby_idx != prev:
		_update_info()

# Whichever townsfolk the active character is standing closest to (within
# NPC_INTERACT_RADIUS) becomes "nearby" -- mirrors _update_nearby() above for
# building doors. Drawn as a pulsing ring + name prompt in _draw().
func _update_nearby_npc() -> void:
	_nearby_npc_idx = -1
	var best_dist: float = NPC_INTERACT_RADIUS
	for i: int in _npcs.size():
		var d: float = _active_player.global_position.distance_to(_npcs[i].global_position)
		if d < best_dist:
			best_dist = d
			_nearby_npc_idx = i

# NPC dialog & quest state machine -- see CLAUDE.md "NPC dialog & quests".
# not_started -> active (shows intro, quest now tracked) -> complete (turn-in
# consumes want_item, grants give_item if any). Reminder shown while active
# and the player hasn't found the item yet; after shown once complete.
func _talk_to_npc(idx: int) -> void:
	var npc = _npcs[idx]
	var quest: Dictionary = QUESTS.get(npc.quest_id, {})
	if quest.is_empty():
		return
	var flag_key: String = "quest_" + npc.quest_id
	var state: String = GameManager.get_level_flag(TOWN_ID, flag_key, "not_started")
	var lines: PackedStringArray
	match state:
		"complete":
			lines = quest["after"]
		"active":
			var holder: String = _find_item_holder(quest["want_item"])
			if holder != "":
				GameManager.consume_item(holder, quest["want_item"])
				if quest["give_item"] != "":
					GameManager.grant_item(holder, quest["give_item"])
				GameManager.set_level_flag(TOWN_ID, flag_key, "complete")
				lines = quest["turn_in"]
			else:
				lines = quest["reminder"]
		_:
			GameManager.set_level_flag(TOWN_ID, flag_key, "active")
			lines = quest["intro"]
	Audio.play("ui_select")
	_dialog_box.open(npc.npc_name, NPC_DATA[idx]["color"], lines)

# Returns the lowercase name of the first unlocked character holding
# `item_id`, or "" if none do -- mirrors GameManager.has_item's lowercase
# inventory keys, so the result can be passed straight to consume_item/
# grant_item.
func _find_item_holder(item_id: String) -> String:
	for character_name in GameManager.unlocked_characters:
		if GameManager.has_item(character_name, item_id):
			return character_name
	return ""

func _swap_duo() -> void:
	if not is_instance_valid(_standby_player):
		return
	var tmp = _active_player
	_active_player = _standby_player
	_standby_player = tmp
	_active_player.mode = PlayerScript.Mode.ACTIVE
	_standby_player.mode = PlayerScript.Mode.FOLLOW
	Audio.play("swap")

func _launch() -> void:
	if _nearby_idx < 0:
		return
	var loc: Dictionary = LOCS[_nearby_idx]
	if not _is_unlocked(_nearby_idx):
		_status_label.text = "Locked   --   Complete the previous location first"
		return
	if loc["scene"] == "":
		_status_label.text = "Coming soon!"
		return
	Audio.play("ui_select")
	GameManager.pending_level = loc["scene"]
	GameManager.pending_level_name = loc["name"]
	GameManager.pending_level_duo = loc.get("duo", [])
	GameManager.preferred_active = loc.get("duo", [""])[0]
	TransitionManager.change_scene("res://scenes/ui/CharacterSelect.tscn")

func _draw() -> void:
	for i: int in LOCS.size():
		_draw_building_overlay(i)
	if _nearby_idx >= 0:
		_draw_interact_ring(_nearby_idx)
	if _nearby_npc_idx >= 0:
		_draw_npc_prompt(_nearby_npc_idx)

func _draw_building_overlay(idx: int) -> void:
	var loc: Dictionary = LOCS[idx]
	var p: Vector2 = _loc_pos[idx]
	var icon: String = loc.get("icon", "")
	var unlocked: bool = _is_unlocked(idx)
	var completed: bool = _is_completed(idx)
	var anchor: Vector2i = _anchor(loc)
	var size: Vector2i = loc["size"]
	var rect := Rect2(Vector2(anchor) * TILE, Vector2(size) * TILE)

	if not unlocked:
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.55))
	elif completed:
		draw_rect(rect, Color(0.3, 1.0, 0.4, 0.10))

	var icon_col: Color = Color(1.0, 1.0, 1.0, 0.9) if unlocked else Color(0.5, 0.5, 0.55, 0.6)
	_draw_icon(icon, p, icon_col)

	var label_col: Color
	if idx == _nearby_idx:  label_col = Color(1.0, 1.0, 0.4)
	elif completed:         label_col = Color(0.40, 1.0, 0.50)
	elif unlocked:          label_col = Color(0.90, 0.88, 0.82)
	else:                   label_col = Color(0.42, 0.42, 0.46)
	var lines: PackedStringArray = loc["short"].split("\n")
	for li: int in lines.size():
		draw_string(_font, Vector2(p.x - 48.0, rect.end.y + 12.0 + li * 12.0),
				lines[li], HORIZONTAL_ALIGNMENT_CENTER, 96.0, 9, label_col)

func _draw_interact_ring(idx: int) -> void:
	var door_px: Vector2 = Vector2(_loc_door[idx]) * TILE + Vector2(TILE / 2.0, TILE / 2.0)
	var pulse: float = (sin(Time.get_ticks_msec() / 200.0) + 1.0) * 0.5
	draw_arc(door_px, 14.0 + pulse * 3.0, 0.0, TAU, 20, Color(1.0, 0.92, 0.30), 2.0, true)

# Pulsing ring + name label above a nearby NPC -- the same "press Enter/F"
# affordance as _draw_interact_ring, distinguished by color so players learn
# cyan = "talk" vs. yellow = "enter building".
func _draw_npc_prompt(idx: int) -> void:
	var npc = _npcs[idx]
	var pos: Vector2 = npc.global_position
	var pulse: float = (sin(Time.get_ticks_msec() / 200.0) + 1.0) * 0.5
	draw_arc(pos, 14.0 + pulse * 3.0, 0.0, TAU, 20, Color(0.4, 0.95, 1.0), 2.0, true)
	draw_string(_font, pos + Vector2(-40.0, -28.0), npc.npc_name,
			HORIZONTAL_ALIGNMENT_CENTER, 80.0, 12, Color(0.4, 0.95, 1.0))

func _draw_icon(kind: String, p: Vector2, color: Color) -> void:
	match kind:
		"gear":
			draw_arc(p, 5.5, 0.0, TAU, 14, color, 2.0, true)
			for i: int in 6:
				var a: float = TAU * float(i) / 6.0
				var dir := Vector2(cos(a), sin(a))
				draw_line(p + dir * 5.5, p + dir * 8.5, color, 2.0, true)
		"arch":
			draw_arc(p + Vector2(0.0, -1.0), 5.5, PI, TAU, 12, color, 2.0, true)
			draw_line(p + Vector2(-5.5, -1.0), p + Vector2(-5.5, 6.0), color, 2.0)
			draw_line(p + Vector2(5.5, -1.0), p + Vector2(5.5, 6.0), color, 2.0)
			draw_line(p + Vector2(-5.5, 6.0), p + Vector2(5.5, 6.0), color, 2.0)
		"dumbbell":
			draw_circle(p + Vector2(-6.0, 0.0), 3.5, color)
			draw_circle(p + Vector2(6.0, 0.0), 3.5, color)
			draw_line(p + Vector2(-3.5, 0.0), p + Vector2(3.5, 0.0), color, 3.0)
		"note":
			draw_circle(p + Vector2(-3.0, 4.0), 3.0, color)
			draw_line(p + Vector2(0.0, 4.0), p + Vector2(0.0, -6.0), color, 2.0)
			draw_line(p + Vector2(0.0, -6.0), p + Vector2(5.0, -4.0), color, 2.0)
		"clock":
			draw_arc(p, 6.0, 0.0, TAU, 16, color, 2.0, true)
			draw_line(p, p + Vector2(0.0, -3.5), color, 1.5, true)
			draw_line(p, p + Vector2(2.5, 1.5), color, 1.5, true)
		"anchor":
			draw_arc(p + Vector2(0.0, 2.5), 3.5, 0.0, PI, 10, color, 2.0, true)
			draw_line(p + Vector2(0.0, -5.0), p + Vector2(0.0, 2.5), color, 2.0)
			draw_line(p + Vector2(-3.5, -3.0), p + Vector2(3.5, -3.0), color, 2.0)
		"book":
			draw_rect(Rect2(p.x - 5.5, p.y - 4.5, 11.0, 9.0), color, false, 2.0)
			draw_line(p + Vector2(0.0, -4.5), p + Vector2(0.0, 4.5), color, 1.5)
		"star":
			var pts := PackedVector2Array()
			for i: int in 5:
				var a: float = -PI / 2.0 + TAU * float(i) / 5.0
				pts.append(p + Vector2(cos(a), sin(a)) * 6.5)
			for i: int in 5:
				draw_line(pts[i], pts[(i + 2) % 5], color, 2.0, true)
		"tunnel":
			draw_arc(p + Vector2(0.0, 2.5), 5.5, PI, TAU, 12, color, 2.0, true)
			draw_line(p + Vector2(-5.5, 2.5), p + Vector2(-5.5, 6.0), color, 2.0)
			draw_line(p + Vector2(5.5, 2.5), p + Vector2(5.5, 6.0), color, 2.0)
		"zipline":
			draw_line(p + Vector2(-6.0, -4.5), p + Vector2(6.0, 4.5), color, 2.0, true)
			draw_circle(p + Vector2(3.5, 2.5), 2.2, color)
		"hex":
			var hpts := PackedVector2Array()
			for i: int in 6:
				var a2: float = TAU * float(i) / 6.0
				hpts.append(p + Vector2(cos(a2), sin(a2)) * 6.0)
			hpts.append(hpts[0])
			draw_polyline(hpts, color, 2.0, true)
		"chevron":
			draw_line(p + Vector2(-5.5, -2.5), p + Vector2(0.0, 4.5), color, 2.5, true)
			draw_line(p + Vector2(0.0, 4.5), p + Vector2(5.5, -2.5), color, 2.5, true)
		"film":
			draw_rect(Rect2(p.x - 6.0, p.y - 4.5, 12.0, 9.0), color, false, 2.0)
			draw_circle(p + Vector2(-3.5, 0.0), 1.4, color)
			draw_circle(p + Vector2(3.5, 0.0), 1.4, color)
		_:
			pass
