extends Node2D

# Pre-level character select — shown between OverworldMap and the level scene.
# The duo is fixed per location (puzzle gates are hardcoded); this screen's only
# choice is which member LEADS (active) vs. follows (standby).
# Reads GameManager.pending_level_duo; on confirm sets GameManager.preferred_active
# and loads GameManager.pending_level.

const FONT: Font = preload("res://assets/fonts/PressStart2P-Regular.ttf")

const CHAR_COLORS: Dictionary = {
	"Quinn": Color(0.3,  0.45, 0.85),
	"Erin":  Color(0.9,  0.35, 0.10),
	"Evan":  Color(0.55, 0.42, 0.18),
	"Ben":   Color(0.75, 0.25, 0.55),
	"Ethan": Color(0.2,  0.65, 0.60),
}

const CHAR_SPECIALS: Dictionary = {
	"Quinn": "HA — stuns nearby enemies",
	"Erin":  "Fast Talk — calm guards",
	"Evan":  "Animal Call — summon companions",
	"Ben":   "Perfect Pitch — rhythm & tones",
	"Ethan": "Hack — crack panels & doors",
}

# HP / Speed / Damage  from  data/characters/*.tres
const CHAR_STATS: Dictionary = {
	"Quinn": [120, 140, 20],
	"Erin":  [ 90, 180, 15],
	"Evan":  [150, 120, 28],
	"Ben":   [100, 155, 17],
	"Ethan": [ 85, 165, 16],
}

const MOTE_COUNT: int = 30
const CARD_W: float  = 340.0
const CARD_H: float  = 400.0
const CARD_Y: float  = 130.0
const GAP: float     = 90.0
const PORTRAIT_H: float = 128.0
const BG_COLOR := Color(0.04, 0.04, 0.10)
const PANEL_DARK := Color(0.08, 0.08, 0.18, 0.97)

var _duo: Array = []
var _selected: int = 0
var _press_label: Label = null
var _blink_timer: float = 0.0
var _blink_visible: bool = true
var _time: float = 0.0
var _motes: Array = []

func _ready() -> void:
	_duo = GameManager.pending_level_duo
	if _duo.is_empty():
		_duo = ["Quinn", "Erin"]
	_selected = 0
	GameManager.preferred_active = _duo[0]
	_build_motes()
	_build_ui()

func _build_motes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 88142
	for i in MOTE_COUNT:
		_motes.append({
			"pos":   Vector2(rng.randf() * 1280.0, rng.randf() * 720.0),
			"speed": rng.randf_range(7.0, 22.0),
			"size":  rng.randf_range(1.2, 3.8),
			"drift": rng.randf_range(-9.0, 9.0),
			"cidx":  rng.randi() % 2,
		})

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 1
	add_child(canvas)

	var location_lbl := Label.new()
	location_lbl.text = GameManager.pending_level_name
	location_lbl.position = Vector2(0.0, 30.0)
	location_lbl.size = Vector2(1280.0, 28.0)
	location_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location_lbl.add_theme_font_size_override("font_size", 12)
	location_lbl.add_theme_color_override("font_color", Color(0.48, 0.48, 0.60))
	canvas.add_child(location_lbl)

	var title := Label.new()
	title.text = "CHOOSE YOUR LEAD"
	title.position = Vector2(0.0, 68.0)
	title.size = Vector2(1280.0, 44.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
	canvas.add_child(title)

	var sub := Label.new()
	sub.text = "The active lead fights first  —  swap with  Tab  at any time"
	sub.position = Vector2(0.0, 116.0)
	sub.size = Vector2(1280.0, 20.0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 8)
	sub.add_theme_color_override("font_color", Color(0.40, 0.40, 0.52))
	canvas.add_child(sub)

	_press_label = Label.new()
	_press_label.text = "ENTER  to  confirm"
	_press_label.position = Vector2(0.0, 586.0)
	_press_label.size = Vector2(1280.0, 36.0)
	_press_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press_label.add_theme_font_size_override("font_size", 20)
	_press_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.55))
	canvas.add_child(_press_label)

	var hint := Label.new()
	hint.text = "< >  Switch lead          Enter  Confirm          Esc  Back to Map"
	hint.position = Vector2(0.0, 672.0)
	hint.size = Vector2(1280.0, 26.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(0.34, 0.34, 0.42))
	canvas.add_child(hint)

func _card_x(i: int) -> float:
	var total_w: float = float(_duo.size()) * CARD_W + float(_duo.size() - 1) * GAP
	return (1280.0 - total_w) * 0.5 + float(i) * (CARD_W + GAP)

func _process(delta: float) -> void:
	_time += delta

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

	for mote in _motes:
		_tick_mote(mote, delta)
	queue_redraw()

func _tick_mote(mote: Dictionary, delta: float) -> void:
	var pos: Vector2 = mote["pos"]
	pos.y -= mote["speed"] * delta
	pos.x += mote["drift"] * delta
	if pos.y < -4.0:
		pos.y = 724.0
		pos.x = randf() * 1280.0
	elif pos.x < -4.0 or pos.x > 1284.0:
		pos.x = randf() * 1280.0
	mote["pos"] = pos

func _confirm() -> void:
	GameManager.preferred_active = _duo[_selected]
	Audio.play("ui_select")
	TransitionManager.change_scene(GameManager.pending_level)

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), BG_COLOR)

	# Drifting motes colored with each character's palette
	for mote in _motes:
		var cidx: int = mote["cidx"]
		var base: Color = CHAR_COLORS.get(_duo[mini(cidx, _duo.size() - 1)], Color(0.5, 0.5, 0.7))
		draw_circle(mote["pos"], mote["size"], Color(base.r, base.g, base.b, 0.30))

	for i in _duo.size():
		_draw_card(i)

	# Arrow hint in the gap between cards
	var gap_cx: float = _card_x(0) + CARD_W + GAP * 0.5
	var arrow_y: float = CARD_Y + CARD_H * 0.5 + 8.0
	draw_string(FONT, Vector2(gap_cx - 20.0, arrow_y),
			"<   >", HORIZONTAL_ALIGNMENT_CENTER, 40.0, 14, Color(0.55, 0.55, 0.65))

func _draw_card(i: int) -> void:
	var char_name: String = _duo[i]
	var cx: float = _card_x(i)
	var is_active: bool = (i == _selected)
	var base: Color = CHAR_COLORS.get(char_name, Color(0.5, 0.5, 0.5))
	var t: float = _time

	# Cards slide down into place on entry (staggered by index)
	var slide_t: float = clampf(t * 2.8 - float(i) * 0.25, 0.0, 1.0)
	var ease_t: float = 1.0 - (1.0 - slide_t) * (1.0 - slide_t)  # ease-out quad
	var card_y: float = CARD_Y + (1.0 - ease_t) * 80.0

	# Soft glow behind the active card
	if is_active:
		var glow_t: float = 0.55 + 0.45 * sin(t * 3.8)
		var gs: float = 10.0 + glow_t * 5.0
		var gc: Color = base
		gc.a = 0.14 + glow_t * 0.08
		draw_rect(Rect2(cx - gs, card_y - gs, CARD_W + gs * 2.0, CARD_H + gs * 2.0), gc)

	# Card background
	draw_rect(Rect2(cx, card_y, CARD_W, CARD_H), PANEL_DARK)

	# Portrait header
	var portrait_bg: Color = base.darkened(0.48 if is_active else 0.66)
	draw_rect(Rect2(cx, card_y, CARD_W, PORTRAIT_H), portrait_bg)

	# Character silhouette
	var center := Vector2(cx + CARD_W * 0.5, card_y + PORTRAIT_H * 0.5)
	_draw_silhouette(center, base if is_active else base.darkened(0.30), is_active)

	# Border — pulsing for active, dim for standby
	var border_col: Color
	if is_active:
		var bp: float = 0.7 + 0.3 * sin(t * 4.5)
		border_col = Color(base.r * bp, base.g * bp, base.b * bp, 1.0)
		draw_rect(Rect2(cx, card_y, CARD_W, CARD_H), border_col, false, 3.0)
	else:
		border_col = base.darkened(0.60)
		draw_rect(Rect2(cx, card_y, CARD_W, CARD_H), border_col, false, 1.5)

	var by: float = card_y + PORTRAIT_H + 10.0

	# Active / standby badge
	var badge_text: String = ">> LEADS <<" if is_active else "   follows   "
	var badge_col: Color = Color(0.95, 0.85, 0.2) if is_active else Color(0.40, 0.40, 0.52)
	draw_string(FONT, Vector2(cx, by + 4.0),
			badge_text, HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 8, badge_col)

	# Character name
	var name_col: Color = Color(0.95, 0.95, 0.95) if is_active else Color(0.50, 0.50, 0.60)
	draw_string(FONT, Vector2(cx, by + 26.0),
			char_name, HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 18, name_col)

	# Special description
	var spec: String = CHAR_SPECIALS.get(char_name, "")
	var spec_col: Color = base.lightened(0.05) if is_active else Color(0.35, 0.35, 0.43)
	draw_string(FONT, Vector2(cx, by + 56.0),
			spec, HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 7, spec_col)

	# Stats row  (HP / Speed / Damage)
	var stats: Array = CHAR_STATS.get(char_name, [0, 0, 0])
	var stats_str: String = "HP %3d    SPD %3d    ATK %2d" % [stats[0], stats[1], stats[2]]
	var stats_col: Color = Color(0.60, 0.60, 0.72) if is_active else Color(0.32, 0.32, 0.40)
	draw_string(FONT, Vector2(cx, by + 80.0),
			stats_str, HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 7, stats_col)

	# Divider line
	var line_col: Color = base.darkened(0.35)
	line_col.a = 0.35 if is_active else 0.18
	draw_line(Vector2(cx + 20.0, by + 100.0), Vector2(cx + CARD_W - 20.0, by + 100.0),
			line_col, 1.0)

	# Held items
	var items: Array = GameManager.inventories.get(char_name.to_lower(), []) as Array
	if items.is_empty():
		draw_string(FONT, Vector2(cx, by + 112.0),
				"no items yet", HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 7,
				Color(0.30, 0.30, 0.38, 0.6))
	else:
		var item_text: String = str(items.size()) + " item" + ("s" if items.size() > 1 else "") + " in pack"
		draw_string(FONT, Vector2(cx, by + 112.0),
				item_text, HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 7,
				Color(0.80, 0.68, 0.25) if is_active else Color(0.48, 0.40, 0.15))
		# Small color pips — one per item, cycling through the character's color
		var pip_r: float = 4.0
		var pip_spacing: float = 12.0
		var pip_count: int = mini(items.size(), 12)
		var total_pip_w: float = float(pip_count) * pip_spacing - pip_spacing + pip_r * 2.0
		var pip_start_x: float = cx + (CARD_W - total_pip_w) * 0.5 + pip_r
		for pi in pip_count:
			var pip_x: float = pip_start_x + float(pi) * pip_spacing
			var pip_y: float = by + 130.0
			var pip_col: Color = base if is_active else base.darkened(0.45)
			pip_col.a = 0.9
			draw_circle(Vector2(pip_x, pip_y), pip_r, pip_col)
			draw_arc(Vector2(pip_x, pip_y), pip_r, 0.0, TAU, 10,
					Color(0.1, 0.1, 0.12, 0.5), 1.0)

func _draw_silhouette(center: Vector2, color: Color, is_active: bool) -> void:
	# Slight breath-bob on active character
	var bob: float = sin(_time * 2.5) * (2.0 if is_active else 0.0)
	var c := Vector2(center.x, center.y + bob)

	var head_r: float   = 15.0
	var body_w: float   = 24.0
	var body_h: float   = 30.0
	var head_y: float   = c.y - body_h * 0.5 - head_r - 2.0

	# Drop shadow
	var sh := Color(0.0, 0.0, 0.0, 0.35)
	draw_circle(Vector2(c.x + 3.0, head_y + 3.0), head_r, sh)
	draw_rect(Rect2(c.x - body_w * 0.5 + 3.0, c.y - body_h * 0.5 + 3.0, body_w, body_h), sh)

	# Body
	draw_rect(Rect2(c.x - body_w * 0.5, c.y - body_h * 0.5, body_w, body_h), color.darkened(0.15))

	# Head
	draw_circle(Vector2(c.x, head_y), head_r, color)

	# Eyes
	var eye_col := Color(0.06, 0.04, 0.10, 0.85)
	draw_circle(Vector2(c.x - 5.0, head_y - 2.0), 2.5, eye_col)
	draw_circle(Vector2(c.x + 5.0, head_y - 2.0), 2.5, eye_col)
