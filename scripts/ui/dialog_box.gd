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
var _tree: Dictionary = {}
var _node_id: String = ""
var _node: Dictionary = {}
var _line_index: int = -1
var _active_character: String = ""
var _effects: Array = []
var _choice_mode: bool = false
var _choice_index: int = 0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
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

# Jumps to `node_id`, collecting any "effects" it carries and resetting page/
# choice state.
func _goto_node(node_id: String) -> void:
	_node_id = node_id
	_node = _tree.get(node_id, {})
	if _node.has("effects"):
		_effects.append(_node["effects"])
	_line_index = 0
	_choice_mode = false
	_choice_index = 0
	queue_redraw()

# Advances to the next page of the current node, or -- once its lines are
# exhausted -- enters choice mode, jumps via "next", or closes the
# conversation (emitting `closed`) if neither is present.
func advance() -> void:
	if not visible or _choice_mode:
		return
	var lines: Array = _node.get("lines", [])
	_line_index += 1
	if _line_index < lines.size():
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
	draw_rect(PANEL_RECT, PANEL_COLOR)
	draw_rect(PANEL_RECT, BORDER_COLOR, false, 2.0)

	var portrait_center: Vector2 = PANEL_RECT.position + Vector2(36.0, 36.0)
	draw_circle(portrait_center, PORTRAIT_RADIUS, _portrait_color)
	draw_arc(portrait_center, PORTRAIT_RADIUS, 0.0, TAU, 24, BORDER_COLOR, 1.5, true)

	draw_string(_font, PANEL_RECT.position + Vector2(70.0, 28.0), _npc_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, NAME_COLOR)

	if _choice_mode:
		_draw_choices()
		return

	var lines: Array = _node.get("lines", [])
	if _line_index < 0 or _line_index >= lines.size():
		return
	var text_lines: PackedStringArray = String(lines[_line_index]).split("\n")
	for i: int in text_lines.size():
		draw_string(_font, PANEL_RECT.position + Vector2(70.0, 56.0 + i * LINE_HEIGHT),
				text_lines[i], HORIZONTAL_ALIGNMENT_LEFT, PANEL_RECT.size.x - 90.0, 14, TEXT_COLOR)

	var has_more: bool = _line_index < lines.size() - 1 or _node.has("choices") or _node.has("next")
	var prompt: String = "Press ENTER to continue" if has_more else "Press ENTER to close"
	draw_string(_font, PANEL_RECT.position + Vector2(PANEL_RECT.size.x - 230.0, PANEL_RECT.size.y - 14.0),
			prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, PROMPT_COLOR)

func _draw_choices() -> void:
	var choices: Array = _node.get("choices", [])
	for i: int in choices.size():
		var color: Color = NAME_COLOR if i == _choice_index else TEXT_COLOR
		var prefix: String = "> " if i == _choice_index else "   "
		draw_string(_font, PANEL_RECT.position + Vector2(70.0, 56.0 + i * LINE_HEIGHT),
				prefix + String(choices[i].get("text", "")), HORIZONTAL_ALIGNMENT_LEFT,
				PANEL_RECT.size.x - 90.0, 14, color)

	draw_string(_font, PANEL_RECT.position + Vector2(PANEL_RECT.size.x - 230.0, PANEL_RECT.size.y - 14.0),
			"↑/↓ choose · ENTER select", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, PROMPT_COLOR)
