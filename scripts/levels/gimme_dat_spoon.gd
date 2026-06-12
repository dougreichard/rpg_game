extends Node2D

# "Gimme Dat Spoon" -- post-game bonus minigame. SELECT_CHARACTER lets the
# player pick one of the six "Gimme Dat Spoon" roster members to play as
# (seat 0); the other five are AI-controlled via SpoonGame.take_ai_turn().
# All UI is programmatic _draw()/queue_redraw(), no imported assets.

const SpoonGameScript = preload("res://scripts/systems/spoon_game.gd")

enum Phase { SELECT_CHARACTER, PLAYING, GAME_OVER }
enum HumanStep { NONE, CHOOSE_SPOON, CHOOSE_ACTIVATE }

const CHAR_RESOURCE_ORDER: Array[String] = ["Quinn", "Erin", "Evan", "Ben", "Ethan"]
const CHAR_RESOURCES := {
	"Quinn": "res://data/characters/quinn.tres",
	"Erin": "res://data/characters/erin.tres",
	"Evan": "res://data/characters/evan.tres",
	"Ben": "res://data/characters/ben.tres",
	"Ethan": "res://data/characters/ethan.tres",
}
const UNCLE_DOUG_COLOR := Color(0.85, 0.6, 0.25, 1.0)

const SPOON_LABELS := {
	"standard": "Spoon",
	"anchor": "Anchor Spoon",
	"magnet": "Magnet Spoon",
	"spinner": "Spinner Spoon",
	"switch": "Switch Spoon",
	"reverse": "Reverse Spoon",
	"anchorless": "Anchorless Spoon",
}
const SPOON_GLYPHS := {
	"standard": "",
	"anchor": "A",
	"magnet": "M",
	"spinner": "S",
	"switch": "W",
	"reverse": "R",
	"anchorless": "X",
}
const SPOON_ACCENT_COLORS := {
	"standard": Color(0.8, 0.8, 0.85, 1.0),
	"anchor": Color(0.55, 0.75, 0.95, 1.0),
	"magnet": Color(0.95, 0.35, 0.35, 1.0),
	"spinner": Color(0.65, 0.45, 0.95, 1.0),
	"switch": Color(0.95, 0.75, 0.3, 1.0),
	"reverse": Color(0.4, 0.9, 0.55, 1.0),
	"anchorless": Color(0.6, 0.6, 0.65, 1.0),
}

const BG_COLOR := Color(0.05, 0.06, 0.1, 1.0)
const PANEL_COLOR := Color(0.08, 0.07, 0.14, 0.97)
const BORDER_COLOR := Color(0.85, 0.78, 0.35, 1.0)
const TITLE_COLOR := Color(0.95, 0.85, 0.2, 1.0)
const TEXT_COLOR := Color(0.92, 0.92, 0.95, 1.0)
const HINT_COLOR := Color(0.55, 0.55, 0.6, 1.0)
const SELECTED_COLOR := Color(0.95, 0.85, 0.2, 1.0)
const DIM_COLOR := Color(0.4, 0.4, 0.45, 1.0)
const ELIMINATED_COLOR := Color(0.3, 0.3, 0.35, 1.0)

const CIRCLE_CENTER := Vector2(640.0, 230.0)
const CIRCLE_RADIUS := 150.0
const TOKEN_RADIUS := 34.0

const PROMPT_PANEL := Rect2(40.0, 420.0, 1200.0, 90.0)
const LOG_PANEL := Rect2(40.0, 520.0, 1200.0, 150.0)
const SELECT_LIST_TOP := 220.0
const SELECT_ROW_HEIGHT := 50.0
const SELECT_SWATCH_SIZE := 28.0

const MAX_LOG_LINES: int = 6
const AI_TURN_DELAY: float = 0.9
const GAME_OVER_DELAY: float = 1.2

var _font: Font

var _phase: int = Phase.SELECT_CHARACTER
var _roster: Array = []  # [{name: String, color: Color}]
var _select_cursor: int = 0

var _game = null
var _log: Array[String] = []
var _last_roll: int = 0
var _busy: bool = false
var _ended: bool = false
var _winner_idx: int = -1
var _pulse_time: float = 0.0

var _human_step: int = HumanStep.NONE
var _hand_cursor: int = 0
var _activate_cursor: int = 0
var _pending_spoon_type: String = ""


func _ready() -> void:
	_font = ThemeDB.fallback_font
	for char_name in CHAR_RESOURCE_ORDER:
		var data = load(CHAR_RESOURCES[char_name])
		_roster.append({"name": char_name, "color": data.sprite_color})
	_roster.append({"name": "Uncle Doug", "color": UNCLE_DOUG_COLOR})
	GameManager.spoon_arcade_entered.emit()
	queue_redraw()


func _process(delta: float) -> void:
	_pulse_time += delta
	if _phase == Phase.PLAYING:
		queue_redraw()
		if not _busy and not _ended and _human_step == HumanStep.NONE:
			_advance_turn()


# --- Game flow -------------------------------------------------------------

func _start_game() -> void:
	var names: Array = []
	var colors: Array = []
	names.append(_roster[_select_cursor]["name"])
	colors.append(_roster[_select_cursor]["color"])
	for i in _roster.size():
		if i != _select_cursor:
			names.append(_roster[i]["name"])
			colors.append(_roster[i]["color"])

	_game = SpoonGameScript.new()
	_game.die_rolled.connect(_on_die_rolled)
	_game.spoon_passed.connect(_on_spoon_passed)
	_game.power_activated.connect(_on_power_activated)
	_game.direction_changed.connect(_on_direction_changed)
	_game.player_eliminated.connect(_on_player_eliminated)
	_game.game_over.connect(_on_game_over)
	_game.start(names, colors)

	_log.clear()
	_last_roll = 0
	_ended = false
	_busy = false
	_human_step = HumanStep.NONE
	_append_log("The spoons are dealt -- good luck!")
	_phase = Phase.PLAYING
	queue_redraw()


func _advance_turn() -> void:
	if _game.active_idx == 0:
		_start_human_turn()
	else:
		_busy = true
		_game.take_ai_turn()
		if _ended:
			get_tree().create_timer(GAME_OVER_DELAY).timeout.connect(_start_game_over)
		else:
			get_tree().create_timer(AI_TURN_DELAY).timeout.connect(_on_ai_turn_done)


func _on_ai_turn_done() -> void:
	_busy = false


func _start_human_turn() -> void:
	_game.begin_turn()
	_human_step = HumanStep.CHOOSE_SPOON
	_hand_cursor = 0
	queue_redraw()


func _resolve_human_turn(spoon_type: String, activate: bool) -> void:
	_game.resolve_turn(spoon_type, activate)
	_human_step = HumanStep.NONE
	if _ended:
		get_tree().create_timer(GAME_OVER_DELAY).timeout.connect(_start_game_over)
	queue_redraw()


func _start_game_over() -> void:
	_phase = Phase.GAME_OVER
	queue_redraw()


func _exit_to_overworld() -> void:
	GameManager.last_location_id = "gimme_dat_spoon"
	TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")


# --- SpoonGame signal handlers ---------------------------------------------

func _player_name(idx: int) -> String:
	return _game.players[idx]["name"]


func _append_log(line: String) -> void:
	_log.append(line)
	if _log.size() > MAX_LOG_LINES:
		_log.remove_at(0)
	queue_redraw()


func _on_die_rolled(roll: int) -> void:
	_last_roll = roll
	_append_log("%s rolls a %d." % [_player_name(_game.active_idx), roll])


func _on_spoon_passed(from_idx: int, to_idx: int, spoon_type: String) -> void:
	var from_name: String = _player_name(from_idx)
	var to_name: String = _player_name(to_idx)
	match spoon_type:
		"anchorless_exiled":
			_append_log("%s tosses the Anchorless Spoon away for good!" % from_name)
		"spinner_redirect":
			_append_log("The Spinner Spoon whirls on to %s!" % to_name)
		_:
			var label: String = SPOON_LABELS.get(spoon_type, "Spoon")
			if from_idx == to_idx:
				_append_log("%s keeps hold of the %s." % [from_name, label])
			else:
				_append_log("%s passes the %s to %s." % [from_name, label, to_name])


func _on_power_activated(player_idx: int, spoon_type: String) -> void:
	_append_log("%s activates the %s!" % [_player_name(player_idx), SPOON_LABELS.get(spoon_type, "Spoon")])
	if player_idx == 0:
		GameManager.spoon_power_used.emit(spoon_type)


func _on_direction_changed(_direction: int) -> void:
	_append_log("The direction reverses!")


func _on_player_eliminated(idx: int) -> void:
	_append_log("%s is out of spoons and is eliminated!" % _player_name(idx))


func _on_game_over(winner_idx: int) -> void:
	_ended = true
	_winner_idx = winner_idx
	_append_log("%s wins the game!" % _player_name(winner_idx))
	if winner_idx == 0:
		GameManager.spoon_game_won.emit()


# --- Input -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	match _phase:
		Phase.SELECT_CHARACTER:
			_handle_select_input(event)
		Phase.PLAYING:
			_handle_playing_input(event)
		Phase.GAME_OVER:
			_handle_game_over_input(event)


func _handle_select_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_select_cursor = wrapi(_select_cursor - 1, 0, _roster.size())
		Audio.play("ui_move")
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_select_cursor = wrapi(_select_cursor + 1, 0, _roster.size())
		Audio.play("ui_move")
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		Audio.play("ui_select")
		_start_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_exit_to_overworld()
		get_viewport().set_input_as_handled()


func _handle_playing_input(event: InputEvent) -> void:
	if _human_step == HumanStep.CHOOSE_SPOON:
		var hand: Array = _game.players[0]["hand"]
		if hand.is_empty():
			return
		if event.is_action_pressed("move_up"):
			_hand_cursor = wrapi(_hand_cursor - 1, 0, hand.size())
			Audio.play("ui_move")
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_down"):
			_hand_cursor = wrapi(_hand_cursor + 1, 0, hand.size())
			Audio.play("ui_move")
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			var spoon_type: String = hand[_hand_cursor]
			Audio.play("ui_select")
			if spoon_type in SpoonGameScript.POWER_TYPES:
				_pending_spoon_type = spoon_type
				_activate_cursor = 0
				_human_step = HumanStep.CHOOSE_ACTIVATE
				queue_redraw()
			else:
				_resolve_human_turn(spoon_type, false)
			get_viewport().set_input_as_handled()
	elif _human_step == HumanStep.CHOOSE_ACTIVATE:
		if event.is_action_pressed("move_up") or event.is_action_pressed("move_down") \
				or event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			_activate_cursor = 1 - _activate_cursor
			Audio.play("ui_move")
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			Audio.play("ui_select")
			_resolve_human_turn(_pending_spoon_type, _activate_cursor == 0)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_exit_to_overworld()
		get_viewport().set_input_as_handled()


func _handle_game_over_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		Audio.play("ui_select")
		_exit_to_overworld()
		get_viewport().set_input_as_handled()


# --- Drawing -------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), BG_COLOR)
	match _phase:
		Phase.SELECT_CHARACTER:
			_draw_select_character()
		Phase.PLAYING:
			_draw_playing()
		Phase.GAME_OVER:
			_draw_game_over()


func _draw_title() -> void:
	draw_string(_font, Vector2(0.0, 36.0), "GIMME DAT SPOON", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 26, TITLE_COLOR)


func _draw_select_character() -> void:
	_draw_title()
	draw_string(_font, Vector2(0.0, 76.0), "Choose your player", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 16, TEXT_COLOR)

	for i in _roster.size():
		var row_y: float = SELECT_LIST_TOP + float(i) * SELECT_ROW_HEIGHT
		var entry: Dictionary = _roster[i]
		var is_selected: bool = (i == _select_cursor)
		var swatch_pos := Vector2(540.0, row_y)
		draw_rect(Rect2(swatch_pos, Vector2(SELECT_SWATCH_SIZE, SELECT_SWATCH_SIZE)), entry["color"])
		draw_rect(Rect2(swatch_pos, Vector2(SELECT_SWATCH_SIZE, SELECT_SWATCH_SIZE)), BORDER_COLOR, false, 2.0)
		var label: String = ("> " if is_selected else "   ") + String(entry["name"])
		var color: Color = SELECTED_COLOR if is_selected else TEXT_COLOR
		draw_string(_font, swatch_pos + Vector2(SELECT_SWATCH_SIZE + 12.0, SELECT_SWATCH_SIZE * 0.75), label, HORIZONTAL_ALIGNMENT_LEFT, 300.0, 18, color)

	draw_string(_font, Vector2(0.0, 690.0), "UP / DOWN  Choose     ENTER  Play     ESC  Back to town", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 13, HINT_COLOR)


func _draw_playing() -> void:
	_draw_title()
	_draw_direction_indicator()
	_draw_die(Rect2(1160.0, 24.0, 56.0, 56.0), _last_roll)
	_draw_player_circle()
	if _human_step == HumanStep.NONE:
		_draw_log_panel(PROMPT_PANEL)
	elif _human_step == HumanStep.CHOOSE_SPOON:
		_draw_choose_spoon_panel()
	elif _human_step == HumanStep.CHOOSE_ACTIVATE:
		_draw_choose_activate_panel()
	_draw_log_panel(LOG_PANEL)


func _draw_player_circle() -> void:
	for i in _game.players.size():
		var player: Dictionary = _game.players[i]
		var angle: float = -PI / 2.0 + float(i) * TAU / 6.0
		var token_pos: Vector2 = CIRCLE_CENTER + Vector2(cos(angle), sin(angle)) * CIRCLE_RADIUS
		var color: Color = player["color"] if player["alive"] else ELIMINATED_COLOR

		if i == _game.active_idx and not _ended:
			var pulse: float = (sin(_pulse_time * 5.0) + 1.0) * 0.5
			draw_arc(token_pos, TOKEN_RADIUS + 6.0 + pulse * 4.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.4 + pulse * 0.5), 3.0)

		draw_circle(token_pos, TOKEN_RADIUS, color)
		draw_arc(token_pos, TOKEN_RADIUS, 0.0, TAU, 32, BORDER_COLOR, 1.5)

		var hand_size: int = player["hand"].size()
		var count_text: String = "OUT" if not player["alive"] else str(hand_size)
		draw_string(_font, token_pos - Vector2(20.0, -5.0), count_text, HORIZONTAL_ALIGNMENT_CENTER, 40.0, 16, TEXT_COLOR)

		var name_color: Color = TEXT_COLOR if player["alive"] else DIM_COLOR
		draw_string(_font, token_pos + Vector2(-50.0, TOKEN_RADIUS + 18.0), String(player["name"]), HORIZONTAL_ALIGNMENT_CENTER, 100.0, 13, name_color)

		if player.get("shielded", false):
			draw_string(_font, token_pos + Vector2(-50.0, -TOKEN_RADIUS - 8.0), "SHIELDED", HORIZONTAL_ALIGNMENT_CENTER, 100.0, 11, SPOON_ACCENT_COLORS["anchor"])


func _draw_direction_indicator() -> void:
	var label: String = "Direction: Clockwise" if _game.direction == 1 else "Direction: Counter-clockwise"
	draw_string(_font, Vector2(40.0, 50.0), label, HORIZONTAL_ALIGNMENT_LEFT, 400.0, 14, TEXT_COLOR)
	var arrow_y: float = 70.0
	if _game.direction == 1:
		draw_colored_polygon(PackedVector2Array([Vector2(40.0, arrow_y), Vector2(40.0, arrow_y + 16.0), Vector2(60.0, arrow_y + 8.0)]), TEXT_COLOR)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(60.0, arrow_y), Vector2(60.0, arrow_y + 16.0), Vector2(40.0, arrow_y + 8.0)]), TEXT_COLOR)


func _draw_die(rect: Rect2, value: int) -> void:
	draw_rect(rect, Color(0.95, 0.95, 0.97, 1.0))
	draw_rect(rect, Color(0.2, 0.2, 0.25, 1.0), false, 2.0)
	if value <= 0:
		return
	var pip_radius: float = rect.size.x * 0.08
	var pip_color := Color(0.15, 0.15, 0.2, 1.0)
	const PIP_LAYOUT := {
		1: [Vector2(0.5, 0.5)],
		2: [Vector2(0.25, 0.25), Vector2(0.75, 0.75)],
		3: [Vector2(0.25, 0.25), Vector2(0.5, 0.5), Vector2(0.75, 0.75)],
		4: [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75), Vector2(0.75, 0.75)],
		5: [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.5, 0.5), Vector2(0.25, 0.75), Vector2(0.75, 0.75)],
		6: [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.5), Vector2(0.75, 0.5), Vector2(0.25, 0.75), Vector2(0.75, 0.75)],
	}
	for p: Vector2 in PIP_LAYOUT.get(value, []):
		draw_circle(rect.position + rect.size * p, pip_radius, pip_color)


func _draw_spoon_icon(center: Vector2, spoon_type: String) -> void:
	var bowl_radius: float = 8.0
	draw_circle(center, bowl_radius, Color(0.85, 0.85, 0.9, 1.0))
	draw_arc(center, bowl_radius, 0.0, TAU, 16, Color(0.4, 0.4, 0.45, 1.0), 1.5)
	draw_rect(Rect2(center + Vector2(-2.0, bowl_radius * 0.4), Vector2(4.0, 14.0)), Color(0.85, 0.85, 0.9, 1.0))
	var glyph: String = SPOON_GLYPHS.get(spoon_type, "")
	if glyph != "":
		var accent: Color = SPOON_ACCENT_COLORS.get(spoon_type, Color.WHITE)
		draw_circle(center, bowl_radius * 0.6, accent)
		draw_string(_font, center + Vector2(-4.0, 4.0), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.BLACK)


func _draw_panel(rect: Rect2) -> void:
	draw_rect(rect, PANEL_COLOR)
	draw_rect(rect, BORDER_COLOR, false, 2.0)


func _draw_log_panel(rect: Rect2) -> void:
	_draw_panel(rect)
	var line_height: float = 22.0
	var start_y: float = rect.position.y + 24.0
	for i in _log.size():
		draw_string(_font, Vector2(rect.position.x + 16.0, start_y + float(i) * line_height), _log[i], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32.0, 13, TEXT_COLOR)


func _draw_choose_spoon_panel() -> void:
	var rect: Rect2 = PROMPT_PANEL
	_draw_panel(rect)
	draw_string(_font, Vector2(rect.position.x + 16.0, rect.position.y + 22.0), "Your turn! Choose a spoon to pass:", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32.0, 14, TEXT_COLOR)

	var hand: Array = _game.players[0]["hand"]
	var row_width: float = 220.0
	var start_x: float = rect.position.x + 32.0
	var row_y: float = rect.position.y + 48.0
	for i in hand.size():
		var spoon_type: String = hand[i]
		var x: float = start_x + float(i) * row_width
		var icon_center := Vector2(x + 10.0, row_y + 10.0)
		_draw_spoon_icon(icon_center, spoon_type)
		var color: Color = SELECTED_COLOR if i == _hand_cursor else TEXT_COLOR
		var prefix: String = "> " if i == _hand_cursor else "   "
		draw_string(_font, Vector2(x + 28.0, row_y + 16.0), prefix + SPOON_LABELS.get(spoon_type, "Spoon"), HORIZONTAL_ALIGNMENT_LEFT, row_width - 28.0, 14, color)

	draw_string(_font, Vector2(rect.position.x + 16.0, rect.position.y + rect.size.y - 12.0), "UP / DOWN  Choose     ENTER  Select", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32.0, 12, HINT_COLOR)


func _draw_choose_activate_panel() -> void:
	var rect: Rect2 = PROMPT_PANEL
	_draw_panel(rect)
	var label: String = SPOON_LABELS.get(_pending_spoon_type, "Spoon")
	draw_string(_font, Vector2(rect.position.x + 16.0, rect.position.y + 22.0), "Activate the %s?" % label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32.0, 14, TEXT_COLOR)

	var options: Array[String] = ["Yes", "No"]
	for i in options.size():
		var color: Color = SELECTED_COLOR if i == _activate_cursor else TEXT_COLOR
		var prefix: String = "> " if i == _activate_cursor else "   "
		draw_string(_font, Vector2(rect.position.x + 32.0 + float(i) * 120.0, rect.position.y + 48.0), prefix + options[i], HORIZONTAL_ALIGNMENT_LEFT, 100.0, 14, color)

	draw_string(_font, Vector2(rect.position.x + 16.0, rect.position.y + rect.size.y - 12.0), "LEFT / RIGHT  Choose     ENTER  Select", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32.0, 12, HINT_COLOR)


func _draw_game_over() -> void:
	_draw_player_circle()
	_draw_log_panel(LOG_PANEL)
	var winner_name: String = _player_name(_winner_idx) if _winner_idx >= 0 else "???"
	draw_string(_font, Vector2(0.0, 200.0), "%s WINS!" % winner_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 36, TITLE_COLOR)
	draw_string(_font, Vector2(0.0, 690.0), "Press ENTER to return to town", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 13, HINT_COLOR)
