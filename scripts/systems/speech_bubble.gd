extends Node2D

# Reusable speech bubble for short NPC exclamations. Draws a filled rectangle
# with a downward-pointing tail above the node's local origin. Text is
# word-wrapped at MAX_TEXT_WIDTH so the bubble never becomes a wide strip.
# Fades out over the last FADE_TIME seconds, then hides itself automatically.
#
# No class_name — use preload() + untyped var (see [[feedback-godot-technical]]):
#   const SpeechBubbleScript: Script = preload("res://scripts/systems/speech_bubble.gd")
#   var _bubble = SpeechBubbleScript.new()
#   _bubble.position = Vector2(0.0, -52.0)   # offset above NPC centre
#   npc_node.add_child(_bubble)
#   _bubble.show_text("Hands out of your pockets!", 3.0)

const PAD           := Vector2(10.0, 5.0)  # inner horizontal / vertical padding
const TAIL_H        : float = 8.0           # downward tail height
const TAIL_W        : float = 10.0          # tail base width
const FADE_TIME     : float = 0.4           # fade-out window before auto-hide
const FONT_SIZE     : int   = 13
const LINE_HEIGHT   : float = 18.0          # px between line baselines
const MAX_TEXT_WIDTH: float = 160.0         # caps the inner text area width
const BG_COLOR     := Color(0.96, 0.94, 0.88, 0.95)
const BORDER_COLOR := Color(0.25, 0.20, 0.15, 1.0)
const TEXT_COLOR   := Color(0.08, 0.05, 0.05, 1.0)

var _font    : Font   = null
var _text    : String = ""
var _duration: float  = 0.0
var _elapsed : float  = 0.0

func _ready() -> void:
	_font   = ThemeDB.fallback_font
	z_index = 5
	visible = false

func show_text(text: String, duration: float = 3.0) -> void:
	_text     = text
	_duration = duration
	_elapsed  = 0.0
	visible   = true
	queue_redraw()

func _process(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	if _elapsed >= _duration:
		visible = false
	queue_redraw()

# Word-wraps `text` to fit within `max_width` px. Honours embedded "\n".
func _wrap_text(text: String, max_width: float) -> PackedStringArray:
	var out := PackedStringArray()
	for raw_line: String in text.split("\n"):
		var current: String = ""
		for word: String in raw_line.split(" "):
			var candidate: String = word if current == "" else current + " " + word
			if current != "" and _font.get_string_size(
					candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x > max_width:
				out.append(current)
				current = word
			else:
				current = candidate
		out.append(current)
	if out.is_empty():
		out.append("")
	return out

func _draw() -> void:
	if _text == "":
		return

	var lines: PackedStringArray = _wrap_text(_text, MAX_TEXT_WIDTH)

	# Bubble width = widest line (capped by MAX_TEXT_WIDTH) + horizontal padding.
	var max_line_w: float = 0.0
	for line: String in lines:
		max_line_w = maxf(max_line_w,
			_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x)
	var bw: float = maxf(max_line_w + PAD.x * 2.0, TAIL_W + PAD.x * 2.0)
	var bh: float = lines.size() * LINE_HEIGHT + PAD.y * 2.0

	# Fade alpha ramps down over FADE_TIME before the bubble hides.
	var alpha: float = clampf((_duration - _elapsed) / FADE_TIME, 0.0, 1.0) if _duration > 0.0 else 1.0

	var bg     := Color(BG_COLOR.r,     BG_COLOR.g,     BG_COLOR.b,     BG_COLOR.a     * alpha)
	var border := Color(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b, BORDER_COLOR.a * alpha)
	var text_c := Color(TEXT_COLOR.r,   TEXT_COLOR.g,   TEXT_COLOR.b,   TEXT_COLOR.a   * alpha)

	# Fill: body rect + tail triangle — same colour so the seam is invisible.
	draw_rect(Rect2(-bw * 0.5, -bh - TAIL_H, bw, bh), bg)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-TAIL_W * 0.5, -TAIL_H),
		Vector2( TAIL_W * 0.5, -TAIL_H),
		Vector2(0.0,            0.0),
	]), bg)

	# Outline: continuous path that skips the bubble-bottom/tail seam.
	draw_polyline(PackedVector2Array([
		Vector2(-bw    * 0.5, -bh - TAIL_H),
		Vector2( bw    * 0.5, -bh - TAIL_H),
		Vector2( bw    * 0.5, -TAIL_H),
		Vector2( TAIL_W * 0.5, -TAIL_H),
		Vector2(0.0,           0.0),
		Vector2(-TAIL_W * 0.5, -TAIL_H),
		Vector2(-bw    * 0.5, -TAIL_H),
		Vector2(-bw    * 0.5, -bh - TAIL_H),
	]), border, 1.5, false)

	# Lines: baseline_y for line i = -bh - TAIL_H + PAD.y + (i+1)*LINE_HEIGHT.
	# Algebraically, the last line always lands at -PAD.y - TAIL_H regardless
	# of line count, keeping the text a consistent distance from the bubble bottom.
	for i: int in lines.size():
		var baseline_y: float = -bh - TAIL_H + PAD.y + (i + 1) * LINE_HEIGHT
		draw_string(_font, Vector2(-bw * 0.5 + PAD.x, baseline_y),
			lines[i], HORIZONTAL_ALIGNMENT_LEFT, bw - PAD.x * 2.0, FONT_SIZE, text_c)
