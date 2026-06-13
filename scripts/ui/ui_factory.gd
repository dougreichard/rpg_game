# Shared Label factory for all programmatic UI.
# Godot's Label defaults to no word-wrap and no overflow trimming, so text
# silently overflows its rect. Centralising creation here means the right
# defaults are set in one place rather than re-derived per screen.
#
# Rule of thumb:
#   wrap=true  — any text whose length you don't fully control (descriptions,
#                quest text, dialog, HTP content, hint lines).
#   wrap=false — fixed single-line labels (titles, menu items, key names)
#                where you own the string and know it fits.
class_name UIFactory

static func make_label(
		text: String,
		pos: Vector2,
		size: Vector2,
		font_size: int,
		color: Color,
		halign: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		wrap: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.size = size
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = halign
	if wrap:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	return lbl
