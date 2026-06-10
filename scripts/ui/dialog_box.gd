extends Control

# Programmatic NPC dialog box -- a paged text panel drawn entirely via
# _draw()/queue_redraw(), the same convention as InventoryPanel/DuoPanel
# (see CLAUDE.md "Collectibles & Inventory"). Instantiated once by
# overworld_map.gd and reused for every conversation. No class_name --
# preload()+untyped var, same as LootBox/Doorway/HidingSpot (see
# [[feedback-godot-technical]]).
#
# Usage: open(npc_name, portrait_color, lines) starts a conversation; each
# entry in `lines` is one "page" (use "\n" for a second line within a page).
# advance() shows the next page, or closes (emitting `closed`) after the last.

signal closed

const PANEL_RECT := Rect2(160.0, 460.0, 960.0, 140.0)
const PANEL_COLOR := Color(0.05, 0.05, 0.09, 0.92)
const BORDER_COLOR := Color(0.85, 0.78, 0.35, 1.0)
const NAME_COLOR := Color(1.0, 0.92, 0.4, 1.0)
const TEXT_COLOR := Color(0.92, 0.92, 0.95, 1.0)
const PROMPT_COLOR := Color(0.55, 0.55, 0.6, 1.0)
const PORTRAIT_RADIUS: float = 18.0
const LINE_HEIGHT: float = 20.0

var _font: Font
var _portrait_color: Color = Color.WHITE
var _npc_name: String = ""
var _lines: Array = []
var _line_index: int = -1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	visible = false

func is_open() -> bool:
	return visible

# Starts (or restarts) a conversation. `lines` is the full set of pages for
# the current quest state -- the caller (overworld_map.gd) decides which
# intro/reminder/turn-in/after lines apply based on quest progress.
func open(npc_name: String, portrait_color: Color, lines: Array) -> void:
	_npc_name = npc_name
	_portrait_color = portrait_color
	_lines = lines
	_line_index = 0
	visible = true
	queue_redraw()

# Advances to the next page, or closes (emitting `closed`) after the last one.
func advance() -> void:
	if not visible:
		return
	_line_index += 1
	if _line_index >= _lines.size():
		visible = false
		closed.emit()
		return
	queue_redraw()

func _draw() -> void:
	if not visible or _line_index < 0 or _line_index >= _lines.size():
		return
	draw_rect(PANEL_RECT, PANEL_COLOR)
	draw_rect(PANEL_RECT, BORDER_COLOR, false, 2.0)

	var portrait_center: Vector2 = PANEL_RECT.position + Vector2(36.0, 36.0)
	draw_circle(portrait_center, PORTRAIT_RADIUS, _portrait_color)
	draw_arc(portrait_center, PORTRAIT_RADIUS, 0.0, TAU, 24, BORDER_COLOR, 1.5, true)

	draw_string(_font, PANEL_RECT.position + Vector2(70.0, 28.0), _npc_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, NAME_COLOR)

	var text_lines: PackedStringArray = _lines[_line_index].split("\n")
	for i: int in text_lines.size():
		draw_string(_font, PANEL_RECT.position + Vector2(70.0, 56.0 + i * LINE_HEIGHT),
				text_lines[i], HORIZONTAL_ALIGNMENT_LEFT, PANEL_RECT.size.x - 90.0, 14, TEXT_COLOR)

	var prompt: String = "Press ENTER to continue" if _line_index < _lines.size() - 1 else "Press ENTER to close"
	draw_string(_font, PANEL_RECT.position + Vector2(PANEL_RECT.size.x - 230.0, PANEL_RECT.size.y - 14.0),
			prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, PROMPT_COLOR)
