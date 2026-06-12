extends Node2D

# Draws an off-screen chevron arrow pointing toward any downed player when they
# fall outside the visible viewport.  Parented to the HUD CanvasLayer so all
# coordinates are screen-space (0,0)–(viewport_size).

const ARROW_SIZE: float = 12.0
const ARROW_MARGIN: float = 28.0

var _a: Player = null
var _b: Player = null

func setup(a: Player, b: Player) -> void:
	_a = a
	_b = b

func _process(_delta: float) -> void:
	if (is_instance_valid(_a) and _a.is_down()) or \
			(is_instance_valid(_b) and _b.is_down()):
		queue_redraw()

func _draw() -> void:
	if not is_instance_valid(_a) or not is_instance_valid(_b):
		return
	var vp_size := get_viewport_rect().size
	var canvas_tf := get_viewport().get_canvas_transform()
	for player in [_a, _b]:
		if not is_instance_valid(player) or not player.is_down():
			continue
		var screen_pos: Vector2 = canvas_tf * player.global_position
		var margin := ARROW_MARGIN + ARROW_SIZE
		var inner := Rect2(margin, margin,
				vp_size.x - margin * 2.0, vp_size.y - margin * 2.0)
		if inner.has_point(screen_pos):
			continue
		var center := vp_size * 0.5
		var dir := (screen_pos - center).normalized()
		_draw_chevron(_rect_edge(center, dir, inner), dir, player.data.sprite_color)

func _rect_edge(from: Vector2, dir: Vector2, bounds: Rect2) -> Vector2:
	var t := INF
	if dir.x > 0.0:
		t = minf(t, (bounds.end.x - from.x) / dir.x)
	elif dir.x < 0.0:
		t = minf(t, (bounds.position.x - from.x) / dir.x)
	if dir.y > 0.0:
		t = minf(t, (bounds.end.y - from.y) / dir.y)
	elif dir.y < 0.0:
		t = minf(t, (bounds.position.y - from.y) / dir.y)
	return from + dir * maxf(t, 0.0)

func _draw_chevron(tip: Vector2, dir: Vector2, color: Color) -> void:
	var perp := Vector2(-dir.y, dir.x)
	var base := tip - dir * ARROW_SIZE
	var p1 := tip
	var p2 := base + perp * (ARROW_SIZE * 0.65)
	var p3 := base - perp * (ARROW_SIZE * 0.65)
	var pts := PackedVector2Array([p1, p2, p3])
	draw_colored_polygon(pts, color.lightened(0.15))
	draw_polyline(PackedVector2Array([p1, p2, p3, p1]), Color.WHITE, 1.5)
