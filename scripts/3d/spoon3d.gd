extends Node3D
## Gimme Dat Spoon — 3D set-piece (interactive + broadcast presentation).
## Six leads seated round a table running the REAL SpoonGame. The camera JUMP-CUTS
## across the table to whoever's turn it is, then slowly DOLLIES in (poker-broadcast
## feel). The player controls ONE seat — their active lead — and on that turn the
## camera holds while they pick a spoon from a scrollable list (mouse OR WASD/arrows/
## gamepad). A poker lower-third shows the active player + spoon count, a PiP
## "announcer" gives run-aware commentary, and spoons sent "to the middle" pile up
## physically on the table. Esc (or game over) opens Resume / Play Again / Leave.

const SpoonGameScript: Script = preload("res://scripts/systems/spoon_game.gd")
const SEAT_KEYS: Array = ["quinn", "erin", "evan", "ben", "ethan", "uncle_doug"]
const SEAT_NAMES: Array = ["Quinn", "Erin", "Evan", "Ben", "Ethan", "Uncle Doug"]
const SEAT_COL: Array = [Color(0.55,0.6,0.95), Color(0.95,0.5,0.5), Color(0.55,0.85,0.55),
	Color(0.95,0.8,0.4), Color(0.6,0.85,0.95), Color(0.85,0.7,0.5)]
const RING_R: float = 1.75
const SEAT_Y: float = -0.35
const TABLE_TOP: float = 0.86
const TABLE_GLB := "res://assets/models/props/table.glb"
const CHAIR_GLB := "res://assets/models/props/chair.glb"
const SPOON_GLB := "res://assets/models/props/spoon.glb"
const ROOFTOP_SCENE := "res://scenes/3d/AlsRooftopGarden3D.tscn"
const DOLLY_TIME: float = 0.8
const AI_BEAT: float = 1.4
const SPOON_LABEL := {"standard": "Standard Spoon", "anchor": "Anchor Spoon",
	"magnet": "Magnet Spoon", "spinner": "Spinner Spoon", "switch": "Switch Spoon",
	"reverse": "Reverse Spoon", "anchorless": "Anchorless Spoon"}

enum St { CUT, HUMAN, OVER }

var _game = null
var _cam: Camera3D = null
var _seat_pos: Array = []
var _seat_char: Array = []
var _alive: Array = []
var _human_seat: int = 0
var _state: int = St.CUT
var _timer: float = 0.0
var _pending: Dictionary = {}
var _shot_frames: int = -1
var _pile_count: int = 0

# nav: the currently-navigable button list (selection OR menu) + focus index
var _btns: Array = []
var _focus_i: int = 0
var _menu_open: bool = false
var _nav_cd: float = 0.0

# HUD
var _root: Control = null
var _lt_name: Label = null
var _lt_count: Label = null
var _ann_text: Label = null
var _pot: Label = null
var _sel_panel: Panel = null
var _sel_list: VBoxContainer = null
var _sel_title: Label = null
var _menu_panel: Panel = null
var _menu_list: VBoxContainer = null
var _banner: Label = null

func _ready() -> void:
	_build_env()
	_floor()
	_prop(TABLE_GLB, Vector3.ZERO, 0.0)
	for i: int in range(SEAT_KEYS.size()):
		var ang: float = TAU * float(i) / float(SEAT_KEYS.size())
		var pos := Vector3(sin(ang) * RING_R, 0.0, cos(ang) * RING_R)
		_seat_pos.append(pos)
		_alive.append(true)
		var face_center: float = atan2(-pos.x, -pos.z)
		_prop(CHAIR_GLB, pos, face_center)
		_seat_char.append(_seat_character(SEAT_KEYS[i], pos, face_center))
	_cam = Camera3D.new()
	_cam.current = true
	add_child(_cam)
	_human_seat = _resolve_human_seat()
	_build_hud()
	_start_game()
	if "--capture" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_args():
		_shot_frames = 90

func _resolve_human_seat() -> int:
	var key := "quinn"
	if GameManager.last_level_duo.size() > 0:
		key = String(GameManager.last_level_duo[0]).to_lower()
	var idx: int = SEAT_KEYS.find(key)
	return idx if idx >= 0 else 0

func _build_env() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-60.0), deg_to_rad(30.0), 0.0)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	add_child(sun)
	var key := OmniLight3D.new()
	key.position = Vector3(0, 3.2, 0)
	key.light_color = Color(1.0, 0.92, 0.78)
	key.light_energy = 2.5
	key.omni_range = 8.0
	add_child(key)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.06, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.46, 0.42)
	env.ambient_light_energy = 0.5
	we.environment = env
	add_child(we)

func _floor() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12, 12)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.26, 0.23)
	mat.roughness = 1.0
	pm.material = mat
	mi.mesh = pm
	add_child(mi)

func _prop(path: String, pos: Vector3, yaw: float) -> void:
	var ps: PackedScene = load(path)
	if ps == null:
		return
	var n := ps.instantiate()
	n.position = pos
	n.rotation.y = yaw
	add_child(n)

func _seat_character(key: String, pos: Vector3, yaw: float) -> Node3D:
	var ps: PackedScene = load("res://assets/models/characters/%s.glb" % key)
	if ps == null:
		return null
	var n := ps.instantiate()
	n.position = pos + Vector3(0.0, SEAT_Y, 0.0)
	n.rotation.y = yaw
	add_child(n)
	var ap := _find_anim(n)
	if ap != null and ap.has_animation("sit"):
		ap.play("sit")
	return n

func _find_anim(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null

# --- HUD ---------------------------------------------------------------------
func _build_hud() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UITheme.get_theme()
	cl.add_child(_root)
	# Fixed 1280x720 viewport → absolute coords (anchor presets were fighting us).
	# Poker lower-third (bottom-left)
	var lt := _panel(Vector2(24, 620), Vector2(360, 72))
	_lt_name = _mk(lt, Vector2(16, 8), 26, UITheme.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 320)
	_lt_count = _mk(lt, Vector2(16, 40), 18, UITheme.CREAM, HORIZONTAL_ALIGNMENT_LEFT, 320)
	# Middle-pile "pot" chip (top-centre)
	var pot := _panel(Vector2(530, 20), Vector2(220, 44))
	_pot = _mk(pot, Vector2(0, 8), 18, UITheme.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, 220)
	_pot.text = "MIDDLE PILE: 0"
	# PiP announcer (top-right)
	var ann := _panel(Vector2(908, 24), Vector2(348, 116))
	var mic := _mk(ann, Vector2(14, 6), 16, UITheme.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, 320); mic.text = "🎙  ON THE CALL"
	_ann_text = _mk(ann, Vector2(14, 32), 16, UITheme.CREAM, HORIZONTAL_ALIGNMENT_LEFT, 320)
	_ann_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _ann_text.size = Vector2(320, 76)
	_ann_text.text = "\"Welcome to the rooftop, folks — six players, one spoon to rule 'em.\""
	# Win banner (centre)
	_banner = _mk(_root, Vector2(0, 300), 48, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	_banner.visible = false
	# Human spoon-selection panel (bottom-centre) with a scrollable list
	_sel_panel = _panel(Vector2(420, 416), Vector2(440, 280))
	_sel_title = _mk(_sel_panel, Vector2(16, 10), 20, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 408)
	var scroll := ScrollContainer.new(); scroll.position = Vector2(16, 46); scroll.size = Vector2(408, 220)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_sel_panel.add_child(scroll)
	_sel_list = VBoxContainer.new(); _sel_list.custom_minimum_size = Vector2(388, 0)
	scroll.add_child(_sel_list)
	_sel_panel.visible = false
	# Pause / game-over menu (lower-right, so it doesn't cover the table/result)
	_menu_panel = _panel(Vector2(936, 452), Vector2(320, 244))
	var mt := _mk(_menu_panel, Vector2(16, 12), 22, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 288); mt.text = "Gimme Dat Spoon"
	_menu_list = VBoxContainer.new(); _menu_list.position = Vector2(40, 56); _menu_list.size = Vector2(240, 0)
	_menu_list.add_theme_constant_override("separation", 10)
	_menu_panel.add_child(_menu_list)
	_menu_panel.visible = false

func _panel(pos: Vector2, sz: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos; p.size = sz
	p.add_theme_stylebox_override("panel", UITheme.panel_box())
	_root.add_child(p)
	return p

func _mk(parent: Node, pos: Vector2, size: int, col: Color, align: int, width: float) -> Label:
	var l := Label.new()
	l.position = pos
	if width > 0: l.size = Vector2(width, size + 12)
	l.horizontal_alignment = align
	l.add_theme_font_override("font", UITheme.font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	parent.add_child(l)
	return l

# --- Game flow ---------------------------------------------------------------
func _start_game() -> void:
	var colors: Array = []
	for c in SEAT_COL:
		colors.append(c)
	_game = SpoonGameScript.new()
	_game.spoon_passed.connect(_on_pass)
	_game.spoon_discarded.connect(_on_discard)
	_game.power_activated.connect(_on_power)
	_game.player_eliminated.connect(_on_elim)
	_game.game_over.connect(_on_over)
	_game.turn_changed.connect(_on_turn)
	_game.start(SEAT_NAMES.duplicate(), colors)
	_begin_turn_for(_game.active_idx)

func _begin_turn_for(idx: int) -> void:
	_update_lower_third(idx)
	_cut_to(idx)
	_state = St.CUT
	_timer = DOLLY_TIME if (idx == _human_seat and _alive[idx]) else DOLLY_TIME + AI_BEAT

func _on_turn(idx: int) -> void:
	if _state == St.OVER:
		return
	_begin_turn_for(idx)

func _process(delta: float) -> void:
	_nav_cd = maxf(_nav_cd - delta, 0.0)
	if _shot_frames >= 0:
		_shot_frames -= 1
		if _shot_frames == 0:
			get_viewport().get_texture().get_image().save_png("res://_arena3d_shot.png")
			print("SHOT_SAVED")
			get_tree().quit()
	if _menu_open or _state != St.CUT:
		return
	if _timer > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			if _game != null and _game.active_idx == _human_seat and _alive[_human_seat]:
				_open_selection()
			elif _game != null:
				_game.take_ai_turn()

func _update_lower_third(idx: int) -> void:
	_lt_name.add_theme_color_override("font_color", SEAT_COL[idx] if idx == _human_seat else UITheme.GOLD)
	_lt_name.text = "%s%s" % [SEAT_NAMES[idx], "  (you)" if idx == _human_seat else ""]
	_lt_count.text = "Spoons in hand: %d" % (_game.players[idx]["hand"].size() if _game != null else 0)

# --- Input / navigation (mouse + WASD/arrows/gamepad) ------------------------
func _input(e: InputEvent) -> void:
	# All menu/selection nav is handled + consumed here (mouse still works natively),
	# so native focus nav never double-fires. move_up/down already cover WASD + arrows
	# + d-pad + left stick; a small cooldown tames key-echo and analog repeat.
	if e.is_action_pressed("ui_cancel") and not e.is_echo():
		_toggle_menu()
		get_viewport().set_input_as_handled()
		return
	if _btns.is_empty():
		return
	if e.is_action_pressed("ui_accept") and not e.is_echo():
		if _focus_i >= 0 and _focus_i < _btns.size():
			_btns[_focus_i].emit_signal("pressed")
		get_viewport().set_input_as_handled()
		return
	if _nav_cd > 0.0:
		return
	if e.is_action_pressed("move_down"):
		_focus(_focus_i + 1); _nav_cd = 0.18; get_viewport().set_input_as_handled()
	elif e.is_action_pressed("move_up"):
		_focus(_focus_i - 1); _nav_cd = 0.18; get_viewport().set_input_as_handled()

func _set_nav(arr: Array) -> void:
	_btns = arr
	_focus_i = 0
	if not arr.is_empty():
		arr[0].grab_focus()
	_repaint_focus()

func _focus(i: int) -> void:
	if _btns.is_empty():
		return
	_focus_i = clampi(i, 0, _btns.size() - 1)
	_btns[_focus_i].grab_focus()
	_repaint_focus()

# Explicit highlight so keyboard/gamepad focus is obvious (the UITheme has no loud
# focus box): the selected button stays bright, the rest dim.
func _repaint_focus() -> void:
	for i in _btns.size():
		(_btns[i] as Button).modulate = Color(1, 1, 1) if i == _focus_i else Color(0.52, 0.52, 0.56)

func _mk_button(parent: Node, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_override("font", UITheme.font())
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b

# --- Human selection ---------------------------------------------------------
func _open_selection() -> void:
	_state = St.HUMAN
	_pending = _game.begin_turn()
	for c in _sel_list.get_children():
		c.queue_free()
	var hand: Array = _game.players[_human_seat]["hand"]
	var btns: Array = []
	if _pending.get("discard", false):
		_sel_title.text = "You rolled a 6 — discard a spoon to the middle"
		for sp: String in hand:
			btns.append(_mk_button(_sel_list, "Discard %s" % SPOON_LABEL.get(sp, sp), _resolve_human.bind(sp, false, true)))
	else:
		var to: int = _pending["recipient_idx"]
		_sel_title.text = "You rolled %d — pass to %s" % [_pending["roll"], SEAT_NAMES[to]]
		for sp: String in hand:
			if sp in SpoonGameScript.POWER_TYPES:
				btns.append(_mk_button(_sel_list, "Pass %s" % SPOON_LABEL.get(sp, sp), _resolve_human.bind(sp, false, false)))
				btns.append(_mk_button(_sel_list, "PLAY %s!" % SPOON_LABEL.get(sp, sp), _resolve_human.bind(sp, true, false)))
			else:
				btns.append(_mk_button(_sel_list, "Pass %s" % SPOON_LABEL.get(sp, sp), _resolve_human.bind(sp, false, false)))
	_sel_panel.visible = true
	if not _menu_open:
		_set_nav(btns)

func _resolve_human(spoon: String, activate: bool, discard: bool) -> void:
	_sel_panel.visible = false
	_set_nav([])
	if discard:
		_game.resolve_discard(spoon)
	else:
		_game.resolve_turn(spoon, activate)

# --- Pause / game-over menu --------------------------------------------------
func _toggle_menu() -> void:
	if _state == St.OVER:
		return   # the menu is already up at game over; Esc does nothing
	if _menu_open:
		_close_menu()
	else:
		_open_menu(false)

func _open_menu(game_over: bool) -> void:
	_menu_open = true
	for b in _sel_list.get_children():   # don't let mouse click the selection behind the menu
		(b as Button).disabled = true
	for c in _menu_list.get_children():
		c.queue_free()
	var btns: Array = []
	if not game_over:
		btns.append(_mk_button(_menu_list, "Resume", _close_menu))
	btns.append(_mk_button(_menu_list, "Play Again", _play_again))
	btns.append(_mk_button(_menu_list, "Leave to the Rooftop", _leave))
	_menu_panel.visible = true
	_set_nav(btns)

func _close_menu() -> void:
	_menu_open = false
	_menu_panel.visible = false
	for b in _sel_list.get_children():
		(b as Button).disabled = false
	if _sel_panel.visible:
		_set_nav(_sel_list.get_children())
	else:
		_set_nav([])

func _play_again() -> void:
	get_tree().reload_current_scene()

func _leave() -> void:
	get_tree().change_scene_to_file(ROOFTOP_SCENE)

# --- Middle pile -------------------------------------------------------------
func _add_to_pile() -> void:
	_pile_count += 1
	_pot.text = "MIDDLE PILE: %d" % _pile_count
	_say("\"Into the middle it goes — the pile's at %d!\"" % _pile_count)
	var ps: PackedScene = load(SPOON_GLB)
	if ps == null:
		return
	var sp := ps.instantiate() as Node3D
	var a := randf() * TAU
	var r := randf() * 0.3
	var rest := Vector3(cos(a) * r, TABLE_TOP + 0.02 + float(_pile_count) * 0.012, sin(a) * r)
	sp.position = rest + Vector3(0, 0.4, 0)
	sp.rotation.y = randf() * TAU
	add_child(sp)
	create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT) \
		.tween_property(sp, "position", rest, 0.4)
	Audio.play("ui_select")

# --- Game events -------------------------------------------------------------
func _on_pass(from_idx: int, _to_idx: int, spoon_type: String) -> void:
	if spoon_type == "anchorless_exiled":
		_add_to_pile()   # an exiled spoon goes to the middle
	if from_idx == _human_seat:
		_say(_human_commentary())
	_update_lower_third(_game.active_idx if _game != null else from_idx)

func _on_discard(_idx: int, _spoon_type: String) -> void:
	_add_to_pile()

func _on_power(idx: int, spoon_type: String) -> void:
	_say("\"%s drops the %s — what a move!\"" % [SEAT_NAMES[idx], SPOON_LABEL.get(spoon_type, spoon_type)])
	CombatFX.shake(0.2)

func _on_elim(idx: int) -> void:
	_alive[idx] = false
	_say("\"%s is OUT! Brutal.\"" % SEAT_NAMES[idx])
	var ch: Node3D = _seat_char[idx]
	if ch != null:
		var tw := create_tween()
		tw.tween_property(ch, "rotation:x", deg_to_rad(30.0), 0.4)
		for mi in ch.find_children("*", "MeshInstance3D"):
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.4, 0.4, 0.42)
			(mi as MeshInstance3D).material_override = m

func _on_over(winner_idx: int) -> void:
	_state = St.OVER
	_timer = 0.0
	_sel_panel.visible = false
	if winner_idx == _human_seat:
		_banner.text = "YOU WIN THE SPOON!"
	elif winner_idx >= 0:
		_banner.text = "%s wins the spoon!" % SEAT_NAMES[winner_idx]
	else:
		_banner.text = "The middle takes it!"
	_banner.visible = true
	if winner_idx >= 0:
		_cut_to(winner_idx, true)
		GameManager.spoon_game_won.emit()
	else:
		_cut_middle()
	_open_menu(true)

func _human_commentary() -> String:
	var pool: Array = [
		"\"%s plays it cool — you don't clear %d locations without nerves like that.\"" % [SEAT_NAMES[_human_seat], GameManager.completed_locations.size()],
		"\"That's the hands that fixed half this town, folks.\"",
		"\"%s keeps the power spoons close — smart, real smart.\"" % SEAT_NAMES[_human_seat],
		"\"Cooler under pressure than a Bies-mode dodge!\"",
		"\"The crowd loves it!\"",
	]
	return pool[randi() % pool.size()]

func _say(text: String) -> void:
	if _ann_text != null:
		_ann_text.text = text

# --- Camera ------------------------------------------------------------------
func _cut_to(seat: int, hero: bool = false) -> void:
	var sp: Vector3 = _seat_pos[seat]
	var look: Vector3 = sp + Vector3(0.0, 0.95, 0.0)
	var n: Vector3 = sp.normalized()
	var far: Vector3 = -n * (RING_R + (2.6 if hero else 3.4)) + Vector3(0.0, 2.8, 0.0)
	var near: Vector3 = -n * (RING_R + (1.5 if hero else 1.9)) + Vector3(0.0, 2.3, 0.0)
	_cam.global_position = far
	_cam.look_at(look, Vector3.UP)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(t: float) -> void:
		_cam.global_position = far.lerp(near, t)
		_cam.look_at(look, Vector3.UP), 0.0, 1.0, DOLLY_TIME)

func _cut_middle() -> void:
	var look := Vector3(0, TABLE_TOP, 0)
	_cam.global_position = Vector3(0, 3.2, 3.4)
	_cam.look_at(look, Vector3.UP)
