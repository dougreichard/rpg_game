extends CanvasLayer

# Three-page "How to Play" overlay. Opened by the title screen and pause menu.
# Handles all its own input so the caller only needs to connect `closed`.
# No class_name — preload() + untyped var (see CLAUDE.md conventions).

signal closed

const HELP_RECT    := Rect2(40.0, 30.0, 1200.0, 660.0)
const BORDER_COLOR  : Color = UITheme.GOLD_DIM
const TITLE_COLOR   : Color = UITheme.GOLD
const KEY_COLOR     : Color = UITheme.GOLD
const NORMAL_COLOR  : Color = UITheme.TEXT
const HINT_COLOR    : Color = UITheme.TEXT_DIM
const PAGE_COUNT    : int   = 3
const ROW_H         : float = 56.0
const CONTENT_START_Y: float = 130.0
const SECTION_Y     : float = 72.0

var _page: int = 0
var _page_nodes: Array = [[], [], []]   # Array[Array[Node]], one per page
var _page_label: Label = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()

func open() -> void:
	_page = 0
	_show_page()
	visible = true

func close() -> void:
	visible = false
	closed.emit()

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.65)
	bg.size = Vector2(1280.0, 720.0)
	add_child(bg)

	var panel := ColorRect.new()
	panel.color = UITheme.PANEL_BG
	panel.position = HELP_RECT.position
	panel.size = HELP_RECT.size
	add_child(panel)

	var bw: float = 2.0
	for r: Rect2 in [
		Rect2(HELP_RECT.position, Vector2(HELP_RECT.size.x, bw)),
		Rect2(HELP_RECT.position + Vector2(0.0, HELP_RECT.size.y - bw), Vector2(HELP_RECT.size.x, bw)),
		Rect2(HELP_RECT.position, Vector2(bw, HELP_RECT.size.y)),
		Rect2(HELP_RECT.position + Vector2(HELP_RECT.size.x - bw, 0.0), Vector2(bw, HELP_RECT.size.y)),
	]:
		var b := ColorRect.new()
		b.color = BORDER_COLOR
		b.position = r.position
		b.size = r.size
		add_child(b)

	var title_lbl := Label.new()
	title_lbl.text = "HOW TO PLAY"
	title_lbl.position = HELP_RECT.position + Vector2(0.0, 18.0)
	title_lbl.size = Vector2(HELP_RECT.size.x, 44.0)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", TITLE_COLOR)
	add_child(title_lbl)

	_page_label = Label.new()
	_page_label.position = HELP_RECT.position + Vector2(HELP_RECT.size.x - 90.0, 22.0)
	_page_label.size = Vector2(80.0, 28.0)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_page_label.add_theme_font_size_override("font_size", 15)
	_page_label.add_theme_color_override("font_color", HINT_COLOR)
	add_child(_page_label)

	var nav_hint := Label.new()
	nav_hint.text = "←  →  flip pages          ESC  close"
	nav_hint.position = HELP_RECT.position + Vector2(0.0, HELP_RECT.size.y - 32.0)
	nav_hint.size = Vector2(HELP_RECT.size.x, 26.0)
	nav_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav_hint.add_theme_font_size_override("font_size", 13)
	nav_hint.add_theme_color_override("font_color", HINT_COLOR)
	add_child(nav_hint)

	_build_page_controls()
	_build_page_characters()
	_build_page_tips()

func _content_y(row: int) -> float:
	return HELP_RECT.position.y + CONTENT_START_Y + float(row) * ROW_H

func _add_label(page: int, text: String, x: float, y: float, w: float,
		font_size: int, color: Color,
		halign: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl: Label = UIFactory.make_label(
		text, Vector2(x, y), Vector2(w, ROW_H), font_size, color, halign, true)
	lbl.visible = false
	add_child(lbl)
	_page_nodes[page].append(lbl)
	return lbl

func _add_glyph(action: String, x: float, y: float, px: float) -> void:
	var g: Control = UITheme.make_glyph_control(action, px)
	g.position = Vector2(x, y)
	g.visible = false
	add_child(g)
	_page_nodes[0].append(g)

func _build_page_controls() -> void:
	var lx: float = HELP_RECT.position.x + 44.0
	var cw: float = HELP_RECT.size.x - 88.0
	var sy: float = HELP_RECT.position.y + SECTION_Y
	var px: float = 38.0
	# Right-align the key column so every description starts at the same x, snug
	# against its glyph(s) — no wide pixel-font-era gap.
	var key_right: float = lx + 200.0
	var desc_x: float = key_right + 26.0
	var desc_w: float = (lx + cw) - desc_x

	_add_label(0, "CONTROLS", lx, sy, cw, 18, TITLE_COLOR)

	# Movement row: a WASD glyph cluster, right-aligned to key_right.
	var move_y: float = _content_y(0) + (ROW_H - px) * 0.5
	var ka: Array = ["move_up", "move_left", "move_down", "move_right"]
	var cluster_w: float = ka.size() * px + (ka.size() - 1) * 6.0
	var cluster_x: float = key_right - cluster_w
	for j in ka.size():
		_add_glyph(ka[j], cluster_x + float(j) * (px + 6.0), move_y, px)
	_add_label(0, "Move", desc_x, _content_y(0), desc_w, 18, NORMAL_COLOR)

	# Single-key actions: glyph (right-aligned) + description.
	var rows: Array = [
		["attack", "Attack"],
		["dash", "Dash  —  brief invincibility frames"],
		["special", "Special ability  (character-specific)"],
		["swap", "Swap the active character"],
		["bies_mode", "Bies Mode  —  bullet-time slowdown"],
	]
	for i in rows.size():
		var row: int = i + 1
		var y: float = _content_y(row)
		_add_glyph(rows[i][0], key_right - px, y + (ROW_H - px) * 0.5, px)
		_add_label(0, rows[i][1], desc_x, y, desc_w, 18, NORMAL_COLOR)

	_add_label(0, "Stand near a downed teammate to revive them",
		lx, _content_y(rows.size() + 1), cw, 18, NORMAL_COLOR)

func _build_page_characters() -> void:
	var lx:     float = HELP_RECT.position.x + 44.0
	var cw:     float = HELP_RECT.size.x - 88.0
	var name_w: float = 96.0
	var gap:    float = 22.0
	var desc_x: float = lx + name_w + gap
	var desc_w: float = cw - name_w - gap

	_add_label(1, "YOUR TEAM", lx, HELP_RECT.position.y + SECTION_Y, cw, 18, TITLE_COLOR)

	var rows: Array = [
		["Quinn", "Wrench — repairs machinery. HA laugh stuns nearby enemies."],
		["Erin",  "Fire — stealth and fast-talk. Calms and distracts guards."],
		["Evan",  "Fists — super strength. Commands animal companions."],
		["Ben",   "Keytar — rhythm attacks. Perfect pitch for sound puzzles."],
		["Ethan", "Tech — hacks panels, doors, and electronic enemies."],
	]
	for i in rows.size():
		var y: float = _content_y(i)
		_add_label(1, rows[i][0], lx,     y, name_w, 18, KEY_COLOR)
		_add_label(1, rows[i][1], desc_x, y, desc_w, 18, NORMAL_COLOR)

func _build_page_tips() -> void:
	var lx: float = HELP_RECT.position.x + 44.0
	var cw: float = HELP_RECT.size.x - 88.0
	var sy: float = HELP_RECT.position.y + SECTION_Y

	_add_label(2, "TIPS", lx, sy, cw, 18, TITLE_COLOR)

	var tips: Array[String] = [
		"·  Each location is built for both duo members — swap to match the puzzle in front of you.",
		"·  Guards have vision cones. Duck into hiding spots to let patrols pass.",
		"·  Loot boxes hold items that can skip puzzle steps or open shortcuts.",
		"·  Every character's Special (G) is a key — use it near objects and NPCs.",
		"·  You need all five movie tickets to enter the Grand Marquee Cinema.",
	]
	for i in tips.size():
		_add_label(2, tips[i], lx, _content_y(i), cw, 18, NORMAL_COLOR)

# ---------------------------------------------------------------------------
# Page navigation
# ---------------------------------------------------------------------------

func _show_page() -> void:
	for p in range(PAGE_COUNT):
		var vis: bool = p == _page
		for n: Node in _page_nodes[p]:
			n.visible = vis
	_page_label.text = "%d / %d" % [_page + 1, PAGE_COUNT]

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left") \
			or event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_page = (_page - 1 + PAGE_COUNT) % PAGE_COUNT
		_show_page()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right") \
			or event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_page = (_page + 1) % PAGE_COUNT
		_show_page()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
		if _page < PAGE_COUNT - 1:
			_page += 1
			_show_page()
			Audio.play("ui_move")
		else:
			Audio.play("ui_select")
			close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		Audio.play("ui_select")
		close()
		get_viewport().set_input_as_handled()
