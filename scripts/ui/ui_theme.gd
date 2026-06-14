# Cozy-warm UI skin built from the Synty ApocalypseHUD sprites (assets/art/ui/).
# The sprites are monochrome white, so everything is tinted warm at runtime — gold
# borders, dark-cream panels — to glam up the old flat-grey UI while staying in
# keeping with the colorful town-adventure tone (NOT sci-fi).
#
# Two consumers:
#  * Control-based UI (Buttons/Labels/Panels/ProgressBars): assign `UITheme.get_theme()`
#    to a root `theme` and everything restyles automatically.
#  * `_draw`-based overlays: call `panel_box().draw(...)` / `UITheme.draw_frame(...)` /
#    `UITheme.input_glyph(...)` directly.
class_name UITheme

# ── Warm palette ──────────────────────────────────────────────────────────────
const GOLD: Color = Color("e8c170")
const GOLD_DIM: Color = Color("b8924a")
const CREAM: Color = Color("f4ead2")
const TEXT: Color = Color("f4ead2")
const TEXT_DIM: Color = Color("bcab8c")
const ACCENT: Color = Color("f0a24e")
const PANEL_BG: Color = Color(0.13, 0.10, 0.08, 0.94)
const PANEL_BG_SOFT: Color = Color(0.18, 0.14, 0.11, 0.92)
const SHADOW: Color = Color(0.0, 0.0, 0.0, 0.6)
const SHADOW_OFFSET := Vector2i(1, 2)

const UI_DIR: String = "res://assets/art/ui/"
const FRAME_MARGIN: int = 46  # 9-slice inset for the 256² frame sprites

# Nunito SemiBold (static wght-600 cut) — bolder UI text than the regular weight.
const FONT_PATH: String = "res://assets/fonts/Nunito-SemiBold.ttf"

static var _theme: Theme = null
static var _font: Font = null
static var _tex_cache: Dictionary = {}
static var _glyph_cache: Dictionary = {}
static var _panel_box: StyleBoxFlat = null


# The project UI font (cozy Nunito). Use this anywhere `_draw` code needs a font
# instead of ThemeDB.fallback_font, so hand-drawn text matches the themed Controls.
static func font() -> Font:
	if _font == null:
		_font = load(FONT_PATH) if ResourceLoader.exists(FONT_PATH) else ThemeDB.fallback_font
	return _font


static func _tex(name: String) -> Texture2D:
	if not _tex_cache.has(name):
		var path: String = UI_DIR + name + ".png"
		_tex_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _tex_cache[name]


# Flat warm panel box (rounded, gold border) — the default Panel look and the box
# `_draw` overlays paint behind their content via `.draw(canvas_item, rect)`.
static func panel_box() -> StyleBoxFlat:
	if _panel_box == null:
		_panel_box = StyleBoxFlat.new()
		_panel_box.bg_color = PANEL_BG
		_panel_box.set_corner_radius_all(8)
		_panel_box.set_border_width_all(2)
		_panel_box.border_color = GOLD_DIM
		_panel_box.set_content_margin_all(10)
		_panel_box.shadow_color = Color(0, 0, 0, 0.35)
		_panel_box.shadow_size = 6
	return _panel_box


static func _button_box(bg: Color, border: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.set_corner_radius_all(6)
	b.set_border_width_all(2)
	b.border_color = border
	b.set_content_margin_all(8)
	return b


static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	var f: Font = font()
	t.default_font = f
	t.default_font_size = 16

	# Panels / popups
	t.set_stylebox("panel", "Panel", panel_box())
	t.set_stylebox("panel", "PanelContainer", panel_box())
	t.set_stylebox("panel", "PopupPanel", panel_box())

	# Labels — with a soft drop shadow so text pops against busy HUD/world backdrops.
	t.set_color("font_color", "Label", TEXT)
	t.set_font_size("font_size", "Label", 14)
	t.set_color("font_shadow_color", "Label", SHADOW)
	t.set_constant("shadow_offset_x", "Label", SHADOW_OFFSET.x)
	t.set_constant("shadow_offset_y", "Label", SHADOW_OFFSET.y)
	t.set_color("font_shadow_color", "Button", SHADOW)
	t.set_constant("shadow_offset_x", "Button", SHADOW_OFFSET.x)
	t.set_constant("shadow_offset_y", "Button", SHADOW_OFFSET.y)

	# Buttons
	t.set_stylebox("normal", "Button", _button_box(PANEL_BG_SOFT, GOLD_DIM))
	t.set_stylebox("hover", "Button", _button_box(Color(0.28, 0.22, 0.15, 0.96), GOLD))
	t.set_stylebox("pressed", "Button", _button_box(Color(0.34, 0.22, 0.12, 0.98), ACCENT))
	t.set_stylebox("focus", "Button", _button_box(Color(0, 0, 0, 0), GOLD))
	t.set_stylebox("disabled", "Button", _button_box(Color(0.16, 0.14, 0.12, 0.7), Color(0.4, 0.36, 0.3, 0.6)))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", GOLD)
	t.set_color("font_pressed_color", "Button", CREAM)
	t.set_color("font_disabled_color", "Button", TEXT_DIM)
	t.set_font_size("font_size", "Button", 15)

	# ProgressBar (health / generic) — textured bar bg + fill from the Synty bar sprite
	var bar: Texture2D = _tex("bar")
	if bar != null:
		var bg := StyleBoxTexture.new()
		bg.texture = bar
		bg.set_texture_margin_all(8)
		bg.modulate_color = Color(0.10, 0.08, 0.07, 0.95)
		var fill := StyleBoxTexture.new()
		fill.texture = bar
		fill.set_texture_margin_all(8)
		fill.modulate_color = ACCENT
		t.set_stylebox("background", "ProgressBar", bg)
		t.set_stylebox("fill", "ProgressBar", fill)
	t.set_color("font_color", "ProgressBar", TEXT)
	t.set_font_size("font_size", "ProgressBar", 10)

	_theme = t
	return _theme


# Per-use ProgressBar fill box tinted to a colour (e.g. a character's sprite_color
# for their health bar). Use via `bar.add_theme_stylebox_override("fill", ...)`.
static func bar_fill_box(color: Color) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	var bar: Texture2D = _tex("bar")
	if bar != null:
		box.texture = bar
		box.set_texture_margin_all(8)
	box.modulate_color = color
	return box


# Manual 9-slice blit of a frame sprite into `rect` on `ci` — for `_draw` overlays
# that want the decorative gold border (Control theme handles the rest).
static func draw_frame(ci: CanvasItem, rect: Rect2, tint: Color = GOLD, variant: String = "simple") -> void:
	var tex: Texture2D = _tex("frame_" + variant)
	if tex == null:
		return
	var ts: Vector2 = tex.get_size()
	var m: float = float(FRAME_MARGIN)
	# source columns/rows (left, center, right) x (top, mid, bottom)
	var sx: Array = [0.0, m, ts.x - m]
	var sw: Array = [m, ts.x - 2.0 * m, m]
	var sy: Array = [0.0, m, ts.y - m]
	var sh: Array = [m, ts.y - 2.0 * m, m]
	# dest columns/rows
	var dx: Array = [rect.position.x, rect.position.x + m, rect.end.x - m]
	var dw: Array = [m, rect.size.x - 2.0 * m, m]
	var dy: Array = [rect.position.y, rect.position.y + m, rect.end.y - m]
	var dh: Array = [m, rect.size.y - 2.0 * m, m]
	for c in 3:
		for r in 3:
			var src := Rect2(sx[c], sy[r], sw[c], sh[r])
			var dst := Rect2(dx[c], dy[r], dw[c], dh[r])
			ci.draw_texture_rect_region(tex, dst, src, tint)


# Input glyphs. Letter keys (F/G/V/B/WASD) use the blank-key sprite with the letter
# drawn on top in _draw; Tab/Enter/arrows use dedicated sprites. Font can't blit to an
# Image, so the letter is rendered live via draw_string rather than baked into a texture.
const _ACTION_KEY: Dictionary = {
	"attack": "F", "special": "G", "dash": "V", "bies_mode": "B",
	"move_up": "W", "move_left": "A", "move_down": "S", "move_right": "D",
}
const _ACTION_SPRITE: Dictionary = {
	"swap": "input/key_tab", "ui_accept": "input/key_enter",
	"jump": "input/key_space",
	"move_up_arrow": "input/arrow_up", "move_down_arrow": "input/arrow_down",
	"move_left_arrow": "input/arrow_left", "move_right_arrow": "input/arrow_right",
}

# Tinted key/sprite texture for an action (no letter baked in). Cached.
static func glyph_tex(action: String, tint: Color = CREAM) -> Texture2D:
	var ck: String = action + "|" + tint.to_html()
	if _glyph_cache.has(ck):
		return _glyph_cache[ck]
	var src: String = _ACTION_SPRITE.get(action, "input/key_blank")
	var result: Texture2D = _tinted(src, tint)
	_glyph_cache[ck] = result
	return result


# The letter to overlay on a letter-key glyph (empty for dedicated sprites).
static func glyph_letter(action: String) -> String:
	return _ACTION_KEY.get(action, "")


# Draw a complete input glyph (key + letter) into a square `rect` on `ci`. Works in
# any CanvasItem `_draw`. `fnt` defaults to the project UI font.
static func draw_glyph(ci: CanvasItem, rect: Rect2, action: String, tint: Color = CREAM, fnt: Font = null) -> void:
	var tex: Texture2D = glyph_tex(action, tint)
	if tex != null:
		ci.draw_texture_rect(tex, rect, false)
	var letter: String = glyph_letter(action)
	if letter != "":
		var glyph_font: Font = fnt if fnt != null else font()
		var fs: int = int(rect.size.y * 0.46)
		var dim: Vector2 = glyph_font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var p: Vector2 = rect.position + (rect.size - dim) * 0.5 + Vector2(0, dim.y * 0.78)
		ci.draw_string(glyph_font, p, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.16, 0.11, 0.07, 1.0))


# A self-contained glyph Control (key sprite + centered letter) for use in the
# Control tree (menus/overlays) where `_draw` isn't convenient.
static func make_glyph_control(action: String, px: float = 40.0, tint: Color = CREAM) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(px, px)
	root.size = Vector2(px, px)
	var tr := TextureRect.new()
	tr.texture = glyph_tex(action, tint)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # don't claim the 256² native size
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(tr)
	var letter: String = glyph_letter(action)
	if letter != "":
		var lbl := Label.new()
		lbl.text = letter
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", int(px * 0.46))
		lbl.add_theme_color_override("font_color", Color(0.16, 0.11, 0.07))
		root.add_child(lbl)
	return root


static func _tinted(name: String, tint: Color) -> Texture2D:
	var tex: Texture2D = _tex(name)
	if tex == null:
		return null
	var img: Image = tex.get_image().duplicate()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var px: Color = img.get_pixel(x, y)
			if px.a > 0.0:
				img.set_pixel(x, y, Color(tint.r, tint.g, tint.b, px.a))
	return ImageTexture.create_from_image(img)
