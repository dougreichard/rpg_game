extends CanvasLayer

# CRT/scanline post-processing overlay drawn on top of everything.
# Uses an inner Node2D since CanvasLayer itself can't _draw().

const SCANLINE_ALPHA: float = 0.18
const SCANLINE_STEP: int = 2

var _drawer: Node2D

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_drawer = _Drawer.new()
	add_child(_drawer)

# Inner drawable node — static overlay, only needs to draw once.
class _Drawer extends Node2D:
	func _ready() -> void:
		# No per-frame updates needed; overlay is static.
		pass

	func _draw() -> void:
		var w: float = 1280.0
		var h: float = 720.0

		# Horizontal scanlines every SCANLINE_STEP pixels
		var scan_col := Color(0.0, 0.0, 0.0, SCANLINE_ALPHA)
		var y: int = 0
		while y < int(h):
			draw_line(Vector2(0.0, float(y)), Vector2(w, float(y)), scan_col, 1.0)
			y += SCANLINE_STEP

		# Vignette — four gradient quads, one per edge, using per-vertex colors
		# so Godot interpolates a perfectly smooth dark-to-transparent gradient
		# with a single draw call per edge and zero banding.
		var reach: float = 110.0
		var dark  := Color(0.0, 0.0, 0.0, 0.30)
		var clear := Color(0.0, 0.0, 0.0, 0.0)
		# Top edge: dark at y=0, transparent at y=reach
		draw_polygon([Vector2(0.0, 0.0), Vector2(w, 0.0),
					  Vector2(w, reach), Vector2(0.0, reach)],
					 [dark, dark, clear, clear])
		# Bottom edge: transparent at y=h-reach, dark at y=h
		draw_polygon([Vector2(0.0, h - reach), Vector2(w, h - reach),
					  Vector2(w, h), Vector2(0.0, h)],
					 [clear, clear, dark, dark])
		# Left edge: dark at x=0, transparent at x=reach
		draw_polygon([Vector2(0.0, 0.0), Vector2(reach, 0.0),
					  Vector2(reach, h), Vector2(0.0, h)],
					 [dark, clear, clear, dark])
		# Right edge: transparent at x=w-reach, dark at x=w
		draw_polygon([Vector2(w - reach, 0.0), Vector2(w, 0.0),
					  Vector2(w, h), Vector2(w - reach, h)],
					 [clear, dark, dark, clear])
