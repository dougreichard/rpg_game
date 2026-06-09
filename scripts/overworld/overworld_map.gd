extends Node2D

const LOCS: Array = [
	{
		"id": "pipe_organ_works", "name": "Bellows & Sons Pipe Organ Works",
		"short": "Organ\nWorks", "scene": "res://scenes/levels/PipeOrganWorks.tscn",
		"pos": Vector2(165, 450), "requires": "", "icon": "gear",
		"duo": ["Quinn", "Erin"],
	},
	{
		"id": "old_parish_church", "name": "The Old Parish Church",
		"short": "Parish\nChurch", "scene": "res://scenes/levels/OldParishChurch.tscn",
		"pos": Vector2(325, 375), "requires": "pipe_organ_works", "icon": "arch",
		"duo": ["Quinn", "Erin"],
	},
	{
		"id": "iron_strings_gym", "name": "Iron & Strings Gym",
		"short": "Gym", "scene": "res://scenes/levels/IronStringsGym.tscn",
		"pos": Vector2(490, 340), "requires": "old_parish_church", "icon": "dumbbell",
		"duo": ["Quinn", "Evan"],
	},
	{
		"id": "recording_studio", "name": "The Recording Studio",
		"short": "Studio", "scene": "res://scenes/levels/RecordingStudio.tscn",
		"pos": Vector2(665, 375), "requires": "iron_strings_gym", "icon": "note",
		"duo": ["Quinn", "Ben"],
	},
	{
		"id": "clocktower", "name": "The Clocktower",
		"short": "Clock-\ntower", "scene": "res://scenes/levels/Clocktower.tscn",
		"pos": Vector2(595, 205), "requires": "recording_studio", "icon": "clock",
		"duo": ["Quinn", "Ben"],
	},
	{
		"id": "harbor_docks", "name": "The Harbor & Docks",
		"short": "Harbor\n& Docks", "scene": "res://scenes/levels/HarborDocks.tscn",
		"pos": Vector2(900, 470), "requires": "recording_studio", "icon": "anchor",
		"duo": ["Quinn", "Evan"],
	},
	{
		"id": "library", "name": "The Public Library & Archive",
		"short": "Library", "scene": "res://scenes/levels/LibraryArchive.tscn",
		"pos": Vector2(455, 200), "requires": "recording_studio", "icon": "book",
		"duo": ["Erin", "Ethan"],
	},
	{
		"id": "carnival", "name": "The Carnival & Fairground",
		"short": "Carnival", "scene": "res://scenes/levels/Carnival.tscn",
		"pos": Vector2(840, 225), "requires": "recording_studio", "icon": "star",
		"duo": ["Quinn", "Erin"],
	},
	{
		"id": "underground", "name": "The Underground Tunnels",
		"short": "Tunnels", "scene": "res://scenes/levels/UndergroundTunnels.tscn",
		"pos": Vector2(630, 490), "requires": "recording_studio", "icon": "tunnel",
		"duo": ["Evan", "Ethan"],
	},
	{
		"id": "zip_line", "name": "Zip Line Park",
		"short": "Zip Line\nPark", "scene": "res://scenes/levels/ZipLinePark.tscn",
		"pos": Vector2(975, 330), "requires": "recording_studio", "icon": "zipline",
		"duo": ["Ethan", "Ben"],
	},
	{
		"id": "vr_room", "name": "VR Escape Room",
		"short": "VR Room", "scene": "res://scenes/levels/VrEscapeRoom.tscn",
		"pos": Vector2(795, 155), "requires": "recording_studio", "icon": "hex",
		"duo": ["Quinn", "Ethan"],
	},
	{
		"id": "the_drop", "name": "The Drop",
		"short": "The\nDrop", "scene": "res://scenes/levels/TheDrop.tscn",
		"pos": Vector2(385, 155), "requires": "vr_room", "icon": "chevron",
		"duo": ["Evan", "Ethan"],
	},
	{
		"id": "grand_marquee", "name": "The Grand Marquee Cinema",
		"short": "Grand\nMarquee", "scene": "res://scenes/levels/GrandMarqueeCinema.tscn",
		"pos": Vector2(595, 100), "requires": "the_drop", "icon": "film",
		"duo": ["Quinn", "Ben"],
	},
]

const CONNECTIONS: Array = [
	["pipe_organ_works", "old_parish_church"],
	["old_parish_church", "iron_strings_gym"],
	["iron_strings_gym", "recording_studio"],
	["recording_studio", "clocktower"],
	["recording_studio", "harbor_docks"],
	["clocktower", "library"],
	["clocktower", "carnival"],
	["clocktower", "vr_room"],
	["library", "underground"],
	["harbor_docks", "zip_line"],
	["carnival", "zip_line"],
	["vr_room", "the_drop"],
	["the_drop", "grand_marquee"],
	["vr_room", "grand_marquee"],
]

var _id_to_idx: Dictionary = {}
var _cursor_idx: int = 0
var _pulse_time: float = 0.0
var _font: Font
var _name_label: Label
var _status_label: Label

func _ready() -> void:
	Audio.play_music("overworld")
	_font = ThemeDB.fallback_font
	for i in LOCS.size():
		_id_to_idx[LOCS[i]["id"]] = i
	_build_ui()
	_update_info()

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)

	var title := Label.new()
	title.text = "HUNKLE BUNKLE"
	title.position = Vector2(0.0, 8.0)
	title.size = Vector2(1280.0, 44.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
	canvas.add_child(title)

	var map_sub := Label.new()
	map_sub.text = "WORLD MAP"
	map_sub.position = Vector2(0.0, 50.0)
	map_sub.size = Vector2(1280.0, 26.0)
	map_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_sub.add_theme_font_size_override("font_size", 16)
	map_sub.add_theme_color_override("font_color", Color(0.55, 0.5, 0.75))
	canvas.add_child(map_sub)

	var panel := ColorRect.new()
	panel.color = Color(0.0, 0.0, 0.0, 0.75)
	panel.position = Vector2(0.0, 608.0)
	panel.size = Vector2(1280.0, 112.0)
	canvas.add_child(panel)

	_name_label = Label.new()
	_name_label.position = Vector2(0.0, 614.0)
	_name_label.size = Vector2(1280.0, 46.0)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 24)
	_name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	canvas.add_child(_name_label)

	_status_label = Label.new()
	_status_label.position = Vector2(0.0, 658.0)
	_status_label.size = Vector2(1280.0, 28.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", Color(0.68, 0.68, 0.7))
	canvas.add_child(_status_label)

	var hint := Label.new()
	hint.text = "Navigate: A / D  |  Arrow Keys  |  D-Pad / Left Stick          Play: Enter / F  |  A Button"
	hint.position = Vector2(0.0, 690.0)
	hint.size = Vector2(1280.0, 24.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.38, 0.38, 0.42))
	canvas.add_child(hint)

func _update_info() -> void:
	var loc: Dictionary = LOCS[_cursor_idx]
	_name_label.text = loc["name"]
	if _is_completed(_cursor_idx):
		_status_label.text = "Completed"
		_name_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.45))
	elif _is_unlocked(_cursor_idx):
		if loc["scene"] == "":
			_status_label.text = "Unlocked   --   Coming soon"
		else:
			_status_label.text = "Unlocked   --   Press Enter to play"
		_name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		var req: String = loc["requires"]
		var req_idx: int = _id_to_idx.get(req, -1)
		var req_name: String = LOCS[req_idx]["name"] if req_idx >= 0 else req
		_status_label.text = "Locked   --   Complete \"" + req_name + "\" first"
		_name_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))

func _is_unlocked(idx: int) -> bool:
	var req: String = LOCS[idx]["requires"]
	return req == "" or req in GameManager.completed_locations

func _is_completed(idx: int) -> bool:
	return LOCS[idx]["id"] in GameManager.completed_locations

func _process(delta: float) -> void:
	_pulse_time += delta
	var moved: bool = false
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("move_left"):
		_cursor_idx = (_cursor_idx - 1 + LOCS.size()) % LOCS.size()
		moved = true
	elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("move_right"):
		_cursor_idx = (_cursor_idx + 1) % LOCS.size()
		moved = true
	if moved:
		Audio.play("ui_move")
		_update_info()
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
		_launch()
	queue_redraw()

func _launch() -> void:
	var loc: Dictionary = LOCS[_cursor_idx]
	if not _is_unlocked(_cursor_idx):
		_status_label.text = "Locked   --   Complete the previous location first"
		return
	if loc["scene"] == "":
		_status_label.text = "Coming soon!"
		return
	Audio.play("ui_select")
	GameManager.pending_level = loc["scene"]
	GameManager.pending_level_name = loc["name"]
	GameManager.pending_level_duo = loc.get("duo", [])
	GameManager.preferred_active = loc.get("duo", [""])[0]
	TransitionManager.change_scene("res://scenes/ui/CharacterSelect.tscn")

const ROAD_SIDE: float = 26.0
const ROAD_MAIN: float = 18.0

func _building_half(icon: String) -> Vector2:
	match icon:
		"film":     return Vector2(50, 36)
		"clock":    return Vector2(20, 36)
		"anchor":   return Vector2(44, 26)
		"star":     return Vector2(44, 30)
		"arch":     return Vector2(34, 28)
		"gear":     return Vector2(38, 24)
		"book":     return Vector2(38, 26)
		"chevron":  return Vector2(38, 24)
		"zipline":  return Vector2(40, 26)
		_:          return Vector2(32, 22)

func _building_color(icon: String, unlocked: bool, completed: bool) -> Color:
	if not unlocked:
		return Color(0.20, 0.19, 0.22)
	var c: Color
	match icon:
		"gear":     c = Color(0.54, 0.36, 0.24)
		"arch":     c = Color(0.86, 0.84, 0.74)
		"dumbbell": c = Color(0.40, 0.46, 0.54)
		"note":     c = Color(0.22, 0.19, 0.28)
		"clock":    c = Color(0.72, 0.62, 0.42)
		"anchor":   c = Color(0.30, 0.35, 0.42)
		"book":     c = Color(0.72, 0.64, 0.50)
		"star":     c = Color(0.70, 0.22, 0.40)
		"tunnel":   c = Color(0.20, 0.20, 0.22)
		"zipline":  c = Color(0.24, 0.52, 0.22)
		"hex":      c = Color(0.18, 0.34, 0.62)
		"chevron":  c = Color(0.55, 0.50, 0.36)
		"film":     c = Color(0.58, 0.16, 0.20)
		_:          c = Color(0.45, 0.45, 0.50)
	return c.lightened(0.12) if completed else c

func _draw() -> void:
	# Grass base with mow stripes
	draw_rect(Rect2(0.0, 0.0, 1280.0, 608.0), Color(0.30, 0.48, 0.20))
	for row: int in range(0, 608, 64):
		draw_rect(Rect2(0.0, float(row), 1280.0, 32.0), Color(0.27, 0.44, 0.18))

	# Park zones
	draw_rect(Rect2(770.0, 155.0, 140.0, 115.0), Color(0.25, 0.50, 0.18))  # Carnival
	draw_rect(Rect2(932.0, 272.0, 125.0, 110.0), Color(0.25, 0.50, 0.18))  # Zip Line
	draw_rect(Rect2(90.0,  390.0, 105.0, 100.0), Color(0.25, 0.50, 0.18))  # Organ Works

	# Harbor water
	draw_rect(Rect2(958.0, 426.0, 290.0, 155.0), Color(0.13, 0.28, 0.55))
	for wi: int in 5:
		draw_line(Vector2(968.0, 444.0 + wi * 24.0),
				  Vector2(1220.0, 452.0 + wi * 24.0),
				  Color(0.22, 0.44, 0.72), 2.0, true)

	# Road network — sidewalk then surface then centerline
	for conn: Array in CONNECTIONS:
		var ai: int = _id_to_idx.get(conn[0], -1)
		var bi: int = _id_to_idx.get(conn[1], -1)
		if ai < 0 or bi < 0:
			continue
		var a: Vector2 = LOCS[ai]["pos"]
		var b: Vector2 = LOCS[bi]["pos"]
		draw_line(a, b, Color(0.56, 0.53, 0.48), ROAD_SIDE, false)
		draw_line(a, b, Color(0.27, 0.26, 0.25), ROAD_MAIN, false)
		_draw_dashed_line(a, b, Color(0.88, 0.80, 0.10), 2.0, 8.0, 8.0)
	# Intersection fill at each location to clean up road-end seams
	for loc: Dictionary in LOCS:
		draw_circle(loc["pos"], ROAD_MAIN * 0.5 + 1.0, Color(0.27, 0.26, 0.25))

	_draw_trees()

	for i: int in LOCS.size():
		_draw_building(i)

	_draw_cursor_ring()

func _draw_building(idx: int) -> void:
	var loc: Dictionary = LOCS[idx]
	var p: Vector2 = loc["pos"]
	var icon: String = loc.get("icon", "")
	var h: Vector2 = _building_half(icon)
	var unlocked: bool = _is_unlocked(idx)
	var completed: bool = _is_completed(idx)
	var wall: Color = _building_color(icon, unlocked, completed)
	var roof: Color = wall.darkened(0.30)
	var rect := Rect2(p.x - h.x, p.y - h.y, h.x * 2.0, h.y * 2.0)

	# Drop shadow
	draw_rect(Rect2(rect.position + Vector2(3.0, 3.0), rect.size), Color(0.0, 0.0, 0.0, 0.35))
	# Wall fill
	draw_rect(rect, wall)
	# Roof strip
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 7.0)), roof)
	# Outline
	draw_rect(rect, roof, false, 1.5)

	# Windows (skip for locked / very dark buildings)
	if unlocked:
		var win: Color = Color(0.85, 0.90, 1.0, 0.70)
		if icon == "note":   win = Color(0.65, 0.40, 0.90, 0.70)
		if icon == "tunnel": win = Color(0.80, 0.55, 0.20, 0.60)
		var wy: float = rect.position.y + 10.0
		var wh: float = rect.size.y - 14.0
		if wh > 5.0:
			for wi: int in 2:
				var wx: float = rect.position.x + 6.0 + wi * (h.x - 3.0)
				draw_rect(Rect2(wx, wy, h.x - 8.0, wh), win)

	# Icon
	var icon_col: Color = Color(1.0, 1.0, 1.0, 0.85) if unlocked else Color(0.38, 0.36, 0.40)
	_draw_icon(icon, p, icon_col)

	# Label below building
	var label_col: Color
	if idx == _cursor_idx:     label_col = Color(1.0, 1.0, 1.0)
	elif completed:            label_col = Color(0.40, 1.0, 0.50)
	elif unlocked:             label_col = Color(0.90, 0.88, 0.82)
	else:                      label_col = Color(0.38, 0.38, 0.42)
	var lines: PackedStringArray = loc["short"].split("\n")
	for li: int in lines.size():
		draw_string(_font, Vector2(p.x - 48.0, p.y + h.y + 8.0 + li * 12.0),
				lines[li], HORIZONTAL_ALIGNMENT_CENTER, 96.0, 9, label_col)

func _draw_cursor_ring() -> void:
	var p: Vector2 = LOCS[_cursor_idx]["pos"]
	var h: Vector2 = _building_half(LOCS[_cursor_idx].get("icon", ""))
	var pulse: float = sin(_pulse_time * 5.0) * 1.5
	var rx: float = p.x - h.x - 5.0 - pulse
	var ry: float = p.y - h.y - 5.0 - pulse
	var rw: float = h.x * 2.0 + 10.0 + pulse * 2.0
	var rh: float = h.y * 2.0 + 10.0 + pulse * 2.0
	var ring := Rect2(rx, ry, rw, rh)
	draw_rect(ring, Color(1.0, 0.92, 0.30), false, 2.0)
	# Corner bracket ticks
	var tick: float = 7.0
	var corners: Array = [ring.position,
		ring.position + Vector2(ring.size.x, 0.0),
		ring.position + Vector2(0.0, ring.size.y),
		ring.end]
	for j: int in corners.size():
		var cx: float = corners[j].x
		var cy: float = corners[j].y
		var dx: float = 1.0 if j in [0, 2] else -1.0
		var dy: float = 1.0 if j in [0, 1] else -1.0
		draw_line(corners[j], Vector2(cx + dx * tick, cy), Color(1.0, 0.92, 0.30), 2.0)
		draw_line(corners[j], Vector2(cx, cy + dy * tick), Color(1.0, 0.92, 0.30), 2.0)

func _draw_dashed_line(a: Vector2, b: Vector2, color: Color, width: float, dash: float, gap: float) -> void:
	var dir: Vector2 = (b - a).normalized()
	var dist: float = a.distance_to(b)
	var pos: float = 0.0
	while pos < dist:
		var end: float = minf(pos + dash, dist)
		draw_line(a + dir * pos, a + dir * end, color, width, true)
		pos += dash + gap

func _draw_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 54321
	var zones: Array[Rect2] = [
		Rect2(780.0, 162.0, 120.0, 100.0),  # Carnival park
		Rect2(942.0, 280.0, 108.0, 96.0),   # Zip Line Park
		Rect2(96.0,  396.0,  90.0, 90.0),   # Organ Works area
		Rect2(220.0,  60.0,  90.0, 70.0),   # Upper left scatter
		Rect2(1060.0, 90.0, 110.0, 90.0),   # Upper right scatter
		Rect2(1080.0,210.0,  80.0, 80.0),   # Right mid scatter
		Rect2(80.0,  530.0, 160.0, 60.0),   # Bottom fringe
	]
	for zone: Rect2 in zones:
		var count: int = int(zone.get_area() / 380.0)
		for _t: int in count:
			var tx: float = zone.position.x + rng.randf_range(0.0, zone.size.x)
			var ty: float = zone.position.y + rng.randf_range(0.0, zone.size.y)
			_draw_tree(Vector2(tx, ty))

func _draw_tree(p: Vector2) -> void:
	draw_circle(p, 8.0, Color(0.10, 0.26, 0.10))
	draw_circle(p + Vector2(-1.0, -2.0), 7.0, Color(0.18, 0.48, 0.14))
	draw_circle(p + Vector2(2.0, -3.0), 5.0, Color(0.26, 0.58, 0.20))

func _draw_icon(kind: String, p: Vector2, color: Color) -> void:
	match kind:
		"gear":
			draw_arc(p, 5.5, 0.0, TAU, 14, color, 2.0, true)
			for i: int in 6:
				var a: float = TAU * float(i) / 6.0
				var dir := Vector2(cos(a), sin(a))
				draw_line(p + dir * 5.5, p + dir * 8.5, color, 2.0, true)
		"arch":
			draw_arc(p + Vector2(0.0, -1.0), 5.5, PI, TAU, 12, color, 2.0, true)
			draw_line(p + Vector2(-5.5, -1.0), p + Vector2(-5.5, 6.0), color, 2.0)
			draw_line(p + Vector2(5.5, -1.0), p + Vector2(5.5, 6.0), color, 2.0)
			draw_line(p + Vector2(-5.5, 6.0), p + Vector2(5.5, 6.0), color, 2.0)
		"dumbbell":
			draw_circle(p + Vector2(-6.0, 0.0), 3.5, color)
			draw_circle(p + Vector2(6.0, 0.0), 3.5, color)
			draw_line(p + Vector2(-3.5, 0.0), p + Vector2(3.5, 0.0), color, 3.0)
		"note":
			draw_circle(p + Vector2(-3.0, 4.0), 3.0, color)
			draw_line(p + Vector2(0.0, 4.0), p + Vector2(0.0, -6.0), color, 2.0)
			draw_line(p + Vector2(0.0, -6.0), p + Vector2(5.0, -4.0), color, 2.0)
		"clock":
			draw_arc(p, 6.0, 0.0, TAU, 16, color, 2.0, true)
			draw_line(p, p + Vector2(0.0, -3.5), color, 1.5, true)
			draw_line(p, p + Vector2(2.5, 1.5), color, 1.5, true)
		"anchor":
			draw_arc(p + Vector2(0.0, 2.5), 3.5, 0.0, PI, 10, color, 2.0, true)
			draw_line(p + Vector2(0.0, -5.0), p + Vector2(0.0, 2.5), color, 2.0)
			draw_line(p + Vector2(-3.5, -3.0), p + Vector2(3.5, -3.0), color, 2.0)
		"book":
			draw_rect(Rect2(p.x - 5.5, p.y - 4.5, 11.0, 9.0), color, false, 2.0)
			draw_line(p + Vector2(0.0, -4.5), p + Vector2(0.0, 4.5), color, 1.5)
		"star":
			var pts := PackedVector2Array()
			for i: int in 5:
				var a: float = -PI / 2.0 + TAU * float(i) / 5.0
				pts.append(p + Vector2(cos(a), sin(a)) * 6.5)
			for i: int in 5:
				draw_line(pts[i], pts[(i + 2) % 5], color, 2.0, true)
		"tunnel":
			draw_arc(p + Vector2(0.0, 2.5), 5.5, PI, TAU, 12, color, 2.0, true)
			draw_line(p + Vector2(-5.5, 2.5), p + Vector2(-5.5, 6.0), color, 2.0)
			draw_line(p + Vector2(5.5, 2.5), p + Vector2(5.5, 6.0), color, 2.0)
		"zipline":
			draw_line(p + Vector2(-6.0, -4.5), p + Vector2(6.0, 4.5), color, 2.0, true)
			draw_circle(p + Vector2(3.5, 2.5), 2.2, color)
		"hex":
			var hpts := PackedVector2Array()
			for i: int in 6:
				var a2: float = TAU * float(i) / 6.0
				hpts.append(p + Vector2(cos(a2), sin(a2)) * 6.0)
			hpts.append(hpts[0])
			draw_polyline(hpts, color, 2.0, true)
		"chevron":
			draw_line(p + Vector2(-5.5, -2.5), p + Vector2(0.0, 4.5), color, 2.5, true)
			draw_line(p + Vector2(0.0, 4.5), p + Vector2(5.5, -2.5), color, 2.5, true)
		"film":
			draw_rect(Rect2(p.x - 6.0, p.y - 4.5, 12.0, 9.0), color, false, 2.0)
			draw_circle(p + Vector2(-3.5, 0.0), 1.4, color)
			draw_circle(p + Vector2(3.5, 0.0), 1.4, color)
		_:
			pass
