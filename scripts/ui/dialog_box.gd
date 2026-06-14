extends Control

# Programmatic NPC dialog box -- a paged text panel drawn entirely via
# _draw()/queue_redraw(), the same convention as InventoryPanel/DuoPanel
# (see CLAUDE.md "Collectibles & Inventory"). Instantiated once per caller
# (overworld_map.gd, pipe_organ_works.gd, etc.) and reused for every
# conversation. No class_name -- preload()+untyped var, same as
# LootBox/Doorway/HidingSpot (see [[feedback-godot-technical]]).
#
# Walks a DialogTree (see scripts/systems/dialog_tree.gd): each node shows
# its "lines" as pages, then either auto-advances via "next", presents
# "choices" for the player to pick from, or ends the conversation. Choices
# may branch differently depending on `active_character` (DialogTree.
# resolve_choice). Any node/choice "effects" encountered along the way are
# collected and handed to the caller via closed(effects) once the
# conversation ends -- the caller applies them (set_level_flag, grant_item,
# etc.) via its own _apply_dialog_effects().
#
# Usage: open(npc_name, portrait_color, tree, start_node, active_character)
# starts a conversation. advance() pages through the current node's lines.
# When is_choice_mode() is true, move_choice_cursor()/select_choice() drive
# the choice list instead. closed(effects) fires once the conversation ends.

signal closed(effects: Array)

const DialogTreeScript: Script = preload("res://scripts/systems/dialog_tree.gd")

# Panel grown + fonts bumped for the proportional Nunito font (the old sizes were
# tuned for the wide PressStart2P pixel font and read small now). Widened to 1040
# so the larger body text still gets a generous line length before wrapping.
const PANEL_RECT := Rect2(120.0, 410.0, 1040.0, 210.0)
const PANEL_COLOR := Color(0.05, 0.05, 0.09, 0.92)
const BORDER_COLOR := Color(0.85, 0.78, 0.35, 1.0)
const NAME_COLOR := Color(1.0, 0.92, 0.4, 1.0)
const TEXT_COLOR := Color(0.92, 0.92, 0.95, 1.0)
const PROMPT_COLOR := Color(0.55, 0.55, 0.6, 1.0)
const PORTRAIT_RADIUS: float = 20.0
const LINE_HEIGHT: float = 26.0
const FONT_SIZE: int = 18
const NAME_FONT_SIZE: int = 22
const PROMPT_FONT_SIZE: int = 14
const TEXT_LEFT_INSET: float = 74.0
const TEXT_RIGHT_INSET: float = 24.0
const TEXT_TOP: float = 64.0
const PROMPT_BOTTOM_MARGIN: float = 18.0

# Max wrapped lines shown per "screen" before advance() moves on -- chosen so
# TEXT_TOP + (MAX_LINES_PER_SCREEN - 1) * LINE_HEIGHT plus a line of text
# still leaves room for the prompt above PANEL_RECT's bottom edge.
const MAX_LINES_PER_SCREEN: int = 5

var _font: Font
var _portrait_color: Color = Color.WHITE
var _npc_name: String = ""
var _tree: Dictionary = {}
var _node_id: String = ""
var _node: Dictionary = {}

# Each node's "lines" are word-wrapped and chunked into "screens" (at most
# MAX_LINES_PER_SCREEN wrapped lines each) by _build_screens() -- see
# _goto_node(). advance() steps through _screens one at a time so long pages
# can never overflow PANEL_RECT.
var _screens: Array[PackedStringArray] = []
var _screen_index: int = -1
var _active_character: String = ""
var _effects: Array = []
var _choice_mode: bool = false
var _choice_index: int = 0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = UITheme.font()
	visible = false

func is_open() -> bool:
	return visible

func is_choice_mode() -> bool:
	return _choice_mode

# Starts (or restarts) a conversation. `tree` is a DialogTree dict (see
# scripts/systems/dialog_tree.gd); `start_node` is the entry node id.
# `active_character` (e.g. "Quinn") is used to resolve any choices whose
# `best_with` doesn't match.
func open(npc_name: String, portrait_color: Color, tree: Dictionary, start_node: String = "start", active_character: String = "") -> void:
	_npc_name = npc_name
	_portrait_color = portrait_color
	_tree = tree
	_active_character = active_character
	_effects = []
	visible = true
	_goto_node(start_node)

# Jumps to `node_id`, collecting any "effects" it carries and resetting
# page/choice state.
func _goto_node(node_id: String) -> void:
	_node_id = node_id
	_node = _tree.get(node_id, {})
	if _node.has("effects"):
		_effects.append(_node["effects"])
	_screens = _build_screens(_node.get("lines", []))
	_screen_index = 0
	_choice_mode = false
	_choice_index = 0
	queue_redraw()

# Word-wraps `text` to fit within `max_width` px at `font_size`, preserving
# any author-supplied "\n" line breaks.
func _wrap_line(text: String, max_width: float, font_size: int) -> PackedStringArray:
	var out := PackedStringArray()
	for raw_line: String in text.split("\n"):
		var current: String = ""
		for word: String in raw_line.split(" "):
			var candidate: String = word if current == "" else current + " " + word
			if current != "" and _font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
				out.append(current)
				current = word
			else:
				current = candidate
		out.append(current)
	return out

# Wraps every page in `lines` to fit the panel, then chunks the wrapped lines
# into "screens" of at most MAX_LINES_PER_SCREEN -- advance() steps through
# these one at a time so a long page can never overflow PANEL_RECT.
func _build_screens(lines: Array) -> Array[PackedStringArray]:
	var max_width: float = PANEL_RECT.size.x - TEXT_LEFT_INSET - TEXT_RIGHT_INSET
	var screens: Array[PackedStringArray] = []
	for page: String in lines:
		var wrapped: PackedStringArray = _wrap_line(page, max_width, FONT_SIZE)
		var i: int = 0
		while i < wrapped.size():
			var screen := PackedStringArray()
			for j: int in MAX_LINES_PER_SCREEN:
				if i + j < wrapped.size():
					screen.append(wrapped[i + j])
			screens.append(screen)
			i += MAX_LINES_PER_SCREEN
	if screens.is_empty():
		screens.append(PackedStringArray())
	return screens

# Advances to the next screen of the current node, or -- once its screens are
# exhausted -- enters choice mode, jumps via "next", or closes the
# conversation (emitting `closed`) if neither is present.
func advance() -> void:
	if not visible or _choice_mode:
		return
	_screen_index += 1
	if _screen_index < _screens.size():
		queue_redraw()
		return
	if _node.has("choices"):
		_choice_mode = true
		_choice_index = 0
		queue_redraw()
		return
	if _node.has("next"):
		_goto_node(_node["next"])
		return
	visible = false
	var effects: Array = _effects
	_effects = []
	closed.emit(effects)

# Moves the choice cursor by `delta` (wrapping), while in choice mode.
func move_choice_cursor(delta: int) -> void:
	if not _choice_mode:
		return
	var choices: Array = _node.get("choices", [])
	if choices.is_empty():
		return
	_choice_index = wrapi(_choice_index + delta, 0, choices.size())
	Audio.play("ui_move")
	queue_redraw()

# Confirms the highlighted choice: collects its effects (if any) and jumps
# to the resolved next node.
func select_choice() -> void:
	if not _choice_mode:
		return
	var choices: Array = _node.get("choices", [])
	if choices.is_empty():
		return
	var choice: Dictionary = choices[_choice_index]
	if choice.has("effects"):
		_effects.append(choice["effects"])
	Audio.play("ui_select")
	_goto_node(DialogTreeScript.resolve_choice(choice, _active_character))

func _draw() -> void:
	if not visible:
		return
	# Cozy-warm Synty skin: filled panel box + decorative gold frame.
	UITheme.panel_box().draw(get_canvas_item(), PANEL_RECT)
	UITheme.draw_frame(self, PANEL_RECT, UITheme.GOLD, "simple")

	var portrait_center: Vector2 = PANEL_RECT.position + Vector2(36.0, 36.0)
	draw_circle(portrait_center, PORTRAIT_RADIUS, _portrait_color)
	draw_arc(portrait_center, PORTRAIT_RADIUS, 0.0, TAU, 24, BORDER_COLOR, 1.5, true)

	draw_string(_font, PANEL_RECT.position + Vector2(74.0, 32.0), _npc_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE, NAME_COLOR)

	if _choice_mode:
		_draw_choices()
		return

	var screen: PackedStringArray = _screens[_screen_index] if _screen_index < _screens.size() else PackedStringArray()
	for i: int in screen.size():
		draw_string(_font, PANEL_RECT.position + Vector2(TEXT_LEFT_INSET, TEXT_TOP + i * LINE_HEIGHT),
				screen[i], HORIZONTAL_ALIGNMENT_LEFT, PANEL_RECT.size.x - TEXT_LEFT_INSET - TEXT_RIGHT_INSET, FONT_SIZE, TEXT_COLOR)

	var has_more: bool = _screen_index < _screens.size() - 1 or _node.has("choices") or _node.has("next")
	var prompt: String = "Press ENTER to continue" if has_more else "Press ENTER to close"
	_draw_prompt(prompt)

# Draws `text` right-aligned within PANEL_RECT, TEXT_RIGHT_INSET from its
# right edge -- guarantees the prompt never paints outside the panel
# regardless of string length (unlike a fixed left offset).
func _draw_prompt(text: String) -> void:
	var pos: Vector2 = PANEL_RECT.position + Vector2(TEXT_LEFT_INSET, PANEL_RECT.size.y - PROMPT_BOTTOM_MARGIN)
	var width: float = PANEL_RECT.size.x - TEXT_LEFT_INSET - TEXT_RIGHT_INSET
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_RIGHT, width, PROMPT_FONT_SIZE, PROMPT_COLOR)

func _draw_choices() -> void:
	var choices: Array = _node.get("choices", [])
	var total_width: float = PANEL_RECT.size.x - TEXT_LEFT_INSET - TEXT_RIGHT_INSET
	var prefix_w: float = _font.get_string_size("> ", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var text_width: float = total_width - prefix_w

	var y_offset: float = TEXT_TOP
	for i: int in choices.size():
		var color: Color = NAME_COLOR if i == _choice_index else TEXT_COLOR
		var prefix: String = "> " if i == _choice_index else "  "
		var wrapped: PackedStringArray = _wrap_line(String(choices[i].get("text", "")), text_width, FONT_SIZE)
		draw_string(_font, PANEL_RECT.position + Vector2(TEXT_LEFT_INSET, y_offset),
				prefix + wrapped[0], HORIZONTAL_ALIGNMENT_LEFT, total_width, FONT_SIZE, color)
		y_offset += LINE_HEIGHT
		for j: int in range(1, wrapped.size()):
			draw_string(_font, PANEL_RECT.position + Vector2(TEXT_LEFT_INSET + prefix_w, y_offset),
					wrapped[j], HORIZONTAL_ALIGNMENT_LEFT, text_width, FONT_SIZE, color)
			y_offset += LINE_HEIGHT

	_draw_prompt("↑/↓ choose · ENTER select")
