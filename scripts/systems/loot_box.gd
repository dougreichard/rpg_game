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
const CLOSED_COLOR := Color(0.48, 0.34, 0.18)
const OPEN_COLOR   := Color(0.35, 0.82, 0.42)
const BAND_COLOR   := Color(0.72, 0.6, 0.18)    # gold metal band
const LID_OFFSET   := 0.38                       # lid takes top 38% of height

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
	var wood: Color  = OPEN_COLOR if is_open else CLOSED_COLOR
	var dark: Color  = wood.darkened(0.38)
	var light: Color = wood.lightened(0.28)
	var half := SIZE * 0.5
	var lid_h := SIZE.y * LID_OFFSET

	# Body (lower portion)
	var body_rect := Rect2(-half.x, -half.y + lid_h, SIZE.x, SIZE.y - lid_h)
	draw_rect(body_rect, wood)
	draw_rect(body_rect, dark, false, 1.5)

	# Lid (upper portion, slightly lighter — arched top via a thin highlight)
	var lid_rect := Rect2(-half.x, -half.y, SIZE.x, lid_h + 1.0)
	draw_rect(lid_rect, light)
	draw_rect(lid_rect, dark, false, 1.5)
	# Arch highlight inside lid
	draw_line(Vector2(-half.x + 3.0, -half.y + 2.0),
			  Vector2( half.x - 3.0, -half.y + 2.0), light.lightened(0.15), 1.0)

	# Metal band across the join (gold)
	var band_y := -half.y + lid_h - 2.0
	draw_rect(Rect2(-half.x, band_y, SIZE.x, 5.0), BAND_COLOR)
	draw_rect(Rect2(-half.x, band_y, SIZE.x, 5.0), BAND_COLOR.darkened(0.3), false, 1.0)

	# Clasp / lock in the center of the band
	var clasp_w := 6.0
	var clasp_h := 6.0
	draw_rect(Rect2(-clasp_w * 0.5, band_y - 1.0, clasp_w, clasp_h),
			  BAND_COLOR.lightened(0.2))
	draw_rect(Rect2(-clasp_w * 0.5, band_y - 1.0, clasp_w, clasp_h),
			  BAND_COLOR.darkened(0.45), false, 1.0)
	# Keyhole dot
	if not is_open:
		draw_circle(Vector2(0.0, band_y + 2.5), 1.2, dark)

	# Corner brackets — small gold squares at 4 corners of body
	for cx: float in [-half.x, half.x - 4.0]:
		for cy: float in [-half.y + lid_h, half.y - 4.0]:
			draw_rect(Rect2(cx, cy, 4.0, 4.0), BAND_COLOR)

	# Wood grain lines on body (subtle horizontal stripes)
	var grain_col := wood.darkened(0.12)
	var gy: float = -half.y + lid_h + 5.0
	while gy < half.y - 2.0:
		draw_line(Vector2(-half.x + 2.0, gy), Vector2(half.x - 2.0, gy), grain_col, 0.5)
		gy += 5.0
