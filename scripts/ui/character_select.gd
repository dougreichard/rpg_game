extends Node2D

# Pre-level character select — shown between OverworldMap and the level scene.
# The duo is fixed per location (each level has hardcoded puzzle gates), so this
# screen's purpose is choosing which member leads (active) vs. follows (standby).
# Reads GameManager.pending_level_duo; on confirm sets GameManager.preferred_active
# and loads GameManager.pending_level.

const FONT: Font = preload("res://assets/fonts/PressStart2P-Regular.ttf")

const CHAR_COLORS: Dictionary = {
	"Quinn": Color(0.3, 0.45, 0.85),
	"Erin":  Color(0.9, 0.35, 0.1),
	"Evan":  Color(0.55, 0.42, 0.18),
	"Ben":   Color(0.75, 0.25, 0.55),
	"Ethan": Color(0.2, 0.65, 0.6),
}

const CHAR_ROLES: Dictionary = {
	"Quinn": "Mechanic & Translator\nHA laugh stuns nearby enemies",
	"Erin":  "Infiltrator\nTalks past guards, stays hidden",
	"Evan":  "Strongman\nCommands animal companions",
	"Ben":   "Bard\nRhythm attacks and perfect pitch",
	"Ethan": "Hacker\nCracks panels, doors, electronics",
}

const CHAR_SPECIALS: Dictionary = {
	"Quinn": "Special: HA",
	"Erin":  "Special: Fast Talk",
	"Evan":  "Special: Animal Call",
	"Ben":   "Special: Perfect Pitch",
	"Ethan": "Special: Hack",
}

const CARD_W: float = 320.0
const CARD_H: float = 300.0
const CARD_Y: float = 200.0
const CHIP_H: float = 80.0
const GAP: float = 80.0
const BG_COLOR: Color = Color(0.06, 0.05, 0.12)
const PANEL_DARK: Color = Color(0.1, 0.09, 0.18, 0.97)
const ACTIVE_LABEL: String = ">> LEADS <<"
const STANDBY_LABEL: String = "   follows   "

var _duo: Array = []
var _selected: int = 0   # 0 = duo[0] is active, 1 = duo[1] is active
var _press_label: Label
var _blink_timer: float = 0.0
var _blink_visible: bool = true

func _ready() -> void:
	_duo = GameManager.pending_level_duo
	if _duo.is_empty():
		_duo = ["Quinn", "Erin"]
	_selected = 0
	_build_ui()

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 1
	add_child(canvas)

	var location_lbl := Label.new()
	location_lbl.text = GameManager.pending_level_name
	location_lbl.position = Vector2(0.0, 52.0)
	location_lbl.size = Vector2(1280.0, 32.0)
	location_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location_lbl.add_theme_font_size_override("font_size", 16)
	location_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	canvas.add_child(location_lbl)

	var title := Label.new()
	title.text = "CHOOSE YOUR LEAD"
	title.position = Vector2(0.0, 96.0)
	title.size = Vector2(1280.0, 44.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
	canvas.add_child(title)

	var sub := Label.new()
	sub.text = "Active lead fights first  --  swap with Tab at any time"
	sub.position = Vector2(0.0, 158.0)
	sub.size = Vector2(1280.0, 24.0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 8)
	sub.add_theme_color_override("font_color", Color(0.48, 0.48, 0.58))
	canvas.add_child(sub)

	var hint_nav := Label.new()
	hint_nav.text = "< >  Switch lead          Enter / F  Confirm          Esc  Back to Map"
	hint_nav.position = Vector2(0.0, 668.0)
	hint_nav.size = Vector2(1280.0, 28.0)
	hint_nav.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_nav.add_theme_font_size_override("font_size", 8)
	hint_nav.add_theme_color_override("font_color", Color(0.38, 0.38, 0.46))
	canvas.add_child(hint_nav)

	_press_label = Label.new()
	_press_label.text = "ENTER / F  to  confirm"
	_press_label.position = Vector2(0.0, 572.0)
	_press_label.size = Vector2(1280.0, 38.0)
	_press_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press_label.add_theme_font_size_override("font_size", 24)
	_press_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.55))
	canvas.add_child(_press_label)

func _total_row_w() -> float:
	return 2.0 * CARD_W + GAP

func _card_x(i: int) -> float:
	return (1280.0 - _total_row_w()) * 0.5 + float(i) * (CARD_W + GAP)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
		_selected = (_selected - 1 + _duo.size()) % _duo.size()
		GameManager.preferred_active = _duo[_selected]
		Audio.play("ui_move")
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
		_selected = (_selected + 1) % _duo.size()
		GameManager.preferred_active = _duo[_selected]
		Audio.play("ui_move")
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
		_confirm()
	elif Input.is_action_just_pressed("ui_cancel"):
		Audio.play("ui_move")
		TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")
		return

	_blink_timer += delta
	if _blink_timer >= 0.5:
		_blink_timer = 0.0
		_blink_visible = not _blink_visible
		_press_label.visible = _blink_visible

	queue_redraw()

func _confirm() -> void:
	GameManager.preferred_active = _duo[_selected]
	Audio.play("ui_select")
	TransitionManager.change_scene(GameManager.pending_level)

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), BG_COLOR)

	for i in _duo.size():
		var char_name: String = _duo[i]
		var cx: float = _card_x(i)
		var is_active: bool = (i == _selected)
		var base_color: Color = CHAR_COLORS.get(char_name, Color(0.5, 0.5, 0.5))

		# Card background
		draw_rect(Rect2(cx, CARD_Y, CARD_W, CARD_H), PANEL_DARK)

		# Border — brighter and thicker for the active card
		var border_col: Color = base_color if is_active else base_color.darkened(0.55)
		var border_w: float = 3.0 if is_active else 1.5
		draw_rect(Rect2(cx, CARD_Y, CARD_W, CARD_H), border_col, false, border_w)

		# Color chip at top of card
		var chip_rect := Rect2(cx, CARD_Y, CARD_W, CHIP_H)
		draw_rect(chip_rect, base_color.darkened(0.45 if is_active else 0.65))
		var sq := 24.0
		draw_rect(
			Rect2(cx + (CARD_W - sq) * 0.5, CARD_Y + (CHIP_H - sq) * 0.5, sq, sq),
			base_color
		)

		# Text rows — baseline Y coords relative to bottom of chip
		var badge_y: float = CARD_Y + CHIP_H + 8.0

		# Active/standby badge
		var badge_text: String = ACTIVE_LABEL if is_active else STANDBY_LABEL
		var badge_col: Color = Color(0.95, 0.85, 0.2) if is_active else Color(0.45, 0.45, 0.55)
		draw_string(FONT, Vector2(cx,badge_y + 8.0),
				badge_text, HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 8, badge_col)

		# Character name
		draw_string(FONT, Vector2(cx,badge_y + 32.0),
				char_name, HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 16,
				Color(0.92, 0.92, 0.92) if is_active else Color(0.55, 0.55, 0.62))

		# Special label
		var special_text: String = CHAR_SPECIALS.get(char_name, "")
		draw_string(FONT, Vector2(cx,badge_y + 56.0),
				special_text, HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 8,
				base_color.lightened(0.1) if is_active else Color(0.38, 0.38, 0.44))

		# Role description — two lines
		var role_text: String = CHAR_ROLES.get(char_name, "")
		var lines: PackedStringArray = role_text.split("\n")
		for li in lines.size():
			var role_col: Color = Color(0.72, 0.72, 0.82) if is_active else Color(0.38, 0.38, 0.44)
			draw_string(FONT,
					Vector2(cx,badge_y + 76.0 + float(li) * 16.0),
					lines[li], HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 8, role_col)

	# Arrow hint centred in the gap between cards
	var gap_x: float = _card_x(0) + CARD_W
	var arrow_y: float = CARD_Y + CARD_H * 0.5
	draw_string(FONT, Vector2(gap_x, arrow_y + 8.0),
			"<  >", HORIZONTAL_ALIGNMENT_CENTER, GAP, 16, Color(0.6, 0.6, 0.7))
