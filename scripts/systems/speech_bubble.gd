extends Node2D

# Reusable speech bubble for short NPC exclamations. Draws a filled rectangle
# with a downward-pointing tail above the node's local origin. Fades out over
# the last FADE_TIME seconds of its duration, then hides itself automatically.
#
# No class_name — use preload() + untyped var (see [[feedback-godot-technical]]):
#   const SpeechBubbleScript: Script = preload("res://scripts/systems/speech_bubble.gd")
#   var _bubble = SpeechBubbleScript.new()
#   _bubble.position = Vector2(0.0, -52.0)   # offset above NPC centre
#   npc_node.add_child(_bubble)
#   _bubble.show_text("Hands out of your pockets!", 3.0)

const PAD        := Vector2(10.0, 5.0)  # inner horizontal / vertical padding
const TAIL_H     : float = 8.0           # downward tail height
const TAIL_W     : float = 10.0          # tail base width
const FADE_TIME  : float = 0.4           # fade-out window before auto-hide
const FONT_SIZE  : int   = 13
const BG_COLOR    := Color(0.96, 0.94, 0.88, 0.95)
const BORDER_COLOR := Color(0.25, 0.20, 0.15, 1.0)
const TEXT_COLOR  := Color(0.08, 0.05, 0.05, 1.0)

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

func _draw() -> void:
	if _text == "":
		return
	var sz: Vector2 = _font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var bw: float = sz.x + PAD.x * 2.0
	var bh: float = sz.y + PAD.y * 2.0

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

	# Text: baseline positioned just above the bubble bottom edge with padding.
	draw_string(_font, Vector2(-bw * 0.5 + PAD.x, -TAIL_H - PAD.y),
		_text, HORIZONTAL_ALIGNMENT_LEFT, bw - PAD.x * 2.0, FONT_SIZE, text_c)
