extends Node2D

# Darkness overlay for the Underground Tunnels  --  a world-space dark rect
# covering the entire level, with a soft glow centered on the active player.
# Instantiated by underground_tunnels.gd with z_index = 50 so it renders above
# all world content (floor, walls, enemies, players) but below any CanvasLayer
# (HUD etc.).  Update `light_pos` and call `queue_redraw()` each frame.

var world_rect: Rect2 = Rect2.EMPTY
var light_pos: Vector2 = Vector2.ZERO
var darkness_alpha: float = 0.82
var has_light: bool = false

const GLOW_STEPS: int = 10
const LANTERN_COLOR := Color(0.90, 0.70, 0.25)
const AMBIENT_COLOR := Color(0.22, 0.28, 0.34)
const LANTERN_RADIUS: float = 190.0
const AMBIENT_RADIUS: float = 65.0

func _draw() -> void:
	if world_rect == Rect2.EMPTY:
		return
	draw_rect(world_rect, Color(0.0, 0.01, 0.05, darkness_alpha))
	var glow_col: Color = LANTERN_COLOR if has_light else AMBIENT_COLOR
	var max_r: float = LANTERN_RADIUS if has_light else AMBIENT_RADIUS
	for i in GLOW_STEPS:
		var t: float = float(i) / float(GLOW_STEPS)
		var r: float = max_r * (1.0 - t * 0.72)
		var a: float = (1.0 - t) * (0.70 if has_light else 0.45)
		draw_circle(light_pos, r, Color(glow_col.r, glow_col.g, glow_col.b, a))
