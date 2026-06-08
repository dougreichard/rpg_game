extends Node2D

# The location's entrance/exit — see CLAUDE.md "Doorways, camera-follow &
# multi-room levels". The duo spawns right beside it, so `check()` "arms"
# itself only once the active character has walked at least ARM_RADIUS away
# (prevents an instant-exit on scene load), then returns true the moment they
# come back within TRIGGER_RADIUS — at any point in the level, cleared or not.
# A level polls it from _process exactly like it polls loot boxes/puzzle props
# (see LootBox.try_open). No class_name — preload()+untyped var, same gotcha
# as LootBox/HidingSpot/AnimalCompanion (see [[feedback-godot-technical]]).

const SIZE := Vector2(40.0, 56.0)
const ARM_RADIUS: float = 96.0
const TRIGGER_RADIUS: float = 56.0
const FRAME_COLOR := Color(0.32, 0.24, 0.16)
const OPEN_COLOR := Color(0.08, 0.07, 0.1)
const ARMED_GLOW := Color(0.5, 0.85, 1.0, 0.5)

var _armed: bool = false

func setup(pos: Vector2) -> void:
	position = pos
	queue_redraw()

func check(player_pos: Vector2) -> bool:
	var d: float = player_pos.distance_to(global_position)
	if not _armed and d > ARM_RADIUS:
		_armed = true
		queue_redraw()
	return _armed and d < TRIGGER_RADIUS

func _draw() -> void:
	draw_rect(Rect2(-SIZE * 0.5, SIZE), FRAME_COLOR)
	var inset: Vector2 = SIZE * 0.7
	draw_rect(Rect2(-inset * 0.5, inset), OPEN_COLOR)
	if _armed:
		draw_rect(Rect2(-SIZE * 0.5, SIZE), ARMED_GLOW, false, 3.0)
