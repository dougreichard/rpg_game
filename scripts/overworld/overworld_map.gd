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
# Authored LOCS anchors / NPC homes live in a compact 40x19 grid. SPREAD scales
# those coordinates apart (via _grid) so the 3/4 building sprites have breathing
# room and the town reads as a bigger place; GRID grows to match.
const SPREAD: float = 1.5
const AUTHORED_COLS: int = 40
const AUTHORED_ROWS: int = 19
const GRID_COLS: int = int(AUTHORED_COLS * SPREAD) + MAP_OFFSET.x * 2
const GRID_ROWS: int = int(AUTHORED_ROWS * SPREAD) + MAP_OFFSET.y * 2
const INTERACT_RADIUS: float = 48.0
const NPC_INTERACT_RADIUS: float = 40.0
const CAMERA_SMOOTHING_SPEED: float = 5.0

# Quest state lives in GameManager.level_progress under this pseudo-location
# id, the same get/set_level_flag pattern every level uses for its own
# progress -- see CLAUDE.md "NPC dialog & quests". NPC roster and quest
# definitions live in scripts/systems/quest_data.gd (QuestData) so the Quest
# Log overlay can read them too.
const TOWN_ID: String = QuestData.TOWN_ID

# Ambient speech-bubble text for each town NPC. "pre" fires until their quest
# is complete; "post" fires after. Text is kept short so it wraps inside the
# 160px-wide speech bubble (see scripts/systems/speech_bubble.gd).
const NPC_BUBBLE_TEXT: Dictionary = {
	"gus":     {"pre": "Haven't touched a pipe organ since Doug...",     "post": "That old spoon's home now."},
	"moira":   {"pre": "I keep thinking about that key...",              "post": "Found it at last. Small mercies."},
	"reggie":  {"pre": "One of these days I'll finish that cabinet.",    "post": "Cabinet's almost running again!"},
	"fanny":   {"pre": "I do miss that little bottle...",                "post": "Keeping it close. Won't lose it again."},
	"penny":   {"pre": "I keep dropping things in that church...",       "post": "Made it right, I think. Mostly."},
	"otis":    {"pre": "Lost something down at the docks...",            "post": "Still doesn't point north. Still mine."},
	"wendell": {"pre": "...Still missing that ticket stub.",             "post": "Collection's whole again. More or less."},
	"clara":   {"pre": "That cable's knotted around something by now.",  "post": "Radio's picking up something, at least."},
	"ambrose": {"pre": "I do love a good map, even a wrong one.",        "post": "Map makes no sense. Perfect specimen."},
	"dottie":  {"pre": "There's a rabbit's foot out there with my name on it.", "post": "Shelf is complete. Well. Enough."},
	"tobias":  {"pre": "...Is anyone out there?",                        "post": "Fresh air! Should've found my way out sooner."},
	"agnes":   {"pre": "Just me and the organ up here...",               "post": "That organ could use some company."},
}

const PlayerScript: Script = preload("res://scripts/overworld/overworld_player.gd")
const NpcScript: Script = preload("res://scripts/overworld/town_npc.gd")
const BubbleCoordinatorScript: Script = preload("res://scripts/systems/bubble_coordinator.gd")
const DialogBoxScript: Script = preload("res://scripts/ui/dialog_box.gd")
const PauseMenuScript: Script = preload("res://scripts/ui/pause_menu.gd")
const AchievementsOverlayScript: Script = preload("res://scripts/ui/achievements_overlay.gd")
const AchievementToastScript: Script = preload("res://scripts/ui/achievement_toast.gd")
const InventoryOverlayScript: Script = preload("res://scripts/ui/inventory_overlay.gd")
const QuestLogOverlayScript: Script = preload("res://scripts/ui/quest_log_overlay.gd")
const TravelOverlayScript: Script = preload("res://scripts/ui/travel_overlay.gd")

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

# Tile coords into PlaceholderArt.make_synty_ground_tileset() (2x2 atlas):
#   (0,0) grass  (1,0) grass accent  (0,1) path/road  (1,1) dirt accent
const GRASS_TILE: Vector2i = Vector2i(0, 0)
const GRASS_ACCENT_TILE: Vector2i = Vector2i(1, 0)
const GRASS_ACCENT_PERIOD: int = 5
# Roads previously reused the indoor STONE-row ashlar tile, which read as a
# dropped-in dungeon floor square rather than a path. Gravel/packed-dirt
# OUTDOOR tiles are non-directional (work for both horizontal and vertical
# road runs) and contrast with the green grass tiles, so an L-shaped route
# reads as a worn road cut through the lawn.
const ROAD_TILE: Vector2i = Vector2i(0, 1)
const ROAD_ACCENT_TILE: Vector2i = Vector2i(1, 1)
const ROAD_ACCENT_PERIOD: int = 3

# Synty 2.5D building sprites (see docs/synty_2_5d_art_plan.md). One PNG per
# location id, rendered at the locked 3/4 angle and trimmed to its alpha bounds.
# When present, the sprite replaces the flat tile footprint; locations without a
# sprite fall back to _paint_building's tile fill.
const BUILDING_SPRITE_DIR: String = "res://assets/art/synty/buildings/"
# A sprite is scaled so its display width ~= footprint width * this factor (3/4
# buildings overhang their ground footprint, so a little wider than the tiles).
const BUILDING_WIDTH_FACTOR: float = 1.4

# Synty scatter props (trees/bushes/hedges) sprinkled on free grass for town
# cohesion. "h" is target display height in tiles; "weight" biases frequency.
const PROP_DIR: String = "res://assets/art/synty/props/"
const SCATTER_PROPS: Array = [
	{"tex": "tree_01", "h": 2.6, "weight": 4},
	{"tex": "tree_pine", "h": 2.9, "weight": 3},
	{"tex": "bush_01", "h": 0.9, "weight": 3},
	{"tex": "hedge_01", "h": 1.0, "weight": 2},
]
# Percent of eligible (free, near-town) grass tiles that receive a prop.
const SCATTER_DENSITY: int = 14

# Synty character billboards (CityCharacters, posed + rendered front-3/4). One
# PNG per lead (lowercase name) or town NPC (quest_id). When present it replaces
# the PIL sheet; the billboard is a single pose shown for every facing (flip_h
# conveys left/right). See docs/synty_2_5d_art_plan.md.
const CHAR_DIR: String = "res://assets/art/synty/characters/"
const CHAR_TARGET_H: float = 58.0  # on-screen character height in px (~1.8 tiles)

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
	{
		"id": "gimme_dat_spoon", "name": "Gimme Dat Spoon Arcade",
		"short": "Gimme Dat\nSpoon", "scene": "res://scenes/levels/GimmeDatSpoon.tscn",
		"anchor": Vector2i(35, 1), "size": Vector2i(4, 3), "terrain_row": T_CARPET,
		"requires": "grand_marquee", "icon": "spoon",
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
	["vr_room", "gimme_dat_spoon"],
]

var _id_to_idx: Dictionary = {}
var _loc_pos: Array = []   # Vector2 pixel center per location, parallel to LOCS
var _loc_door: Array = []  # Vector2i door tile per location, parallel to LOCS
var _building_sprites: Array = []  # Sprite2D (or null) per location, parallel to LOCS
var _occupied: Dictionary = {}  # Vector2i tile -> true (roads/buildings; no scatter)
var _nearby_idx: int = -1
var _npcs: Array = []      # parallel to QuestData.NPC_DATA
var _nearby_npc_idx: int = -1
var _font: Font
var _name_label: Label
var _status_label: Label
var _dialog_box = null
var _active_player = null
var _standby_player = null
var _inventory_overlay = null

@onready var camera: Camera2D = $Camera2D


# LOCS anchors are authored against the original 40x19 layout; offset them
# into the padded GRID_COLS x GRID_ROWS grid.
func _anchor(loc: Dictionary) -> Vector2i:
	return _grid(Vector2i(loc["anchor"]))


# Map an authored 40x19 tile coordinate into the spread-out, padded play grid.
func _grid(c: Vector2i) -> Vector2i:
	return Vector2i(roundi(c.x * SPREAD), roundi(c.y * SPREAD)) + MAP_OFFSET


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
	# Y-sort the root so building sprites, the duo, and town NPCs interleave by
	# screen-Y -- the duo passes behind tall buildings and in front of near ones.
	y_sort_enabled = true
	_build_floor()
	_build_building_sprites()
	_scatter_props()
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
	tile_map.tile_set = PlaceholderArt.make_synty_ground_tileset()
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
		# Sprite'd buildings stand on the grass/road; only tile-fill the footprint
		# for locations that have no rendered sprite yet (fallback).
		if not _has_building_sprite(LOCS[i]["id"]):
			_paint_building(tile_map, i)

# Orthogonal L-shaped road: horizontal run from a along a's row to b's column,
# then vertical run down/up b's column to b. Roads sit on layer 1, buildings
# on layer 2 painted afterward, so any road tile under a building footprint
# is simply covered — no routing-around-buildings logic needed.
func _paint_road(tile_map: TileMap, a: Vector2i, b: Vector2i) -> void:
	var x: int = a.x
	while true:
		tile_map.set_cell(1, Vector2i(x, a.y), 0, _road_tile_at(x, a.y))
		_occupied[Vector2i(x, a.y)] = true
		if x == b.x:
			break
		x += signi(b.x - a.x)
	var y: int = a.y
	while true:
		tile_map.set_cell(1, Vector2i(b.x, y), 0, _road_tile_at(b.x, y))
		_occupied[Vector2i(b.x, y)] = true
		if y == b.y:
			break
		y += signi(b.y - a.y)

func _road_tile_at(x: int, y: int) -> Vector2i:
	return ROAD_ACCENT_TILE if (x * 7 + y * 13) % ROAD_ACCENT_PERIOD == 0 else ROAD_TILE

# Fallback for a location with no rendered building sprite: pave its footprint
# as a dirt "lot" so the spot still reads as built ground. With all 14 locations
# now sprite'd this rarely runs, but it stays valid against the Synty ground atlas.
func _paint_building(tile_map: TileMap, idx: int) -> void:
	var loc: Dictionary = LOCS[idx]
	var anchor: Vector2i = _anchor(loc)
	var size: Vector2i = loc["size"]
	for x: int in range(anchor.x, anchor.x + size.x):
		for y: int in range(anchor.y, anchor.y + size.y):
			var tile: Vector2i = ROAD_ACCENT_TILE if (x + y) % 3 == 0 else ROAD_TILE
			tile_map.set_cell(2, Vector2i(x, y), 0, tile)

func _has_building_sprite(id: String) -> bool:
	return ResourceLoader.exists(BUILDING_SPRITE_DIR + id + ".png")

# Place a Synty 2.5D building sprite per location, anchored at the front-bottom
# centre of its footprint so its base sits on the ground tile and it rises up
# and back in 3/4 view. Added as a y-sorted root child so the duo interleaves.
func _build_building_sprites() -> void:
	_building_sprites.resize(LOCS.size())  # all null
	for i: int in LOCS.size():
		var loc: Dictionary = LOCS[i]
		var path: String = BUILDING_SPRITE_DIR + String(loc["id"]) + ".png"
		if not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path)
		var anchor: Vector2i = _anchor(loc)
		var size: Vector2i = loc["size"]
		var spr := Sprite2D.new()
		spr.texture = tex
		# Bottom edge of the (alpha-trimmed) texture sits at the node origin.
		spr.offset = Vector2(0.0, -tex.get_height() / 2.0)
		var s: float = (size.x * TILE * BUILDING_WIDTH_FACTOR) / float(tex.get_width())
		spr.scale = Vector2(s, s)
		spr.position = Vector2((anchor.x + size.x / 2.0) * TILE, (anchor.y + size.y) * TILE)
		if not _is_unlocked(i):
			spr.modulate = Color(0.5, 0.5, 0.55)  # dim locked locations
		_add_ground_shadow(spr.position, size.x * TILE * 0.8)
		add_child(spr)
		_building_sprites[i] = spr

# Sprinkle Synty trees/bushes/hedges on free grass around the town for cohesion.
# Deterministic (hash-based) so the layout is stable across runs. Avoids road
# and building/door tiles (via _occupied) plus NPC homes, and stays within a few
# tiles of the built-up area so the far camera-padding grass reads as open field.
func _scatter_props() -> void:
	# Reserve building footprints (+1 tile margin), their doors, and NPC homes.
	for i: int in LOCS.size():
		var a: Vector2i = _anchor(LOCS[i])
		var sz: Vector2i = LOCS[i]["size"]
		for x: int in range(a.x - 1, a.x + sz.x + 1):
			for y: int in range(a.y - 1, a.y + sz.y + 1):
				_occupied[Vector2i(x, y)] = true
		_occupied[_loc_door[i]] = true
	for data: Dictionary in QuestData.NPC_DATA + QuestData.NPC_DATA_2:
		_occupied[_grid(Vector2i(data["home"]))] = true

	# Load prop textures into a weighted pick list.
	var defs: Array = []
	var total_w: int = 0
	for p: Dictionary in SCATTER_PROPS:
		var path: String = PROP_DIR + String(p["tex"]) + ".png"
		if not ResourceLoader.exists(path):
			continue
		total_w += int(p["weight"])
		defs.append({"texture": load(path), "h": float(p["h"]), "cum": total_w})
	if defs.is_empty():
		return

	# Scatter region: building bounding box expanded a few tiles, clamped to grid.
	var mn := Vector2i(GRID_COLS, GRID_ROWS)
	var mx := Vector2i(0, 0)
	for loc: Dictionary in LOCS:
		var a2: Vector2i = _anchor(loc)
		var sz2: Vector2i = loc["size"]
		mn = Vector2i(mini(mn.x, a2.x), mini(mn.y, a2.y))
		mx = Vector2i(maxi(mx.x, a2.x + sz2.x), maxi(mx.y, a2.y + sz2.y))
	var pad: int = 5
	var x0: int = maxi(1, mn.x - pad)
	var x1: int = mini(GRID_COLS - 2, mx.x + pad)
	var y0: int = maxi(1, mn.y - pad)
	var y1: int = mini(GRID_ROWS - 2, mx.y + pad)

	for ty: int in range(y0, y1 + 1):
		for tx: int in range(x0, x1 + 1):
			if _occupied.has(Vector2i(tx, ty)):
				continue
			var h: int = _hash2(tx, ty)
			if h % 100 >= SCATTER_DENSITY:
				continue
			var pick: int = (h / 100) % total_w
			var chosen: Dictionary = defs[defs.size() - 1]
			for d: Dictionary in defs:
				if pick < int(d["cum"]):
					chosen = d
					break
			_place_prop(chosen, tx, ty, h)

func _place_prop(d: Dictionary, tx: int, ty: int, h: int) -> void:
	var tex: Texture2D = d["texture"]
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.offset = Vector2(0.0, -tex.get_height() / 2.0)  # bottom edge at origin
	var s: float = (float(d["h"]) * TILE) / float(tex.get_height())
	s *= 0.85 + float(h % 30) / 100.0  # subtle per-instance size variation
	spr.scale = Vector2(s, s)
	# Jitter within the tile so props don't sit on a rigid grid.
	var jx: float = float((h >> 3) % TILE) - TILE / 2.0
	spr.position = Vector2(tx * TILE + TILE / 2.0 + jx * 0.4, (ty + 1) * TILE)
	_add_ground_shadow(spr.position, tex.get_width() * s * 0.55)
	add_child(spr)

func _hash2(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663))

# Soft ground shadow under a billboard's feet. Added as a y-sorted root child at
# the same position (call BEFORE adding the billboard so it sorts underneath).
func _add_ground_shadow(pos: Vector2, width: float) -> void:
	var sh := Sprite2D.new()
	sh.texture = PlaceholderArt.make_shadow_texture()
	var s: float = width / 64.0
	sh.scale = Vector2(s, s * 0.42)
	sh.position = pos
	add_child(sh)

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
	# Spawn at the door of whichever location the duo last left (set by that
	# level's _exit_to_overworld), so re-entering the overworld picks up where
	# they left off instead of always starting at Pipe Organ Works.
	var spawn_idx: int = _id_to_idx.get(GameManager.last_location_id, _id_to_idx["pipe_organ_works"])
	var spawn: Vector2 = Vector2(_loc_door[spawn_idx]) * TILE + Vector2(TILE / 2.0, TILE / 2.0)

	_active_player = PlayerScript.new()
	add_child(_active_player)
	_setup_duo_visual(_active_player, active_name)
	_active_player.global_position = spawn
	_active_player.mode = PlayerScript.Mode.ACTIVE

	# A new game starts with only Quinn unlocked — Erin is "on loan" inside
	# Pipe Organ Works (see CLAUDE.md) but isn't part of the traveling duo
	# until that location is completed. No standby spawns in that case;
	# _swap_duo() and the per-frame follow/camera update already guard with
	# is_instance_valid(_standby_player).
	if names.size() > 1:
		var standby_name: String = String(names[1]).capitalize()
		_standby_player = PlayerScript.new()
		add_child(_standby_player)
		_setup_duo_visual(_standby_player, standby_name)
		_standby_player.global_position = spawn + Vector2(-TILE, 0.0)
		_standby_player.mode = PlayerScript.Mode.FOLLOW
		_inventory_overlay.call("setup", active_name, standby_name)
	else:
		_inventory_overlay.call("setup", active_name, active_name)

# Same SpriteLoader-with-PlaceholderArt-fallback pattern as player.gd, so the
# overworld duo matches the sprite sheets used in-level instead of always
# falling back to placeholder art.
func _load_player_frames(character_name: String) -> SpriteFrames:
	var loaded: SpriteFrames = SpriteLoader.try_load_player(character_name)
	if loaded != null:
		return loaded
	return PlaceholderArt.make_player_frames(CHAR_DATA[character_name].sprite_color, character_name)

# 64x64 real sheets are 2x-oversampled (DESIGN.md SS2.0) and need scaling down
# to the 32x32 gameplay footprint; 32x32 placeholder frames render at 1:1.
func _player_sprite_scale(character_name: String) -> float:
	if SpriteLoader.try_load_player(character_name) != null:
		return SpriteLoader.PLAYER_SPRITE_SCALE
	return 1.0

# Returns the Synty character billboard texture for a lead name / NPC quest_id,
# or null if none exists (caller falls back to the PIL sheet / placeholder).
func _char_billboard_tex(key: String) -> Texture2D:
	var path: String = CHAR_DIR + key.to_lower() + ".png"
	return load(path) if ResourceLoader.exists(path) else null

# SpriteFrames whose idle + directional-walk anims all point at the single 3/4
# billboard, so overworld_player / town_npc (which play those anims + flip_h)
# work unchanged.
func _billboard_frames(tex: Texture2D) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim: String in ["idle", "walk_down", "walk_up", "walk_right"]:
		sf.add_animation(anim)
		sf.set_animation_loop(anim, true)
		sf.add_frame(anim, tex)
	return sf

# Configure an overworld_player/town_npc AnimatedSprite2D as a feet-anchored
# billboard sprite: scaled to CHAR_TARGET_H and offset so the feet sit at the
# node origin (matching the building/prop ground anchoring for y-sort).
func _apply_billboard(spr: AnimatedSprite2D, tex: Texture2D) -> void:
	spr.scale = Vector2.ONE * (CHAR_TARGET_H / float(tex.get_height()))
	spr.offset = Vector2(0.0, -tex.get_height() / 2.0)

# Set up a duo member's sprite: Synty billboard if one exists, else the existing
# PIL sheet / placeholder.
func _setup_duo_visual(player, display_name: String) -> void:
	var tex: Texture2D = _char_billboard_tex(display_name)
	if tex != null:
		player.setup(_billboard_frames(tex), 1.0, display_name)
		_apply_billboard(player.sprite, tex)
	else:
		player.setup(_load_player_frames(display_name), _player_sprite_scale(display_name), display_name)

# NPC_DATA_2 entries may carry a "requires_flag" ({location, flag}) -- those
# townsfolk represent characters "freed" by a secret-passage discovery
# elsewhere (see CLAUDE.md "Numbered Spoons") and are skipped entirely until
# that location's level_progress flag is set. _npcs is therefore not always
# parallel to QuestData.NPC_DATA + QuestData.NPC_DATA_2 -- each npc carries
# its own `color` (set via setup()) so _talk_to_npc() never needs to index
# back into the data arrays by position.
func _spawn_npcs() -> void:
	var bubble_coord = BubbleCoordinatorScript.new()
	bubble_coord.set_pause_check(func() -> bool: return GameManager.is_paused())
	add_child(bubble_coord)
	for data: Dictionary in QuestData.NPC_DATA + QuestData.NPC_DATA_2:
		var req: Dictionary = data.get("requires_flag", {})
		if not req.is_empty() and not GameManager.get_level_flag(req["location"], req["flag"], false):
			continue
		var npc = NpcScript.new()
		add_child(npc)
		var home: Vector2 = Vector2(_grid(Vector2i(data["home"]))) * TILE + Vector2(TILE / 2.0, TILE / 2.0)
		var bb_tex: Texture2D = _char_billboard_tex(data["quest_id"])
		if bb_tex != null:
			npc.setup(_billboard_frames(bb_tex), home, data["name"], data["quest_id"], data["color"])
			_apply_billboard(npc.sprite, bb_tex)
		else:
			var npc_key: String = data["name"].to_lower()
			var npc_frames: SpriteFrames = SpriteLoader.try_load_npc(npc_key)
			var npc_scale: float = SpriteLoader.NPC_SPRITE_SCALE if npc_frames != null else 1.0
			if npc_frames == null:
				npc_frames = PlaceholderArt.make_player_frames(data["color"], "")
			npc.setup(npc_frames, home, data["name"], data["quest_id"], data["color"])
			npc.sprite.scale = Vector2(npc_scale, npc_scale)
		var bubble_txt: Dictionary = NPC_BUBBLE_TEXT.get(data["quest_id"], {})
		if not bubble_txt.is_empty():
			npc.setup_bubble(bubble_txt["pre"], bubble_txt["post"])
			bubble_coord.register(npc.fire_bubble)
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
	_dialog_box.closed.connect(_on_dialog_closed)

	# Pause menu (ESC) — same group of CanvasLayers as the in-level HUD
	# (PauseMenu.gd looks up "../AchievementsOverlay", "../InventoryOverlay",
	# and "../QuestLogOverlay" as siblings, so add those first). "Quit to Map"
	# is dropped in the overworld via in_overworld — there's nowhere to quit
	# "back" to.
	var achievements_overlay = AchievementsOverlayScript.new()
	achievements_overlay.name = "AchievementsOverlay"
	add_child(achievements_overlay)

	_inventory_overlay = InventoryOverlayScript.new()
	_inventory_overlay.name = "InventoryOverlay"
	add_child(_inventory_overlay)

	var quest_log_overlay = QuestLogOverlayScript.new()
	quest_log_overlay.name = "QuestLogOverlay"
	add_child(quest_log_overlay)

	var travel_overlay = TravelOverlayScript.new()
	travel_overlay.name = "TravelOverlay"
	add_child(travel_overlay)
	travel_overlay.setup(LOCS)
	travel_overlay.location_chosen.connect(_on_travel_chosen)

	var achievement_toast = AchievementToastScript.new()
	achievement_toast.name = "AchievementToast"
	add_child(achievement_toast)

	var pause_menu = PauseMenuScript.new()
	pause_menu.name = "PauseMenu"
	pause_menu.in_overworld = true
	add_child(pause_menu)

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
	if GameManager.is_paused():
		return
	GameManager.set_dialog_active(_dialog_box.is_open())
	if is_instance_valid(_standby_player):
		_standby_player.follow_target = _active_player.global_position - _active_player.facing * (TILE * 0.9)
	if is_instance_valid(_active_player):
		camera.global_position = _active_player.global_position
		_active_player.input_locked = _dialog_box.is_open()
	_update_nearby()
	_update_nearby_npc()
	if _dialog_box.is_open() and _dialog_box.is_choice_mode():
		if Input.is_action_just_pressed("move_up"):
			_dialog_box.move_choice_cursor(-1)
		elif Input.is_action_just_pressed("move_down"):
			_dialog_box.move_choice_cursor(1)
		elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
			_dialog_box.select_choice()
		queue_redraw()
		return
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
#
# Each tree's terminal node carries the "effects" (flag transitions, item
# grant/consume) for that conversation -- see QuestData and
# _apply_dialog_effects(), applied once the dialog is fully read and closed
# via _on_dialog_closed().
func _talk_to_npc(idx: int) -> void:
	var npc = _npcs[idx]
	var quest: Dictionary = QuestData.get_quest(npc.quest_id)
	if quest.is_empty():
		return
	var flag_key: String = "quest_" + npc.quest_id
	var state: String = GameManager.get_level_flag(TOWN_ID, flag_key, "not_started")
	var tree: Dictionary
	match state:
		"complete":
			tree = quest["after"]
		"active":
			tree = quest["turn_in"] if _find_item_holder(quest["want_item"]) != "" else quest["reminder"]
		_:
			tree = quest["intro"]
	Audio.play("ui_select")
	_dialog_box.open(npc.npc_name, npc.color, tree, "start", _active_player.character_name)

# Applies the effects collected while walking a dialog tree (set_level_flag,
# item consume/grant) once the conversation is fully read and closed -- see
# scripts/systems/dialog_tree.gd and dialog_box.gd's closed(effects) signal.
func _on_dialog_closed(effects: Array) -> void:
	_apply_dialog_effects(effects)

func _apply_dialog_effects(effects: Array) -> void:
	for fx: Dictionary in effects:
		var holder: String = _active_player.character_name.to_lower()
		if fx.has("consume_item"):
			var found: String = _find_item_holder(fx["consume_item"])
			if found != "":
				holder = found
				GameManager.consume_item(holder, fx["consume_item"])
		for item_id: String in fx.get("grant_items", []):
			GameManager.grant_item(holder, item_id)
		if fx.has("set_flag"):
			GameManager.set_level_flag(TOWN_ID, fx["set_flag"], fx.get("flag_value", true))

# Returns the lowercase name of the first unlocked character holding
# `item_id`, or "" if none do -- mirrors GameManager.has_item's lowercase
# inventory keys, so the result can be passed straight to consume_item/
# grant_item.
func _find_item_holder(item_id: String) -> String:
	for character_name in GameManager.unlocked_characters:
		if GameManager.has_item(character_name, item_id):
			return character_name
	return ""

# Teleports the duo + camera to loc_id's door tile -- the fast-travel
# destination chosen via the Pause Menu's "Travel" entry / TravelOverlay.
func _on_travel_chosen(loc_id: String) -> void:
	var idx: int = _id_to_idx.get(loc_id, -1)
	if idx < 0:
		return
	var door_px: Vector2 = Vector2(_loc_door[idx]) * TILE + Vector2(TILE / 2.0, TILE / 2.0)
	_active_player.global_position = door_px
	if is_instance_valid(_standby_player):
		_standby_player.global_position = door_px + Vector2(-TILE, 0.0)
	camera.global_position = door_px
	_update_nearby()

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
	# The arcade is a single-player bonus minigame with its own character
	# select -- skip CharacterSelect.tscn (which expects a 2-character duo)
	# and go straight to the minigame scene.
	if loc["id"] == "gimme_dat_spoon":
		TransitionManager.change_scene(loc["scene"])
		return
	# Remember which location we entered so any exit path -- doorway, level
	# clear, or the pause menu's "Quit to Map" -- returns the duo to this
	# building's door instead of always defaulting to Pipe Organ Works.
	GameManager.last_location_id = loc["id"]
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
	# A rendered building sprite (drawn as a y-sorted child) covers the footprint
	# and carries its own identity + locked dimming, so skip the flat tile-era
	# tint/icon for those; the name label below still renders for every location.
	var has_sprite: bool = idx < _building_sprites.size() and _building_sprites[idx] != null
	if not has_sprite:
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
		"spoon":
			draw_arc(p + Vector2(0.0, -2.5), 4.0, 0.0, TAU, 12, color, 2.0, true)
			draw_line(p + Vector2(0.0, 1.5), p + Vector2(0.0, 8.0), color, 2.0)
		_:
			pass
