extends Node

signal bies_activated
signal bies_ended
signal characters_swapped
signal game_over
signal paused
signal unpaused

const UNLOCKS_CHARACTER: Dictionary = {
	"pipe_organ_works": "erin",
	"old_parish_church": "evan",
	"iron_strings_gym": "ben",
	"recording_studio": "ethan",
}

var active_player: Player = null
var standby_player: Player = null
var completed_locations: Array = []
var unlocked_characters: Array = ["quinn", "erin"]

func _ready() -> void:
	SaveManager.load_game()

func complete_location(id: String) -> void:
	if id not in completed_locations:
		completed_locations.append(id)
	var unlocked: String = UNLOCKS_CHARACTER.get(id, "")
	if unlocked != "" and unlocked not in unlocked_characters:
		unlocked_characters.append(unlocked)
	SaveManager.save_game()

const BIES_SLOWDOWN: float = 0.4
const BIES_DURATION: float = 5.0
const REVIVE_RADIUS: float = 48.0
const REVIVE_DECAY_RATE: float = 2.0

var _bies_active: bool = false
var _bies_timer: float = 0.0
var _game_over_active: bool = false
var _paused: bool = false
var _pre_pause_time_scale: float = 1.0

func _process(delta: float) -> void:
	if _game_over_active:
		if Input.is_action_just_pressed("ui_accept"):
			_retry_level()
		return

	if is_instance_valid(active_player) and Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()
	if _paused:
		return

	if _bies_active:
		_bies_timer -= delta / Engine.time_scale
		if _bies_timer <= 0.0:
			_end_bies()

	if not is_instance_valid(active_player):
		return

	if Input.is_action_just_pressed("bies_mode") and active_player.bies_charge >= 1.0:
		_activate_bies()

	if Input.is_action_just_pressed("swap"):
		swap_characters()

	if is_instance_valid(standby_player):
		standby_player.leash_to(active_player.global_position)
		_tick_revive(delta)

func _tick_revive(delta: float) -> void:
	if active_player.is_down() and standby_player.is_down():
		_trigger_game_over()
		return
	if active_player.is_down() or not standby_player.is_down():
		standby_player.revive_progress = maxf(standby_player.revive_progress - delta * REVIVE_DECAY_RATE, 0.0)
		return
	if active_player.global_position.distance_to(standby_player.global_position) <= REVIVE_RADIUS:
		standby_player.revive_progress = minf(standby_player.revive_progress + delta, Player.REVIVE_HOLD_DURATION)
		if standby_player.revive_progress >= Player.REVIVE_HOLD_DURATION:
			standby_player.revive()
	else:
		standby_player.revive_progress = maxf(standby_player.revive_progress - delta * REVIVE_DECAY_RATE, 0.0)

func toggle_pause() -> void:
	if _game_over_active:
		return
	_paused = not _paused
	if _paused:
		_pre_pause_time_scale = Engine.time_scale
		Engine.time_scale = 0.0
		Audio.play("ui_select")
		paused.emit()
	else:
		Engine.time_scale = _pre_pause_time_scale
		Audio.play("ui_select")
		unpaused.emit()

func is_paused() -> bool:
	return _paused

func is_game_over() -> bool:
	return _game_over_active

func _trigger_game_over() -> void:
	if _game_over_active:
		return
	_game_over_active = true
	_bies_active = false
	Engine.time_scale = 0.0
	Audio.play("defeat")
	game_over.emit()
	_show_game_over_overlay()

func _show_game_over_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	var label := Label.new()
	label.text = "TEAM DOWN\n\nThe duo regroups and tries again...\n\nPress ENTER to retry"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.offset_left = 340.0
	label.offset_top = 280.0
	label.offset_right = 940.0
	label.offset_bottom = 440.0
	layer.add_child(label)
	get_tree().current_scene.add_child(layer)

func _retry_level() -> void:
	_game_over_active = false
	_paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func register_players(p1: Player, p2: Player) -> void:
	active_player = p1
	standby_player = p2
	active_player.is_active = true
	standby_player.is_active = false

func swap_characters() -> void:
	if active_player == null or standby_player == null:
		return
	var prev: Player = active_player
	active_player = standby_player
	standby_player = prev
	active_player.is_active = true
	standby_player.is_active = false
	Audio.play("swap")
	characters_swapped.emit()

func _activate_bies() -> void:
	active_player.bies_charge = 0.0
	active_player.bies_charge_changed.emit(0.0)
	Engine.time_scale = BIES_SLOWDOWN
	_bies_timer = BIES_DURATION
	_bies_active = true
	Audio.play("bies")
	bies_activated.emit()

func _end_bies() -> void:
	Engine.time_scale = 1.0
	_bies_active = false
	bies_ended.emit()
