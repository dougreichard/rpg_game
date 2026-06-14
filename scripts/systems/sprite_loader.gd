class_name SpriteLoader
extends RefCounted

# Sprite sheet loader matching the layout defined in sprites.md.
# try_load_player / try_load_enemy return a SpriteFrames built from
# assets/art/sprites/<name>.png when the file exists, or null so the
# caller can fall back to PlaceholderArt.  Results are cached so each
# PNG is decoded at most once per session.

const TILE_SIZE: int = 32

# Player sheets are authored at 64x64 (2x oversample over the 32x32 gameplay
# tile, per DESIGN.md SS2.0/SS3) — try_load_player scales the AnimatedSprite2D
# down via PLAYER_SPRITE_SCALE so the on-screen footprint stays 32x32.
const PLAYER_TILE_SIZE: int = 64
const PLAYER_SPRITE_SCALE: float = 0.5

# Player animation layout — row order from sprites.md.
const PLAYER_ANIMS: Array = [
	{name="idle",         row=0,  frames=6,  fps=8.0,  loop=true},
	{name="walk_down",    row=1,  frames=8,  fps=10.0, loop=true},
	{name="walk_up",      row=2,  frames=8,  fps=10.0, loop=true},
	{name="walk_right",   row=3,  frames=8,  fps=10.0, loop=true},
	{name="run_down",     row=4,  frames=8,  fps=14.0, loop=true},
	{name="run_up",       row=5,  frames=8,  fps=14.0, loop=true},
	{name="run_right",    row=6,  frames=8,  fps=14.0, loop=true},
	{name="attack",       row=7,  frames=6,  fps=12.0, loop=false},
	{name="special",      row=8,  frames=8,  fps=10.0, loop=false},
	{name="talk",         row=9,  frames=6,  fps=8.0,  loop=true},
	{name="talk_closeup", row=10, frames=8,  fps=8.0,  loop=true},
	{name="hurt",         row=11, frames=4,  fps=15.0, loop=false},
	{name="down",         row=12, frames=10, fps=10.0, loop=false},
	{name="revive",       row=13, frames=8,  fps=10.0, loop=false},
	{name="dash",         row=14, frames=5,  fps=15.0, loop=false},
	{name="interact",     row=15, frames=8,  fps=10.0, loop=true},
	{name="doorway",      row=16, frames=6,  fps=10.0, loop=false},
]

# Enemy animation layout — same row order for Grunt, Runner, Sentry, and Boss.
# Brute and Boss use wider/taller tiles (see ENEMY_TILE_OVERRIDES).
const ENEMY_ANIMS: Array = [
	{name="walk",    row=0, frames=6, fps=8.0,  loop=true},
	{name="chase",   row=1, frames=8, fps=10.0, loop=true},
	{name="windup",  row=2, frames=6, fps=8.0,  loop=false},
	{name="attack",  row=3, frames=4, fps=12.0, loop=false},
	{name="recover", row=4, frames=4, fps=8.0,  loop=false},
	{name="hurt",    row=5, frames=4, fps=15.0, loop=false},
	{name="death",   row=6, frames=8, fps=10.0, loop=false},
	{name="alert",   row=7, frames=4, fps=8.0,  loop=true},
]

# Enemy sheets are authored 2x-oversampled (64x64 default tile, per
# sprites.md/DESIGN.md SS2.0 — same convention as PLAYER_TILE_SIZE /
# PLAYER_SPRITE_SCALE) — try_load_enemy scales the AnimatedSprite2D down via
# ENEMY_SPRITE_SCALE so the on-screen footprint matches the old
# PlaceholderArt gameplay size (32x32 default, 48x32 brute, 64x64 boss).
const ENEMY_TILE_SIZE: int = 64
const ENEMY_SPRITE_SCALE: float = 0.5

# Brute (96×64 source -> 48x32 on screen) and Boss (128×128 source -> 64x64 on
# screen) use wider/taller source tiles than the 64x64 default.
const ENEMY_TILE_OVERRIDES: Dictionary = {
	"brute": Vector2i(96, 64),
	"boss":  Vector2i(128, 128),
}

# NPC sheets — 64x64 tiles, 0.5x scale (same convention as players/enemies).
const NPC_TILE_SIZE: int = 64
const NPC_SPRITE_SCALE: float = 0.5

# Town NPC animation layout (all 12 overworld quest-givers).
const NPC_TOWN_ANIMS: Array = [
	{name="idle",         row=0, frames=6, fps=8.0,  loop=true},
	{name="walk_right",   row=1, frames=8, fps=10.0, loop=true},
	{name="walk_down",    row=2, frames=8, fps=10.0, loop=true},
	{name="talk_closeup", row=3, frames=6, fps=8.0,  loop=true},
]

# Mr. Bellows (Pipe Organ Works) — seated desk NPC with item hand-off row.
const NPC_MR_BELLOWS_ANIMS: Array = [
	{name="idle",           row=0, frames=6, fps=8.0,  loop=true},
	{name="talk",           row=1, frames=6, fps=8.0,  loop=true},
	{name="talk_closeup",   row=2, frames=8, fps=8.0,  loop=true},
	{name="relieved",       row=3, frames=6, fps=8.0,  loop=true},
	{name="hand_over_item", row=4, frames=4, fps=8.0,  loop=false},
]

# Father Aldric (Old Parish Church) — three emotion-specific closeup rows
# replacing the standard walk rows; played by name to match impression flag.
const NPC_ALDRIC_ANIMS: Array = [
	{name="idle",         row=0, frames=6, fps=8.0, loop=true},
	{name="talk",         row=1, frames=6, fps=8.0, loop=true},
	{name="talk_pleased", row=2, frames=8, fps=8.0, loop=true},
	{name="talk_amused",  row=3, frames=8, fps=8.0, loop=true},
	{name="talk_annoyed", row=4, frames=6, fps=8.0, loop=true},
]

# Uncle Doug (Grand Marquee Cinema projection booth).
const NPC_UNCLE_DOUG_ANIMS: Array = [
	{name="idle",         row=0, frames=6, fps=8.0,  loop=true},
	{name="wave",         row=1, frames=8, fps=10.0, loop=true},
	{name="talk",         row=2, frames=6, fps=8.0,  loop=true},
	{name="talk_closeup", row=3, frames=8, fps=8.0,  loop=true},
]

# Shared layout for gate NPCs (Librarian and Carnival Guard share identical rows).
const NPC_GATEKEEPER_ANIMS: Array = [
	{name="idle",         row=0, frames=6, fps=8.0,  loop=true},
	{name="refuse",       row=1, frames=6, fps=8.0,  loop=true},
	{name="step_aside",   row=2, frames=8, fps=10.0, loop=false},
	{name="talk_closeup", row=3, frames=6, fps=8.0,  loop=true},
]

# Shared layout for level-interior NPCs generated via gen_*.py biped sheets:
# Hieronymus (Clocktower), Viktor (Harbor), Cyrus (Underground),
# Lena (Zip Line Park), ARIA (VR Escape Room), Rio (The Drop).
const NPC_LEVEL_BIPED_ANIMS: Array = [
	{name="idle",         row=0, frames=4, fps=6.0,  loop=true},
	{name="idle_alt",     row=1, frames=6, fps=7.0,  loop=true},
	{name="talk_closeup", row=2, frames=6, fps=8.0,  loop=true},
	{name="gesture",      row=3, frames=6, fps=8.0,  loop=true},
	{name="surprise",     row=4, frames=4, fps=10.0, loop=false},
]

# Animal companion sheets — 64x64 tiles, 0.5x scale (matches player/enemy/NPC convention).
const COMPANION_TILE_SIZE: int = 64
const COMPANION_SPRITE_SCALE: float = 0.5

const COMPANION_FROSTY_ANIMS: Array = [
	{name="idle",         row=0,  frames=6, fps=8.0,  loop=true},
	{name="trot_down",    row=1,  frames=8, fps=10.0, loop=true},
	{name="trot_up",      row=2,  frames=8, fps=10.0, loop=true},
	{name="trot_right",   row=3,  frames=8, fps=10.0, loop=true},
	{name="gallop_down",  row=4,  frames=8, fps=12.0, loop=true},
	{name="gallop_up",    row=5,  frames=8, fps=12.0, loop=true},
	{name="gallop_right", row=6,  frames=8, fps=12.0, loop=true},
	{name="charge",       row=7,  frames=6, fps=14.0, loop=true},
	{name="hurt",         row=8,  frames=4, fps=15.0, loop=false},
	{name="down",         row=9,  frames=8, fps=10.0, loop=false},
	{name="return",       row=10, frames=6, fps=10.0, loop=true},
]

const COMPANION_TWINKLE_ANIMS: Array = [
	{name="idle",          row=0, frames=6, fps=8.0,  loop=true},
	{name="trot_down",     row=1, frames=6, fps=10.0, loop=true},
	{name="trot_right",    row=2, frames=6, fps=10.0, loop=true},
	{name="bark_distract", row=3, frames=8, fps=10.0, loop=false},
	{name="return_trot",   row=4, frames=6, fps=10.0, loop=true},
	{name="hurt",          row=5, frames=4, fps=15.0, loop=false},
	{name="down",          row=6, frames=6, fps=10.0, loop=false},
	{name="sniff",         row=7, frames=4, fps=8.0,  loop=true},
	{name="annoyed",       row=8, frames=4, fps=8.0,  loop=true},
]

const COMPANION_WILLIAM_MARY_ANIMS: Array = [
	{name="idle_pair",             row=0, frames=6, fps=8.0,  loop=true},
	{name="hop_down_pair",         row=1, frames=8, fps=10.0, loop=true},
	{name="hop_right_pair",        row=2, frames=8, fps=10.0, loop=true},
	{name="brace_hold_right_pair", row=3, frames=6, fps=8.0,  loop=true},
	{name="william_squeeze_gap",   row=4, frames=6, fps=10.0, loop=false},
	{name="reunite",               row=5, frames=6, fps=10.0, loop=false},
	{name="hurt_pair",             row=6, frames=4, fps=15.0, loop=false},
	{name="down_pair",             row=7, frames=8, fps=10.0, loop=false},
]

const COMPANION_CALVIN_COOLIDGE_ANIMS: Array = [
	{name="idle_pair",         row=0, frames=6, fps=8.0,  loop=true},
	{name="walk_down_pair",    row=1, frames=8, fps=10.0, loop=true},
	{name="walk_right_pair",   row=2, frames=8, fps=10.0, loop=true},
	{name="calvin_charge",     row=3, frames=6, fps=14.0, loop=true},
	{name="coolidge_brace",    row=4, frames=6, fps=8.0,  loop=false},
	{name="dual_charge_split", row=5, frames=8, fps=14.0, loop=false},
	{name="hurt_pair",         row=6, frames=4, fps=15.0, loop=false},
	{name="down_pair",         row=7, frames=8, fps=10.0, loop=false},
	{name="return",            row=8, frames=6, fps=10.0, loop=true},
]

const COMPANION_LIZARD_ANIMS: Array = [
	{name="idle",              row=0, frames=4, fps=6.0,  loop=true},
	{name="walk_right_ground", row=1, frames=6, fps=10.0, loop=true},
	{name="climb_upward",      row=2, frames=8, fps=12.0, loop=true},
	{name="perch_hold",        row=3, frames=4, fps=8.0,  loop=true},
	{name="target_reached",    row=4, frames=4, fps=10.0, loop=false},
	{name="descend",           row=5, frames=8, fps=12.0, loop=true},
	{name="flee_scatter",      row=6, frames=4, fps=12.0, loop=false},
]

const COMPANION_GUINEA_PIGS_ANIMS: Array = [
	{name="idle_scatter",  row=0, frames=6, fps=8.0,  loop=true},
	{name="scurry_right",  row=1, frames=8, fps=12.0, loop=true},
	{name="scurry_down",   row=2, frames=8, fps=12.0, loop=true},
	{name="flood_panic",   row=3, frames=8, fps=14.0, loop=true},
	{name="calm_regroup",  row=4, frames=6, fps=8.0,  loop=false},
	{name="down",          row=5, frames=6, fps=10.0, loop=false},
]

static var _player_cache: Dictionary = {}
static var _enemy_cache: Dictionary = {}
static var _npc_cache: Dictionary = {}
static var _companion_cache: Dictionary = {}
static var _anim_billboard_cache: Dictionary = {}
static var _anim_side_cache: Dictionary = {}

# Synty animated billboards: per-character directional strips baked under
# assets/art/synty/characters/anim/<key>/ (idle, walk_down/up/right, …). Shared by
# the in-level Player, the overworld duo, and town NPCs.
const _ANIM_BILLBOARD_DIR: String = "res://assets/art/synty/characters/anim/"
const _ANIM_LOOPING: Array = ["idle", "walk", "run"]
const _ANIM_FPS: Dictionary = {"idle": 7.0, "walk": 14.0, "run": 18.0}

# Builds a directional SpriteFrames from the anim strips for `key`, or null if the
# dir/strips are absent (caller falls back to a static billboard). Each <anim>.png is
# a row of square frames (frame side == strip height). anim_frame_side(key) returns
# that side afterward, for feet-anchored scaling.
static func try_load_anim_billboard(key: String) -> SpriteFrames:
	var k: String = key.to_lower()
	if k in _anim_billboard_cache:
		return _anim_billboard_cache[k]
	var dir_path: String = _ANIM_BILLBOARD_DIR + k
	var da: DirAccess = DirAccess.open(dir_path)
	var sf: SpriteFrames = null
	if da != null:
		sf = SpriteFrames.new()
		sf.remove_animation("default")
		var any: bool = false
		for f: String in da.get_files():
			if not f.ends_with(".png"):
				continue
			var tex: Texture2D = load(dir_path + "/" + f)
			if tex == null:
				continue
			var anim: String = f.get_basename()
			var s: int = tex.get_height()
			var cols: int = maxi(1, tex.get_width() / s)
			sf.add_animation(anim)
			sf.set_animation_loop(anim, _anim_base(anim) in _ANIM_LOOPING)
			sf.set_animation_speed(anim, _ANIM_FPS.get(_anim_base(anim), 10.0))
			for c: int in cols:
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(c * s, 0, s, s)
				sf.add_frame(anim, at)
			_anim_side_cache[k] = s
			any = true
		if not any:
			sf = null
	_anim_billboard_cache[k] = sf
	return sf

static func anim_frame_side(key: String) -> int:
	return _anim_side_cache.get(key.to_lower(), 0)

static func _anim_base(anim: String) -> String:
	for suffix: String in ["_down", "_up", "_right", "_left"]:
		if anim.ends_with(suffix):
			return anim.trim_suffix(suffix)
	return anim

# Returns a SpriteFrames built from assets/art/sprites/<character_name>.png,
# or null if the file is absent (caller should use PlaceholderArt instead).
static func try_load_player(character_name: String) -> SpriteFrames:
	var key: String = character_name.to_lower()
	if key in _player_cache:
		return _player_cache[key]
	var path: String = "res://assets/art/sprites/%s.png" % key
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	var result: SpriteFrames = _build(tex.get_image(), PLAYER_ANIMS, PLAYER_TILE_SIZE, PLAYER_TILE_SIZE)
	_player_cache[key] = result
	return result

# Returns a SpriteFrames built from assets/art/sprites/<enemy_name>.png,
# or null if the file is absent.
static func try_load_enemy(enemy_name: String) -> SpriteFrames:
	var key: String = enemy_name.to_lower()
	if key in _enemy_cache:
		return _enemy_cache[key]
	var path: String = "res://assets/art/sprites/%s.png" % key
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	var tile: Vector2i = ENEMY_TILE_OVERRIDES.get(key, Vector2i(ENEMY_TILE_SIZE, ENEMY_TILE_SIZE))
	var result: SpriteFrames = _build(tex.get_image(), ENEMY_ANIMS, tile.x, tile.y)
	_enemy_cache[key] = result
	return result

# Returns a SpriteFrames built from assets/art/sprites/<npc_name>.png using the
# animation table registered for that NPC, or null if the file is absent.
# Names not in the registry use NPC_TOWN_ANIMS (all 12 town quest-givers).
static func try_load_npc(npc_name: String) -> SpriteFrames:
	var key: String = npc_name.to_lower()
	if key in _npc_cache:
		return _npc_cache[key]
	var path: String = "res://assets/art/sprites/%s.png" % key
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	var result: SpriteFrames = _build(tex.get_image(), _npc_anims(key), NPC_TILE_SIZE, NPC_TILE_SIZE)
	_npc_cache[key] = result
	return result

static func _npc_anims(key: String) -> Array:
	match key:
		"mr_bellows":     return NPC_MR_BELLOWS_ANIMS
		"father_aldric":  return NPC_ALDRIC_ANIMS
		"uncle_doug":     return NPC_UNCLE_DOUG_ANIMS
		"librarian":      return NPC_GATEKEEPER_ANIMS
		"carnival_guard": return NPC_GATEKEEPER_ANIMS
		"hieronymus":     return NPC_LEVEL_BIPED_ANIMS
		"viktor":         return NPC_LEVEL_BIPED_ANIMS
		"cyrus":          return NPC_LEVEL_BIPED_ANIMS
		"lena":           return NPC_LEVEL_BIPED_ANIMS
		"aria":           return NPC_LEVEL_BIPED_ANIMS
		"rio":            return NPC_LEVEL_BIPED_ANIMS
		"usher":          return NPC_LEVEL_BIPED_ANIMS
		_:                return NPC_TOWN_ANIMS

# Returns a SpriteFrames for an animal companion, or null if the PNG is absent.
static func try_load_companion(companion_name: String) -> SpriteFrames:
	var key: String = companion_name.to_lower()
	if key in _companion_cache:
		return _companion_cache[key]
	var path: String = "res://assets/art/sprites/%s.png" % key
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	var result: SpriteFrames = _build(tex.get_image(), _companion_anims(key), COMPANION_TILE_SIZE, COMPANION_TILE_SIZE)
	_companion_cache[key] = result
	return result

static func _companion_anims(key: String) -> Array:
	match key:
		"frosty":              return COMPANION_FROSTY_ANIMS
		"twinkle":             return COMPANION_TWINKLE_ANIMS
		"william_and_mary":    return COMPANION_WILLIAM_MARY_ANIMS
		"calvin_and_coolidge": return COMPANION_CALVIN_COOLIDGE_ANIMS
		"lizard":              return COMPANION_LIZARD_ANIMS
		"guinea_pigs":         return COMPANION_GUINEA_PIGS_ANIMS
		_:                     return COMPANION_FROSTY_ANIMS

static func _build(img: Image, anims: Array, tile_w: int, tile_h: int) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim in anims:
		var anim_name: String = anim["name"]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, anim["loop"])
		frames.set_animation_speed(anim_name, anim["fps"])
		for col: int in range(anim["frames"]):
			var region := Rect2i(col * tile_w, anim["row"] * tile_h, tile_w, tile_h)
			frames.add_frame(anim_name, ImageTexture.create_from_image(img.get_region(region)))
	return frames
