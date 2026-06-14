class_name PlaceholderArt
extends RefCounted

static func make_player_frames(color: Color, character_name: String = "") -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var skin := color.lightened(0.25)
	var limb := color.darkened(0.2)
	var idle_f: Array  = [_humanoid(skin, color, limb, Color.WHITE, 0, character_name)]
	var walk_f: Array  = [_humanoid(skin, color, limb, Color.WHITE, 0, character_name),
						   _humanoid(skin, color, limb, Color.WHITE, 1, character_name),
						   _humanoid(skin, color, limb, Color.WHITE, 0, character_name),
						   _humanoid(skin, color, limb, Color.WHITE, 2, character_name)]
	var atk_f: Array   = [_humanoid(skin, color.lightened(0.45), limb, Color.WHITE, 0, character_name, true),
						   _humanoid(skin, color.lightened(0.45), limb, Color.WHITE, 2, character_name, true)]
	var hurt_f: Array  = [_humanoid(skin, Color(1.0, 0.3, 0.3), Color(0.8, 0.2, 0.2), Color.WHITE, 0, character_name)]
	var down_f: Array  = [_humanoid(color.darkened(0.4), color.darkened(0.55), color.darkened(0.55), Color.TRANSPARENT, 0, character_name)]
	_add(frames, "idle",         idle_f)
	_add(frames, "walk",         walk_f)
	# Directional aliases — same frames; real sprites will have distinct rows.
	_add(frames, "walk_down",    walk_f)
	_add(frames, "walk_up",      walk_f)
	_add(frames, "walk_right",   walk_f)
	_add(frames, "run_down",     walk_f)
	_add(frames, "run_up",       walk_f)
	_add(frames, "run_right",    walk_f)
	_add(frames, "attack",       atk_f)
	_add(frames, "special",      atk_f)
	_add(frames, "dash",         idle_f)
	_add(frames, "hurt",         hurt_f)
	_add(frames, "down",         down_f)
	_add(frames, "revive",       idle_f)
	_add(frames, "interact",     idle_f)
	_add(frames, "doorway",      walk_f)
	return frames

static func make_enemy_frames(color: Color, enemy_name: String = "", stocky: bool = false) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var limb := color.darkened(0.25)
	var windup := Color(1.0, 0.65, 0.0)
	var e_name: String = enemy_name if not enemy_name.is_empty() else ("Grunt" if stocky else "Runner")
	var walk_f: Array  = [_enemy_type(color, limb, e_name, 0), _enemy_type(color, limb, e_name, 1)]
	var atk_f: Array   = [_enemy_type(color.lightened(0.5), limb.lightened(0.3), e_name, 0)]
	var hurt_f: Array  = [_enemy_type(Color(1.0, 0.3, 0.3), Color(0.7, 0.15, 0.15), e_name, 0)]
	_add(frames, "walk",    walk_f)
	_add(frames, "chase",   walk_f)   # distinct row in real sheets; alias here
	_add(frames, "windup",  [_enemy_type(windup, windup.darkened(0.3), e_name, 0)])
	_add(frames, "attack",  atk_f)
	_add(frames, "recover", walk_f)   # distinct row in real sheets; alias here
	_add(frames, "hurt",    hurt_f)
	_add(frames, "death",   hurt_f)   # distinct row in real sheets; alias here
	_add(frames, "alert",   walk_f)   # distinct row in real sheets; alias here
	return frames

static func _add(frames: SpriteFrames, anim: String, textures: Array) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, true)
	frames.set_animation_speed(anim, 6.0)
	for t: ImageTexture in textures:
		frames.add_frame(anim, t)

# 32×32 humanoid sprite, facing right — slightly taller proportions than the old
# chibi: taller torso, longer legs, smaller head so characters read as adults.
# `walk_frame` cycles 0 (neutral) → 1 (left leg forward) → 2 (right leg forward).
# `character_name` drives a character-specific head accessory + the held prop.
static func _humanoid(head: Color, body: Color, limb: Color, eye: Color, walk_frame: int, character_name: String = "", attacking: bool = false) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	# Head — slightly smaller, shifted right to imply a rightward facing
	_rect(img, 13,  2,  8,  7, head)
	# Neck
	_rect(img, 15,  9,  3,  2, head.darkened(0.1))
	# Torso — taller than before
	_rect(img, 10, 11, 12, 10, body)
	# Arms
	_rect(img,  7, 12,  3,  8, limb)   # left arm
	_rect(img, 22, 12,  3,  8, limb)   # right arm
	# Legs with walk-cycle offset
	var ll_y: int = 21
	var rl_y: int = 21
	if walk_frame == 1:
		ll_y = 23
	elif walk_frame == 2:
		rl_y = 23
	_rect(img, 11, ll_y, 4, 30 - ll_y, limb)
	_rect(img, 17, rl_y, 4, 30 - rl_y, limb)
	# Eyes (two pixels)
	if eye.a > 0.5:
		img.set_pixel(19, 5, eye)
		img.set_pixel(18, 5, eye)
	# Character-specific head accessory
	if not character_name.is_empty():
		_draw_head_accessory(img, character_name, head, body)
		_draw_character_prop(img, character_name, walk_frame, attacking)
	return ImageTexture.create_from_image(img)

# Draws a small head/hair accessory that makes each character silhouette distinct.
static func _draw_head_accessory(img: Image, character_name: String, head: Color, body: Color) -> void:
	match character_name:
		"Quinn":
			# Flat newsboy cap — dark band just above the head, brim extending left
			_rect(img, 11,  1, 10,  2, Color(0.2, 0.2, 0.25))  # brim
			_rect(img, 13,  0,  8,  2, Color(0.25, 0.25, 0.32))  # crown
		"Erin":
			# Shoulder-length hair — colored strands below and beside the head
			var hair: Color = Color(0.85, 0.45, 0.1)  # warm auburn
			_rect(img, 12,  2,  2, 10, hair)   # hair left of head
			_rect(img, 21,  2,  2,  9, hair)   # hair right of head
			_rect(img, 13,  1,  8,  2, hair)   # hair top
		"Evan":
			# Crew-cut / flat top — same color as head, squared off
			_rect(img, 13,  1,  8,  2, head.darkened(0.12))  # flat top
			# Extra-wide shoulders to suggest bulk
			_rect(img,  8, 11,  2,  4, body.darkened(0.05))
			_rect(img, 22, 11,  2,  4, body.darkened(0.05))
		"Ben":
			# Spiky hair — three short spikes above the head
			var hair2: Color = Color(0.55, 0.25, 0.6).lightened(0.2)
			img.set_pixel(14,  1, hair2)
			img.set_pixel(14,  0, hair2)
			img.set_pixel(17,  0, hair2)
			img.set_pixel(17,  1, hair2)
			img.set_pixel(20,  0, hair2)
			img.set_pixel(20,  1, hair2)
		"Ethan":
			# Glasses — two small white rectangles across the eye row
			_rect(img, 16,  5,  3,  2, Color(0.85, 0.92, 1.0, 0.9))
			_rect(img, 13,  5,  2,  2, Color(0.85, 0.92, 1.0, 0.9))

# Draws a small held-prop silhouette keyed to the CLAUDE.md roster's
# "Weapon / Tool" column, next to the right hand (raised into a strike pose
# when `attacking`). Purely a recognizability cue — same procedural
# Image/_rect technique as the rest of this file, so it costs nothing beyond
# a few extra rects and keeps the no-imported-assets/original-IP guarantee.
# Prototyped on Quinn; extend the match arm-by-arm as each character gets
# its pass (mirrors the tile-floor/wall rollout's "prototype, then repeat").
static func _draw_character_prop(img: Image, character_name: String, walk_frame: int, attacking: bool) -> void:
	var x: int = 24
	var y: int = 6 if attacking else 15
	match character_name:
		"Quinn":
			# wrench — grey shaft with a lighter L-shaped jaw
			_rect(img, x, y, 2, 6, Color(0.55, 0.57, 0.6))
			_rect(img, x - 2, y - 2, 6, 2, Color(0.72, 0.74, 0.78))
		"Erin":
			# torch — handle plus a flame that flickers between two hues across frames
			var flame: Color = Color(1.0, 0.55, 0.1) if walk_frame % 2 == 0 else Color(1.0, 0.75, 0.2)
			_rect(img, x, y + 1, 2, 5, Color(0.4, 0.3, 0.2))
			_rect(img, x - 1, y - 2, 4, 4, flame)
		"Evan":
			# oversized fists — broaden both hand blocks past the arm sprites
			_rect(img, x - 1, y, 5, 5, Color(0.9, 0.9, 0.92))
			_rect(img, 5, y, 5, 5, Color(0.9, 0.9, 0.92))
		"Ben":
			# keytar — a strap across the torso plus a small key row at the hand
			_rect(img, 9, 12, 13, 2, Color(0.2, 0.2, 0.25))
			_rect(img, x - 2, y, 7, 3, Color(0.15, 0.15, 0.2))
			for i: int in range(3):
				img.set_pixel(x - 1 + i * 2, y, Color.WHITE)
		"Ethan":
			# tech gadget — a compact device with a glowing cyan readout
			_rect(img, x, y, 4, 4, Color(0.22, 0.22, 0.27))
			img.set_pixel(x + 1, y + 1, Color(0.3, 1.0, 1.0))
			img.set_pixel(x + 2, y + 1, Color(0.3, 1.0, 1.0))

# 32×32 enemy sprite — 5 distinct silhouettes keyed to enemy_name.
# Each design reads differently at gameplay scale: Grunt is compact/boxy,
# Runner is lean/forward-leaning, Brute is massive, Sentry is upright/helmeted,
# Boss is large and imposing.
static func _enemy_type(body: Color, limb: Color, enemy_name: String, walk: int) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var ll_y: int
	var rl_y: int
	match enemy_name:
		"Grunt":
			# Stocky brawler: big helmeted head, wide torso, short thick legs
			_rect(img,  9,  1, 13,  8, body)            # head
			_rect(img,  9,  1, 13,  3, body.darkened(0.3))  # helmet brim
			_rect(img,  6, 10, 20,  9, body)            # wide torso
			_rect(img,  3, 11,  4,  7, limb)            # L arm
			_rect(img, 25, 11,  4,  7, limb)            # R arm
			ll_y = 17 + (2 if walk == 1 else 0)
			rl_y = 17 + (2 if walk == 0 else 0)
			_rect(img,  8, ll_y, 6, 30 - ll_y, limb)
			_rect(img, 18, rl_y, 6, 30 - rl_y, limb)
			img.set_pixel(17, 5, Color.RED)
			img.set_pixel(14, 5, Color.RED)
		"Runner":
			# Lean sprinter: small head, slim torso angled slightly forward, long legs
			_rect(img, 14,  1,  7,  6, body)            # small head
			_rect(img, 12,  7,  9,  9, body)            # angled slim torso
			_rect(img,  9,  8,  3,  9, limb)            # L arm (swept back)
			_rect(img, 21,  7,  3,  6, limb)            # R arm (forward)
			ll_y = 16 + (3 if walk == 1 else 0)
			rl_y = 16 + (3 if walk == 0 else 0)
			_rect(img, 13, ll_y, 3, 31 - ll_y, limb)   # longer legs
			_rect(img, 17, rl_y, 3, 31 - rl_y, limb)
			img.set_pixel(18,  3, Color(1.0, 1.0, 0.0))  # yellow eye
			img.set_pixel(19,  3, Color(1.0, 1.0, 0.0))
		"Brute":
			# Massive tank: almost no neck, enormous torso, huge arms, tiny legs
			_rect(img,  8,  2, 15,  7, body)            # very wide head/neck merged
			_rect(img,  3,  9, 26, 12, body)            # enormous torso
			_rect(img,  0, 10,  4, 10, limb)            # huge L arm
			_rect(img, 28, 10,  4, 10, limb)            # huge R arm
			ll_y = 20 + (1 if walk == 1 else 0)
			rl_y = 20 + (1 if walk == 0 else 0)
			_rect(img,  7, ll_y, 7, 30 - ll_y, limb)   # thick short legs
			_rect(img, 18, rl_y, 7, 30 - rl_y, limb)
			img.set_pixel(16,  5, Color(1.0, 0.3, 0.0))  # orange menacing eye
			img.set_pixel(18,  5, Color(1.0, 0.3, 0.0))
		"Sentry":
			# Upright guard: tall narrow build, distinctive visor band across head
			_rect(img, 13,  0,  9,  9, body)            # tall head
			_rect(img, 12,  3,  9,  3, body.darkened(0.5))  # visor
			_rect(img, 11,  9, 10, 12, body)            # slim torso
			_rect(img,  8, 10,  3, 10, limb)            # L arm
			_rect(img, 21, 10,  3, 10, limb)            # R arm (holds weapon)
			_rect(img, 23,  6,  2, 14, limb.darkened(0.3))  # weapon / baton
			ll_y = 21 + (2 if walk == 1 else 0)
			rl_y = 21 + (2 if walk == 0 else 0)
			_rect(img, 12, ll_y, 3, 30 - ll_y, limb)
			_rect(img, 17, rl_y, 3, 30 - rl_y, limb)
			img.set_pixel(17,  4, Color(0.4, 1.0, 1.0))  # cyan visor glow
			img.set_pixel(19,  4, Color(0.4, 1.0, 1.0))
		_:  # "Boss" and any fallback
			# Large imposing figure: fills most of the 32×32, crown-like head,
			# broad torso, heavy arms, a visible aura border
			_rect(img,  7,  1, 18, 10, body)            # large head
			# Crown spikes
			_rect(img,  8,  0,  2,  3, body.lightened(0.25))
			_rect(img, 13,  0,  2,  3, body.lightened(0.25))
			_rect(img, 18,  0,  2,  3, body.lightened(0.25))
			_rect(img,  4, 11, 24, 13, body)            # wide heavy torso
			_rect(img,  1, 12,  4, 10, limb)            # L arm
			_rect(img, 27, 12,  4, 10, limb)            # R arm
			ll_y = 23 + (1 if walk == 1 else 0)
			rl_y = 23 + (1 if walk == 0 else 0)
			_rect(img,  7, ll_y, 6, 30 - ll_y, limb)
			_rect(img, 19, rl_y, 6, 30 - rl_y, limb)
			# Glowing eyes
			_rect(img, 12,  5,  3,  2, Color(0.9, 0.0, 1.0))
			_rect(img, 18,  5,  3,  2, Color(0.9, 0.0, 1.0))
	return ImageTexture.create_from_image(img)

# Builds a 32×32-tile floor TileSet: tile (0,0) is a recessed-panel stone tile
# with a beveled inner border; tile (1,0) is the same with a decorative diamond
# accent — a Zelda-dungeon-style two-tone tiled floor with 3-D depth cues.
static func make_level_tileset(base: Color, accent: Color) -> TileSet:
	var seam: Color   = base.darkened(0.38)
	var light_bevel   = base.lightened(0.28)
	var dark_bevel    = base.darkened(0.22)
	var inner: Color  = base.darkened(0.08)   # subtle floor depression
	var atlas := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	for tile: int in range(2):
		var ox: int = tile * 32
		# Fill interior with a slightly darker inset
		_rect(atlas, ox, 0, 32, 32, inner)
		# Outer seam border (1px)
		for i: int in range(32):
			atlas.set_pixel(ox + i, 0,  seam)
			atlas.set_pixel(ox + i, 31, seam)
			atlas.set_pixel(ox, i,      seam)
			atlas.set_pixel(ox + 31, i, seam)
		# Inner bevel — 2px inset light (top/left) and dark (bottom/right)
		for i: int in range(1, 31):
			atlas.set_pixel(ox + i, 1,  light_bevel)
			atlas.set_pixel(ox + i, 30, dark_bevel)
			atlas.set_pixel(ox + 1, i,  light_bevel)
			atlas.set_pixel(ox + 30, i, dark_bevel)
		# Corner overtones
		atlas.set_pixel(ox + 1,  1,  light_bevel.lightened(0.12))
		atlas.set_pixel(ox + 30, 30, dark_bevel.darkened(0.12))
	# Accent tile (1,0) — diamond inlay pattern
	var cx: int = 32 + 16
	var cy: int = 16
	for r: int in range(5):
		_rect(atlas, cx - r, cy - (4 - r), r * 2, 1, accent)
		_rect(atlas, cx - r, cy + (4 - r), r * 2, 1, accent)
	var tex := ImageTexture.create_from_image(atlas)
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(32, 32)
	source.create_tile(Vector2i(0, 0))
	source.create_tile(Vector2i(1, 0))
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(32, 32)
	tile_set.add_source(source, 0)
	return tile_set

# Hunkle Bunkle custom tileset — 8 terrain rows × 12 variants at 16×16 px source,
# upscaled 2× to 32×32 at runtime. Single shared instance; address tiles as
# Vector2i(col, terrain_row) in set_cell().
# Terrain rows: 0=STONE  1=WORKSHOP  2=WOOD  3=OUTDOOR  4=TUNNEL  5=DOCK  6=CARPET  7=CYBER
static var _hb_ts: TileSet = null

static func make_hb_tileset() -> TileSet:
	if _hb_ts != null:
		return _hb_ts
	var base: Texture2D = load("res://assets/art/tiles/hb_tiles.png")
	var img: Image = base.get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(img)
	src.texture_region_size = Vector2i(32, 32)
	src.use_texture_padding = false
	for row: int in 8:
		for col: int in 12:
			src.create_tile(Vector2i(col, row))
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	ts.add_source(src, 0)
	_hb_ts = ts
	return ts

# Synty-derived overworld ground tileset (see docs/synty_2_5d_art_plan.md). A
# 2x2 atlas of 32px tiles baked from NatureBiomes terrain textures:
#   (0,0) grass   (1,0) grass accent   (0,1) path/road   (1,1) dirt accent
# Used by overworld_map.gd's floor so the ground reads as Synty terrain under
# the 3/4 building sprites.
static var _synty_ground_ts: TileSet = null

static func make_synty_ground_tileset() -> TileSet:
	if _synty_ground_ts != null:
		return _synty_ground_ts
	var tex: Texture2D = load("res://assets/art/tiles/synty_ground.png")
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(32, 32)
	src.use_texture_padding = false
	for row: int in 2:
		for col: int in 2:
			src.create_tile(Vector2i(col, row))
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	ts.add_source(src, 0)
	_synty_ground_ts = ts
	return ts

# Synty interior floor tileset for the levels (see docs/synty_2_5d_art_plan.md).
# Loads a 64x32 atlas (two 32px tiles: plain + accent) baked from a Synty
# interior surface texture. Parameterized + cached per path so each level can
# pass its own floor (workshop wood, dock concrete, etc.).
static var _synty_floor_ts_cache: Dictionary = {}

static func make_synty_floor_tileset(atlas_path: String) -> TileSet:
	if _synty_floor_ts_cache.has(atlas_path):
		return _synty_floor_ts_cache[atlas_path]
	var src := TileSetAtlasSource.new()
	src.texture = load(atlas_path)
	src.texture_region_size = Vector2i(32, 32)
	src.use_texture_padding = false
	for col: int in 2:
		src.create_tile(Vector2i(col, 0))
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	ts.add_source(src, 0)
	_synty_floor_ts_cache[atlas_path] = ts
	return ts

# Synty wall tile texture (a small tileable surface). Pair with a Sprite2D using
# region_enabled + region_rect = wall size + texture_repeat ENABLED to tile it
# across an arbitrary wall rect. Cached per path.
static var _synty_wall_tex_cache: Dictionary = {}

static func make_synty_wall_tile(tex_path: String) -> Texture2D:
	if _synty_wall_tex_cache.has(tex_path):
		return _synty_wall_tex_cache[tex_path]
	var tex: Texture2D = load(tex_path)
	_synty_wall_tex_cache[tex_path] = tex
	return tex

# 2.5D wall faces: builds a top surface + a darker "front face" strip along the
# south edge of a wall rect, so flat top-down walls read with a little height
# instead of a flat tile (see docs/synty_2_5d_art_plan.md Phase 6a). Adds the two
# Sprite2Ds as children of `wall_body`; call once per wall in a level's
# `_build_walls`. The front face is added first so it sits under the top surface.
const WALL_FACE_HEIGHT: float = 42.0
const WALL_FACE_SHADE: Color = Color(0.62, 0.54, 0.48)  # shadowed front face (warm, keeps wall hue)
const WALL_TOP_TINT: Color = Color(1.18, 1.18, 1.20)    # lit top surface

# Soft round drop-shadow texture (radial alpha falloff), cached. Pair with a
# Sprite2D flattened on Y (scale.y ~= 0.42) and placed at a billboard's feet so
# buildings/props/characters read as standing on the ground instead of floating.
static var _shadow_tex: Texture2D = null

# Subtle per-level mood tint via a CanvasModulate on the level's default canvas
# (the HUD lives on separate CanvasLayers, so it's unaffected). Unifies the mixed
# art under one mood and warms/cools each location. Tints are kept gentle.
const MOOD_TINTS: Dictionary = {
	"pipe_organ_works": Color(1.04, 0.98, 0.88),   # warm workshop lamps
	"old_parish_church": Color(0.92, 0.94, 1.06),  # cool stone
	"iron_strings_gym": Color(0.98, 0.99, 1.02),   # neutral-cool
	"recording_studio": Color(0.93, 0.93, 1.04),   # cool studio
	"clocktower": Color(0.96, 0.95, 1.04),          # cool dusk
	"harbor_docks": Color(0.9, 0.97, 1.06),         # cool sea air
	"library": Color(1.05, 0.99, 0.88),             # warm reading light
	"carnival": Color(1.06, 0.97, 0.9),             # festive warm
	"underground": Color(0.82, 0.87, 1.02),         # cold, dim
	"zip_line": Color(1.0, 1.01, 0.94),             # bright daylight
	"vr_room": Color(0.88, 0.98, 1.12),             # cyan tech glow
	"the_drop": Color(1.02, 0.99, 0.9),             # warm outdoor
	"grand_marquee": Color(1.07, 0.95, 0.82),       # warm cinema amber
}

# Configure an in-level NPC AnimatedSprite2D as a Synty character billboard
# (assets/art/synty/characters/<key>.png) — one 3/4 pose mapped to every NPC
# animation name, feet-anchored. Returns false if no PNG, so callers fall back to
# the PIL sheet / placeholder. NPCs are stationary, so a billboard reads fine.
const NPC_BILLBOARD_ANIMS: Array = ["idle", "idle_alt", "walk_right", "walk_down",
	"walk_up", "talk", "talk_closeup", "talk_pleased", "talk_amused",
	"talk_annoyed", "relieved", "hand_over_item", "refuse", "step_aside", "wave"]

static func apply_npc_billboard(spr: AnimatedSprite2D, key: String, target_h: float = 54.0) -> bool:
	# Prefer the animated set (idle breathe / walk / conduct). It's authoritative —
	# any expected NPC anim without its own strip (e.g. talk_*) is aliased to idle so
	# playback never fails — because mixing animated + static frame sizes in one
	# SpriteFrames would resize the figure between anims. Falls back to the single
	# static billboard, else returns false.
	var anim: SpriteFrames = SpriteLoader.try_load_anim_billboard(key)
	if anim != null:
		if anim.has_animation("idle"):
			for a: String in NPC_BILLBOARD_ANIMS:
				if not anim.has_animation(a):
					anim.add_animation(a)
					anim.set_animation_loop(a, true)
					for i: int in anim.get_frame_count("idle"):
						anim.add_frame(a, anim.get_frame_texture("idle", i))
		spr.sprite_frames = anim
		var side: int = SpriteLoader.anim_frame_side(key)
		if side > 0:
			spr.scale = Vector2.ONE * (target_h / float(side))
			spr.offset = Vector2(0.0, -float(side) * 0.5)
		return true
	var path: String = "res://assets/art/synty/characters/" + key + ".png"
	if not ResourceLoader.exists(path):
		return false
	var tex: Texture2D = load(path)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for a: String in NPC_BILLBOARD_ANIMS:
		sf.add_animation(a)
		sf.set_animation_loop(a, true)
		sf.add_frame(a, tex)
	spr.sprite_frames = sf
	spr.offset = Vector2(0.0, -tex.get_height() / 2.0)
	spr.scale = Vector2.ONE * (target_h / float(tex.get_height()))
	return true

static func add_mood_light(parent: Node, location_id: String) -> void:
	if not MOOD_TINTS.has(location_id):
		return
	var cm := CanvasModulate.new()
	cm.color = MOOD_TINTS[location_id]
	parent.add_child(cm)

static func make_shadow_texture() -> Texture2D:
	if _shadow_tex != null:
		return _shadow_tex
	var size: int = 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	for y: int in size:
		for x: int in size:
			var d: float = Vector2(x, y).distance_to(c) / (size / 2.0)
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.0, 0.0, 0.0, a * a * 0.5))
	_shadow_tex = ImageTexture.create_from_image(img)
	return _shadow_tex

static func add_synty_wall_faces(wall_body: Node, size: Vector2, tex: Texture2D) -> void:
	var front := Sprite2D.new()
	front.texture = tex
	front.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	front.region_enabled = true
	front.region_rect = Rect2(0.0, 0.0, size.x, WALL_FACE_HEIGHT)
	front.position = Vector2(0.0, size.y * 0.5 + WALL_FACE_HEIGHT * 0.5)
	front.modulate = WALL_FACE_SHADE
	wall_body.add_child(front)

	var top := Sprite2D.new()
	top.texture = tex
	top.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	top.region_enabled = true
	top.region_rect = Rect2(0.0, 0.0, size.x, size.y)
	top.modulate = WALL_TOP_TINT
	wall_body.add_child(top)

# Generic prop/gate texture: a beveled panel with an outer black frame.
# Works for any rectangular prop — wall gates, containers, doors, etc.
# Thick props (w>16, h>16) get an inner bevel for a 3-D recessed panel look.
static func make_gate_texture(color: Color, w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	# Outer border
	for x: int in range(w):
		img.set_pixel(x, 0,     Color.BLACK)
		img.set_pixel(x, h - 1, Color.BLACK)
	for y: int in range(h):
		img.set_pixel(0,     y, Color.BLACK)
		img.set_pixel(w - 1, y, Color.BLACK)
	# Inner bevel for shapes that are big enough to show it
	if w > 16 and h > 16:
		var light := color.lightened(0.32)
		var dark  := color.darkened(0.38)
		for x: int in range(1, w - 1):
			img.set_pixel(x, 1,     light)
			img.set_pixel(x, h - 2, dark)
		for y: int in range(1, h - 1):
			img.set_pixel(1,     y, light)
			img.set_pixel(w - 2, y, dark)
	return ImageTexture.create_from_image(img)

# Running-bond brick pattern scaled to fit an arbitrary w x h rectangle —
# matches a level's wall StaticBody2D collider exactly, whatever its size, so
# the same call works for both the long horizontal top/bottom walls and the
# tall vertical side walls without separate textures or tiling artifacts.
static func make_wall_texture(color: Color, w: int, h: int) -> ImageTexture:
	const BRICK_W: int = 16
	const BRICK_H: int = 8
	var mortar: Color = color.darkened(0.45)
	var iw: int = maxi(w, 1)
	var ih: int = maxi(h, 1)
	var img := Image.create(iw, ih, false, Image.FORMAT_RGBA8)
	img.fill(color)
	for y: int in range(ih):
		var row: int = y / BRICK_H
		if y % BRICK_H == 0:
			for x: int in range(iw):
				img.set_pixel(x, y, mortar)
			continue
		var offset: int = (BRICK_W / 2) if row % 2 == 1 else 0
		var x: int = -offset
		while x < iw:
			if x >= 0:
				img.set_pixel(x, y, mortar)
			x += BRICK_W
	return ImageTexture.create_from_image(img)

# 16x16 collectible icon: a gem-like diamond in `color` over a dark backing
# square, with a darker outline — junk items additionally get a muted, desaturated
# rendering so the HUD inventory can tell "might matter later" from "keepsake"
# at a glance without text (see CLAUDE.md "Collectibles & Inventory").
static func make_item_icon(color: Color, is_junk: bool = false) -> ImageTexture:
	var fill: Color = color.darkened(0.35) if is_junk else color
	var outline: Color = fill.darkened(0.4)
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	_rect(img, 1, 1, 14, 14, Color(0.12, 0.12, 0.16, 0.85 if is_junk else 1.0))
	for i: int in range(8):
		_rect(img, 7 - i / 2, 2 + i, 2 + i, 1, fill)
	for i: int in range(7):
		_rect(img, 1 + i, 9 + i, 14 - i * 2, 1, fill)
	for x: int in range(16):
		img.set_pixel(x, 0, outline)
		img.set_pixel(x, 15, outline)
	for y: int in range(16):
		img.set_pixel(0, y, outline)
		img.set_pixel(15, y, outline)
	return ImageTexture.create_from_image(img)

# Pipe organ prop — tall vertical pipes of varying heights over a wood-framed body.
# Columns of bright metal pipes, a keyboard strip at the bottom, ornate case.
static func make_organ_texture(color: Color, w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var wood    := color
	var pipe    := Color(0.75, 0.78, 0.82)
	var pipe_hi := Color(0.92, 0.95, 1.0)
	var key_w   := Color(0.95, 0.95, 0.9)
	var key_b   := Color(0.18, 0.16, 0.14)
	img.fill(wood)
	# Case frame
	_rect(img, 0, 0, w, h, wood)
	# Pipe array — fill top 70% with pipes
	var pipe_area_h: int = int(h * 0.70)
	var pipe_w: int  = 5
	var gap: int     = 2
	var px: int      = 4
	var pipe_heights: Array = [pipe_area_h, pipe_area_h - 6, pipe_area_h - 12,
		pipe_area_h - 6, pipe_area_h, pipe_area_h - 4, pipe_area_h - 9, pipe_area_h - 15]
	var ph_idx: int = 0
	while px + pipe_w <= w - 4:
		var ph: int = pipe_heights[ph_idx % pipe_heights.size()]
		var py: int = 2 + (pipe_area_h - ph)
		_rect(img, px, py, pipe_w, ph, pipe)
		# Highlight on left edge of each pipe
		for y: int in range(py, py + ph):
			img.set_pixel(px, y, pipe_hi)
		# Shade on right edge
		for y: int in range(py, py + ph):
			img.set_pixel(px + pipe_w - 1, y, pipe.darkened(0.3))
		# Pipe cap at top
		_rect(img, px - 1, py, pipe_w + 2, 2, pipe_hi)
		px += pipe_w + gap
		ph_idx += 1
	# Keyboard strip — bottom 12px
	var kb_y: int = h - 12
	_rect(img, 2, kb_y, w - 4, 10, Color(0.3, 0.25, 0.18))
	var key_pw: int = 4
	var kx: int = 4
	var ki: int = 0
	while kx + key_pw <= w - 4:
		var is_black: bool = (ki % 7) in [1, 2, 4, 5, 6]
		_rect(img, kx, kb_y + 1, key_pw - 1, 8, key_b if is_black else key_w)
		kx += key_pw
		ki += 1
	# Outer border
	for x: int in range(w):
		img.set_pixel(x, 0,     Color.BLACK)
		img.set_pixel(x, h - 1, Color.BLACK)
	for y: int in range(h):
		img.set_pixel(0,     y, Color.BLACK)
		img.set_pixel(w - 1, y, Color.BLACK)
	return ImageTexture.create_from_image(img)

# Pipe rack — a row of freestanding vertical brass/copper cylinders of
# varying height, anchored to the bottom of the bounding box. Background
# stays transparent so it reads as loose pipes leaning against a wall
# rather than a boxed prop. Used in Pipe Organ Works' entry bay — see
# CLAUDE.md "1. Bellows & Sons Pipe Organ Works".
static func make_pipe_rack_texture(color: Color, w: int, h: int, n_pipes: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var pipe_hi: Color = color.lightened(0.35)
	var pipe_dark: Color = color.darkened(0.3)
	var pipe_w: int = maxi(w / n_pipes - 2, 2)
	var gap: int = maxi((w - pipe_w * n_pipes) / maxi(n_pipes - 1, 1), 1) if n_pipes > 1 else 0
	var x: int = 0
	for i: int in range(n_pipes):
		var pipe_h: int = h - (i % 3) * (h / 4)
		var y: int = h - pipe_h
		_rect(img, x, y, pipe_w, pipe_h, color)
		for py: int in range(y, h):
			img.set_pixel(x, py, pipe_hi)
			img.set_pixel(x + pipe_w - 1, py, pipe_dark)
		_rect(img, x - 1, y, pipe_w + 2, 2, pipe_hi)
		x += pipe_w + gap
	return ImageTexture.create_from_image(img)

# Bellows — a wide accordion-shaped prop: a copper-toned panel with a series
# of diagonal fold creases running its length, alternating direction to read
# as a zigzag/accordion silhouette. Used in Pipe Organ Works' main workshop.
static func make_bellows_texture(color: Color, w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var dark: Color = color.darkened(0.45)
	var hi: Color = color.lightened(0.25)
	img.fill(color)
	var fold_w: int = maxi(w / 6, 4)
	var nx: int = 0
	while nx < w:
		for y: int in range(h):
			var t: float = float(y) / float(maxi(h - 1, 1))
			var cx: int = nx + int(t * fold_w)
			if cx < w:
				img.set_pixel(cx, y, dark)
				if cx + 1 < w:
					img.set_pixel(cx + 1, y, hi)
		nx += fold_w
	_rect(img, 0, 0, w, 2, hi)
	_rect(img, 0, h - 2, w, 2, dark)
	for x: int in range(w):
		img.set_pixel(x, 0,     Color.BLACK)
		img.set_pixel(x, h - 1, Color.BLACK)
	for y: int in range(h):
		img.set_pixel(0,     y, Color.BLACK)
		img.set_pixel(w - 1, y, Color.BLACK)
	return ImageTexture.create_from_image(img)

# Workbench — a flat horizontal tabletop with two legs and three small tool
# silhouettes (hammer, wrench, screwdriver) resting on top. Used in Pipe
# Organ Works' main workshop to fill in the "factory floor scattered with
# parts" spec line.
static func make_workbench_texture(color: Color, w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var top_color: Color = color.lightened(0.18)
	var leg_color: Color = color.darkened(0.35)
	var tool_color: Color = Color(0.55, 0.57, 0.6)
	var top_h: int = maxi(h / 3, 3)
	_rect(img, 0, 0, w, top_h, top_color)
	_rect(img, 0, top_h - 1, w, 1, leg_color)
	var leg_w: int = maxi(w / 12, 2)
	_rect(img, 2, top_h, leg_w, h - top_h, leg_color)
	_rect(img, w - 2 - leg_w, top_h, leg_w, h - top_h, leg_color)
	# Hammer — wood handle + metal head
	var hx: int = w / 6
	_rect(img, hx, 1, 2, top_h - 3, Color(0.4, 0.28, 0.16))
	_rect(img, hx - 2, 0, 6, 2, tool_color)
	# Wrench — angled bar with open-end heads at each end
	var wx: int = w / 2
	_rect(img, wx, 1, top_h - 2, 2, tool_color)
	_rect(img, wx - 1, 0, 2, 2, tool_color)
	_rect(img, wx + top_h - 4, top_h - 2, 2, 2, tool_color)
	# Screwdriver — red handle, metal tip
	var sx: int = w * 5 / 6
	_rect(img, sx, 1, 1, top_h - 2, Color(0.85, 0.15, 0.1))
	_rect(img, sx - 1, top_h - 3, 3, 2, Color(0.7, 0.7, 0.75))
	for x: int in range(w):
		img.set_pixel(x, 0,     Color.BLACK)
		img.set_pixel(x, h - 1, Color.BLACK)
	for y: int in range(h):
		img.set_pixel(0,     y, Color.BLACK)
		img.set_pixel(w - 1, y, Color.BLACK)
	return ImageTexture.create_from_image(img)

# Soot stain — an irregular dark smudge (a noisy-edged ellipse) for walls
# near the organ; semi-transparent so the brick wall texture shows through
# near the edges. Fixed RNG seed keeps the shape deterministic across runs.
static func make_soot_stain_texture(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var soot: Color = Color(0.05, 0.05, 0.06, 0.55)
	var soot_core: Color = Color(0.02, 0.02, 0.03, 0.75)
	var cx: float = float(w) / 2.0
	var cy: float = float(h) / 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for y: int in range(h):
		for x: int in range(w):
			var dx: float = (float(x) - cx) / cx
			var dy: float = (float(y) - cy) / cy
			var dist: float = dx * dx + dy * dy
			var noise: float = rng.randf_range(-0.15, 0.15)
			if dist + noise <= 1.0:
				img.set_pixel(x, y, soot_core if dist + noise < 0.4 else soot)
	return ImageTexture.create_from_image(img)

# Electronic console / soundboard — dark panel with a glowing screen and buttons.
static func make_console_texture(color: Color, w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var panel   := color
	var screen  := color.lightened(0.12)
	var scanlin := color.darkened(0.18)
	var glow    := Color(0.3, 0.9, 0.7, 0.9)
	img.fill(panel)
	# Screen area — top 55% of panel
	var scr_h: int = int(h * 0.55)
	_rect(img, 4, 3, w - 8, scr_h, screen)
	# Scanlines across the screen
	var sy: int = 3
	while sy < 3 + scr_h:
		for sx: int in range(4, w - 4):
			img.set_pixel(sx, sy, scanlin)
		sy += 3
	# Glowing cursor dot on screen
	_rect(img, w / 2 - 2, 3 + scr_h / 2 - 1, 5, 3, glow)
	# Button row — bottom third
	var btn_y: int = 3 + scr_h + 4
	var btn_colors: Array[Color] = [
		Color(0.9, 0.25, 0.25), Color(0.9, 0.75, 0.1),
		Color(0.3, 0.85, 0.3),  Color(0.4, 0.55, 0.95),
	]
	var btn_x: int = 5
	var btn_spacing: int = maxi((w - 10) / 4, 8)
	for bc: Color in btn_colors:
		if btn_x + 4 < w - 4:
			_rect(img, btn_x, btn_y, 5, 4, bc)
			btn_x += btn_spacing
	# LED strip above buttons
	var led_x: int = 4
	while led_x < w - 6:
		img.set_pixel(led_x, btn_y - 3, Color(0.3, 1.0, 0.5) if led_x % 6 == 0 else Color(0.9, 0.3, 0.3))
		led_x += 3
	# Outer border + bevel
	for x: int in range(w):
		img.set_pixel(x, 0,     Color.BLACK)
		img.set_pixel(x, h - 1, Color.BLACK)
	for y: int in range(h):
		img.set_pixel(0,     y, Color.BLACK)
		img.set_pixel(w - 1, y, Color.BLACK)
	if w > 16 and h > 16:
		for x: int in range(1, w - 1):
			img.set_pixel(x, 1,     color.lightened(0.3))
			img.set_pixel(x, h - 2, color.darkened(0.35))
		for y: int in range(1, h - 1):
			img.set_pixel(1,     y, color.lightened(0.3))
			img.set_pixel(w - 2, y, color.darkened(0.35))
	return ImageTexture.create_from_image(img)

# Clockwork gear mechanism — a large toothed gear with satellite gears.
static func make_gear_prop_texture(color: Color, w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var metal   := color
	var tooth   := color.lightened(0.22)
	var hub     := color.darkened(0.35)
	img.fill(metal.darkened(0.5))   # dark background
	# Main gear — draw as filled circle + teeth
	var cx: int = w / 2
	var cy: int = h / 2
	var rad: int = mini(w, h) / 2 - 5
	# Fill circle
	for y: int in range(h):
		for x: int in range(w):
			var dx: float = float(x - cx)
			var dy: float = float(y - cy)
			if dx * dx + dy * dy <= float(rad * rad):
				img.set_pixel(x, y, metal)
	# Gear teeth — 10 teeth evenly around
	var tooth_count: int = 10
	for ti: int in range(tooth_count):
		var a: float = TAU * float(ti) / float(tooth_count)
		var a2: float = TAU * (float(ti) + 0.3) / float(tooth_count)
		for r: int in range(rad, rad + 5):
			for ai: int in range(8):
				var aa: float = lerp(a, a2, float(ai) / 8.0)
				var px: int = cx + int(cos(aa) * r)
				var py: int = cy + int(sin(aa) * r)
				if px >= 0 and px < w and py >= 0 and py < h:
					img.set_pixel(px, py, tooth)
	# Highlight arc on gear (top-left quadrant)
	for ti: int in range(24):
		var a: float = PI + TAU * float(ti) / 32.0
		var px: int = cx + int(cos(a) * (rad - 2))
		var py: int = cy + int(sin(a) * (rad - 2))
		if px >= 0 and px < w and py >= 0 and py < h:
			img.set_pixel(px, py, tooth)
	# Hub circle in center
	var hub_r: int = rad / 3
	for y: int in range(h):
		for x: int in range(w):
			var dx: float = float(x - cx)
			var dy: float = float(y - cy)
			if dx * dx + dy * dy <= float(hub_r * hub_r):
				img.set_pixel(x, y, hub)
	# Small satellite gear at bottom-right
	var sc: int = rad / 2
	var scx: int = cx + rad - 2
	var scy: int = cy + rad - 2
	for y: int in range(h):
		for x: int in range(w):
			var dx: float = float(x - scx)
			var dy: float = float(y - scy)
			if dx * dx + dy * dy <= float(sc * sc):
				img.set_pixel(x, y, tooth)
	# Outer border
	for x: int in range(w):
		img.set_pixel(x, 0,     Color.BLACK)
		img.set_pixel(x, h - 1, Color.BLACK)
	for y: int in range(h):
		img.set_pixel(0,     y, Color.BLACK)
		img.set_pixel(w - 1, y, Color.BLACK)
	return ImageTexture.create_from_image(img)

# Bell prop — two church bells hanging side by side with clappers.
static func make_bell_texture(color: Color, w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bell   := color
	var bell_hi := color.lightened(0.35)
	var clapper := color.darkened(0.55)
	img.fill(color.darkened(0.6))   # dark wood background
	# Draw two bells side by side
	var bell_count: int = 2
	var bell_w: int = (w - 6) / bell_count
	for bi: int in range(bell_count):
		var bx: int = 3 + bi * (bell_w + 2)
		var by: int = 4
		var bh: int = h - 12
		# Bell body — trapezoid (narrower at top, wider at bottom)
		for row: int in range(bh):
			var t: float = float(row) / float(bh)
			var half_w: int = int(lerp(bell_w * 0.25, bell_w * 0.5, t))
			var bcx: int = bx + bell_w / 2
			_rect(img, bcx - half_w, by + row, half_w * 2, 1, bell)
		# Bell highlight on left curve
		for row: int in range(bh):
			var t: float = float(row) / float(bh)
			var half_w: int = int(lerp(bell_w * 0.25, bell_w * 0.5, t))
			var bcx: int = bx + bell_w / 2
			if bcx - half_w >= 0 and bcx - half_w < w:
				img.set_pixel(bcx - half_w, by + row, bell_hi)
		# Bell rim at bottom (thick bright line)
		_rect(img, bx, by + bh - 3, bell_w, 3, bell_hi)
		# Clapper — thin line hanging from center top
		var clapper_x: int = bx + bell_w / 2
		_rect(img, clapper_x, by + bh / 3, 1, bh / 2, clapper)
		_rect(img, clapper_x - 1, by + bh * 3 / 4, 3, 3, clapper)
		# Suspension bracket at top
		_rect(img, bx + bell_w / 2 - 2, 1, 4, 4, color.darkened(0.3))
	# Cross-beam at top
	_rect(img, 1, 2, w - 2, 3, color.darkened(0.2))
	# Outer border
	for x: int in range(w):
		img.set_pixel(x, 0,     Color.BLACK)
		img.set_pixel(x, h - 1, Color.BLACK)
	for y: int in range(h):
		img.set_pixel(0,     y, Color.BLACK)
		img.set_pixel(w - 1, y, Color.BLACK)
	return ImageTexture.create_from_image(img)

# Weight barbell — two plates on each end, knurled bar connecting them.
static func make_barbell_texture(color: Color, w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var plate  := color.lightened(0.15)
	var bar    := color.darkened(0.15)
	var knurl  := color.darkened(0.35)
	img.fill(Color(0.08, 0.07, 0.1))   # very dark bg
	# Bar through center
	var bar_t: int = maxi(h / 4, 2)
	var by: int = (h - bar_t) / 2
	_rect(img, 0, by, w, bar_t, bar)
	# Knurling — alternating dark notches across the middle
	var knurl_start: int = w / 6
	var knurl_end: int   = w - w / 6
	var kx: int = knurl_start
	while kx < knurl_end:
		for ky: int in range(by, by + bar_t):
			img.set_pixel(kx, ky, knurl)
		kx += 3
	# Plates — thick rects at each end, full height
	var plate_w: int = maxi(w / 10, 6)
	_rect(img, 0,          0, plate_w,     h, plate)
	_rect(img, w - plate_w, 0, plate_w,     h, plate)
	# Plate highlight
	for y: int in range(h):
		img.set_pixel(1, y, plate.lightened(0.3))
		img.set_pixel(w - 2, y, plate.darkened(0.2))
	# Collar rings (where bar meets plates)
	var collar_w: int = 3
	_rect(img, plate_w,          by - 1, collar_w, bar_t + 2, color)
	_rect(img, w - plate_w - collar_w, by - 1, collar_w, bar_t + 2, color)
	# Outer border
	for x: int in range(w):
		img.set_pixel(x, 0,     Color.BLACK)
		img.set_pixel(x, h - 1, Color.BLACK)
	for y: int in range(h):
		img.set_pixel(0,     y, Color.BLACK)
		img.set_pixel(w - 1, y, Color.BLACK)
	return ImageTexture.create_from_image(img)

# Pew bench — dark wood rectangle with a 2px back rail across the top and
# small leg blocks at each end. 80x18px in The Old Parish Church.
static func make_pew_texture(color: Color, w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var rail: Color = color.lightened(0.18)
	var leg: Color = color.darkened(0.35)
	_rect(img, 0, 0, w, 2, rail)
	var leg_w: int = maxi(w / 10, 2)
	_rect(img, 0, h - 4, leg_w, 4, leg)
	_rect(img, w - leg_w, h - 4, leg_w, 4, leg)
	return ImageTexture.create_from_image(img)

# Altar — raised stone platform with a cloth-draped table on top. 64x24px.
static func make_altar_texture(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var stone: Color = Color(0.55, 0.53, 0.50)
	var cloth: Color = Color(0.55, 0.12, 0.14)
	var cloth_dark: Color = cloth.darkened(0.25)
	img.fill(stone)
	var cloth_h: int = h / 2
	_rect(img, 0, 0, w, cloth_h, cloth)
	_rect(img, 0, cloth_h - 1, w, 1, cloth_dark)
	for x: int in range(0, w, 6):
		_rect(img, x, cloth_h, 3, 2, cloth_dark)
	_rect(img, 0, h - 2, w, 2, stone.darkened(0.3))
	return ImageTexture.create_from_image(img)

# Stained glass — 3x4 grid of colored panels separated by 1px black lead
# lines, cycling through the colors array. 32x64px on the nave's east/west
# walls.
static func make_stained_glass_texture(w: int, h: int, colors: Array) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color.BLACK)
	const COLS: int = 3
	const ROWS: int = 4
	var cell_w: int = (w - (COLS - 1)) / COLS
	var cell_h: int = (h - (ROWS - 1)) / ROWS
	for row: int in range(ROWS):
		for col: int in range(COLS):
			var panel: Color = colors[(row * COLS + col) % colors.size()]
			_rect(img, col * (cell_w + 1), row * (cell_h + 1), cell_w, cell_h, panel)
	return ImageTexture.create_from_image(img)

# Candle — thin white wax stub with a small orange flame teardrop at the top
# when lit. 8x24px.
static func make_candle_texture(w: int, h: int, lit: bool) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var wax: Color = Color(0.92, 0.88, 0.78)
	var flame_h: int = 6 if lit else 0
	_rect(img, 0, flame_h, w, h - flame_h, wax)
	_rect(img, w - 1, flame_h, 1, h - flame_h, wax.darkened(0.15))
	if lit:
		var flame: Color = Color(1.0, 0.55, 0.1)
		var flame_core: Color = Color(1.0, 0.85, 0.3)
		var cx: int = w / 2
		_rect(img, cx, 0, 1, 1, flame)
		_rect(img, cx - 1, 1, 3, 2, flame)
		_rect(img, cx, 3, 1, 1, flame_core)
		_rect(img, cx - 1, 4, 3, 1, flame)
		_rect(img, cx, 5, 1, 1, flame)
	return ImageTexture.create_from_image(img)

# Arch window — pointed-arch outline with a colored glass fill and a center
# mullion. Used above the altar on the nave's north wall.
static func make_arch_window_texture(w: int, h: int, glass_color: Color) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var frame: Color = Color(0.25, 0.22, 0.18)
	img.fill(frame)
	var arch_h: int = h / 2
	# Pointed arch top — triangular taper from a point down to full width.
	for y: int in range(arch_h):
		var t: float = float(y) / float(maxi(arch_h - 1, 1))
		var inset: int = int(lerp(float(w) / 2.0 - 1.0, 2.0, t))
		_rect(img, inset, y, maxi(w - inset * 2, 0), 1, glass_color)
	# Rectangular base below the arch.
	_rect(img, 2, arch_h, w - 4, h - arch_h - 2, glass_color)
	# Center mullion divider.
	_rect(img, w / 2, 0, 1, h, glass_color.darkened(0.35))
	return ImageTexture.create_from_image(img)

static func _rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var iw: int = img.get_width()
	var ih: int = img.get_height()
	for px: int in range(maxi(x, 0), mini(x + w, iw)):
		for py: int in range(maxi(y, 0), mini(y + h, ih)):
			img.set_pixel(px, py, color)
