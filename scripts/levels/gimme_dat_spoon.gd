extends Node2D

# "Gimme Dat Spoon" -- post-game bonus minigame. SELECT_CHARACTER lets the
# player pick one of the six "Gimme Dat Spoon" roster members to play as
# (seat 0); the other five are AI-controlled via SpoonGame.take_ai_turn().
# All UI is programmatic _draw()/queue_redraw(), no imported assets.

const SpoonGameScript = preload("res://scripts/systems/spoon_game.gd")

enum Phase { SELECT_CHARACTER, PLAYING, GAME_OVER }
enum HumanStep { NONE, CHOOSE_SPOON, CHOOSE_ACTIVATE, DISCARD_SPOON }

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
const SPOON_DESCRIPTIONS := {
	"standard": "A plain spoon -- no special ability. Just pass it on.",
	"anchor": "Shield: if activated, you're immune to elimination until the start of your next turn. Best saved for your last spoon.",
	"magnet": "Swap: if activated, pass this spoon, then immediately take one spoon from the receiver. The only way to grow your hand.",
	"spinner": "Deflect: if activated, the recipient must immediately re-pass it to whoever it points to next. Forces an opponent's move.",
	"switch": "Hijack: if activated, the recipient instantly becomes the Active Player, seizing the die and turn order.",
	"reverse": "Pivot: if activated, reverses the direction of play. Keeps everyone off-balance.",
	"anchorless": "Exile: if activated, this spoon is discarded from the game entirely instead of being passed. Safely shrinks your hand.",
}

const BG_COLOR := Color(0.05, 0.06, 0.1, 1.0)
const PANEL_COLOR := UITheme.PANEL_BG
const BORDER_COLOR := Color(0.85, 0.78, 0.35, 1.0)
const TITLE_COLOR := Color(0.95, 0.85, 0.2, 1.0)
const TEXT_COLOR := Color(0.92, 0.92, 0.95, 1.0)
const HINT_COLOR := Color(0.55, 0.55, 0.6, 1.0)
const SELECTED_COLOR := Color(0.95, 0.85, 0.2, 1.0)
const DIM_COLOR := Color(0.4, 0.4, 0.45, 1.0)
const ELIMINATED_COLOR := Color(0.3, 0.3, 0.35, 1.0)
const RECIPIENT_RING_COLOR := Color(0.35, 0.9, 0.85, 1.0)

const CIRCLE_CENTER := Vector2(420.0, 360.0)
const CIRCLE_RADIUS := 200.0
const TOKEN_RADIUS := 50.0
# Poker-table billboard placement: felt centre as a UV of the 700x900 art, and the
# on-screen draw width (felt ~ inside the seat ring so players sit at its edge).
const TABLE_FELT_UV := Vector2(0.503, 0.424)
const TABLE_DRAW_WIDTH := 600.0

const MIDDLE_PILE_ICON_COLS := 4
const MIDDLE_PILE_ICON_SPACING := 20.0
const MIDDLE_PILE_ICON_SCALE := 0.9
const MIDDLE_PILE_MAX_ICONS := 12
const MIDDLE_PILE_GLOW_RADIUS := 90.0

const FACE_SPRITE_SIZE := 70.0
const FACE_EYE_RADIUS := 4.0
const FACE_EYE_OFFSET := Vector2(16.0, -12.0)
const FACE_FEATURE_COLOR := Color(0.15, 0.15, 0.18, 1.0)

const HAND_SPOON_SCALE := 0.7
const HAND_SPOON_SPACING := 17.0
const HAND_SPOON_MAX_ICONS := 6
const HAND_SPOON_Y_OFFSET := TOKEN_RADIUS + 38.0
const NAME_Y_OFFSET := TOKEN_RADIUS + 18.0
const NAME_LABEL_WIDTH := 140.0

const SIDE_PANEL_X := 680.0
const SIDE_PANEL_WIDTH := 560.0
const HEADER_PANEL := Rect2(SIDE_PANEL_X, 90.0, SIDE_PANEL_WIDTH, 64.0)
const MAIN_PANEL := Rect2(SIDE_PANEL_X, 168.0, SIDE_PANEL_WIDTH, 500.0)

const PICKER_LIST_TOP_OFFSET := 70.0
const PICKER_ROW_HEIGHT := 46.0
const PICKER_ICON_SCALE := 1.1
const PICKER_HINT_HEIGHT := 28.0
const DESCRIPTION_BOX_HEIGHT := 140.0

const SELECT_LIST_TOP := 220.0
const SELECT_ROW_HEIGHT := 50.0
const SELECT_SWATCH_SIZE := 28.0

# Each entry in the event queue (see "Event queue" below) holds the screen
# for this many seconds -- the source of the minigame's readable pacing.
const EVENT_DURATIONS := {
	"roll": 0.5,
	"pass": 0.6,
	"discard": 0.6,
	"power": 0.8,
	"direction": 0.5,
	"eliminate": 0.7,
	"game_over": 1.2,
}

var _font: Font

var _phase: int = Phase.SELECT_CHARACTER
var _roster: Array = []  # [{name: String, color: Color}]
var _portraits: Dictionary = {}  # character name -> SpriteFrames (talk_closeup)
var _seated: Dictionary = {}  # character name -> {idle/grab/out(/_up): Texture2D} seated billboard
var _table_tex: Texture2D = null  # Casino poker table billboard drawn at the centre
var _select_cursor: int = 0

var _game = null
var _last_roll: int = 0
var _ended: bool = false
var _winner_idx: int = -1
var _pulse_time: float = 0.0

# Event queue -- each SpoonGame signal enqueues a Dictionary describing what
# happened; _process_events() plays them out one at a time so the player can
# follow along, and turn advancement waits for the queue to drain.
var _event_queue: Array[Dictionary] = []
var _current_event: Dictionary = {}
var _event_timer: float = 0.0
var _action_text: String = ""

var _human_step: int = HumanStep.NONE
var _hand_cursor: int = 0
var _activate_cursor: int = 0
var _pending_spoon_type: String = ""
var _pending_recipient_idx: int = -1


func _ready() -> void:
	_font = UITheme.font()
	for char_name in CHAR_RESOURCE_ORDER:
		var data = load(CHAR_RESOURCES[char_name])
		_roster.append({"name": char_name, "color": data.sprite_color})
		var frames: SpriteFrames = SpriteLoader.try_load_player(char_name.to_lower())
		if frames != null and frames.has_animation("talk_closeup"):
			_portraits[char_name] = frames
	_roster.append({"name": "Uncle Doug", "color": UNCLE_DOUG_COLOR})
	var doug_frames: SpriteFrames = SpriteLoader.try_load_npc("uncle_doug")
	if doug_frames != null and doug_frames.has_animation("talk_closeup"):
		_portraits["Uncle Doug"] = doug_frames
	for entry in _roster:
		var seated: Dictionary = _load_seated(entry["name"])
		if not seated.is_empty():
			_seated[entry["name"]] = seated
	var table_path: String = "res://assets/art/synty/props/spoon_table.png"
	if ResourceLoader.exists(table_path):
		_table_tex = load(table_path)
	GameManager.spoon_arcade_entered.emit()
	Audio.play_music("combat")
	queue_redraw()


func _process(delta: float) -> void:
	_pulse_time += delta
	if _phase == Phase.PLAYING:
		_process_events(delta)
		queue_redraw()
		if _human_step != HumanStep.NONE or _events_pending():
			return
		if _ended:
			_start_game_over()
		else:
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
	_game.spoon_discarded.connect(_on_spoon_discarded)
	_game.power_activated.connect(_on_power_activated)
	_game.direction_changed.connect(_on_direction_changed)
	_game.player_eliminated.connect(_on_player_eliminated)
	_game.game_over.connect(_on_game_over)
	_game.start(names, colors)

	_event_queue.clear()
	_current_event = {}
	_event_timer = 0.0
	_last_roll = 0
	_ended = false
	_human_step = HumanStep.NONE
	_action_text = "The spoons are dealt -- good luck!"
	_phase = Phase.PLAYING
	queue_redraw()


func _advance_turn() -> void:
	if _game.active_idx == 0:
		_start_human_turn()
	else:
		_game.take_ai_turn()


func _start_human_turn() -> void:
	var turn: Dictionary = _game.begin_turn()
	if turn["discard"]:
		_pending_recipient_idx = -1
		_human_step = HumanStep.DISCARD_SPOON
		_hand_cursor = 0
		queue_redraw()
		return
	_pending_recipient_idx = turn["recipient_idx"]
	_human_step = HumanStep.CHOOSE_SPOON
	_hand_cursor = 0
	queue_redraw()


func _resolve_human_turn(spoon_type: String, activate: bool) -> void:
	_game.resolve_turn(spoon_type, activate)
	_human_step = HumanStep.NONE
	_pending_recipient_idx = -1
	queue_redraw()


func _resolve_human_discard(spoon_type: String) -> void:
	_game.resolve_discard(spoon_type)
	_human_step = HumanStep.NONE
	_pending_recipient_idx = -1
	queue_redraw()


func _start_game_over() -> void:
	_phase = Phase.GAME_OVER
	queue_redraw()


func _exit_to_overworld() -> void:
	GameManager.last_location_id = "gimme_dat_spoon"
	TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")


# --- Event queue -------------------------------------------------------------

func _player_name(idx: int) -> String:
	return _game.players[idx]["name"]


func _token_pos(idx: int) -> Vector2:
	var angle: float = -PI / 2.0 + float(idx) * TAU / 6.0
	return CIRCLE_CENTER + Vector2(cos(angle), sin(angle)) * CIRCLE_RADIUS


# Loads a character's seated billboard frames (first frame of each strip) baked
# by render_anim_lead.sh. Returns {} when the character has no animated set yet
# (those seats fall back to the colored token + drawn face).
func _load_seated(name: String) -> Dictionary:
	var key: String = name.to_lower().replace(" ", "_")
	var base: String = "res://assets/art/synty/characters/anim/" + key + "/"
	var out: Dictionary = {}
	# Front (az225, faces down) + back (az45, faces up) seated billboards, so seats
	# on the far side of the table can face inward. Keyed idle/grab/out (+ _up).
	var files: Dictionary = {
		"idle": "spoon_idle", "grab": "spoon_grab", "out": "spoon_out",
		"idle_up": "spoon_idle_up", "grab_up": "spoon_grab_up", "out_up": "spoon_out_up",
	}
	for state: String in files:
		var path: String = base + files[state] + ".png"
		if ResourceLoader.exists(path):
			out[state] = load(path)
	return out


# Draws one seated billboard centered on a seat. Picks the grab frame on the
# active turn, the slumped "out" frame when eliminated, idle otherwise. Each strip
# is a row of square frames; only the first frame is drawn (static seat pose).
func _draw_seated(token_pos: Vector2, name: String, is_active: bool, alive: bool, modulate: Color) -> void:
	var seated: Dictionary = _seated[name]
	# Seats below the table centre face up/away (back render); above face down (front).
	# Flip horizontally on the right side so diagonal seats angle inward.
	var suffix: String = "_up" if token_pos.y > CIRCLE_CENTER.y else ""
	var flip: bool = token_pos.x > CIRCLE_CENTER.x
	var state: String = "out" if not alive else ("grab" if is_active else "idle")
	var tex: Texture2D = seated.get(state + suffix)
	if tex == null:
		tex = seated.get(state)
	if tex == null:
		tex = seated.get("idle")
	if tex == null:
		return
	var side: float = float(tex.get_height())
	var target_h: float = TOKEN_RADIUS * 2.7
	var draw_w: float = target_h  # square frame
	var src := Rect2(0.0, 0.0, side, side)
	# Centered horizontally; lifted so the lap/hands sit near the seat center.
	var rel := Rect2(-draw_w * 0.5, -target_h * 0.62, draw_w, target_h)
	if flip:
		# Mirror horizontally around the seat so diagonal seats angle inward.
		draw_set_transform(token_pos, 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect_region(tex, rel, src, modulate)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture_rect_region(tex, Rect2(token_pos + rel.position, rel.size), src, modulate)


func _enqueue_event(event: Dictionary) -> void:
	_event_queue.append(event)


func _events_pending() -> bool:
	return not _current_event.is_empty() or not _event_queue.is_empty()


func _process_events(delta: float) -> void:
	if _current_event.is_empty() and not _event_queue.is_empty():
		_current_event = _event_queue.pop_front()
		_event_timer = 0.0
		_action_text = _event_action_text(_current_event)
	if _current_event.is_empty():
		return
	_event_timer += delta
	if _event_timer >= EVENT_DURATIONS.get(_current_event["type"], 0.5):
		_current_event = {}


func _event_action_text(event: Dictionary) -> String:
	match event["type"]:
		"roll":
			return "%s rolls a %d!" % [_player_name(event["player_idx"]), event["roll"]]
		"pass":
			return _spoon_passed_text(event["from_idx"], event["to_idx"], event["spoon_type"])
		"discard":
			return "%s tosses the %s into the middle!" % [_player_name(event["player_idx"]), SPOON_LABELS.get(event["spoon_type"], "Spoon")]
		"power":
			return "%s activates the %s!" % [_player_name(event["player_idx"]), SPOON_LABELS.get(event["spoon_type"], "Spoon")]
		"direction":
			return "The direction reverses!"
		"eliminate":
			return "%s is out of spoons and is eliminated!" % _player_name(event["idx"])
		"game_over":
			if event["winner_idx"] == -1:
				return "The middle has more spoons than anyone left -- THE PILE WINS!"
			return "%s wins the game!" % _player_name(event["winner_idx"])
	return ""


func _spoon_passed_text(from_idx: int, to_idx: int, spoon_type: String) -> String:
	var from_name: String = _player_name(from_idx)
	var to_name: String = _player_name(to_idx)
	match spoon_type:
		"anchorless_exiled":
			return "%s tosses the Anchorless Spoon into the middle!" % from_name
		"spinner_redirect":
			return "The Spinner Spoon whirls on to %s!" % to_name
		_:
			var label: String = SPOON_LABELS.get(spoon_type, "Spoon")
			if from_idx == to_idx:
				return "%s keeps hold of the %s." % [from_name, label]
			return "%s passes the %s to %s." % [from_name, label, to_name]


# --- SpoonGame signal handlers ---------------------------------------------

func _on_die_rolled(roll: int) -> void:
	_last_roll = roll
	_enqueue_event({"type": "roll", "player_idx": _game.active_idx, "roll": roll})
	Audio.play("dice_roll")


func _on_spoon_passed(from_idx: int, to_idx: int, spoon_type: String) -> void:
	_enqueue_event({"type": "pass", "from_idx": from_idx, "to_idx": to_idx, "spoon_type": spoon_type})
	if from_idx != to_idx:
		Audio.play("spoon_pass")


func _on_spoon_discarded(player_idx: int, spoon_type: String) -> void:
	_enqueue_event({"type": "discard", "player_idx": player_idx, "spoon_type": spoon_type})
	Audio.play("spoon_pass")


func _on_power_activated(player_idx: int, spoon_type: String) -> void:
	_enqueue_event({"type": "power", "player_idx": player_idx, "spoon_type": spoon_type})
	Audio.play("spoon_power")
	if player_idx == 0:
		GameManager.spoon_power_used.emit(spoon_type)


func _on_direction_changed(direction: int) -> void:
	_enqueue_event({"type": "direction", "direction": direction})


func _on_player_eliminated(idx: int) -> void:
	_enqueue_event({"type": "eliminate", "idx": idx})
	Audio.play("spoon_eliminate")


func _on_game_over(winner_idx: int) -> void:
	_ended = true
	_winner_idx = winner_idx
	_enqueue_event({"type": "game_over", "winner_idx": winner_idx})
	if winner_idx == 0:
		Audio.play("spoon_victory")
		GameManager.spoon_game_won.emit()
	else:
		Audio.play("defeat")


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
	elif _human_step == HumanStep.DISCARD_SPOON:
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
			Audio.play("ui_select")
			_resolve_human_discard(hand[_hand_cursor])
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_exit_to_overworld()
		get_viewport().set_input_as_handled()


func _handle_game_over_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		Audio.play("ui_select")
		_play_again()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		Audio.play("ui_select")
		_exit_to_overworld()
		get_viewport().set_input_as_handled()


func _play_again() -> void:
	_phase = Phase.SELECT_CHARACTER
	_game = null
	_ended = false
	_winner_idx = -1
	_event_queue.clear()
	_current_event = {}
	_action_text = ""
	queue_redraw()


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
	_draw_header_panel()
	_draw_player_circle()
	_draw_event_animation()
	if _human_step == HumanStep.NONE:
		_draw_action_panel(MAIN_PANEL)
	elif _human_step == HumanStep.CHOOSE_SPOON:
		_draw_choose_spoon_panel()
	elif _human_step == HumanStep.CHOOSE_ACTIVATE:
		_draw_choose_activate_panel()
	elif _human_step == HumanStep.DISCARD_SPOON:
		_draw_discard_spoon_panel()


func _draw_header_panel() -> void:
	_draw_panel(HEADER_PANEL)
	_draw_direction_indicator(HEADER_PANEL.position + Vector2(16.0, 14.0))
	_draw_die(Rect2(HEADER_PANEL.position.x + HEADER_PANEL.size.x - 64.0, HEADER_PANEL.position.y + 8.0, 48.0, 48.0), _last_roll)


func _draw_player_circle() -> void:
	# Poker table under the seats; the spoon pile sits on its felt. Anchored by the
	# felt centre (the table art has the felt high-left and legs sprawling below),
	# sized so the felt fits inside the seat ring with players around its edge.
	if _table_tex != null:
		var tw: float = TABLE_DRAW_WIDTH
		var th: float = tw * float(_table_tex.get_height()) / float(_table_tex.get_width())
		var top_left: Vector2 = CIRCLE_CENTER - Vector2(tw * TABLE_FELT_UV.x, th * TABLE_FELT_UV.y)
		draw_texture_rect(_table_tex, Rect2(top_left, Vector2(tw, th)), false)
	_draw_middle_pile()
	for i in _game.players.size():
		var player: Dictionary = _game.players[i]
		var token_pos: Vector2 = _token_pos(i)
		var base_color: Color = player["color"] if player["alive"] else ELIMINATED_COLOR
		var color: Color = base_color
		var radius: float = TOKEN_RADIUS
		var is_winner: bool = _ended and i == _winner_idx

		if _current_event.get("type") == "eliminate" and _current_event["idx"] == i:
			var t: float = clampf(_event_timer / EVENT_DURATIONS["eliminate"], 0.0, 1.0)
			color = base_color.lerp(Color(1.0, 0.2, 0.2, 1.0), 1.0 - t)
			radius = TOKEN_RADIUS * (1.0 + 0.15 * sin(t * PI))
		elif _current_event.get("type") == "game_over" and _current_event["winner_idx"] == i:
			var t: float = clampf(_event_timer / EVENT_DURATIONS["game_over"], 0.0, 1.0)
			radius = TOKEN_RADIUS * (1.0 + 0.25 * sin(t * PI))
			color = base_color.lerp(Color(1.0, 1.0, 0.6, 1.0), 0.5 * sin(t * PI))

		if i == _game.active_idx and not _ended:
			var pulse: float = (sin(_pulse_time * 5.0) + 1.0) * 0.5
			draw_arc(token_pos, TOKEN_RADIUS + 6.0 + pulse * 4.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.4 + pulse * 0.5), 3.0)

		if _human_step != HumanStep.NONE and i == _pending_recipient_idx:
			var recipient_pulse: float = (sin(_pulse_time * 5.0) + 1.0) * 0.5
			draw_arc(token_pos, TOKEN_RADIUS + 6.0 + recipient_pulse * 4.0, 0.0, TAU, 32, RECIPIENT_RING_COLOR, 3.0)

		if _seated.has(player["name"]):
			# Seated billboard: a colored seat pad behind the figure keeps each
			# player's color identity; the sprite replaces the drawn face token.
			draw_circle(token_pos + Vector2(0.0, TOKEN_RADIUS * 0.5), radius * 0.7,
				Color(color.r, color.g, color.b, 0.5))
			var fig_mod: Color = Color.WHITE if player["alive"] else ELIMINATED_COLOR
			if _current_event.get("type") == "eliminate" and _current_event["idx"] == i:
				fig_mod = color
			_draw_seated(token_pos, player["name"], i == _game.active_idx and not _ended,
				player["alive"], fig_mod)
		else:
			draw_circle(token_pos, radius, color)
			draw_arc(token_pos, radius, 0.0, TAU, 32, BORDER_COLOR, 1.5)
			_draw_face(token_pos, player, is_winner)
		_draw_hand_spoons(token_pos, player, i)

		if is_winner:
			var glow: float = 0.6 + 0.4 * sin(_pulse_time * 4.0)
			draw_arc(token_pos, radius + 6.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.2, glow), 4.0)

		var name_color: Color = TEXT_COLOR if player["alive"] else DIM_COLOR
		draw_string(_font, token_pos + Vector2(-NAME_LABEL_WIDTH * 0.5, NAME_Y_OFFSET), String(player["name"]), HORIZONTAL_ALIGNMENT_CENTER, NAME_LABEL_WIDTH, 16, name_color)

		if player.get("shielded", false):
			draw_string(_font, token_pos + Vector2(-NAME_LABEL_WIDTH * 0.5, -TOKEN_RADIUS - 10.0), "SHIELDED", HORIZONTAL_ALIGNMENT_CENTER, NAME_LABEL_WIDTH, 12, SPOON_ACCENT_COLORS["anchor"])


func _draw_middle_pile() -> void:
	var count: int = _game.discarded_count
	draw_string(_font, CIRCLE_CENTER + Vector2(-60.0, -56.0), "PILE: %d" % count, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 14, HINT_COLOR)

	var shown: int = mini(count, MIDDLE_PILE_MAX_ICONS)
	for i in shown:
		var col: int = i % MIDDLE_PILE_ICON_COLS
		var row: int = floori(float(i) / float(MIDDLE_PILE_ICON_COLS))
		var x: float = CIRCLE_CENTER.x + (float(col) - float(MIDDLE_PILE_ICON_COLS - 1) * 0.5) * MIDDLE_PILE_ICON_SPACING
		var y: float = CIRCLE_CENTER.y - 30.0 + float(row) * MIDDLE_PILE_ICON_SPACING
		_draw_spoon_icon(Vector2(x, y), "standard", MIDDLE_PILE_ICON_SCALE)

	if _ended and _winner_idx == -1:
		var glow: float = 0.6 + 0.4 * sin(_pulse_time * 4.0)
		draw_arc(CIRCLE_CENTER, MIDDLE_PILE_GLOW_RADIUS, 0.0, TAU, 32, Color(1.0, 0.85, 0.2, glow), 4.0)


func _draw_face(token_pos: Vector2, player: Dictionary, is_winner: bool) -> void:
	var frames: SpriteFrames = _portraits.get(player["name"], null)
	if frames != null:
		var tex: Texture2D = frames.get_frame_texture("talk_closeup", 0)
		var rect := Rect2(token_pos - Vector2(FACE_SPRITE_SIZE, FACE_SPRITE_SIZE) * 0.5, Vector2(FACE_SPRITE_SIZE, FACE_SPRITE_SIZE))
		var face_modulate: Color = Color.WHITE if player["alive"] else Color(0.4, 0.4, 0.45, 1.0)
		draw_texture_rect(tex, rect, false, face_modulate)
		return

	# Procedural fallback face for roster members without sprite art (Uncle Doug)
	if not player["alive"]:
		for side in [-1.0, 1.0]:
			var c: Vector2 = token_pos + Vector2(FACE_EYE_OFFSET.x * side, FACE_EYE_OFFSET.y)
			var r: float = FACE_EYE_RADIUS + 1.5
			draw_line(c + Vector2(-r, -r), c + Vector2(r, r), FACE_FEATURE_COLOR, 2.0)
			draw_line(c + Vector2(-r, r), c + Vector2(r, -r), FACE_FEATURE_COLOR, 2.0)
		draw_arc(token_pos + Vector2(0.0, 16.0), 10.0, PI + 0.3, TAU - 0.3, 12, FACE_FEATURE_COLOR, 2.0)
		return

	for side in [-1.0, 1.0]:
		var c: Vector2 = token_pos + Vector2(FACE_EYE_OFFSET.x * side, FACE_EYE_OFFSET.y)
		draw_circle(c, FACE_EYE_RADIUS, FACE_FEATURE_COLOR)

	if is_winner:
		draw_arc(token_pos, 14.0, 0.2, PI - 0.2, 12, FACE_FEATURE_COLOR, 2.5)
	else:
		draw_arc(token_pos + Vector2(0.0, -2.0), 10.0, 0.35, PI - 0.35, 10, FACE_FEATURE_COLOR, 2.0)


func _draw_hand_spoons(token_pos: Vector2, player: Dictionary, idx: int) -> void:
	var hand: Array = player["hand"]
	if hand.is_empty():
		return
	var shown: int = mini(hand.size(), HAND_SPOON_MAX_ICONS)
	var total_width: float = float(shown - 1) * HAND_SPOON_SPACING
	var start_x: float = token_pos.x - total_width * 0.5
	var y: float = token_pos.y + HAND_SPOON_Y_OFFSET
	for i in shown:
		var spoon_type: String = hand[i] if idx == 0 else "standard"
		_draw_spoon_icon(Vector2(start_x + float(i) * HAND_SPOON_SPACING, y), spoon_type, HAND_SPOON_SCALE)
	if hand.size() > HAND_SPOON_MAX_ICONS:
		draw_string(_font, Vector2(start_x + total_width + 8.0, y + 4.0), "+%d" % (hand.size() - HAND_SPOON_MAX_ICONS), HORIZONTAL_ALIGNMENT_LEFT, 30.0, 11, TEXT_COLOR)


func _draw_direction_indicator(origin: Vector2) -> void:
	var highlight: float = 0.0
	if _current_event.get("type") == "direction":
		highlight = 1.0 - clampf(_event_timer / EVENT_DURATIONS["direction"], 0.0, 1.0)
	var label: String = "Direction: Clockwise" if _game.direction == 1 else "Direction: Counter-clockwise"
	var color: Color = TEXT_COLOR.lerp(SELECTED_COLOR, highlight)
	draw_string(_font, origin + Vector2(0.0, 4.0), label, HORIZONTAL_ALIGNMENT_LEFT, 360.0, 14, color)
	var arrow_y: float = origin.y + 24.0
	if _game.direction == 1:
		draw_colored_polygon(PackedVector2Array([Vector2(origin.x, arrow_y), Vector2(origin.x, arrow_y + 16.0), Vector2(origin.x + 20.0, arrow_y + 8.0)]), color)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(origin.x + 20.0, arrow_y), Vector2(origin.x + 20.0, arrow_y + 16.0), Vector2(origin.x, arrow_y + 8.0)]), color)


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


func _draw_spoon_icon(center: Vector2, spoon_type: String, icon_scale: float = 1.0) -> void:
	var bowl_radius: float = 8.0 * icon_scale
	draw_circle(center, bowl_radius, Color(0.85, 0.85, 0.9, 1.0))
	draw_arc(center, bowl_radius, 0.0, TAU, 16, Color(0.4, 0.4, 0.45, 1.0), 1.5)
	draw_rect(Rect2(center + Vector2(-2.0 * icon_scale, bowl_radius * 0.4), Vector2(4.0 * icon_scale, 14.0 * icon_scale)), Color(0.85, 0.85, 0.9, 1.0))
	var glyph: String = SPOON_GLYPHS.get(spoon_type, "")
	if glyph != "":
		var accent: Color = SPOON_ACCENT_COLORS.get(spoon_type, Color.WHITE)
		draw_circle(center, bowl_radius * 0.6, accent)
		if icon_scale >= 0.8:
			draw_string(_font, center + Vector2(-4.0, 4.0) * icon_scale, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(8, roundi(11.0 * icon_scale)), Color.BLACK)


func _draw_panel(rect: Rect2) -> void:
	draw_rect(rect, PANEL_COLOR)
	draw_rect(rect, BORDER_COLOR, false, 2.0)


func _draw_action_panel(rect: Rect2) -> void:
	_draw_panel(rect)
	draw_multiline_string(_font, Vector2(rect.position.x + 20.0, rect.position.y + rect.size.y * 0.5 - 10.0), _action_text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 40.0, 20, -1, TEXT_COLOR)


func _draw_event_animation() -> void:
	if _current_event.is_empty():
		return
	match _current_event["type"]:
		"pass":
			_draw_pass_animation(_current_event, clampf(_event_timer / EVENT_DURATIONS["pass"], 0.0, 1.0))
		"discard":
			_draw_discard_animation(_current_event, clampf(_event_timer / EVENT_DURATIONS["discard"], 0.0, 1.0))
		"power":
			_draw_power_animation(_current_event, clampf(_event_timer / EVENT_DURATIONS["power"], 0.0, 1.0))


func _draw_pass_animation(event: Dictionary, t: float) -> void:
	var spoon_type: String = event["spoon_type"]
	var from_pos: Vector2 = _token_pos(event["from_idx"])

	if spoon_type == "anchorless_exiled":
		var exile_pos: Vector2 = from_pos.lerp(CIRCLE_CENTER, t)
		_draw_spoon_icon(exile_pos, "anchorless", 1.1 * (1.0 - t))
		return

	if spoon_type == "spinner_redirect":
		spoon_type = "spinner"

	if event["from_idx"] == event["to_idx"]:
		return

	var to_pos: Vector2 = _token_pos(event["to_idx"])
	var pos: Vector2 = from_pos.lerp(to_pos, t)
	var arc_lift: float = sin(t * PI) * 40.0
	pos += (CIRCLE_CENTER - pos).normalized() * arc_lift
	_draw_spoon_icon(pos, spoon_type, 1.1)


func _draw_discard_animation(event: Dictionary, t: float) -> void:
	var from_pos: Vector2 = _token_pos(event["player_idx"])
	var pos: Vector2 = from_pos.lerp(CIRCLE_CENTER, t)
	_draw_spoon_icon(pos, event["spoon_type"], 1.1 * (1.0 - t))


func _draw_power_animation(event: Dictionary, t: float) -> void:
	var token_pos: Vector2 = _token_pos(event["player_idx"])
	var accent: Color = SPOON_ACCENT_COLORS.get(event["spoon_type"], SELECTED_COLOR)
	var radius: float = TOKEN_RADIUS + 4.0 + t * 28.0
	draw_arc(token_pos, radius, 0.0, TAU, 32, Color(accent.r, accent.g, accent.b, 1.0 - t), 3.0)


func _draw_choose_spoon_panel() -> void:
	var rect: Rect2 = MAIN_PANEL
	_draw_panel(rect)
	var pad: float = 16.0
	draw_string(_font, Vector2(rect.position.x + pad, rect.position.y + 26.0), "Your turn! Choose a spoon to pass:", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pad * 2.0, 15, TEXT_COLOR)
	_draw_recipient_line(rect, pad)
	_draw_hand_picker_body(rect, pad, _game.players[0]["hand"], "Select")


func _draw_discard_spoon_panel() -> void:
	var rect: Rect2 = MAIN_PANEL
	_draw_panel(rect)
	var pad: float = 16.0
	draw_string(_font, Vector2(rect.position.x + pad, rect.position.y + 26.0), "Rolled a %d! Toss a spoon into the middle:" % _last_roll, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pad * 2.0, 15, RECIPIENT_RING_COLOR)
	_draw_hand_picker_body(rect, pad, _game.players[0]["hand"], "Discard")


func _draw_hand_picker_body(rect: Rect2, pad: float, hand: Array, action_label: String) -> void:
	var list_top: float = rect.position.y + PICKER_LIST_TOP_OFFSET
	for i in hand.size():
		var spoon_type: String = hand[i]
		var row_y: float = list_top + float(i) * PICKER_ROW_HEIGHT
		var is_selected: bool = i == _hand_cursor
		if is_selected:
			draw_rect(Rect2(rect.position.x + pad * 0.5, row_y, rect.size.x - pad, PICKER_ROW_HEIGHT - 4.0), Color(1.0, 1.0, 1.0, 0.08))
		var icon_center := Vector2(rect.position.x + pad + 16.0, row_y + PICKER_ROW_HEIGHT * 0.5 - 2.0)
		_draw_spoon_icon(icon_center, spoon_type, PICKER_ICON_SCALE)
		var color: Color = SELECTED_COLOR if is_selected else TEXT_COLOR
		var prefix: String = "> " if is_selected else "   "
		draw_string(_font, Vector2(rect.position.x + pad + 40.0, row_y + PICKER_ROW_HEIGHT * 0.5 + 4.0), prefix + SPOON_LABELS.get(spoon_type, "Spoon"), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pad * 2.0 - 40.0, 15, color)

	var desc_rect := Rect2(rect.position.x, rect.position.y + rect.size.y - DESCRIPTION_BOX_HEIGHT - PICKER_HINT_HEIGHT, rect.size.x, DESCRIPTION_BOX_HEIGHT)
	_draw_spoon_description(desc_rect, hand[_hand_cursor] if not hand.is_empty() else "")

	draw_string(_font, Vector2(rect.position.x + pad, rect.position.y + rect.size.y - 12.0), "UP / DOWN  Choose     ENTER  %s" % action_label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pad * 2.0, 12, HINT_COLOR)


func _draw_spoon_description(rect: Rect2, spoon_type: String) -> void:
	draw_rect(rect, PANEL_COLOR.lightened(0.06))
	draw_rect(rect, BORDER_COLOR, false, 1.5)
	if not SPOON_DESCRIPTIONS.has(spoon_type):
		return
	var pad: float = 14.0
	var accent: Color = SPOON_ACCENT_COLORS.get(spoon_type, TEXT_COLOR)
	draw_string(_font, Vector2(rect.position.x + pad, rect.position.y + 24.0), SPOON_LABELS.get(spoon_type, "Spoon"), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pad * 2.0, 15, accent)
	draw_multiline_string(_font, Vector2(rect.position.x + pad, rect.position.y + 48.0), SPOON_DESCRIPTIONS[spoon_type], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pad * 2.0, 13, -1, TEXT_COLOR)


func _draw_recipient_line(rect: Rect2, pad: float) -> void:
	if _pending_recipient_idx < 0:
		return
	var text: String = "Rolled a %d -- passing to %s" % [_last_roll, _player_name(_pending_recipient_idx)]
	draw_string(_font, Vector2(rect.position.x + pad, rect.position.y + 48.0), text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pad * 2.0, 13, RECIPIENT_RING_COLOR)


func _draw_choose_activate_panel() -> void:
	var rect: Rect2 = MAIN_PANEL
	_draw_panel(rect)
	var pad: float = 16.0
	var label: String = SPOON_LABELS.get(_pending_spoon_type, "Spoon")
	draw_string(_font, Vector2(rect.position.x + pad, rect.position.y + 26.0), "Activate the %s?" % label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pad * 2.0, 15, TEXT_COLOR)
	_draw_recipient_line(rect, pad)

	var options: Array[String] = ["Yes, activate it", "No, pass it as-is"]
	var list_top: float = rect.position.y + PICKER_LIST_TOP_OFFSET
	for i in options.size():
		var row_y: float = list_top + float(i) * PICKER_ROW_HEIGHT
		var is_selected: bool = i == _activate_cursor
		if is_selected:
			draw_rect(Rect2(rect.position.x + pad * 0.5, row_y, rect.size.x - pad, PICKER_ROW_HEIGHT - 4.0), Color(1.0, 1.0, 1.0, 0.08))
		var color: Color = SELECTED_COLOR if is_selected else TEXT_COLOR
		var prefix: String = "> " if is_selected else "   "
		draw_string(_font, Vector2(rect.position.x + pad + 8.0, row_y + PICKER_ROW_HEIGHT * 0.5 + 4.0), prefix + options[i], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pad * 2.0, 15, color)

	var desc_rect := Rect2(rect.position.x, rect.position.y + rect.size.y - DESCRIPTION_BOX_HEIGHT - PICKER_HINT_HEIGHT, rect.size.x, DESCRIPTION_BOX_HEIGHT)
	_draw_spoon_description(desc_rect, _pending_spoon_type)

	draw_string(_font, Vector2(rect.position.x + pad, rect.position.y + rect.size.y - 12.0), "UP / DOWN  Choose     ENTER  Select", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pad * 2.0, 12, HINT_COLOR)


func _draw_game_over() -> void:
	_draw_title()
	_draw_player_circle()
	_draw_panel(MAIN_PANEL)
	var winner_name: String = "THE PILE" if _winner_idx == -1 else _player_name(_winner_idx).to_upper()
	draw_string(_font, Vector2(MAIN_PANEL.position.x, MAIN_PANEL.position.y + MAIN_PANEL.size.y * 0.5 - 16.0), winner_name, HORIZONTAL_ALIGNMENT_CENTER, MAIN_PANEL.size.x, 30, TITLE_COLOR)
	draw_string(_font, Vector2(MAIN_PANEL.position.x, MAIN_PANEL.position.y + MAIN_PANEL.size.y * 0.5 + 24.0), "WINS!", HORIZONTAL_ALIGNMENT_CENTER, MAIN_PANEL.size.x, 30, TITLE_COLOR)
	draw_string(_font, Vector2(0.0, 690.0), "ENTER  Play Again     ESC  Back to town", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 13, HINT_COLOR)
