extends Node2D

# Loot box: a chest prop opened via the same proximity + Special interaction
# as the baseline puzzle-gate template (see CLAUDE.md "Puzzle-gate variety").
# On open it grants its ItemData to whichever character opened it, flips to
# its open palette, and stops responding — a level just calls `try_open()`
# from its existing `_on_special_used` handler alongside its puzzle-gate checks.
# No class_name — preload()+untyped var, same gotcha as HidingSpot/AnimalCompanion
# (see [[feedback-godot-technical]]).

const SIZE := Vector2(34.0, 26.0)
const RADIUS: float = 56.0
const CLOSED_COLOR := Color(0.5, 0.36, 0.2)
const OPEN_COLOR := Color(0.4, 1.0, 0.5)
const BAND_COLOR := Color(0.3, 0.22, 0.12)

var item: ItemData = null
var is_open: bool = false

func setup(item_data: ItemData, pos: Vector2, already_open: bool = false) -> void:
	item = item_data
	position = pos
	if already_open:
		is_open = true
		modulate = OPEN_COLOR
	queue_redraw()

# Returns true if this box was opened by the call (false if already open or
# the character isn't close enough) — lets a level chain it into its own
# proximity-gate `if`/`elif` ladder without duplicating the distance check.
func try_open(character_name: String, character_pos: Vector2) -> bool:
	if is_open or character_pos.distance_to(global_position) >= RADIUS:
		return false
	is_open = true
	GameManager.grant_item(character_name, item.id)
	Audio.play("special")
	modulate = OPEN_COLOR
	queue_redraw()
	return true

func _draw() -> void:
	var lid_color: Color = OPEN_COLOR if is_open else CLOSED_COLOR
	draw_rect(Rect2(-SIZE * 0.5, SIZE), lid_color)
	draw_rect(Rect2(Vector2(-SIZE.x * 0.5, -2.0), Vector2(SIZE.x, 4.0)), BAND_COLOR)
	draw_rect(Rect2(-SIZE * 0.5, SIZE), lid_color.darkened(0.4), false, 2.0)
