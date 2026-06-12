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

static var _player_cache: Dictionary = {}
static var _enemy_cache: Dictionary = {}

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
