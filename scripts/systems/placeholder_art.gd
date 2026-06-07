class_name PlaceholderArt
extends RefCounted

static func make_player_frames(color: Color) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var skin := color.lightened(0.25)
	var limb := color.darkened(0.2)
	_add(frames, "idle",   [_humanoid(skin, color, limb, Color.WHITE, 0)])
	_add(frames, "walk",   [_humanoid(skin, color, limb, Color.WHITE, 0),
							_humanoid(skin, color, limb, Color.WHITE, 1)])
	_add(frames, "attack", [_humanoid(skin, color.lightened(0.45), limb, Color.WHITE, 0)])
	_add(frames, "dash",   [_humanoid(skin, color.lightened(0.2), limb, Color.WHITE, 0)])
	_add(frames, "hurt",   [_humanoid(skin, Color(1.0, 0.3, 0.3), Color(0.8, 0.2, 0.2), Color.WHITE, 0)])
	_add(frames, "down",   [_humanoid(color.darkened(0.4), color.darkened(0.55), color.darkened(0.55), Color.TRANSPARENT, 0)])
	return frames

static func make_enemy_frames(color: Color, stocky: bool = false) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var limb := color.darkened(0.25)
	var windup := Color(1.0, 0.65, 0.0)
	_add(frames, "walk",   [_enemy(color, limb, stocky, 0), _enemy(color, limb, stocky, 1)])
	_add(frames, "windup", [_enemy(windup, windup.darkened(0.3), stocky, 0)])
	_add(frames, "attack", [_enemy(color.lightened(0.5), limb.lightened(0.3), stocky, 0)])
	_add(frames, "hurt",   [_enemy(Color(1.0, 0.3, 0.3), Color(0.7, 0.15, 0.15), stocky, 0)])
	return frames

static func _add(frames: SpriteFrames, anim: String, textures: Array) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, true)
	frames.set_animation_speed(anim, 6.0)
	for t: ImageTexture in textures:
		frames.add_frame(anim, t)

# 32×32 humanoid sprite, facing right — compact chibi proportions (big head, short legs)
static func _humanoid(head: Color, body: Color, limb: Color, eye: Color, walk: int) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	_rect(img, 12,  1,  9,  8, head)   # head (right-of-centre = facing right)
	_rect(img, 10,  9, 12,  9, body)   # torso
	_rect(img,  7, 10,  4,  7, limb)   # left arm
	_rect(img, 21, 10,  4,  7, limb)   # right arm
	var ll_y: int = 18 + (2 if walk == 1 else 0)
	var rl_y: int = 18 + (2 if walk == 0 else 0)
	_rect(img, 11, ll_y, 4, 30 - ll_y, limb)  # left leg
	_rect(img, 17, rl_y, 4, 30 - rl_y, limb)  # right leg
	if eye.a > 0.5:
		img.set_pixel(19, 4, eye)
		img.set_pixel(18, 4, eye)
	return ImageTexture.create_from_image(img)

# 32×32 enemy sprite — compact chibi proportions
static func _enemy(body: Color, limb: Color, stocky: bool, walk: int) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	if stocky:
		_rect(img,  9,  1, 13,  9, body)   # big head
		_rect(img,  6, 10, 20,  9, body)   # wide torso
		_rect(img,  2, 11,  4,  7, limb)   # left arm
		_rect(img, 26, 11,  4,  7, limb)   # right arm
		var ll_y: int = 17 + (2 if walk == 1 else 0)
		var rl_y: int = 17 + (2 if walk == 0 else 0)
		_rect(img,  8, ll_y, 6, 30 - ll_y, limb)
		_rect(img, 18, rl_y, 6, 30 - rl_y, limb)
		img.set_pixel(17, 4, Color.RED)
		img.set_pixel(15, 4, Color.RED)
	else:
		_rect(img, 12,  0,  8,  7, body)   # small head
		_rect(img, 11,  7, 10, 10, body)   # slim torso
		_rect(img,  8,  8,  3,  8, limb)   # left arm
		_rect(img, 21,  8,  3,  8, limb)   # right arm
		var ll_y: int = 17 + (2 if walk == 1 else 0)
		var rl_y: int = 17 + (2 if walk == 0 else 0)
		_rect(img, 12, ll_y, 3, 30 - ll_y, limb)
		_rect(img, 17, rl_y, 3, 30 - rl_y, limb)
		img.set_pixel(17, 3, Color.YELLOW)
		img.set_pixel(16, 3, Color.YELLOW)
	return ImageTexture.create_from_image(img)

# Builds a 32×32-tile floor TileSet: tile (0,0) is a plain seamed floor square,
# tile (1,0) is the same square plus a small accent fleck for organic variety —
# a Zelda-dungeon-style two-tone tiled floor, generated at runtime (no imported art).
static func make_level_tileset(base: Color, accent: Color) -> TileSet:
	var seam: Color = base.darkened(0.3)
	var atlas := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	for tile: int in range(2):
		var ox: int = tile * 32
		_rect(atlas, ox, 0, 32, 32, base)
		for i: int in range(32):
			atlas.set_pixel(ox + i, 0, seam)
			atlas.set_pixel(ox + i, 31, seam)
			atlas.set_pixel(ox, i, seam)
			atlas.set_pixel(ox + 31, i, seam)
	_rect(atlas, 32 + 9,  9, 4, 4, accent)
	_rect(atlas, 32 + 19, 18, 3, 3, accent.darkened(0.15))
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

static func make_gate_texture(color: Color, w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	for x: int in range(w):
		img.set_pixel(x, 0, Color.BLACK)
		img.set_pixel(x, h - 1, Color.BLACK)
	for y: int in range(h):
		img.set_pixel(0, y, Color.BLACK)
		img.set_pixel(w - 1, y, Color.BLACK)
	return ImageTexture.create_from_image(img)

static func _rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var iw: int = img.get_width()
	var ih: int = img.get_height()
	for px: int in range(maxi(x, 0), mini(x + w, iw)):
		for py: int in range(maxi(y, 0), mini(y + h, ih)):
			img.set_pixel(px, py, color)
