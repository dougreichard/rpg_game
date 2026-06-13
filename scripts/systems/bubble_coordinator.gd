extends Node

# Drives ambient speech bubbles for a group of NPCs so only one speaks at a
# time. Callers register a Callable per NPC; the coordinator picks one at
# random (never the same NPC twice in a row) and invokes it on a shared timer.
# No class_name — use preload() + untyped var (see CLAUDE.md conventions).

const FIRE_INTERVAL_MIN: float = 8.0
const FIRE_INTERVAL_MAX: float = 16.0

var _entries: Array = []    # Array[Callable] — each fires one NPC's bubble
var _timer: float = 0.0
var _last_index: int = -1
var _pause_check: Callable = func() -> bool: return false

func _ready() -> void:
	_timer = randf_range(FIRE_INTERVAL_MIN, FIRE_INTERVAL_MAX)

# fire must be a Callable that shows the bubble and returns nothing.
func register(fire: Callable) -> void:
	_entries.append(fire)

# check must be a Callable() -> bool; when it returns true the coordinator
# skips firing but keeps the timer running so the gap stays natural.
func set_pause_check(check: Callable) -> void:
	_pause_check = check

func _process(delta: float) -> void:
	if _entries.is_empty():
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(FIRE_INTERVAL_MIN, FIRE_INTERVAL_MAX)
		if not _pause_check.call():
			_pick_and_fire()

func _pick_and_fire() -> void:
	var count: int = _entries.size()
	var idx: int = _last_index
	if count > 1:
		while idx == _last_index:
			idx = randi() % count
	else:
		idx = 0
	_last_index = idx
	_entries[idx].call()
